require 'minitest/autorun'
require_relative '../../extensions/amnesia' # Update the relative path to `amnesia.rb` as necessary

class AmnesiaTest < Minitest::Test
  def setup
    puts "Setting up test environment for AmnesiaTest"
    
    # Create test directories and files
    @test_root = File.expand_path('../../../test', __dir__)
    FileUtils.mkdir_p(@test_root)

    @three_days_ago_file = File.join(@test_root, "Task three days old.txt")
    @four_days_ago_file = File.join(@test_root, "Task four days old.txt")
    @today_file = File.join(@test_root, "Task created today.txt")

    File.write(@three_days_ago_file, "Task content")
    FileUtils.touch(@three_days_ago_file, mtime: (Date.today - 3).to_time)

    File.write(@four_days_ago_file, "Task content")
    FileUtils.touch(@four_days_ago_file, mtime: (Date.today - 4).to_time)

    File.write(@today_file, "Task content")
    FileUtils.touch(@today_file)

    puts "Test environment setup complete"
  end

  def test_three_days_old_task
    # Verify that the three-days-old file remains unchanged
    assert File.exist?(@three_days_ago_file), "The file modified three days ago should remain unchanged."
  end

  def test_four_days_old_task_skulls
    # Simulate processing for four-day-old file
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")

    # Verify the file now has one skull emoji
    skull_file = File.join(@test_root, "💀Task four days old.txt")
    assert File.exist?(skull_file), "The file modified four days ago should have one skull emoji."
  end

  def test_task_archiving
    # Simulate progression to archiving
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)

    # Move through skull increments and archive
    FileUtils.touch(@four_days_ago_file, mtime: (Date.today - 7).to_time)
    system("ruby #{amnesia_extension_path} #{@test_root}")

    archived_file = File.join(File.join(@test_root, 'archived'), "💀💀💀💀Task four days old.txt")
    assert File.exist?(archived_file), "The file should be moved to archived with four skull emojis."
  end

  def test_today_file_remains
    # Verify today's file remains untouched
    assert File.exist?(@today_file), "The file created today should remain untouched."
  end
end