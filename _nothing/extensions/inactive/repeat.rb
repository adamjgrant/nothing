#!/usr/bin/env ruby

# repeat.rb
#
# This extension automates the handling of repeating tasks based on rules in the filename.
#
# Filename Formats:
# - `<YYYY-MM-DD>.<task name>.<repetition rule>.<extension>` (Default repetition)
# - `<YYYY-MM-DD>.<task name>.@<repetition rule>.<extension>` (Strict repetition)
#
# Supported Repetition Rules:
# - Daily: `3d` (every 3 days).
# - Weekly: `1w-mo-fr` (every week on Monday and Friday).
# - Monthly by date: `1m-15` (every month on the 15th).
# - Monthly by weekday: `1m-2mo` (every month on the 2nd Monday).
# - Yearly: `1y` (every year).
#
# Behavior:
# - **Default Repetition**: Creates the next instance of the task after it’s completed (in `_done`).
# - **Strict Repetition**: Always schedules the next instance, regardless of completion, as long as the file is in the root directory.
#
# Usage:
#   ruby repeat.rb <root_directory>
#   - Replace `<root_directory>` with the path to the directory you want to process.
#   - If no directory is provided, the current working directory is used.
#
# Examples:
# - Daily Task: `2024-12-21.daily-task.1d.txt` 
#   - Archived today, creates `2024-12-22.daily-task.1d.txt` in `_later`.
# - Weekly Multi-Day Task: `2024-12-21.weekly-task.1w-mo-fr.txt`
#   - Archived today, creates the next Monday and Friday instances in `_later`.
# - Monthly Specific Day: `2024-12-21.monthly-task.1m-15.txt`
#   - Archived today, creates `2025-01-15.monthly-task.1m-15.txt` in `_later`.
# - Strict Weekly Task: `2024-12-21.strict-task.@1w-mo.txt`
#   - Always schedules `2024-12-28.strict-task.@1w-mo.txt` in `_later` without requiring completion.

require 'fileutils'
require 'date'
require_relative '../name_parser'

# Accept the root directory as a command-line argument, defaulting to the current directory
root_dir = ARGV[0] || Dir.pwd
done_dir = File.join(root_dir, '_done')
later_dir = File.join(root_dir, '_later')

# Ensure _done and _later directories exist
FileUtils.mkdir_p(done_dir)
FileUtils.mkdir_p(later_dir)

def calculate_modification_string(current_date, rule)
  if rule =~ /^(\d+)([hdwmy])$/i
    return rule
  elsif rule =~ /^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$/i 
    return rule 
  elsif rule =~ /^(\d+)m-(\d+)$/
    number = $1.to_i
    specific_day = $2.to_i
    target_month = current_date >> number
    target_date = Date.new(target_month.year, target_month.month, specific_day) rescue nil
    if target_date
      # calculate the number of days between the current date and the target date
      days_difference = (target_date - current_date).to_i
      return "#{days_difference}d"
    end
  elsif rule =~ /^(\d+)w-((?:su|mo|tu|we|th|fr|sa)(?:-(?:su|mo|tu|we|th|fr|sa))*)$/i 
    number = $1.to_i
    weekdays = $2.split('-').map { |day| %w[su mo tu we th fr sa].index(day.downcase) }

    # Calculate next dates for all specified weekdays
    next_dates = weekdays.map do |target_weekday|
      days_ahead = (target_weekday - current_date.wday + 7) % 7
      days_ahead = 7 if days_ahead.zero? # Move to next week if today is the target weekday
      current_date + days_ahead
    end

    # Return the earliest next date
    target_date = next_dates.min
    if target_date
      # calculate the number of days between the current date and the target date
      days_difference = (target_date - current_date).to_i
      return "#{days_difference}d"
    end
  elsif rule =~ /^(\d+)m-(\d*)(su|mo|tu|we|th|fr|sa)$/i
    number = $1.to_i
    nth = $2.empty? ? 1 : $2.to_i # Default to 1 if nth is missing
    weekday = %w[su mo tu we th fr sa].index($3.downcase)
  
    target_month = current_date >> number
    first_day = Date.new(target_month.year, target_month.month, 1)
    first_weekday = first_day + ((weekday - first_day.wday + 7) % 7)
    target_date = first_weekday + ((nth - 1) * 7) rescue nil
    if target_date
      # calculate the number of days between the current date and the target date
      days_difference = (target_date - current_date).to_i
      return "#{days_difference}d"
    end
  else
    # Invalid rule
    return nil
  end
end

# Method to calculate the next date based on the repetition rule
def calculate_next_date(current_date, parsed)
  rule = parsed[:rule]
  task_name = parsed[:name]
  extension = parsed[:extension]

  if rule =~ /^(\d+)([hdwmy])$/i
    parser = NameParser.new("#{current_date}.doesntmatter.txt")
    new_filename = parser.modify_filename_with_time(rule)
    new_filename_parser = NameParser.new(new_filename)
    return Date.strptime(new_filename_parser.date, '%Y-%m-%d') rescue nil
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
  elsif rule =~ /^(\d+)w-((?:su|mo|tu|we|th|fr|sa)(?:-(?:su|mo|tu|we|th|fr|sa))*)$/i
    number = $1.to_i
    weekdays = $2.split('-').map { |day| %w[su mo tu we th fr sa].index(day.downcase) }

    # Calculate next dates for all specified weekdays
    next_dates = weekdays.map do |target_weekday|
      days_ahead = (target_weekday - current_date.wday + 7) % 7
      days_ahead = 7 if days_ahead.zero? # Move to next week if today is the target weekday
      current_date + days_ahead
    end

    # Return the earliest next date
    return next_dates.min
  elsif rule =~ /^(\d+)m-(\d*)(su|mo|tu|we|th|fr|sa)$/i
    number = $1.to_i
    nth = $2.empty? ? 1 : $2.to_i # Default to 1 if nth is missing
    weekday = %w[su mo tu we th fr sa].index($3.downcase)
  
    target_month = current_date >> number
    first_day = Date.new(target_month.year, target_month.month, 1)
    first_weekday = first_day + ((weekday - first_day.wday + 7) % 7)
    return first_weekday + ((nth - 1) * 7) rescue nil
  else
    # puts "Invalid rule: #{rule} for task: #{task_name}. Returning nil."
    return nil
  end
end

def parse_filename(filename, directory=false)
  # Split the filename by periods
  parts = filename.split('.')

  # Ensure there are at least two parts (name and extension)
  return { date: nil, time: nil, name: nil, rule: nil, strict: false, extension: nil } if parts.length < 2

  # Extract the mandatory extension (last part)
  extension = parts.pop unless directory

  # Determine if the first part contains a date and optional time
  date, time = nil, nil
  if parts.first =~ /^(\d{4}-\d{2}-\d{2})(?:\+(\d{4}))?$/
    date = $1
    time = $2 # Capture time if present
    parts.shift # Extract the date+time if valid
  end

  # Remaining parts: name and (optional) rule
  name = parts.shift
  rule = parts.shift

  # Adjust rule parsing for weekday lists
  if rule && rule.match?(/^(\d+[dwmy])-((?:su|mo|tu|we|th|fr|sa)(?:-(?:su|mo|tu|we|th|fr|sa))*)$/i)
    rule = rule
  elsif rule && rule.match?(/^(\d+[dwmy])-((\d)(su|mo|tu|we|th|fr|sa))$/i)
    rule = rule
  end

  # Determine if the rule is strict (starts with '@')
  strict = false
  if rule&.start_with?('@')
    strict = true
    rule = rule[1..] # Remove '@' from the rule
  end

  # Return a structured hash
  { date: date, time: time, name: name, rule: rule, strict: strict, extension: extension }
end

def handle_default_repeating_task(file_path, filename, parsed, from_dir, to_dir)
  return unless parsed[:rule] # Skip if no repetition rule
  return if parsed[:strict] # Skip strict rules in `_done`

  date_prefix = parsed[:date]
  task_name = parsed[:name]
  rule = parsed[:rule]
  extension = parsed[:extension]

  current_date = Date.strptime(date_prefix, '%Y-%m-%d') rescue nil
  return unless current_date # Skip invalid dates

  # Calculate the next date
  modification_string = calculate_modification_string(current_date, parsed[:rule])
  return unless modification_string # Skip invalid rules
  filename_parser = NameParser.new(filename)
  new_filename = filename_parser.modify_filename_with_time(modification_string)

  # Create the next instance
  next_file_path = File.join(to_dir, new_filename)
  unless File.exist?(next_file_path)
    FileUtils.cp_r(file_path, next_file_path)
  end

  # Rename the current file to remove the repetition rule
  renamed_file = filename_parser.filename.gsub(".#{filename_parser.repeat_logic}#{"." if filename_parser.extension}#{filename_parser.extension}", "#{"." if filename_parser.extension}#{filename_parser.extension}")
  File.rename(file_path, File.join(from_dir, renamed_file))
end

def handle_strict_repeating_task(filename, from_dir, to_dir)
  file_path = File.join(from_dir, filename)
  parsed = parse_filename(filename, File.directory?(file_path))
  return unless parsed[:rule] && parsed[:strict] # Process only strict rules

  date_prefix = parsed[:date]
  task_name = parsed[:name]
  rule = parsed[:rule]
  extension = parsed[:extension]

  current_date = Date.strptime(date_prefix, '%Y-%m-%d') rescue nil
  return unless current_date # Skip invalid dates

  # Calculate the next date
  modification_string = calculate_modification_string(current_date, parsed[:rule])
  return unless modification_string # Skip invalid rules
  filename_parser = NameParser.new(filename)
  new_filename = filename_parser.modify_filename_with_time(modification_string)

  # Create the next instance
  next_file_path = File.join(to_dir, new_filename)
  unless File.exist?(next_file_path)
    FileUtils.cp_r(file_path, next_file_path)
  end
end

# Process files in _done for default and strict repetition
Dir.foreach(done_dir) do |filename|
  next if filename == '.' || filename == '..'
  next if filename.start_with?('.') # Skip hidden files

  file_path = File.join(done_dir, filename)
  directory = File.directory?(file_path)
  parsed = parse_filename(filename, directory)

  handle_default_repeating_task(file_path, filename, parsed, done_dir, later_dir)
end

# Process files in root for strict repetition only
Dir.foreach(root_dir) do |filename|
  next if filename == '.' || filename == '..'
  next if filename.start_with?('.') # Skip hidden files

  # Process files and directories
  handle_strict_repeating_task(filename, root_dir, later_dir)
end