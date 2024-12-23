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

    @push_1d_dir = File.join(@test_root, '_push-1d')
    @push_1w_dir = File.join(@test_root, '_push-1w')
    @push_rand_dir = File.join(@test_root, '_push-rand')

    # Remove existing push directories to test their creation
    [@push_1d_dir, @push_1w_dir, @push_rand_dir].each do |dir|
      FileUtils.rm_rf(dir)
    end

    @extension_path = File.expand_path('../../extensions/push.rb', __dir__)
  end

  def test_directories_created
    system("ruby #{@extension_path} #{@test_root}")

    assert Dir.exist?(@push_1d_dir), "_push-1d directory was not created."
    assert Dir.exist?(@push_1w_dir), "_push-1w directory was not created."
    assert Dir.exist?(@push_rand_dir), "_push-rand directory was not created."
  end

  def test_push_1d
    filename = "#{@today.strftime('%Y-%m-%d')}.test-task.1d.txt"
    file_path = File.join(@push_1d_dir, filename)
    FileUtils.mkdir_p(@push_1d_dir) # Ensure the directory exists
    File.write(file_path, "Test content")

    system("ruby #{@extension_path} #{@test_root}")

    expected_filename = "#{(@today + 1).strftime('%Y-%m-%d')}.test-task.1d.txt"
    expected_file_path = File.join(@later_dir, expected_filename)
    assert File.exist?(expected_file_path), "File was not pushed to _later with +1 day."
  end

  def test_push_1w
    filename = "#{@today.strftime('%Y-%m-%d')}.test-task.1w.txt"
    file_path = File.join(@push_1w_dir, filename)
    FileUtils.mkdir_p(@push_1w_dir) # Ensure the directory exists
    File.write(file_path, "Test content")

    system("ruby #{@extension_path} #{@test_root}")

    expected_filename = "#{(@today + 7).strftime('%Y-%m-%d')}.test-task.1w.txt"
    expected_file_path = File.join(@later_dir, expected_filename)
    assert File.exist?(expected_file_path), "File was not pushed to _later with +1 week."
  end

  def test_push_rand
    filename = "#{@today.strftime('%Y-%m-%d')}.test-task.rand.txt"
    file_path = File.join(@push_rand_dir, filename)
    FileUtils.mkdir_p(@push_rand_dir) # Ensure the directory exists
    File.write(file_path, "Test content")

    system("ruby #{@extension_path} #{@test_root}")

    pushed_file = Dir.glob(File.join(@later_dir, "*.test-task.rand.txt")).first
    refute_nil pushed_file, "File was not pushed to _later with a random date."
    random_date = Date.strptime(File.basename(pushed_file).split('.').first, '%Y-%m-%d')
    expected_min_date = @today + 1
    expected_max_date = @today + 10

    assert random_date >= expected_min_date && random_date <= expected_max_date,
           "File was pushed with an invalid random date (#{random_date})."
  end

  def test_push_with_time_value
    # Test for _push-1d
    filename_1d = "#{@today.strftime('%Y-%m-%d')}+1300.test-task.1d.txt"
    file_path_1d = File.join(@push_1d_dir, filename_1d)
    FileUtils.mkdir_p(@push_1d_dir) # Ensure the directory exists
    File.write(file_path_1d, "Test content")

    # Test for _push-1w
    filename_1w = "#{@today.strftime('%Y-%m-%d')}+0930.test-task.1w.txt"
    file_path_1w = File.join(@push_1w_dir, filename_1w)
    FileUtils.mkdir_p(@push_1w_dir) # Ensure the directory exists
    File.write(file_path_1w, "Test content")

    # Test for _push-rand
    filename_rand = "#{@today.strftime('%Y-%m-%d')}+1800.test-task.rand.txt"
    file_path_rand = File.join(@push_rand_dir, filename_rand)
    FileUtils.mkdir_p(@push_rand_dir) # Ensure the directory exists
    File.write(file_path_rand, "Test content")

    system("ruby #{@extension_path} #{@test_root}")

    # Validate _push-1d file
    expected_filename_1d = "#{(@today + 1).strftime('%Y-%m-%d')}+1300.test-task.1d.txt"
    expected_file_path_1d = File.join(@later_dir, expected_filename_1d)
    assert File.exist?(expected_file_path_1d), "File with time value was not pushed to _later with +1 day."

    # Validate _push-1w file
    expected_filename_1w = "#{(@today + 7).strftime('%Y-%m-%d')}+0930.test-task.1w.txt"
    expected_file_path_1w = File.join(@later_dir, expected_filename_1w)
    assert File.exist?(expected_file_path_1w), "File with time value was not pushed to _later with +1 week."

    # Validate _push-rand file
    pushed_file_rand = Dir.glob(File.join(@later_dir, "*.test-task.rand.txt")).first
    refute_nil pushed_file_rand, "File with time value was not pushed to _later with a random date."
    random_date = Date.strptime(File.basename(pushed_file_rand).split('+').first, '%Y-%m-%d')
    expected_min_date = @today + 1
    expected_max_date = @today + 10

    assert random_date >= expected_min_date && random_date <= expected_max_date,
           "File with time value was pushed with an invalid random date (#{random_date})."
  end
end