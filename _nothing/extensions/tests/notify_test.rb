require 'minitest/autorun'
require 'fileutils'
require 'date'

class NotifyTest < Minitest::Test
  def setup
    @test_root = File.expand_path('../../../../test', __dir__)
    @meta_file = File.join(@test_root, '_nothing', 'extensions', 'notify-meta.txt')
    
    # Clean up and create fresh test directory
    FileUtils.mkdir_p(@test_root)
    
    # Create test files
    @notify_file = File.join(@test_root, '2024-12-20+1200+.mytask.txt')
    @notify_file_2 = File.join(@test_root, '2024-12-20+1500+.another-task.txt')
    @no_notify_file = File.join(@test_root, '2024-12-20+1500.another-task-no-notify.txt')
    @normal_file = File.join(@test_root, '2024-12-20.normal-task.txt')
    @no_date_file = File.join(@test_root, 'justtask.txt')
    @repeat_file = File.join(@test_root, 'task.3d.txt')
    
    # Create test files
    File.write(@notify_file, 'Task content')
    File.write(@notify_file_2, 'Another task content')
    File.write(@no_notify_file, 'Another task content')
    File.write(@normal_file, 'Normal task content')
    File.write(@no_date_file, 'No date task content')
    File.write(@repeat_file, 'Repeat task content')

    @notify_dir = File.join(@test_root, '2024-12-20+1200+.mydir')
    @no_notify_dir = File.join(@test_root, '2024-12-20.mydir')
    @normal_dir = File.join(@test_root, 'just_mydir')

    # Create test directories
    FileUtils.mkdir_p(@notify_dir)
    FileUtils.mkdir_p(@no_notify_dir)
    FileUtils.mkdir_p(@normal_dir)
  end

  def teardown
    [@notify_file, @notify_file_2, @no_notify_file, @normal_file, @no_date_file, @repeat_file].each do |file|
      FileUtils.rm_rf(file)
    end
    FileUtils.rm_rf(@meta_file)

    [@notify_dir, @no_notify_dir, @normal_dir].each do |dir|
      FileUtils.rm_rf(dir)
    end
  end

  def test_identifies_files_with_plus_ending_first_part
    extension_path = File.expand_path('../../extensions/notify.rb', __dir__)
    
    # Capture the notification command that would be executed
    output = `ruby \"#{extension_path}\" \"#{@test_root}\" test`

    meta_file = File.join(@test_root, '_nothing', 'extensions', 'notify-meta.txt')
    
    # Read existing notifications
    notified_files = File.readlines(meta_file, chomp: true)

    # The test mode should return the filenames it would notify about
    assert_includes output, '2024-12-20+1200+.mytask.txt'
    assert_includes output, '2024-12-20+1500+.another-task.txt'
    refute_includes output, '2024-12-20.normal-task.txt'
    refute_includes output, 'justtask.txt'
    refute_includes output, 'task.3d.txt'
  end

  def test_creates_and_updates_meta_file
    extension_path = File.expand_path('../../extensions/notify.rb', __dir__)
    
    # First run should create meta file and add entries
    system("ruby #{extension_path} #{@test_root}")
    
    assert File.exist?(@meta_file), "Meta file should be created"
    meta_content = File.read(@meta_file)
    assert_includes meta_content, '2024-12-20+1200+.mytask.txt'
    assert_includes meta_content, '2024-12-20+1500+.another-task.txt'
    refute_includes meta_content, '2024-12-20+1500.another-task-no-notify.txt'
    
    # Create a new notification file after first run
    new_file = File.join(@test_root, '2024-12-20+1800+.new-task.txt')
    File.write(new_file, 'New task content')
    
    # Second run should only add the new file
    system("ruby #{extension_path} #{@test_root}")
    
    meta_content = File.read(@meta_file)
    assert_includes meta_content, '2024-12-20+1800+.new-task.txt'
    # 4 because there's that dir too. Bad code separation. Sorry.
    assert_equal 4, meta_content.lines.count, "Should have exactly three entries"
  end

  def test_handles_empty_meta_file
    extension_path = File.expand_path('../../extensions/notify.rb', __dir__)
    
    # Create empty meta file
    FileUtils.touch(@meta_file)
    
    # Run extension
    system("ruby #{extension_path} #{@test_root}")
    
    meta_content = File.read(@meta_file)
    assert_includes meta_content, '2024-12-20+1200+.mytask.txt'
    assert_includes meta_content, '2024-12-20+1500+.another-task.txt'
    refute_includes meta_content, '2024-12-20+1500.another-task-no-notify.txt'
  end

  def test_handles_duplicate_notifications
    extension_path = File.expand_path('../../extensions/notify.rb', __dir__)
    
    # First run to create notifications
    system("ruby #{extension_path} #{@test_root}")
    
    # Modify a file to simulate an update
    File.write(@notify_file, 'Updated content')
    
    # Second run shouldn't create duplicate entries
    system("ruby #{extension_path} #{@test_root}")
    
    meta_content = File.read(@meta_file)
    assert_equal 1, meta_content.lines.count { |line| line.include?('2024-12-20+1200+.mytask.txt') }
  end

  def test_identifies_directories_with_plus_ending_first_part
    extension_path = File.expand_path('../../extensions/notify.rb', __dir__)
    
    # Capture the notification command that would be executed
    output = `ruby \"#{extension_path}\" \"#{@test_root}\" test`
  
    # The test mode should return the directory names it would notify about
    assert_includes output, '2024-12-20+1200+.mydir'
    refute_includes output, '2024-12-20.mydir'
    refute_includes output, 'just_mydir'
  end

  def test_non_date_prefixed_directories
    extension_path = File.expand_path('../../extensions/notify.rb', __dir__)
    
    output = `ruby \"#{extension_path}\" \"#{@test_root}\" test`
  
    # Directories without date prefixes should not trigger notifications
    refute_includes output, 'just_mydir'
  end
end