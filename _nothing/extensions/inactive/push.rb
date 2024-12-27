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

# Parse a push directory name and extract increment days and optional time value
def parse_push_directory(dir_name)
  match = dir_name.match(/^_push-(\d+)([dwmy])(?:\+(\d{4}))?$/)
  return unless match

  increment = match[1].to_i
  unit = match[2]
  time_value = match[3] # Optional time value (e.g., 1400 for 14:00)

  # Determine increment unit
  increment_unit = case unit
                   when 'd' then increment # days
                   when 'w' then increment * 7 # weeks
                   when 'm' then { months: increment } # months
                   when 'y' then { years: increment } # years
                   else nil
                   end

  { increment: increment_unit, time: time_value }
end

# Process a file and move it to _later with the date incremented
def process_file(file_path, increment_days, later_dir, is_directory=false)
  filename = File.basename(file_path)
  components = filename.split('.')
  
  # If the first component is a valid date, use it. Otherwise use today's date
  date_time_str = components[0]
  time_str = nil

  # Try to parse the date if it looks like one
  if filename == "never-to-today-afternoon.txt"
    puts "DEBUG: #{increment_days[:time]}"
  end

  begin
    if date_time_str.match?(/^\d{4}-\d{2}-\d{2}/)
      # Split date and time if the format includes '+HHMM'
      # make sure the string does not end in a "+"

      if date_time_str.include?('+') && !date_time_str.end_with?('+')
        date_str, time_str = date_time_str.split('+')[0..1]
      else
        date_str = date_time_str
      end
      task_date = Date.strptime(date_str, '%Y-%m-%d')
    else
      # No valid date found, use today's date
      task_date = Date.today
      # Construct new filename with today's date
      original_name = filename
      date_time_str = original_name
      time_str = increment_days[:time]
    end
  rescue ArgumentError
    # Invalid date format, use today's date
    task_date = Date.today
    date_time_str = filename
  end

  if filename == "never-to-today-afternoon.txt"
    puts "DEBUG: Time string should be set: #{time_str}"
  end

  # Increment the date
  new_date = case increment_days[:increment]
              when Integer
                task_date + increment_days[:increment] # days and weeks
              when Hash
                if increment_days[:increment][:months] 
                  task_date >> increment_days[:increment][:months] # months
                elsif increment_days[:increment][:years]
                  task_date.next_year(increment_days[:increment][:years]) # years
                else
                  task_date
                end
              else
                task_date
              end

  # Create new filename
  new_date_str = new_date.strftime('%Y-%m-%d')
  if time_str
    new_filename = "#{new_date_str}+#{time_str}.#{components[1..-1].join('.')}"
  else
    if filename == "never-to-today-afternoon.txt"
      puts "DEBUG: #{filename} #{date_time_str} #{time_str}"
    end
    # If the original file had no date, insert the new date at the start
    if date_time_str == filename
      new_time_str = time_str ? "+#{time_str}" : ''
      new_filename = "#{new_date_str}#{time_str}.#{filename}"
    else
      new_filename = filename.sub(date_time_str, new_date_str)
    end
  end

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
    
    if entry == PUSH_RAND
      increment_days = { increment: rand(1..10), time_value: nil }
    else
      increment_days = parse_push_directory(entry)
    end
    next unless increment_days # Skip invalid directories

    # Process files in the directory
    Dir.foreach(dir_path) do |file|
      next if file == '.' || file == '..'
      file_path = File.join(dir_path, file)
      is_directory = File.directory?(file_path)
      process_file(file_path, increment_days, later_dir, is_directory)
    end
  end
end

# Entry point
if __FILE__ == $0
  root_dir = ARGV[0] || Dir.pwd
  ensure_directories(root_dir)
  process_push_directories(root_dir)
end