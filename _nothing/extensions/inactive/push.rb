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

# Constants for directory names
PUSH_1D = '_push-1d'
PUSH_1W = '_push-1w'
PUSH_RAND = '_push-rand'
LATER = '_later'

# Ensure directories exist
def ensure_directories(root_dir)
  [PUSH_1D, PUSH_1W, PUSH_RAND].each do |dir|
    path = File.join(root_dir, dir)
    Dir.mkdir(path) unless Dir.exist?(path)
  end
end

# Process a file and move it to _later with the date incremented
def process_file(file_path, increment_days, later_dir)
  filename = File.basename(file_path)
  components = filename.split('.')
  return unless components.size >= 2 # Skip files without a date

  date_time_str = components[0]
  time_str = nil

  # Split date and time if the format includes '+HHMM'
  if date_time_str.include?('+')
    date_str, time_str = date_time_str.split('+')
  else
    date_str = date_time_str
  end

  begin
    task_date = Date.strptime(date_str, '%Y-%m-%d')
  rescue ArgumentError
    return # Skip files that don't have a valid date format
  end

  # Increment the date
  new_date = task_date + increment_days
  new_date_time_str = time_str ? "#{new_date.strftime('%Y-%m-%d')}+#{time_str}" : new_date.strftime('%Y-%m-%d')
  new_filename = filename.sub(date_time_str, new_date_time_str)
  new_path = File.join(later_dir, new_filename)

  # Move the file to _later
  FileUtils.mv(file_path, new_path)
end

# Main processing logic
def process_push_directories(root_dir)
  later_dir = File.join(root_dir, LATER)
  Dir.mkdir(later_dir) unless Dir.exist?(later_dir)

  {
    PUSH_1D => 1,
    PUSH_1W => 7,
    PUSH_RAND => rand(1..10)
  }.each do |push_dir, increment_days|
    dir_path = File.join(root_dir, push_dir)
    next unless Dir.exist?(dir_path)

    Dir.foreach(dir_path) do |file|
      next if file == '.' || file == '..'
      file_path = File.join(dir_path, file)
      process_file(file_path, increment_days, later_dir)
    end
  end
end

# Entry point
if __FILE__ == $0
  root_dir = ARGV[0] || Dir.pwd
  ensure_directories(root_dir)
  process_push_directories(root_dir)
end