#!/usr/bin/env ruby

# repeating.rb
#
# This extension automates the handling of repeating tasks based on rules in the filename.
#
# Filename Formats:
# - `<YYYYMMDD>.<task name>.<repetition rule>.<extension>` (Default repetition)
# - `<YYYYMMDD>.<task name>.@<repetition rule>.<extension>` (Strict repetition)
#
# Supported Repetition Rules:
# - Daily: `3d` repeats every 3 days.
# - Weekly: `2w` repeats every 2 weeks.
# - Monthly: `3m` repeats every 3 months.
# - Weekdays: `monday`, `friday`, etc., repeats on the specified weekday.
#
# Behavior:
# - Default Repetition: Creates the next instance of the task after it’s completed (in `_archived`).
# - Strict Repetition: Always schedules the next instance, regardless of completion.
#
# Usage:
#   ruby repeating.rb <root_directory>
#   - Replace <root_directory> with the path to the directory you want to process.
#   - If no directory is provided, the current working directory is used.
#
# Example:
# - Before: `20241220.mytask.3d.txt` (Archived)
# - After:  `20241223.mytask.3d.txt` (Created in `_later`)

require 'fileutils'
require 'date'

# Accept the root directory as a command-line argument, defaulting to the current directory
root_dir = ARGV[0] || Dir.pwd
archived_dir = File.join(root_dir, '_archived')
later_dir = File.join(root_dir, '_later')

# Ensure _archived and _later directories exist
FileUtils.mkdir_p(archived_dir)
FileUtils.mkdir_p(later_dir)

# Method to calculate the next date based on the repetition rule
def calculate_next_date(current_date, parsed)
  rule = parsed[:rule]
  task_name = parsed[:name]
  extension = parsed[:extension]

  if rule =~ /^(\d+)([dwmy])$/i
    number = $1.to_i
    unit = $2.downcase

    case unit
    when 'd' # Days
      return current_date + number
    when 'w' # Weeks
      return current_date + (number * 7)
    when 'm' # Months
      return current_date >> number
    when 'y' # Years
      return current_date >> (number * 12)
    end
  elsif rule =~ /^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$/i
    target_weekday = Date::DAYNAMES.index($1.capitalize)
    days_ahead = (target_weekday - current_date.wday) % 7
    days_ahead = 7 if days_ahead.zero? # If today is the target weekday, set to next week
    return current_date + days_ahead
  elsif rule =~ /^(\d+)m-(\d+)$/
    number = $1.to_i
    specific_day = $2.to_i
    target_month = current_date >> number
    return Date.new(target_month.year, target_month.month, specific_day) rescue nil
  elsif rule =~ /^(\d+)w-([mtwhfs]+)$/i
    number = $1.to_i
    weekdays = $2.chars.map { |day| "mtwhfs".index(day.downcase) + 1 }
  
    # Calculate next dates for all specified weekdays
    next_dates = weekdays.map do |target_weekday|
      days_ahead = (target_weekday - current_date.wday + 7) % 7
      days_ahead = 7 if days_ahead.zero? # Next week if today is the target day
      current_date + (number * 7) + days_ahead
    end
  
    # Return the earliest next date (useful if this function needs a single date)
    return next_dates.min
  elsif rule =~ /^(\d+)m-(\d)([mtwhfs])$/i
    number = $1.to_i
    nth = $2.to_i
    weekday = "mtwhfs".index($3.downcase) + 1
    target_month = current_date >> number
    first_day = Date.new(target_month.year, target_month.month, 1)
    first_weekday = first_day + ((weekday - first_day.wday + 7) % 7)
    return first_weekday + ((nth - 1) * 7) rescue nil
  elsif rule =~ /^(\d+)m-([mtwhfs])$/i
    number = $1.to_i
    nth = 1 # Default to the first occurrence
    weekday = "mtwhfs".index($2.downcase) + 1
    target_month = current_date >> number
    first_day = Date.new(target_month.year, target_month.month, 1)
    first_weekday = first_day + ((weekday - first_day.wday + 7) % 7)
    return first_weekday + ((nth - 1) * 7) rescue nil
  else
    puts "Invalid rule: #{rule} for task: #{task_name}. Returning nil."
    return nil
  end
end

def parse_filename(filename)
  # Split the filename by periods
  parts = filename.split('.')

  # Ensure there are at least two parts (name and extension)
  return { date: nil, name: nil, rule: nil, strict: false, extension: nil } if parts.length < 2

  # Extract the mandatory extension (last part)
  extension = parts.pop

  # Determine if the first part is a date
  date = nil
  if parts.first =~ /^\d{4}-\d{2}-\d{2}$/
    date = parts.shift # Extract the date if valid
  end

  # Remaining parts: name and (optional) rule
  name = parts.shift
  rule = parts.shift

  # Determine if the rule is strict (starts with '@')
  strict = false
  if rule&.start_with?('@')
    strict = true
    rule = rule[1..] # Remove '@' from the rule
  end

  # Return a structured hash
  { date: date, name: name, rule: rule, strict: strict, extension: extension }
end

# Process files in _archived for default repetition
Dir.foreach(archived_dir) do |filename|
  next if filename == '.' || filename == '..'
  next if filename.start_with?('.') # Skip hidden files

  file_path = File.join(archived_dir, filename)

  parsed = parse_filename(filename)
  
  if !parsed[:strict]
    # Match files with the repetition rule format
    date_prefix = parsed[:date]
    task_name = parsed[:name]
    rule = parsed[:rule]
    extension = parsed[:extension]

    current_date = Date.strptime(date_prefix, '%Y-%m-%d') rescue nil
    next unless current_date # Skip if the date cannot be parsed

    # Calculate the next date
    next_date = calculate_next_date(current_date, parsed)
    next unless next_date # Skip if the rule is invalid

    # Check if the next instance already exists in _later
    next_filename = "#{next_date.strftime('%Y-%m-%d')}.#{task_name}.#{rule}#{extension}"
    next_file_path = File.join(later_dir, next_filename)

    unless File.exist?(next_file_path)
      # Create the next instance
      FileUtils.cp(file_path, next_file_path)
      puts "Created repeating task: #{next_filename}"
    end

    # Rename the current file to remove the repetition rule
    renamed_file = "#{date_prefix}.#{task_name}.#{extension}"
    File.rename(file_path, File.join(archived_dir, renamed_file))
    puts "Archived task renamed: #{renamed_file}"
  end
end

# Process files in root for strict repetition
Dir.foreach(root_dir) do |filename|
  next if filename == '.' || filename == '..'
  next if filename.start_with?('.') # Skip hidden files

  file_path = File.join(root_dir, filename)

  # Match files with the strict repetition rule format
  parsed = parse_filename(filename)
  
  if parsed[:strict]
    # Match files with the repetition rule format
    date_prefix = parsed[:date]
    task_name = parsed[:name]
    rule = parsed[:rule]
    extension = parsed[:extension]

    current_date = Date.strptime(date_prefix, '%Y-%m-%d') rescue nil
    next unless current_date # Skip if the date cannot be parsed

    # Calculate the next date
    next_date = calculate_next_date(current_date, parsed)
    next unless next_date # Skip if the rule is invalid

    # Check if the next instance already exists in _later
    next_filename = "#{next_date.strftime('%Y-%m-%d')}.#{task_name}.@#{rule}#{extension}"
    next_file_path = File.join(later_dir, next_filename)

    unless File.exist?(next_file_path)
      # Create the next instance
      FileUtils.cp(file_path, next_file_path)
      puts "Created strict repeating task: #{next_filename}"
    end
  end
end