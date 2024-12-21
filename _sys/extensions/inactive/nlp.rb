#!/usr/bin/env ruby

require 'fileutils'
require 'date'

# Accept the root directory as a command-line argument, defaulting to the current directory
root_dir = ARGV[0] || Dir.pwd

# Process all files in the root directory
Dir.foreach(root_dir) do |filename|
  next if filename == '.' || filename == '..'
  next if filename.start_with?('.') # Skip hidden files

  file_path = File.join(root_dir, filename)

  # Skip directories, only process files
  next unless File.file?(file_path)

  # Check if the filename starts with "today" or "tomorrow" (case-insensitive)
  if filename =~ /^(today|tomorrow)\.(.+)$/i
    prefix = $1.downcase
    rest_of_filename = $2

    # Determine the appropriate date
    date = if prefix == 'today'
             Date.today
           elsif prefix == 'tomorrow'
             Date.today + 1
           end

    # Construct the new filename with the date
    new_filename = "#{date.strftime('%Y%m%d')}.#{rest_of_filename}"
    new_file_path = File.join(root_dir, new_filename)

    # Rename the file
    File.rename(file_path, new_file_path)
  end
end