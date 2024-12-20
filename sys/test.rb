#!/usr/bin/env ruby
require 'fileutils'
require 'minitest/autorun'
require 'date'

class TestDueDateMovement < Minitest::Test
  BASE_DIR = File.expand_path(File.join(__dir__, '..'))
  LATER_DIR = File.join(BASE_DIR, 'later')
  ARCHIVED_DIR = File.join(BASE_DIR, 'archived')
  SYS_DIR = File.join(BASE_DIR, 'sys')
  EXTENSIONS_DIR = File.join(BASE_DIR, 'extensions')
  ACTIVITY_LOG = File.join(SYS_DIR, 'activity.log')
  ERROR_LOG = File.join(SYS_DIR, 'error.log')

  def setup
    [LATER_DIR, ARCHIVED_DIR, SYS_DIR, EXTENSIONS_DIR].each do |dir|
      Dir.mkdir(dir) unless Dir.exist?(dir)
    end

    FileUtils.rm_f(ACTIVITY_LOG)
    FileUtils.rm_f(ERROR_LOG)
    cleanup_test_files

    @today_str = Date.today.strftime('%Y%m%d')
    @yesterday_str = (Date.today - 1).strftime('%Y%m%d')
    @tomorrow_str = (Date.today + 1).strftime('%Y%m%d')

    FileUtils.touch(File.join(LATER_DIR, "task_overdue.#{@yesterday_str}.txt"))
    FileUtils.touch(File.join(LATER_DIR, "task_due_today.#{@today_str}.txt"))
    FileUtils.touch(File.join(LATER_DIR, "task_due_tomorrow.#{@tomorrow_str}.txt"))
    FileUtils.touch(File.join(LATER_DIR, "task_no_date.txt"))
  end

  def teardown
    cleanup_test_files
  end

  def test_due_date_movement
    Dir.chdir(BASE_DIR) do
      system("ruby script.rb")
    end

    # Check that overdue & due-today tasks moved
    assert File.exist?(File.join(BASE_DIR, "task_overdue.#{@yesterday_str}.txt")),
           "Overdue task should have been moved."
    assert File.exist?(File.join(BASE_DIR, "task_due_today.#{@today_str}.txt")),
           "Due-today task should have been moved."

    # Tomorrow and no-date remain in later
    assert File.exist?(File.join(LATER_DIR, "task_due_tomorrow.#{@tomorrow_str}.txt")),
           "Tomorrow’s task should still be in later."
    assert File.exist?(File.join(LATER_DIR, "task_no_date.txt")),
           "No-date task should remain in later."

    # Activity log created
    assert File.exist?(ACTIVITY_LOG), "Activity log should be created."
    # No errors
    refute File.exist?(ERROR_LOG), "Error log should not exist if no errors."
  end

  private

  def cleanup_test_files
    # Remove test files from later and from BASE_DIR
    Dir.foreach(LATER_DIR) do |f|
      next if f == '.' || f == '..'
      FileUtils.rm(File.join(LATER_DIR, f))
    end

    Dir.foreach(BASE_DIR) do |f|
      next if f == '.' || f == '..' || File.directory?(File.join(BASE_DIR, f))
      if f.start_with?('task_overdue') || f.start_with?('task_due_today')
        FileUtils.rm(File.join(BASE_DIR, f))
      end
    end
  end
end