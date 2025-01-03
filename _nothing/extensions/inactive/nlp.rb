#!/usr/bin/env ruby

require 'fileutils'
require 'date'

# Accept the root directory as a command-line argument, defaulting to the current directory
root_dir = ARGV[0] || Dir.pwd

# Dynamically determine directories to process (exclude `_nothing`)
directories_to_process = Dir.glob(File.join(root_dir, '*')).select do |path|
  File.directory?(path) && !File.basename(path).start_with?('_nothing')
end
directories_to_process << root_dir # Include the root directory itself

directories_to_process.each do |current_dir|
  # Skip if the directory doesn't exist
  next unless Dir.exist?(current_dir)

  # Process all files in the current directory
  Dir.foreach(current_dir) do |filename|
    next if filename == '.' || filename == '..' || filename == '.DS_Store'
    next if filename.start_with?('.') # Skip hidden files

    file_path = File.join(current_dir, filename)

    # Skip directories that start with an underscore
    is_directory = File.directory?(file_path)
    next if is_directory && filename.start_with?('_')

    # Extract the base name and extension
    if is_directory
      extension = ''
      base_name = filename
    else
      extension = File.extname(filename)
      base_name = File.basename(filename, '.*')
    end

    # Logic for "today", "tomorrow", or "<number><unit>" formats with optional time
    if base_name =~ /^(today|tomorrow|(\d+)([dwmy]))([\+\d]*)\.(.+)?$/i
      prefix = $1.downcase
      number = $2 ? $2.to_i : nil
      unit = $3
      time_component = $4
      rest_of_filename = $5

      # Determine the appropriate date
      date = case prefix
             when 'today'
               Date.today
             when 'tomorrow'
               Date.today + 1
             else
               # Calculate based on <number><unit>
               case unit
               when 'd'
                 Date.today + number
               when 'w'
                 Date.today + (number * 7)
               when 'm'
                 Date.today >> number # Add months
               when 'y'
                 Date.today >> (number * 12) # Add years
               end
             end

      # Construct the new filename with the date and optional time
      date_str = date.strftime('%Y-%m-%d')
      new_filename = "#{date_str}#{time_component}.#{rest_of_filename}#{extension}"
      new_file_path = File.join(current_dir, new_filename)

      # Rename the file
      File.rename(file_path, new_file_path)
    end

    # Logic for day names (e.g., "Monday.task.txt")
    if base_name =~ /^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)([\+\d]*)\.(.+)?$/i
      day_name = $1.downcase
      time_component = $2 # Captures the +HHMM part, if present
      task_name = $3

      # Calculate the target day of the week (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
      target_wday = %w[sunday monday tuesday wednesday thursday friday saturday].index(day_name)
      today = Date.today
      today_wday = today.wday

      # Calculate the next occurrence of the day (always at least 7 days ahead)
      days_until_next_occurrence = (target_wday - today_wday + 7) % 7
      days_until_next_occurrence = 7 if days_until_next_occurrence.zero? # Ensure it's at least a week away
      next_day = today + days_until_next_occurrence

      # Construct the new filename with the calculated date
      date_str = next_day.strftime('%Y-%m-%d')
      new_filename = "#{date_str}#{time_component}.#{task_name}#{extension}"
      new_file_path = File.join(current_dir, new_filename)

      # Rename the file
      File.rename(file_path, new_file_path)
    end
  end
end