#!/usr/bin/env ruby

# Force UTF-8 encoding
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'fileutils'
require 'date'

current_dir = File.expand_path('.')
parent_dir = File.expand_path('..', __FILE__)
parent_dir_name = File.basename(parent_dir)

# Check if this is the first time setup
if parent_dir_name != '_sys' && !Dir.exist?(File.join(current_dir, '_later')) && 
   !Dir.exist?(File.join(current_dir, '_archived')) && 
   !Dir.exist?(File.join(current_dir, '_sys'))
  # First-time setup
  puts "First-time setup detected. Creating '_sys' directory and moving 'nothing.rb' into it."

  # Create _sys directory
  sys_dir = File.join(current_dir, '_sys')
  Dir.mkdir(sys_dir)

  # Move this script to _sys
  new_script_path = File.join(sys_dir, 'nothing.rb')
  FileUtils.cp(__FILE__, new_script_path)

  # Remove the original script
  File.delete(__FILE__)

  puts "'nothing.rb' has been moved to '_sys'. Please run it from there."

  system("ruby #{new_script_path}")

  exit
else
  puts "Skipping first-time setup."
end

# Set the root directory to the provided argument or default to the parent of the _sys directory
root_dir = ARGV[0] || File.expand_path('..', __dir__)

BASE_DIR = root_dir
LATER_DIR = File.join(BASE_DIR, '_later')
ARCHIVED_DIR = File.join(BASE_DIR, '_archived')
SYS_DIR = File.join(BASE_DIR, '_sys') # This stays the same
EXTENSIONS_DIR = File.join(SYS_DIR, 'extensions')
INACTIVE_EXTENSIONS_DIR = File.join(EXTENSIONS_DIR, 'inactive')
EXTENSIONS_TESTS_DIR = File.join(EXTENSIONS_DIR, 'tests')
ACTIVITY_LOG = File.join(SYS_DIR, 'activity.log')
ERROR_LOG = File.join(SYS_DIR, 'error.log')

# Ensure directories exist and include a .keep file
[ LATER_DIR, ARCHIVED_DIR, EXTENSIONS_DIR, INACTIVE_EXTENSIONS_DIR, EXTENSIONS_TESTS_DIR ].each do |dir|
  unless Dir.exist?(dir)
    Dir.mkdir(dir)
  end
  # Add a .keep file to the directory
  keep_file = File.join(dir, '.keep')
  FileUtils.touch(keep_file) unless File.exist?(keep_file)
end

today = Date.today

# Parse date prefix in new format YYYY-MM-DD
def parse_yyyymmdd_prefix(filename)
  match = filename.match(/^(\d{4}-\d{2}-\d{2})\./)
  return Date.strptime(match[1], '%Y-%m-%d') if match
rescue ArgumentError
  nil
end

# Run all extensions in the extensions directory
def run_extensions(root_dir)
  Dir.glob(File.join(EXTENSIONS_DIR, '*.rb')).each do |extension_file|
    begin
      system("ruby #{extension_file} #{root_dir}")
    rescue => e
      File.open(File.join(root_dir, '_sys', 'error.log'), 'a') do |f|
        f.puts "#{Time.now} Error running extension #{File.basename(extension_file)}: #{e.message}"
        f.puts e.backtrace
      end
    end
  end
end

begin
  moved_tasks = false

  # Check tasks in _later for due tasks
  Dir.foreach(LATER_DIR) do |filename|
    next if filename == '.' || filename == '..'

    # Parse the optional date prefix
    due_date = parse_yyyymmdd_prefix(filename)

    if due_date && due_date <= today
      from_path = File.join(LATER_DIR, filename)
      to_path = File.join(BASE_DIR, filename)
      FileUtils.mv(from_path, to_path)
      File.open(ACTIVITY_LOG, 'a') do |f|
        f.puts "#{Time.now} Moved #{filename} from '_later' to '#{BASE_DIR}'."
      end
      moved_tasks = true
    end
  end

  # Check tasks in BASE_DIR for future tasks and move them to _later
  Dir.foreach(BASE_DIR) do |filename|
    next if filename == '.' || filename == '..'
    next if filename.start_with?('_') # Skip special directories like _later, _archived, _sys

    # Parse the optional date prefix
    due_date = parse_yyyymmdd_prefix(filename)

    if due_date && due_date > today
      from_path = File.join(BASE_DIR, filename)
      to_path = File.join(LATER_DIR, filename)
      FileUtils.mv(from_path, to_path)
      File.open(ACTIVITY_LOG, 'a') do |f|
        f.puts "#{Time.now} Moved #{filename} from '#{BASE_DIR}' to '_later'."
      end
      moved_tasks = true
    end
  end

  # Run any extension scripts
  run_extensions(BASE_DIR)
rescue => e
  File.open(ERROR_LOG, 'a') do |f|
    f.puts "#{Time.now} Error: #{e.message}"
    f.puts e.backtrace
  end
end