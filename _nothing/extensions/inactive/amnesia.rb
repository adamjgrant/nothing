# amnesia.rb
# This extension gradually "erases" tasks over time based on their last modified date.

require 'fileutils'
require 'date'
require_relative '../name_parser'

# Accept a root directory as a command-line argument, defaulting to the current directory
root_dir = ARGV[0] || Dir.pwd

BASE_DIR = root_dir
DONE_DIR = File.join(BASE_DIR, '_done')

# Ensure the archived directory exists
FileUtils.mkdir_p(DONE_DIR) unless Dir.exist?(DONE_DIR)

# Check if a string is a valid date or date-like prefix
def is_date_part?(date_part)
  definitely_the_date_part = date_part.split("+")[0]
  return true if definitely_the_date_part =~ /^\d{4}-\d{2}-\d{2}/ # Matches YYYY-MM-DD
  return true if date_part.casecmp?('today') || date_part.casecmp?('tomorrow') || date_part =~ /^\d+[dwmy]$/i # Matches "12w", "3d", etc. 
  return false
end

# Process all task files in the base directory
Dir.foreach(BASE_DIR) do |filename|
  next if filename == '.' || filename == '..'
  next if filename.start_with?('.') # Skip hidden files (like `.keep`)
  parser = NameParser.new(filename)

  file_path = File.join(BASE_DIR, filename)

  # Skip directories that start with an underscore
  is_directory = File.directory?(file_path)
  next if is_directory && filename.start_with?('_')

  # Calculate how many days old the file is
  last_modified = File.mtime(file_path)
  days_old = (Date.today - last_modified.to_date).to_i

  # Determine the number of skulls based on days_old
  skull_count = [0, days_old - 2].max # Start applying skulls at 3 days old

  # Found skull count in the filename
  found_skull_count = parser.name_decorators.count { |decorator| decorator == '»' }

  # If the file was modified today, ensure no skulls are applied

  if skull_count > 0 || found_skull_count > 0
    skull_count = 0 if days_old == 0
    skulls = '»' * [skull_count, 4].min # Cap the skull count at 4

    # Remove existing skulls if days_old is 0
    new_name_decorators = parser.name_decorators.select { |decorator| decorator != '»' } # Remove any existing skulls
    parser.name_decorators = new_name_decorators + skulls.split("")
    new_filename = parser.filename

    new_file_path = File.join(BASE_DIR, new_filename)

    # Rename the file with the correct number of skulls
    if new_filename != filename
      if is_directory
        FileUtils.mv(file_path, new_file_path)
      else
        File.rename(file_path, new_file_path)
      end
      file_path = new_file_path # Update the file_path to reflect the rename
    end
  end

  # Archive the file if it has reached 6 or more days old
  if days_old >= 6
    if is_directory
      done_path = file_path.gsub(BASE_DIR, DONE_DIR)
    else
      done_path = File.join(DONE_DIR, File.basename(file_path))
    end
    begin
      FileUtils.mv(file_path, done_path)
    rescue => e
      puts "Error archiving file: #{e.message}" # Debugging: Log errors
    end
  end
end