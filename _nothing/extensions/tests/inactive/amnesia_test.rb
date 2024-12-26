require 'minitest/autorun'
require_relative '../../extensions/amnesia' # Update the relative path to `amnesia.rb` as necessary

class AmnesiaTest < Minitest::Test
  def setup
    # Create test directories and files
    @test_root = File.expand_path('../../../../test', __dir__)
    FileUtils.mkdir_p(File.join(@test_root, '_done')) # Ensure 'archived' directory exists
  
    now = Time.now
    three_days_ago = now - (3 * 24 * 60 * 60) - (5 * 60) # 3 days ago, minus 5 minutes
    four_days_ago = now - (4 * 24 * 60 * 60) - (5 * 60) # 4 days ago, minus 5 minutes
    five_days_ago = now - (5 * 24 * 60 * 60) - (5 * 60) # 5 days ago, minus 5 minutes
    six_days_ago = now - (6 * 24 * 60 * 60) - (5 * 60) # 6 days ago, minus 5 minutes
  
    @three_days_ago_file = File.join(@test_root, "Task three days old.txt")
    @four_days_ago_file = File.join(@test_root, "Task four days old.txt")
    @five_days_ago_file = File.join(@test_root, "Task five days old.txt")
    @six_days_ago_file = File.join(@test_root, "Task six days old.txt")
    @today_file = File.join(@test_root, "Task created today.txt")
  
    File.write(@three_days_ago_file, "Task content")
    FileUtils.touch(@three_days_ago_file, mtime: three_days_ago)
  
    File.write(@four_days_ago_file, "Task content")
    FileUtils.touch(@four_days_ago_file, mtime: four_days_ago)
  
    File.write(@five_days_ago_file, "Task content")
    FileUtils.touch(@five_days_ago_file, mtime: five_days_ago)

    File.write(@six_days_ago_file, "Task content")
    FileUtils.touch(@six_days_ago_file, mtime: six_days_ago)
  
    File.write(@today_file, "Task content")
    FileUtils.touch(@today_file, mtime: now)

    # Dynamically calculate a date that will result in a single skull
    one_skull_date = (Date.today - 3).strftime('%Y-%m-%d') # 3 days ago
    @file_with_date_and_task = File.join(@test_root, "#{one_skull_date}.my task with date.txt")
    File.write(@file_with_date_and_task, "Task content")
    FileUtils.touch(@file_with_date_and_task, mtime: Time.now - (3 * 24 * 60 * 60)) # Set modified time to 3 days ago

    @file_without_date = File.join(@test_root, "my task wo date.txt")
    File.write(@file_without_date, "Task content")
    FileUtils.touch(@file_without_date, mtime: Time.now - (3 * 24 * 60 * 60)) # Set modified time to 3 days ago
  end

  def test_three_days_old_task
    # Verify that the three-days-old file gets one skull emoji
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")

    skull_file = File.join(@test_root, "»Task three days old.txt")
    assert File.exist?(skull_file), "The file modified three days ago should have one skull emoji."
  end

  def test_four_days_old_task
    # Verify that the four-days-old file gets two skull emojis
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")

    skull_file = File.join(@test_root, "»»Task four days old.txt")
    assert File.exist?(skull_file), "The file modified four days ago should have two skull emojis."
  end

  def test_five_days_old_task
    # Verify that the five-days-old file gets three skull emojis
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")

    skull_file = File.join(@test_root, "»»»Task five days old.txt")
    assert File.exist?(skull_file), "The file modified five days ago should have three skull emojis."
  end

  def test_six_days_old_task_done
    # Simulate progression to archiving
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")

    done_file = File.join(@test_root, '_done', "»»»»Task six days old.txt")
    assert File.exist?(done_file), "The file modified six days ago should be archived with four skull emojis."
  end

  def test_today_file_remains
    # Verify today's file remains untouched
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")

    assert File.exist?(@today_file), "The file created today should remain untouched."
  end

  def test_skull_emoji_placement
    # Run the amnesia script
    system("ruby #{@amnesia_extension_path} #{@test_root}")
  
    # Dynamically calculate expected filenames
    one_skull_date = (Date.today - 3).strftime('%Y-%m-%d')
    expected_with_date = File.join(@test_root, "#{one_skull_date}.»my task with date.txt")
    expected_without_date = File.join(@test_root, "»my task wo date.txt")
  
    # Assertions
    assert File.exist?(expected_with_date), "File with date did not have the skull added correctly."
    assert File.exist?(expected_without_date), "File without date did not have the skull added correctly."
  end
end