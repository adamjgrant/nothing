#!/usr/bin/env ruby

# overdue.rb
#
# This extension processes files with a due date in their names that are past due.
# It adds a ■ emoji before the task name to indicate the task is overdue.
# Removes ■ emoji from tasks that are not overdue.
# Moves overdue files to the base directory if required.
#
# Expected Filename Format:
#   <YYYY-MM-DD>.<task name>.<extension>
#
# Usage:
#   ruby overdue.rb <root_directory>
#   - Replace <root_directory> with the path to the directory you want to process.
#   - If no directory is provided, the current working directory is used.

# Force UTF-8 encoding
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'fileutils'
require 'date'
require 'time'

# Accept the root directory as a command-line argument, defaulting to the current directory
root_dir = ARGV[0] || Dir.pwd
later_dir = File.join(root_dir, '_later')

def process_directory(directory)
  Dir.foreach(directory) do |filename|
    next if filename == '.' || filename == '..'
    next if filename.start_with?('.') # Skip hidden files

    file_path = File.join(directory, filename)

    # Skip directories that start with an underscore
    next if File.directory?(file_path) && filename.start_with?('_')
      
    # Match files with the format <YYYY-MM-DD[+HHMM]>.<task name>.<extension>
    if filename =~ /^(\d{4}-\d{2}-\d{2})(\+\d{4})?\.(.+)(\..+)$/
      date_prefix = $1
      time_suffix = $2 # Optional time component
      task_name = $3
      extension = $4

      # Parse the date prefix
      due_date = Date.strptime(date_prefix, '%Y-%m-%d') rescue nil
      next unless due_date # Skip if the date cannot be parsed

      if time_suffix.nil?
        assumed_time_suffix = "+2359" 
      else time_suffix
        assumed_time_suffix = time_suffix
      end

      # Parse the time component
      due_time = Time.strptime(assumed_time_suffix, '+%H%M')

      due_date = Time.new(due_date.year, due_date.month, due_date.day, due_time.hour, due_time.min, due_time.sec, due_time.utc_offset)

      # Determine if the task is overdue
      current_time = Time.now
      is_overdue = due_date.to_date < current_time.to_date

      # Remove ■ emoji from non-overdue tasks
      if !is_overdue && task_name.start_with?('■')
        new_task_name = task_name.sub(/^■/, '') # Remove the ■ emoji
        new_filename = "#{date_prefix}#{time_suffix}.#{new_task_name}#{extension}"
        new_file_path = File.join(directory, new_filename)

        # Rename the file
        begin
          File.rename(file_path, new_file_path)
          # puts "Removed ■ from #{filename} -> #{new_filename}" # Debugging output
        rescue => e
          puts "Error renaming file: #{e.message}" # Log errors during renaming
        end
        next
      end

      # Add ■ emoji to overdue tasks
      if is_overdue && !task_name.start_with?('■')
        new_task_name = "■#{task_name}"
        new_filename = "#{date_prefix}#{time_suffix}.#{new_task_name}#{extension}"
        new_file_path = File.join(directory, new_filename)

        # Rename the file
        begin
          File.rename(file_path, new_file_path)
          # puts "Renamed #{filename} to #{new_filename}" # Debugging output
          file_path = new_file_path # Update the file path after renaming
        rescue => e
          # puts "Error renaming file: #{e.message}" # Log errors during renaming
        end

        # Move overdue file to the base directory
        base_directory_path = File.join(directory, File.basename(new_file_path))
        begin
          FileUtils.mv(new_file_path, base_directory_path)
          # puts "Moved overdue file: #{new_file_path} -> #{base_directory_path}"
        rescue => e
          # puts "Error moving overdue file: #{e.message}" # Log errors during movement
        end
      end
    end
  end
end

# Process the root directory and the _later directory
process_directory(root_dir)
process_directory(later_dir) if Dir.exist?(later_dir)