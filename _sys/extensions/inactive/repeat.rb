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
def calculate_next_date(current_date, rule)
  if rule =~ /^(\d+)([dwmy])$/i
    number = $1.to_i
    unit = $2.downcase

    case unit
    when 'd' # Days
      current_date + number
    when 'w' # Weeks
      current_date + (number * 7)
    when 'm' # Months
      current_date >> number
    when 'y' # Years
      current_date >> (number * 12)
    else
      nil
    end
  elsif rule =~ /^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$/i
    target_weekday = Date::DAYNAMES.index($1.capitalize)
    days_ahead = (target_weekday - current_date.wday) % 7
    days_ahead = 7 if days_ahead.zero? # If today is the target weekday, set to next week
    current_date + days_ahead
  else
    nil
  end
end

# Process files in _archived for default repetition
Dir.foreach(archived_dir) do |filename|
  next if filename == '.' || filename == '..'
  next if filename.start_with?('.') # Skip hidden files

  file_path = File.join(archived_dir, filename)

  # Match files with the repetition rule format
  if filename =~ /^(\d{8})\.(.+)\.(\d+[dwmy]|monday|tuesday|wednesday|thursday|friday|saturday|sunday)(\..+)$/
    date_prefix = $1
    task_name = $2
    rule = $3
    extension = $4

    current_date = Date.strptime(date_prefix, '%Y%m%d') rescue nil
    next unless current_date # Skip if the date cannot be parsed

    # Calculate the next date
    next_date = calculate_next_date(current_date, rule)
    next unless next_date # Skip if the rule is invalid

    # Check if the next instance already exists in _later
    next_filename = "#{next_date.strftime('%Y%m%d')}.#{task_name}.#{rule}#{extension}"
    next_file_path = File.join(later_dir, next_filename)

    unless File.exist?(next_file_path)
      # Create the next instance
      FileUtils.cp(file_path, next_file_path)
      puts "Created repeating task: #{next_filename}"
    end

    # Rename the current file to remove the repetition rule
    renamed_file = "#{date_prefix}.#{task_name}#{extension}"
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
  if filename =~ /^(\d{8})\.(.+)\.@(\d+[dwmy]|monday|tuesday|wednesday|thursday|friday|saturday|sunday)(\..+)$/
    date_prefix = $1
    task_name = $2
    rule = $3
    extension = $4

    current_date = Date.strptime(date_prefix, '%Y%m%d') rescue nil
    next unless current_date # Skip if the date cannot be parsed

    # Calculate the next date
    next_date = calculate_next_date(current_date, rule)
    next unless next_date # Skip if the rule is invalid

    # Check if the next instance already exists in _later
    next_filename = "#{next_date.strftime('%Y%m%d')}.#{task_name}.@#{rule}#{extension}"
    next_file_path = File.join(later_dir, next_filename)

    unless File.exist?(next_file_path)
      # Create the next instance
      FileUtils.cp(file_path, next_file_path)
      puts "Created strict repeating task: #{next_filename}"
    end
  end
end