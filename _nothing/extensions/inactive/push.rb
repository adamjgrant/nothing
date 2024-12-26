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

# Ensure necessary directories exist
def ensure_directories(root_dir)
  push_rand_dir = File.join(root_dir, PUSH_RAND)
  Dir.mkdir(push_rand_dir) unless Dir.exist?(push_rand_dir)
end

# Parse a push directory name and extract increment days
def parse_push_directory(dir_name)
  match = dir_name.match(/^_push-(\d+)([dwmy])$/)
  return unless match

  increment = match[1].to_i
  unit = match[2]

  # Determine increment unit
  case unit
  when 'd' then increment # days
  when 'w' then increment * 7 # weeks
  when 'm' then { months: increment } # months
  when 'y' then { years: increment } # years
  else nil
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
  new_date = case increment_days
              when Integer
                task_date + increment_days # days and weeks
              when Hash
                if increment_days[:months]
                  task_date >> increment_days[:months] # months
                elsif increment_days[:years]
                  task_date.next_year(increment_days[:years]) # years
                else
                  task_date
                end
              else
                task_date
              end
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

  # Find all _push-* directories
  Dir.foreach(root_dir) do |entry|
    next unless entry.start_with?('_push-')
    dir_path = File.join(root_dir, entry)
    next unless Dir.exist?(dir_path)

    # Parse increment from directory name
    increment_days = parse_push_directory(entry)
    next unless increment_days # Skip invalid directories

    # Process files in the directory
    Dir.foreach(dir_path) do |file|
      next if file == '.' || file == '..'
      file_path = File.join(dir_path, file)
      process_file(file_path, increment_days, later_dir)
    end
  end

  # Handle _push-rand as a special case
  rand_dir = File.join(root_dir, PUSH_RAND)
  if Dir.exist?(rand_dir)
    Dir.foreach(rand_dir) do |file|
      next if file == '.' || file == '..'
      file_path = File.join(rand_dir, file)
      process_file(file_path, rand(1..10), later_dir)
    end
  end
end

# Entry point
if __FILE__ == $0
  root_dir = ARGV[0] || Dir.pwd
  ensure_directories(root_dir)
  process_push_directories(root_dir)
end