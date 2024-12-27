require 'minitest/autorun'
require 'fileutils'
require 'date'

class PushExtensionTest < Minitest::Test
  def setup
    @today = Date.today
    @test_root = File.expand_path('test_push', __dir__)

    # Reference _later directory (assumed to exist)
    @later_dir = File.join(@test_root, '_later')
    FileUtils.mkdir_p(@later_dir) # Ensure _later exists

    @push_rand_dir = File.join(@test_root, '_push-rand')
    @push_1d_dir = File.join(@test_root, '_push-1d')
    @push_1w_dir = File.join(@test_root, '_push-1w')

    # Remove existing push directories to test their creation
    FileUtils.rm_rf(@push_rand_dir)

    @extension_path = File.expand_path('../../extensions/push.rb', __dir__)
  end

  def test_directories_created
    system("ruby #{@extension_path} #{@test_root}")

    assert Dir.exist?(@push_rand_dir), "_push-rand directory was not created."
  end

  def test_push_rand
    filename = "#{@today.strftime('%Y-%m-%d')}.test-task-rand.txt"
    file_path = File.join(@push_rand_dir, filename)
    FileUtils.mkdir_p(@push_rand_dir) # Ensure the directory exists
    File.write(file_path, "Test content")

    system("ruby #{@extension_path} #{@test_root}")

    pushed_file = Dir.glob(File.join(@later_dir, "*.test-task-rand.txt")).first
    refute_nil pushed_file, "File was not pushed to _later with a random date."
    random_date = Date.strptime(File.basename(pushed_file).split('.').first, '%Y-%m-%d')
    expected_min_date = @today + 1
    expected_max_date = @today + 10

    assert random_date >= expected_min_date && random_date <= expected_max_date,
           "File was pushed with an invalid random date (#{random_date})."
  end

  def test_push_with_time_value
    # Test for _push-1d
    filename_1d = "#{@today.strftime('%Y-%m-%d')}+1300.test-task.txt"
    file_path_1d = File.join(@push_1d_dir, filename_1d)
    FileUtils.mkdir_p(@push_1d_dir) # Ensure the directory exists
    File.write(file_path_1d, "Test content")

    # Test for _push-1w
    filename_1w = "#{@today.strftime('%Y-%m-%d')}+0930.test-task.txt"
    file_path_1w = File.join(@push_1w_dir, filename_1w)
    FileUtils.mkdir_p(@push_1w_dir) # Ensure the directory exists
    File.write(file_path_1w, "Test content")

    # Test for _push-rand
    filename_rand = "#{@today.strftime('%Y-%m-%d')}+1800.test-task-rand.txt"
    file_path_rand = File.join(@push_rand_dir, filename_rand)
    FileUtils.mkdir_p(@push_rand_dir) # Ensure the directory exists
    File.write(file_path_rand, "Test content")

    system("ruby #{@extension_path} #{@test_root}")

    # Validate _push-1d file
    expected_filename_1d = "#{(@today + 1).strftime('%Y-%m-%d')}+1300.test-task.txt"
    expected_file_path_1d = File.join(@later_dir, expected_filename_1d)
    assert File.exist?(expected_file_path_1d), "File with time value was not pushed to _later with +1 day."

    # Validate _push-1w file
    expected_filename_1w = "#{(@today + 7).strftime('%Y-%m-%d')}+0930.test-task.txt"
    expected_file_path_1w = File.join(@later_dir, expected_filename_1w)
    assert File.exist?(expected_file_path_1w), "File with time value was not pushed to _later with +1 week."

    # Validate _push-rand file
    pushed_file_rand = Dir.glob(File.join(@later_dir, "*.test-task-rand.txt")).first
    refute_nil pushed_file_rand, "File with time value was not pushed to _later with a random date."
    random_date = Date.strptime(File.basename(pushed_file_rand).split('+').first, '%Y-%m-%d')
    expected_min_date = @today + 1
    expected_max_date = @today + 10

    assert random_date >= expected_min_date && random_date <= expected_max_date,
           "File with time value was pushed with an invalid random date (#{random_date})."
  end

  def test_general_push_folders
    # Test for _push-3d
    push_3d_dir = File.join(@test_root, '_push-3d')
    filename_3d = "#{@today.strftime('%Y-%m-%d')}.test-task.txt"
    file_path_3d = File.join(push_3d_dir, filename_3d)
    FileUtils.mkdir_p(push_3d_dir)
    File.write(file_path_3d, "Test content")
  
    # Test for _push-2w
    push_2w_dir = File.join(@test_root, '_push-2w')
    filename_2w = "#{@today.strftime('%Y-%m-%d')}.test-task.txt"
    file_path_2w = File.join(push_2w_dir, filename_2w)
    FileUtils.mkdir_p(push_2w_dir)
    File.write(file_path_2w, "Test content")
  
    # Test for _push-6m
    push_6m_dir = File.join(@test_root, '_push-6m')
    filename_6m = "#{@today.strftime('%Y-%m-%d')}.test-task.txt"
    file_path_6m = File.join(push_6m_dir, filename_6m)
    FileUtils.mkdir_p(push_6m_dir)
    File.write(file_path_6m, "Test content")
  
    # Test for _push-1y
    push_1y_dir = File.join(@test_root, '_push-1y')
    filename_1y = "#{@today.strftime('%Y-%m-%d')}.test-task.txt"
    file_path_1y = File.join(push_1y_dir, filename_1y)
    FileUtils.mkdir_p(push_1y_dir)
    File.write(file_path_1y, "Test content")
  
    system("ruby #{@extension_path} #{@test_root}")
  
    # Validate _push-3d file
    expected_filename_3d = "#{(@today + 3).strftime('%Y-%m-%d')}.test-task.txt"
    expected_file_path_3d = File.join(@later_dir, expected_filename_3d)
    assert File.exist?(expected_file_path_3d), "File was not pushed to _later with +3 days."
  
    # Validate _push-2w file
    expected_filename_2w = "#{(@today + 14).strftime('%Y-%m-%d')}.test-task.txt"
    expected_file_path_2w = File.join(@later_dir, expected_filename_2w)
    assert File.exist?(expected_file_path_2w), "File was not pushed to _later with +2 weeks."
  
    # Validate _push-6m file
    expected_filename_6m = "#{(@today >> 6).strftime('%Y-%m-%d')}.test-task.txt"
    expected_file_path_6m = File.join(@later_dir, expected_filename_6m)
    assert File.exist?(expected_file_path_6m), "File was not pushed to _later with +6 months."
  
    # Validate _push-1y file
    expected_filename_1y = "#{(@today.next_year(1)).strftime('%Y-%m-%d')}.test-task.txt"
    expected_file_path_1y = File.join(@later_dir, expected_filename_1y)
    assert File.exist?(expected_file_path_1y), "File was not pushed to _later with +1 year."
  end

  def test_push_without_date
    # Test for files without dates in _push-1d
    push_1d_dir = File.join(@test_root, '_push-1d')
    filename_no_date = "my task.txt"
    file_path_no_date = File.join(push_1d_dir, filename_no_date)
    FileUtils.mkdir_p(push_1d_dir)
    File.write(file_path_no_date, "Test content")
  
    system("ruby #{@extension_path} #{@test_root}")
  
    # The expected filename should have today's date plus one day (since it's in push-1d)
    # and preserve the original filename after the date
    expected_filename = "#{(@today + 1).strftime('%Y-%m-%d')}.my task.txt"
    expected_file_path = File.join(@later_dir, expected_filename)
    
    assert File.exist?(expected_file_path), 
           "File without date was not properly pushed with today's date +1 day"
    
    # Also verify the original file was removed
    refute File.exist?(file_path_no_date),
           "Original file without date was not removed from push directory"
  end

  def test_push_1d_for_folder
    folder_name = "#{(Date.today - 1).strftime('%Y-%m-%d')}.folder-task"
    folder_path = File.join(@push_1d_dir, folder_name)
    FileUtils.mkdir_p(folder_path)
  
    system("ruby #{@extension_path} #{@test_root}")
  
    # Verify folder is moved to _later with date incremented by 1 day
    expected_folder_name = "#{Date.today.strftime('%Y-%m-%d')}.folder-task"
    expected_folder_path = File.join(@later_dir, expected_folder_name)
    assert Dir.exist?(expected_folder_path), "Folder in _push-1d was not processed correctly."
  end
  
  def test_push_1w_for_folder
    folder_name = "#{(Date.today - 7).strftime('%Y-%m-%d')}.folder-task"
    folder_path = File.join(@push_1w_dir, folder_name)
    FileUtils.mkdir_p(folder_path)
  
    system("ruby #{@extension_path} #{@test_root}")
  
    # Verify folder is moved to _later with date incremented by 7 days
    expected_folder_name = "#{Date.today.strftime('%Y-%m-%d')}.folder-task"
    expected_folder_path = File.join(@later_dir, expected_folder_name)
    assert Dir.exist?(expected_folder_path), "Folder in _push-1w was not processed correctly."
  end
  
  def test_push_rand_for_folder
    folder_name = "#{Date.today.strftime('%Y-%m-%d')}.folder-task"
    folder_path = File.join(@push_rand_dir, folder_name)
    FileUtils.mkdir_p(folder_path)
  
    system("ruby #{@extension_path} #{@test_root}")
  
    # Verify folder is moved to _later with date incremented by 1-10 days
    moved_folder = Dir.glob(File.join(@later_dir, '*.folder-task')).first
    assert Dir.exist?(moved_folder), "Folder in _push-rand was not processed correctly."
    
    moved_date = Date.strptime(File.basename(moved_folder).split('.').first, '%Y-%m-%d')
    assert_includes (Date.today..Date.today + 10), moved_date, "Folder in _push-rand was moved to an incorrect date."
  end
  
  def test_folder_without_date_prefix
    folder_name = "folder-without-date"
    folder_path = File.join(@push_1d_dir, folder_name)
    FileUtils.mkdir_p(folder_path)
  
    # Run the extension
    system("ruby #{@extension_path} #{@test_root}")
  
    # Expected folder name and path after the push operation
    expected_folder_name = "#{(Date.today+1).strftime('%Y-%m-%d')}.folder-without-date"
    expected_folder_path = File.join(@later_dir, expected_folder_name)
  
    # Verify the folder was moved and renamed correctly
    assert Dir.exist?(expected_folder_path), "Folder without date prefix should be moved with today's date plus 1."
    refute Dir.exist?(folder_path), "Original folder without date prefix should be removed after processing."
  end
  
  def test_future_dated_folder
    # Create a folder with a date one day in the future
    folder_name = "#{(Date.today + 1).strftime('%Y-%m-%d')}.folder-task"
    folder_path = File.join(@push_1d_dir, folder_name)
    FileUtils.mkdir_p(folder_path)
  
    # Run the extension
    system("ruby #{@extension_path} #{@test_root}")
  
    # Expected folder name and path after the push operation
    expected_folder_name = "#{(Date.today + 2).strftime('%Y-%m-%d')}.folder-task"
    expected_folder_path = File.join(LATER_DIR, expected_folder_name)
  
    # Verify the folder was moved and renamed correctly
    assert Dir.exist?(expected_folder_path), "Future-dated folder should be pushed to the correct future date."
  end
end