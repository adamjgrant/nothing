#!/usr/bin/env ruby

# overdue.rb
#
# This extension processes files with a due date in their names that are past due.
# It adds a ⚠️ emoji before the task name to indicate the task is overdue.
# 
# Expected Filename Format:
#   <YYYYMMDD>.<task name>.<extension>
#
# What It Does:
# - Adds ⚠️ to the task name for files with a date earlier than today.
# - Leaves files with today’s or future dates unchanged.
# - Skips files that do not match the expected format.
# - Does not add duplicate ⚠️ if the emoji is already present.
#
# Usage:
#   ruby overdue.rb <root_directory>
#   - Replace <root_directory> with the path to the directory you want to process.
#   - If no directory is provided, the current working directory is used.
#
# Example:
# - Before: 20231219.my task.md
# - After:  20231219.⚠️my task.md

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

  # Match files with the format <YYYYMMDD>.<task name>.<extension>
  if filename =~ /^(\d{8})\.(.+)(\..+)$/
    date_prefix = $1
    task_name = $2
    extension = $3

    # Parse the date prefix
    due_date = Date.strptime(date_prefix, '%Y%m%d') rescue nil
    next unless due_date # Skip if the date cannot be parsed

    # Skip files that are not past due
    next if due_date >= Date.today

    # Skip files that already have the ⚠️ emoji
    next if task_name.start_with?('⚠️')

    # Add the ⚠️ emoji to the task name
    new_task_name = "⚠️#{task_name}"
    new_filename = "#{date_prefix}.#{new_task_name}#{extension}"
    new_file_path = File.join(root_dir, new_filename)

    # Rename the file
    File.rename(file_path, new_file_path)
    puts "Renamed #{filename} to #{new_filename}" # Debugging output
  end
end