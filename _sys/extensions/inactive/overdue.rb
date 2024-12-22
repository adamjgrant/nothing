#!/usr/bin/env ruby

# overdue.rb
#
# This extension processes files with a due date in their names that are past due.
# It adds a « emoji before the task name to indicate the task is overdue.
# Removes « emoji from tasks that are not overdue.
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

# Accept the root directory as a command-line argument, defaulting to the current directory
root_dir = ARGV[0] || Dir.pwd
later_dir = File.join(root_dir, '_later')

def process_directory(directory)
  Dir.foreach(directory) do |filename|
    next if filename == '.' || filename == '..'
    next if filename.start_with?('.') # Skip hidden files

    file_path = File.join(directory, filename)

    # Skip directories, only process files
    next unless File.file?(file_path)

    # Match files with the format <YYYY-MM-DD>.<task name>.<extension>
    if filename =~ /^(\d{4}-\d{2}-\d{2})\.(.+)(\..+)$/
      date_prefix = $1
      task_name = $2
      extension = $3

      # Parse the date prefix
      due_date = Date.strptime(date_prefix, '%Y-%m-%d') rescue nil
      next unless due_date # Skip if the date cannot be parsed

      # Remove « emoji from non-overdue tasks
      if due_date >= Date.today && task_name.start_with?('«')
        new_task_name = task_name.sub(/^«/, '') # Remove the « emoji
        new_filename = "#{date_prefix}.#{new_task_name}#{extension}"
        new_file_path = File.join(directory, new_filename)

        # Rename the file
        begin
          File.rename(file_path, new_file_path)
          # puts "Removed « from #{filename} -> #{new_filename}" # Debugging output
        rescue => e
          puts "Error renaming file: #{e.message}" # Log errors during renaming
        end
        next
      end

      # Add « emoji to overdue tasks
      if due_date < Date.today && !task_name.start_with?('«')
        new_task_name = "«#{task_name}"
        new_filename = "#{date_prefix}.#{new_task_name}#{extension}"
        new_file_path = File.join(directory, new_filename)

        # Rename the file
        begin
          File.rename(file_path, new_file_path)
          # puts "Renamed #{filename} to #{new_filename}" # Debugging output
          file_path = new_file_path # Update the file path after renaming
        rescue => e
          puts "Error renaming file: #{e.message}" # Log errors during renaming
        end

        # Move overdue file to the base directory
        base_directory_path = File.join(directory, File.basename(new_file_path))
        begin
          FileUtils.mv(new_file_path, base_directory_path)
          # puts "Moved overdue file: #{new_file_path} -> #{base_directory_path}"
        rescue => e
          puts "Error moving overdue file: #{e.message}" # Log errors during movement
        end
      end
    end
  end
end

# Process the root directory and the _later directory
process_directory(root_dir)
process_directory(later_dir) if Dir.exist?(later_dir)