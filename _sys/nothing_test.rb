require 'minitest/autorun'

class TestDueDateMovement < Minitest::Test
  def fuzzy_file_exists?(directory, base_filename)
    # Perform a fuzzy lookup in the specified directory
    Dir.entries(directory).any? do |file|
      file.gsub(/⚠️/, '') == base_filename # Strip ⚠️ emoji for comparison
    end
  end

  def test_due_date_movement
    # Run the main script with the test root directory
    system("ruby #{File.expand_path('../nothing.rb', __dir__)} #{TEST_ROOT}")

    # Verify overdue and due-today tasks were moved to the base directory
    assert fuzzy_file_exists?(TEST_ROOT, "#{(Date.today - 1).strftime('%Y%m%d')}.Task overdue.txt"),
           "Overdue task should have been moved to the base directory."
    assert fuzzy_file_exists?(TEST_ROOT, "#{Date.today.strftime('%Y%m%d')}.Task due today.txt"),
           "Due-today task should have been moved to the base directory."

    # Verify overdue and due-today tasks are no longer in '_later/'
    refute fuzzy_file_exists?(LATER_DIR, "#{(Date.today - 1).strftime('%Y%m%d')}.Task overdue.txt"),
           "Overdue task should no longer be in '_later'."
    refute fuzzy_file_exists?(LATER_DIR, "#{Date.today.strftime('%Y%m%d')}.Task due today.txt"),
           "Due-today task should no longer be in '_later'."

    # Verify future-dated and no-date tasks remain in '_later/'
    assert fuzzy_file_exists?(LATER_DIR, "#{(Date.today + 1).strftime('%Y%m%d')}.Task due tomorrow.txt"),
           "Tomorrow’s task should still be in '_later'."
    assert fuzzy_file_exists?(LATER_DIR, "Task no date.txt"),
           "No-date task should remain in '_later'."

    # Verify activity log entries
    assert File.exist?(ACTIVITY_LOG), "Activity log should be created."
    activity_log_contents = File.read(ACTIVITY_LOG)
    assert activity_log_contents.include?("Moved #{(Date.today - 1).strftime('%Y%m%d')}.Task overdue.txt"),
           "Activity log should contain a log entry for overdue task."
    assert activity_log_contents.include?("Moved #{Date.today.strftime('%Y%m%d')}.Task due today.txt"),
           "Activity log should contain a log entry for due-today task."
    refute activity_log_contents.include?("Task no date.txt"),
           "Activity log should not contain any entry for a date-less task."

    # Verify no error log was created
    refute File.exist?(ERROR_LOG), "Error log should not exist if no errors occurred."
  end
end