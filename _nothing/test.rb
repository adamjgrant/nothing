require 'fileutils'
require 'minitest/autorun'
require 'date'

# Test environment setup paths
ROOT_DIR = File.expand_path('..', __dir__)
TEST_ROOT = File.join(ROOT_DIR, '_nothing/test')
LATER_DIR = File.join(TEST_ROOT, '_later')
DONE_DIR = File.join(TEST_ROOT, '_done')
ACTIVITY_LOG = File.join(TEST_ROOT, '_nothing', 'activity.log')
ERROR_LOG = File.join(TEST_ROOT, '_nothing', 'error.log')
EXTENSIONS_SRC_DIR = File.join(ROOT_DIR, '_nothing/extensions')
INACTIVE_EXTENSIONS_DIR = File.join(EXTENSIONS_SRC_DIR, 'inactive')
TEST_EXTENSIONS_DIR = File.join(TEST_ROOT, '_nothing/extensions')

def setup_test_environment
  # Completely reset the test root directory
  FileUtils.rm_rf(TEST_ROOT)
  FileUtils.mkdir_p([TEST_ROOT, LATER_DIR, DONE_DIR, TEST_EXTENSIONS_DIR])

  # Copy active extensions
  FileUtils.cp_r(Dir.glob(File.join(EXTENSIONS_SRC_DIR, '*')), TEST_EXTENSIONS_DIR)

  # Copy inactive extensions
  FileUtils.cp_r(Dir.glob(File.join(INACTIVE_EXTENSIONS_DIR, '*')), TEST_EXTENSIONS_DIR)

  # Remove the inactive dir at sys/test/extensions
  FileUtils.rm_rf(File.join(TEST_EXTENSIONS_DIR, 'inactive'))


end

# Set up the test environment before running any tests
setup_test_environment

# Explicitly load `nothing_test.rb`
nothing_test_file = File.expand_path('nothing_test.rb', __dir__)
require nothing_test_file

# Dynamically load only active _test.rb files in the extensions directory
Dir.glob(File.join(TEST_EXTENSIONS_DIR, '**', '*_test.rb')).each do |extension_test_file|
  # Skip test files in the inactive directory
  next if extension_test_file.include?('/inactive/')
  
  require extension_test_file
end