require 'minitest/autorun'
require 'fileutils'
require 'date'

class HousekeeperTest < Minitest::Test
  def setup
    @test_root = File.expand_path('../../../../test', __dir__)
    @done_dir = File.join(@test_root, '_done')
    
    # Clean up and create fresh test directory
    FileUtils.rm_rf(@done_dir)
    FileUtils.mkdir_p(@done_dir)

    # Create an old file (7 months ago)
    @old_file = File.join(@done_dir, 'old_task.txt')
    File.write(@old_file, 'Old task content')
    old_time = Time.now - (7 * 30 * 24 * 60 * 60)
    File.utime(old_time, old_time, @old_file)

    # Create a recent file (3 months ago)
    @recent_file = File.join(@done_dir, 'recent_task.txt')
    File.write(@recent_file, 'Recent task content')
    recent_time = Time.now - (3 * 30 * 24 * 60 * 60)
    File.utime(recent_time, recent_time, @recent_file)

    # Create a file in root directory (should be ignored)
    @root_file = File.join(@test_root, 'root_task.txt')
    File.write(@root_file, 'Root task content')
    File.utime(old_time, old_time, @root_file)
  end

  def test_old_files_are_deleted
    # Run the extension
    extension_path = File.expand_path('../../extensions/housekeeper.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify old file was deleted
    refute File.exist?(@old_file), "File older than 6 months should be deleted"

    # Verify recent file still exists
    assert File.exist?(@recent_file), "File newer than 6 months should not be deleted"

    # Verify root file was not touched
    assert File.exist?(@root_file), "File outside _done directory should not be touched"
  end

  def test_handles_empty_directory
    # Clear the _done directory
    FileUtils.rm_rf(@done_dir)
    FileUtils.mkdir_p(@done_dir)

    # Run the extension
    extension_path = File.expand_path('../../extensions/housekeeper.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify directory still exists
    assert Dir.exist?(@done_dir), "_done directory should still exist"
  end

  def test_handles_subdirectories
    # Create a subdirectory with an old file
    subdir = File.join(@done_dir, 'subdir')
    FileUtils.mkdir_p(subdir)
    
    old_subdir_file = File.join(subdir, 'old_subdir_task.txt')
    File.write(old_subdir_file, 'Old subdir task content')
    old_time = Time.now - (7 * 30 * 24 * 60 * 60)
    File.utime(old_time, old_time, old_subdir_file)

    # Run the extension
    extension_path = File.expand_path('../../extensions/housekeeper.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify old file in subdirectory was deleted
    refute File.exist?(old_subdir_file), "Old file in subdirectory should be deleted"
    
    # Verify subdirectory still exists
    assert Dir.exist?(subdir), "Subdirectory should still exist"
  end
end