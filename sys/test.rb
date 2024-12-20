#!/usr/bin/env ruby
require 'fileutils'
require 'minitest/autorun'
require 'date'

class TestDueDateMovement < Minitest::Test
  TEST_ROOT = File.expand_path(File.join(__dir__, 'test'))
  BASE_DIR = TEST_ROOT
  LATER_DIR = File.join(BASE_DIR, 'later')
  EXTENSIONS_TESTS_DIR = File.join(BASE_DIR, 'extensions', 'tests')
  ACTUAL_TESTS_DIR = File.expand_path(File.join(__dir__, '..', 'extensions', 'tests'))
  ACTIVITY_LOG = File.join(BASE_DIR, 'sys', 'activity.log')
  ERROR_LOG = File.join(BASE_DIR, 'sys', 'error.log')

  def setup
    # Ensure the test root directory exists and is clean
    FileUtils.rm_rf(TEST_ROOT)
    FileUtils.mkdir_p(TEST_ROOT)
    FileUtils.mkdir_p(LATER_DIR)
    FileUtils.mkdir_p(EXTENSIONS_TESTS_DIR)
  
    # Copy all extension test files into the test root's extensions/tests directory
    Dir.glob(File.join(ACTUAL_TESTS_DIR, '*.rb')).each do |test_file|
      FileUtils.cp(test_file, EXTENSIONS_TESTS_DIR)
    end
  
    # Copy all extensions (active and inactive) into the test/extensions directory
    actual_extensions_dir = File.expand_path(File.join(__dir__, '..', 'extensions'))
    test_extensions_dir = File.join(TEST_ROOT, 'extensions')
    FileUtils.mkdir_p(test_extensions_dir)
  
    Dir.glob(File.join(actual_extensions_dir, '**', '*.rb')).each do |extension_file|
      relative_path = extension_file.sub(actual_extensions_dir + '/', '') # Preserve subdirectory structure
      target_path = File.join(test_extensions_dir, relative_path)
  
      # Ensure subdirectories are created
      FileUtils.mkdir_p(File.dirname(target_path))
      FileUtils.cp(extension_file, target_path)
    end
  
    # Move inactive extensions to active extensions for testing
    inactive_extensions_dir = File.join(test_extensions_dir, 'inactive')
    Dir.glob(File.join(inactive_extensions_dir, '*.rb')).each do |inactive_extension|
      active_extension_path = File.join(test_extensions_dir, File.basename(inactive_extension))
      FileUtils.mv(inactive_extension, active_extension_path)
    end
  
    # Create test task files in the 'later/' directory
    @today_str = Date.today.strftime('%Y%m%d')
    @yesterday_str = (Date.today - 1).strftime('%Y%m%d')
    @tomorrow_str = (Date.today + 1).strftime('%Y%m%d')
  
    FileUtils.touch(File.join(LATER_DIR, "#{@yesterday_str}.Task overdue.txt"))
    FileUtils.touch(File.join(LATER_DIR, "#{@today_str}.Task due today.txt"))
    FileUtils.touch(File.join(LATER_DIR, "#{@tomorrow_str}.Task due tomorrow.txt"))
    FileUtils.touch(File.join(LATER_DIR, "Task no date.txt")) # Date-less task
  
    puts "Contents of TEST_ROOT after setup:"
    puts Dir.glob("#{TEST_ROOT}/**/*").join("\n")
  end

  def test_due_date_movement
    # Run the main script with the test root directory
    system("ruby #{File.join(__dir__, '..', 'nothing.rb')} #{TEST_ROOT}")

    # Check that overdue and due-today tasks moved to the root directory
    assert File.exist?(File.join(BASE_DIR, "#{@yesterday_str}.Task overdue.txt")),
           "Overdue task should have been moved to the base directory."
    assert File.exist?(File.join(BASE_DIR, "#{@today_str}.Task due today.txt")),
           "Due-today task should have been moved to the base directory."

    # Ensure overdue and due-today tasks are no longer in 'later/'
    refute File.exist?(File.join(LATER_DIR, "#{@yesterday_str}.Task overdue.txt")),
           "Overdue task should no longer be in 'later'."
    refute File.exist?(File.join(LATER_DIR, "#{@today_str}.Task due today.txt")),
           "Due-today task should no longer be in 'later'."

    # Ensure future-dated and no-date tasks remain in 'later/'
    assert File.exist?(File.join(LATER_DIR, "#{@tomorrow_str}.Task due tomorrow.txt")),
           "Tomorrow’s task should still be in 'later'."
    assert File.exist?(File.join(LATER_DIR, "Task no date.txt")),
           "No-date task should remain in 'later'."

    # Check activity log for entries
    assert File.exist?(ACTIVITY_LOG), "Activity log should be created."
    activity_log_contents = File.read(ACTIVITY_LOG)
    assert activity_log_contents.include?("Moved #{@yesterday_str}.Task overdue.txt"),
           "Activity log should contain a log entry for overdue task."
    assert activity_log_contents.include?("Moved #{@today_str}.Task due today.txt"),
           "Activity log should contain a log entry for due-today task."
    refute activity_log_contents.include?("Task no date.txt"),
           "Activity log should not contain any entry for a date-less task."

    # Ensure no error log was created
    refute File.exist?(ERROR_LOG), "Error log should not exist if no errors occurred."
  end

  def test_extensions
    # Force load all test files before discovery
    puts "Loading extension test files..."
    Dir.glob(File.join(EXTENSIONS_TESTS_DIR, '*.rb')).each do |test_file|
      puts "Requiring test file: #{test_file}" # Debugging
      require test_file
    end
  
    # Discover subclasses of ExtensionTestBase
    puts "Discovering subclasses of ExtensionTestBase:"
    subclasses = ObjectSpace.each_object(Class).select do |klass|
      klass < ExtensionTestBase && klass != ExtensionTestBase
    end
  
    subclasses.each do |klass|
      puts "Found subclass: #{klass}"
    end
  
    if subclasses.empty?
      puts "No subclasses of ExtensionTestBase found."
    end
  
    subclasses.each do |klass|
      puts "Running tests for subclass: #{klass}"
      begin
        extension_test = klass.new('test_extensions') # Pass the test method name explicitly
        extension_test.run
      rescue NotImplementedError => e
        puts "ERROR: #{e.message}"
      rescue => e
        puts "Unexpected error while running #{klass}: #{e.message}"
        puts e.backtrace
      end
    end
  end
end

class ExtensionTestBase < Minitest::Test
  attr_reader :test_root

  def initialize(name, *args)
    @test_root = File.expand_path(File.join(__dir__, 'test'))
    super
  end

  # Override setup if needed in the child class
  def setup
    puts "Setting up for #{self.class.name}"
  end

  # Implement test_extensions in the child class
  def test_extensions
    raise NotImplementedError, "#{self.class.name} must implement test_extensions"
  end

  def run
    setup
    test_extensions
  end

  # Prevent ExtensionTestBase itself from being run
  def self.runnable_methods
    []
  end
end