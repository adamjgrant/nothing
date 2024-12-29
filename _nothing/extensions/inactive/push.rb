# push.rb
# Extension to process files in _push-1d, _push-1w, and _push-rand directories.
# It increments the dates on tasks based on the directory rules and moves them to _later.
# 
# Usage:
# - Place a task in _push-1d to add 1 day to its date and move to _later.
# - Place a task in _push-1w to add 7 days to its date and move to _later.
# - Place a task in _push-rand to add a random number of days (1-10) and move to _later.

require 'fileutils'
require 'date'
require_relative '../name_parser'

# Constants for directory names
PUSH_1D = '_push-1d'
PUSH_1W = '_push-1w'
PUSH_RAND = '_push-rand'
LATER = '_later'

# Ensure necessary directories exist
def ensure_directories(root_dir)
  push_rand_dir = File.join(root_dir, PUSH_RAND)
  Dir.mkdir(push_rand_dir) unless Dir.exist?(push_rand_dir)
end

def process_push_directories(root_dir)
  later_dir = File.join(root_dir, LATER)
  Dir.mkdir(later_dir) unless Dir.exist?(later_dir)

  # Find all _push-* directories
  Dir.foreach(root_dir) do |entry|
    next unless entry.start_with?('_push-')
    dir_path = File.join(root_dir, entry)
    next unless Dir.exist?(dir_path)

    random = true if entry == PUSH_RAND
    modification_string = entry.gsub("_push-", "")

    # Process files in the directory
    Dir.foreach(dir_path) do |file|
      next if file == '.' || file == '..'
      file_path = File.join(dir_path, file)
      is_directory = File.directory?(file_path)
      filename = File.basename(file_path)
      parser = NameParser.new(filename)
      modification_string = "#{rand(1..10)}d" if random

      new_filename = parser.modify_filename_with_time(modification_string)
      new_path = File.join(dir_path, new_filename)
      if filename == "2024-12-28.test-task-rand.txt"
        puts "DEBUG: #{modification_string}"
        puts "DEBUG: #{new_path}"
      end
      FileUtils.mv(file_path, new_path) if new_path != file_path
    end
  end
end

# Entry point
if __FILE__ == $0
  root_dir = ARGV[0] || Dir.pwd
  ensure_directories(root_dir)
  process_push_directories(root_dir)
end