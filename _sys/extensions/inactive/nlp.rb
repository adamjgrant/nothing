#!/usr/bin/env ruby

require 'fileutils'
require 'date'

# Accept the root directory as a command-line argument, defaulting to the current directory
root_dir = ARGV[0] || Dir.pwd

# Directories to process: root and _later
directories_to_process = [root_dir, File.join(root_dir, '_later')]

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

    # Check if the filename starts with "today", "tomorrow", or matches "<number><unit>" format (case-insensitive)
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
      puts "Renamed #{filename} to #{new_filename}" # Debugging output
    end
  end
end