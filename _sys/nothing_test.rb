require 'minitest/autorun'

class TestDueDateMovement < Minitest::Test
  def fuzzy_file_exists?(directory, base_filename)
    # Perform a fuzzy lookup in the specified directory
    Dir.entries(directory).any? do |file|
      file.gsub(/⚠️/, '') == base_filename # Strip ⚠️ emoji for comparison
    end
  end

  def fuzzy_log_match?(log_contents, expected_fragment)
    # Check if any line in the log contains the expected fragment, ignoring emojis
    log_contents.any? do |line|
      line.gsub(/⚠️/, '').include?(expected_fragment)
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
end