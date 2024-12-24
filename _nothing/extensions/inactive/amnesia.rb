# amnesia.rb
# This extension gradually "erases" tasks over time based on their last modified date.

require 'fileutils'
require 'date'

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

  file_path = File.join(BASE_DIR, filename)
  next unless File.file?(file_path) # Skip directories

  # Calculate how many days old the file is
  last_modified = File.mtime(file_path)
  days_old = (Date.today - last_modified.to_date).to_i

  # Determine the number of skulls based on days_old
  skull_count = [0, days_old - 2].max # Start applying skulls at 3 days old

  if skull_count > 0
    skulls = '💀' * [skull_count, 4].min # Cap the skull count at 4

    # Split filename by "."
    parent_array = filename.split('.')
    first_part = parent_array[0]
    second_part = parent_array[1]
    extension = parent_array[-1]

    # Check if the first part matches any of the date conditions
    if is_date_part?(first_part)
      date_part = first_part + "."
      task_part = second_part
    else
      # If not a date, apply skulls to the whole filename
      task_part = first_part
    end
    base_name = task_part.gsub(/^(\u{1F480}+)/, '') # Remove any existing skulls
    new_filename = "#{date_part}#{skulls}#{base_name}.#{extension}"

    new_file_path = File.join(BASE_DIR, new_filename)

    # Rename the file with the correct number of skulls
    if new_filename != filename
      File.rename(file_path, new_file_path)
      file_path = new_file_path # Update the file_path to reflect the rename
    end
  end

  # Archive the file if it has reached 6 or more days old
  if days_old >= 6
    done_path = File.join(DONE_DIR, File.basename(file_path))
    begin
      FileUtils.mv(file_path, done_path)
    rescue => e
      puts "Error archiving file: #{e.message}" # Debugging: Log errors
    end
  end
end