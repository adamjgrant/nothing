require 'fileutils'
require 'minitest/autorun'
require 'date'

# Test environment setup paths
ROOT_DIR = File.expand_path('..', __dir__) # Correctly points to the root directory
TEST_ROOT = File.join(ROOT_DIR, '_sys/test')
LATER_DIR = File.join(TEST_ROOT, '_later')
ARCHIVED_DIR = File.join(TEST_ROOT, '_archived')
ACTIVITY_LOG = File.join(TEST_ROOT, '_sys', 'activity.log')
ERROR_LOG = File.join(TEST_ROOT, '_sys', 'error.log')
EXTENSIONS_SRC_DIR = File.join(ROOT_DIR, '_sys/extensions')
INACTIVE_EXTENSIONS_DIR = File.join(EXTENSIONS_SRC_DIR, 'inactive')
TEST_EXTENSIONS_DIR = File.join(TEST_ROOT, '_sys/extensions')

def setup_test_environment
  # Completely reset the test root directory
  FileUtils.rm_rf(TEST_ROOT)
  FileUtils.mkdir_p([TEST_ROOT, LATER_DIR, ARCHIVED_DIR, TEST_EXTENSIONS_DIR])

  # Copy active extensions
  FileUtils.cp_r(Dir.glob(File.join(EXTENSIONS_SRC_DIR, '*')), TEST_EXTENSIONS_DIR)

  # Copy inactive extensions
  FileUtils.cp_r(Dir.glob(File.join(INACTIVE_EXTENSIONS_DIR, '*')), TEST_EXTENSIONS_DIR)

  # Remove the inactive dir at sys/test/extensions
  FileUtils.rm_rf(File.join(TEST_EXTENSIONS_DIR, 'inactive'))

  # Create test task files in the 'later/' directory
  today_str = Date.today.strftime('%Y%m%d')
  yesterday_str = (Date.today - 1).strftime('%Y%m%d')
  tomorrow_str = (Date.today + 1).strftime('%Y%m%d')

  File.write(File.join(LATER_DIR, "#{yesterday_str}.Task overdue.txt"), "Overdue task")
  File.write(File.join(LATER_DIR, "#{today_str}.Task due today.txt"), "Due today task")
  File.write(File.join(LATER_DIR, "#{tomorrow_str}.Task due tomorrow.txt"), "Due tomorrow task")
  File.write(File.join(LATER_DIR, "Task no date.txt"), "No date task")
end

# Set up the test environment before running any tests
setup_test_environment

# Dynamically load all test files in the root and extensions/tests
Dir.glob(File.expand_path('nothing_test.rb', __dir__)).each do |test_file|
  require test_file
end

Dir.glob(File.join(TEST_EXTENSIONS_DIR, '**', '*_test.rb')).each do |extension_test_file|
  require extension_test_file
end