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
    next if filename == '.' || filename == '..'
    next if filename.start_with?('.') # Skip hidden files

    file_path = File.join(current_dir, filename)

    # Skip directories, only process files
    next unless File.file?(file_path)

    # Extract the base name and extension
    base_name = File.basename(filename, '.*')
    extension = File.extname(filename)

    # Logic for "today", "tomorrow", or "<number><unit>" formats
    if base_name =~ /^(today|tomorrow|(\d+)([dwmy]))\.(.+)$/i
      prefix = $1.downcase
      number = $2 ? $2.to_i : nil
      unit = $3
      rest_of_filename = $4

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

      # Construct the new filename with the date
      new_filename = "#{date.strftime('%Y-%m-%d')}.#{rest_of_filename}#{extension}"
      new_file_path = File.join(current_dir, new_filename)

      # Rename the file
      File.rename(file_path, new_file_path)
      # puts "DEBUG: Processing file #{file_path}" if File.exist?(file_path)
      # puts "DEBUG: Renaming #{file_path} to #{new_file_path}" if new_file_path
    end

    # Logic for day names (e.g., "Monday.task.txt")
    if base_name =~ /^(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\.(.+)$/i
      day_name = $1.downcase
      task_name = $2

      # Calculate the target day of the week (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
      target_wday = %w[sunday monday tuesday wednesday thursday friday saturday].index(day_name)
      today = Date.today
      today_wday = today.wday

      # Calculate the next occurrence of the day (always at least 7 days ahead)
      days_until_next_occurrence = (target_wday - today_wday + 7) % 7
      days_until_next_occurrence = 7 if days_until_next_occurrence.zero? # Ensure it's at least a week away
      next_day = today + days_until_next_occurrence

      # Construct the new filename with the calculated date
      new_filename = "#{next_day.strftime('%Y-%m-%d')}.#{task_name}#{extension}"
      new_file_path = File.join(current_dir, new_filename)

      # Rename the file
      File.rename(file_path, new_file_path)
      puts "Renamed #{filename} to #{new_filename}" # Debugging output
    end
  end
end