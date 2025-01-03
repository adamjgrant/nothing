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
require_relative '../name_parser'

# Accept the root directory as a command-line argument, defaulting to the current directory
root_dir = ARGV[0] || Dir.pwd
later_dir = File.join(root_dir, '_later')

def process_directory(directory, root_dir)
  Dir.foreach(directory) do |filename|
    next if filename == '.' || filename == '..' || filename == '.DS_Store'
    next if filename.start_with?('.') # Skip hidden files

    file_path = File.join(directory, filename)

    # Skip directories that start with an underscore
    is_directory = File.directory?(file_path)
    next if is_directory && filename.start_with?('_')

    parser = NameParser.new(filename)
    due_date = Date.strptime(parser.date, '%Y-%m-%d') rescue nil
    next unless due_date # Skip if the date cannot be parsed

    assumed_time_suffix = parser.time ? "+#{parser.time}" : "+2359"
    due_time = Time.strptime(assumed_time_suffix, '+%H%M')

    due_date = Time.new(due_date.year, due_date.month, due_date.day, due_time.hour, due_time.min, due_time.sec, due_time.utc_offset)

    # Determine if the task is overdue
    current_time = Time.now
    is_overdue = due_date.to_date < current_time.to_date

    if !is_overdue && parser.date_decorators.include?('■')
      parser.remove_date_decorators(['■'])
    elsif is_overdue && !parser.date_decorators.include?('■')
      parser.add_date_decorators(['■'])
    end
    new_file_path = File.join(directory, parser.filename)
    begin
      File.rename(file_path, new_file_path)
    rescue => e
      puts "Error renaming file: #{e.message}" # Log errors during renaming
    end

    if is_overdue
      base_directory_path = File.join(root_dir, parser.filename)
      begin
        FileUtils.mv(new_file_path, base_directory_path)
      rescue => e
        # puts "Error moving overdue file: #{e.message}" # Log errors during movement
      end
    end
    next
  end
end

# Process the root directory and the _later directory
process_directory(root_dir, root_dir)
process_directory(later_dir, root_dir) if Dir.exist?(later_dir)