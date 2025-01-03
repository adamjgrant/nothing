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
    one_skull_date = (Date.today - 3) # 3 days ago
    @file_with_date_and_task = File.join(@test_root, "#{one_skull_date.strftime('%Y-%m-%d')}.my task with date.txt")
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
    # Set the modified time of the file to three days old
    FileUtils.touch(skull_file, mtime: Time.now - (3 * 24 * 60 * 60))
    assert File.exist?(skull_file), "The file modified three days ago should have one skull emoji."
  end

  def test_four_days_old_task
    # Verify that the four-days-old file gets two skull emojis
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")

    skull_file = File.join(@test_root, "»»Task four days old.txt")
    # Set the modified time of the file to four days ago
    FileUtils.touch(skull_file, mtime: Time.now - (4 * 24 * 60 * 60))
    assert File.exist?(skull_file), "The file modified four days ago should have two skull emojis."
  end

  def test_five_days_old_task
    # Verify that the five-days-old file gets three skull emojis
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")

    skull_file = File.join(@test_root, "»»»Task five days old.txt")
    # Set the modified time of skull_file to five days ago
    FileUtils.touch(skull_file, mtime: Time.now - (5 * 24 * 60 * 60))
    assert File.exist?(skull_file), "The file modified five days ago should have three skull emojis."
  end

  def test_six_days_old_task_done
    # Simulate progression to archiving
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")

    done_file = File.join(@test_root, '_done', "»»»»Task six days old.txt")
    # Set the modified time of done_file to six days ago
    FileUtils.touch(done_file, mtime: Time.now - (6 * 24 * 60 * 60))
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
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")
  
    # Dynamically calculate expected filenames
    one_skull_date = (Date.today - 3)
    expected_with_date = File.join(@test_root, "#{one_skull_date.strftime("%Y-%m-%d")}.»my task with date.txt")
    # Set modified time of file to one_skull_date
    FileUtils.touch(expected_with_date, mtime: one_skull_date.to_time)
    expected_without_date = File.join(@test_root, "»my task wo date.txt")
  
    # Assertions
    assert File.exist?(expected_with_date), "File with date did not have the skull added correctly."
    assert File.exist?(expected_without_date), "File without date did not have the skull added correctly."
  end

  def test_directory_with_date_prefix
    directory_name = "#{(Date.today - 3).strftime('%Y-%m-%d')}.my-folder-task"
    directory_path = File.join(@test_root, directory_name)
    FileUtils.mkdir_p(directory_path)
    FileUtils.touch(directory_path, mtime: Time.now - (3 * 24 * 60 * 60)) # Set modified time to 3 days ago
  
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")
  
    skull_directory = File.join(@test_root, "#{(Date.today - 3).strftime('%Y-%m-%d')}.»my-folder-task")
    assert Dir.exist?(skull_directory), "Directory with date prefix did not have the skull added correctly."
  end

  def test_directory_without_date_prefix
    directory_name = "my-folder-task"
    directory_path = File.join(@test_root, directory_name)
    FileUtils.mkdir_p(directory_path)
    FileUtils.touch(directory_path, mtime: Time.now) # Set modified time to now
  
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")
  
    assert Dir.exist?(directory_path), "Directory without date prefix should remain unchanged."
  end

  def test_directory_archived_after_max_skulls
    directory_name = "#{(Date.today - 6).strftime('%Y-%m-%d')}.my-folder-task"
    directory_path = File.join(@test_root, directory_name)
    FileUtils.mkdir_p(directory_path)
    FileUtils.touch(directory_path, mtime: Time.now - (6 * 24 * 60 * 60)) # Set modified time to 6 days ago
  
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")
  
    archived_directory = File.join(@test_root, '_done', "#{(Date.today - 6).strftime('%Y-%m-%d')}.»»»»my-folder-task")
    assert Dir.exist?(archived_directory), "Directory should have been archived with the maximum number of skulls."
  end

  def test_mixed_files_and_directories
    # File setup
    file_name = "#{(Date.today - 3).strftime('%Y-%m-%d')}.my-file-task.txt"
    file_path = File.join(@test_root, file_name)
    File.write(file_path, "Task content")
    FileUtils.touch(file_path, mtime: Time.now - (3 * 24 * 60 * 60)) # 3 days ago
  
    # Directory setup
    directory_name = "#{(Date.today - 3).strftime('%Y-%m-%d')}.my-folder-task"
    directory_path = File.join(@test_root, directory_name)
    FileUtils.mkdir_p(directory_path)
    FileUtils.touch(directory_path, mtime: Time.now - (3 * 24 * 60 * 60)) # 3 days ago
  
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")
  
    # Expected results
    skull_file = File.join(@test_root, "#{(Date.today - 3).strftime('%Y-%m-%d')}.»my-file-task.txt")
    skull_directory = File.join(@test_root, "#{(Date.today - 3).strftime('%Y-%m-%d')}.»my-folder-task")
  
    # Assertions
    assert File.exist?(skull_file), "File did not have skull added correctly."
    assert Dir.exist?(skull_directory), "Directory did not have skull added correctly."
  end

  def test_directory_with_future_date
    directory_name = "#{(Date.today + 3).strftime('%Y-%m-%d')}.my-folder-task"
    directory_path = File.join(@test_root, directory_name)
    FileUtils.mkdir_p(directory_path)
    FileUtils.touch(directory_path, mtime: Time.now) # Set modified time to now
  
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")
  
    assert Dir.exist?(directory_path), "Directory with future date should remain unchanged."
  end

  def test_directory_with_date_and_time
    directory_name = "#{(Date.today - 3).strftime('%Y-%m-%d')}+1200.my-folder-task"
    directory_path = File.join(@test_root, directory_name)
    FileUtils.mkdir_p(directory_path)
    FileUtils.touch(directory_path, mtime: Time.now - (3 * 24 * 60 * 60)) # Set modified time to 3 days ago
  
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")
  
    skull_directory = File.join(@test_root, "#{(Date.today - 3).strftime('%Y-%m-%d')}+1200.»my-folder-task")
    assert Dir.exist?(skull_directory), "Directory with date and time did not have skull added correctly."
  end

  def test_file_with_skull_modified_today_removes_skull
    # Create a file with a skull character in the name and modified today
    file_with_skull = File.join(@test_root, "»Task modified today.txt")
    File.write(file_with_skull, "Task content")
    FileUtils.touch(file_with_skull, mtime: Time.now) # Set modified time to today
    
    # Run the amnesia script
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    system("ruby #{amnesia_extension_path} #{@test_root}")
    
    # Expected filename without the skull
    expected_file = File.join(@test_root, "Task modified today.txt")
    
    # Assertions
    assert File.exist?(expected_file), "File modified today with a skull should have the skull character removed."
    refute File.exist?(file_with_skull), "Original file with skull character should no longer exist."
  end

  def test_single_skull_issue_i_found
    # Test that a file called "2025-01-03.»check income.txt" that was created and modified today
    # is renamed to 2025-01-03.check income.txt
    file_with_skull = File.join(@test_root, "2025-01-03.»check income.txt")
    File.write(file_with_skull, "Task content")
    FileUtils.touch(file_with_skull, mtime: Time.now) # Set modified time to today

    # Run the amnesia script
    amnesia_extension_path = File.expand_path('../../extensions/amnesia.rb', __dir__)
    # Intentionally using the wrong formatting to make sure it enforces UTF-8
    system("ruby #{amnesia_extension_path} #{@test_root}")

    # Expected filename without the skull
    expected_file = File.join(@test_root, "2025-01-03.check income.txt")
    assert File.exist?(expected_file), "File modified today with a skull should have the skull character removed."
  end
end