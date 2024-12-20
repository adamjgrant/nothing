#!/usr/bin/env ruby
require 'fileutils'
require 'minitest/autorun'
require 'date'

class TestDueDateMovement < Minitest::Test
  TEST_ROOT = File.expand_path(File.join(__dir__, 'test'))
  BASE_DIR = TEST_ROOT
  LATER_DIR = File.join(BASE_DIR, 'later')
  ACTIVITY_LOG = File.join(BASE_DIR, 'sys', 'activity.log')
  ERROR_LOG = File.join(BASE_DIR, 'sys', 'error.log')

  def setup
    # Ensure the test root directory exists and is clean
    FileUtils.rm_rf(TEST_ROOT) # Remove any existing test root directory
    FileUtils.mkdir_p(TEST_ROOT) # Create a clean test root directory

    # Create test task files in the 'later/' directory
    @today_str = Date.today.strftime('%Y%m%d')
    @yesterday_str = (Date.today - 1).strftime('%Y%m%d')
    @tomorrow_str = (Date.today + 1).strftime('%Y%m%d')

    FileUtils.mkdir_p(LATER_DIR) # Create the 'later' directory for tasks
    FileUtils.touch(File.join(LATER_DIR, "task_overdue.#{@yesterday_str}.txt"))
    FileUtils.touch(File.join(LATER_DIR, "task_due_today.#{@today_str}.txt"))
    FileUtils.touch(File.join(LATER_DIR, "task_due_tomorrow.#{@tomorrow_str}.txt"))
    FileUtils.touch(File.join(LATER_DIR, "task_no_date.txt"))
  end

  def test_due_date_movement
    # Run the main script with the test root directory
    system("ruby #{File.join(__dir__, '..', 'nothing.rb')} #{TEST_ROOT}")

    # Check that overdue and due-today tasks moved to the root directory
    assert File.exist?(File.join(BASE_DIR, "task_overdue.#{@yesterday_str}.txt")),
           "Overdue task should have been moved to the base directory."
    assert File.exist?(File.join(BASE_DIR, "task_due_today.#{@today_str}.txt")),
           "Due-today task should have been moved to the base directory."

    # Ensure overdue and due-today tasks are no longer in 'later/'
    refute File.exist?(File.join(LATER_DIR, "task_overdue.#{@yesterday_str}.txt")),
           "Overdue task should no longer be in 'later'."
    refute File.exist?(File.join(LATER_DIR, "task_due_today.#{@today_str}.txt")),
           "Due-today task should no longer be in 'later'."

    # Ensure future-dated and no-date tasks remain in 'later/'
    assert File.exist?(File.join(LATER_DIR, "task_due_tomorrow.#{@tomorrow_str}.txt")),
           "Tomorrow’s task should still be in 'later'."
    assert File.exist?(File.join(LATER_DIR, "task_no_date.txt")),
           "No-date task should remain in 'later'."

    # Check activity log for entries
    assert File.exist?(ACTIVITY_LOG), "Activity log should be created."
    activity_log_contents = File.read(ACTIVITY_LOG)
    assert activity_log_contents.include?("Moved task_overdue.#{@yesterday_str}.txt"),
           "Activity log should contain a log entry for overdue task."
    assert activity_log_contents.include?("Moved task_due_today.#{@today_str}.txt"),
           "Activity log should contain a log entry for due-today task."

    # Ensure no error log was created
    refute File.exist?(ERROR_LOG), "Error log should not exist if no errors occurred."
  end
end