require 'minitest/autorun'

class TestDueDateMovement < Minitest::Test
  def fuzzy_file_exists?(directory, base_filename)
    # Perform a fuzzy lookup in the specified directory
    Dir.entries(directory).any? do |file|
      file.gsub(/«/, '') == base_filename # Strip « emoji for comparison
    end
  end

  def fuzzy_log_match?(log_contents, expected_fragment)
    # Check if any line in the log contains the expected fragment, ignoring emojis
    log_contents.any? do |line|
      line.gsub(/«/, '').include?(expected_fragment)
    end
  end

  def setup
    # Create test task files in the 'later/' directory
    today_str = Date.today.strftime('%Y-%m-%d')
    yesterday_str = (Date.today - 1).strftime('%Y-%m-%d')
    tomorrow_str = (Date.today + 1).strftime('%Y-%m-%d')

    File.write(File.join(LATER_DIR, "#{yesterday_str}.Task overdue.txt"), "Overdue task")
    File.write(File.join(LATER_DIR, "#{today_str}.Task due today.txt"), "Due today task")
    File.write(File.join(LATER_DIR, "#{tomorrow_str}.Task due tomorrow.txt"), "Due tomorrow task")
    File.write(File.join(LATER_DIR, "Task no date.txt"), "No date task")
  end

  def test_due_date_movement
    # Run the main script with the test root directory
    system("ruby #{File.expand_path('../nothing.rb', __dir__)} #{TEST_ROOT}")
  
    # Verify overdue and due-today tasks were moved to the base directory
    assert fuzzy_file_exists?(TEST_ROOT, "#{(Date.today - 1).strftime('%Y-%m-%d')}.Task overdue.txt"),
           "Overdue task should have been moved to the base directory."
    assert fuzzy_file_exists?(TEST_ROOT, "#{Date.today.strftime('%Y-%m-%d')}.Task due today.txt"),
           "Due-today task should have been moved to the base directory."
  
    # Verify overdue and due-today tasks are no longer in '_later/'
    refute fuzzy_file_exists?(LATER_DIR, "#{(Date.today - 1).strftime('%Y-%m-%d')}.Task overdue.txt"),
           "Overdue task should no longer be in '_later'."
    refute fuzzy_file_exists?(LATER_DIR, "#{Date.today.strftime('%Y-%m-%d')}.Task due today.txt"),
           "Due-today task should no longer be in '_later'."
  
    # Verify future-dated tasks are moved back to '_later/'
    assert fuzzy_file_exists?(LATER_DIR, "#{(Date.today + 1).strftime('%Y-%m-%d')}.Task due tomorrow.txt"),
           "Tomorrow’s task should have been moved back to '_later'."
  
    # Verify no-date tasks remain in '_later/'
    assert fuzzy_file_exists?(LATER_DIR, "Task no date.txt"),
           "No-date task should remain in '_later'."
  
    # Verify activity log entries
    assert File.exist?(ACTIVITY_LOG), "Activity log should be created."
    activity_log_contents = File.readlines(ACTIVITY_LOG).map(&:strip)
  
    overdue_task_fragment = "Moved #{(Date.today - 1).strftime('%Y-%m-%d')}.Task overdue.txt from '_later' to '#{TEST_ROOT}'"
    due_today_task_fragment = "Moved #{Date.today.strftime('%Y-%m-%d')}.Task due today.txt from '_later' to '#{TEST_ROOT}'"
    future_task_fragment = "Moved #{(Date.today + 1).strftime('%Y-%m-%d')}.Task due tomorrow.txt from '#{TEST_ROOT}' to '_later'"
  
    assert fuzzy_log_match?(activity_log_contents, overdue_task_fragment),
           "Activity log should contain a log entry for overdue task."
    assert fuzzy_log_match?(activity_log_contents, due_today_task_fragment),
           "Activity log should contain a log entry for due-today task."
  
    refute fuzzy_log_match?(activity_log_contents, "Task no date.txt"),
           "Activity log should not contain any entry for a date-less task."
  
    # Verify no error log was created
    refute File.exist?(ERROR_LOG), "Error log should not exist if no errors occurred."
  end

  def test_future_date_task_moved_to_later
    future_date = (Date.today + 3).strftime('%Y-%m-%d') # Three days in the future
    future_task = File.join(TEST_ROOT, "#{future_date}.Future task.txt")
  
    # Create a file in the root directory with a future date
    File.write(future_task, "Task content for a future task")
  
    # Run the script
    system("ruby #{File.expand_path('../nothing.rb', __dir__)} #{TEST_ROOT}")
  
    # Verify the task is moved to '_later'
    assert fuzzy_file_exists?(LATER_DIR, "#{future_date}.Future task.txt"),
           "Future-dated task should have been moved to '_later'."
  
    # Verify the task is no longer in the root directory
    refute fuzzy_file_exists?(TEST_ROOT, "#{future_date}.Future task.txt"),
           "Future-dated task should no longer be in the root directory."
  end

  def test_time_based_movement
    # Set up a task with a date and time in the future
    future_time = Time.now + (2 * 60 * 60) # 2 hours from now
    future_date_str = future_time.strftime('%Y-%m-%d')
    future_time_str = future_time.strftime('%H%M')
    future_task = File.join(LATER_DIR, "#{future_date_str}+#{future_time_str}.Task future with time.txt")
  
    # Write the task file in '_later'
    File.write(future_task, "Task content for a future time task")
  
    # Run the script
    system("ruby #{File.expand_path('../nothing.rb', __dir__)} #{TEST_ROOT}")
  
    # Verify the task remains in '_later' because its time has not yet passed
    assert fuzzy_file_exists?(LATER_DIR, "#{future_date_str}+#{future_time_str}.Task future with time.txt"),
           "Future task with a specific time should remain in '_later' if its time has not yet passed."
  
    # Manually adjust the task time to simulate a past time
    past_time = Time.now - (2 * 60 * 60) # 2 hours ago
    past_date_str = past_time.strftime('%Y-%m-%d')
    past_time_str = past_time.strftime('%H%M')
    past_task = File.join(LATER_DIR, "#{past_date_str}+#{past_time_str}.Task past with time.txt")
    File.write(past_task, "Task content for a past time task")
  
    # Run the script again
    system("ruby #{File.expand_path('../nothing.rb', __dir__)} #{TEST_ROOT}")
  
    # Verify the past task is moved to the root because its time has passed
    assert fuzzy_file_exists?(TEST_ROOT, "#{past_date_str}+#{past_time_str}.Task past with time.txt"),
           "Past task with a specific time should be moved to the root if its time has passed."
  
    # Clean up
    File.delete(future_task) if File.exist?(future_task)
    File.delete(past_task) if File.exist?(past_task)
  end
end