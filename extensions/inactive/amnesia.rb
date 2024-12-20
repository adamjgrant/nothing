# amnesia.rb
# This extension gradually "erases" tasks over time based on their last modified date.

require 'fileutils'
require 'date'

# Accept a root directory as a command-line argument, defaulting to the current directory
root_dir = ARGV[0] || Dir.pwd

BASE_DIR = root_dir
ARCHIVED_DIR = File.join(BASE_DIR, 'archived')

# Ensure the archived directory exists
FileUtils.mkdir_p(ARCHIVED_DIR) unless Dir.exist?(ARCHIVED_DIR)

# Process all task files in the base directory
Dir.foreach(BASE_DIR) do |filename|
  next if filename == '.' || filename == '..'
  next if filename.start_with?('.') # Skip hidden files (like `.keep`)

  file_path = File.join(BASE_DIR, filename)
  next unless File.file?(file_path) # Skip directories

  # Calculate how many days old the file is
  last_modified = File.mtime(file_path)
  days_old = (Date.today - last_modified.to_date).to_i

  puts "Processing file: #{file_path}" # Debugging
  puts "Last modified time: #{last_modified}" # Debugging
  puts "Days old: #{days_old}" # Debugging

  # Determine the number of skulls based on days_old
  skull_count = [0, days_old - 2].max # Start applying skulls at 3 days old

  if skull_count > 0
    skulls = '💀' * [skull_count, 4].min # Cap the skull count at 4
    base_name = filename.gsub(/^(\u{1F480}+)/, '') # Remove any existing skulls
    new_filename = "#{skulls}#{base_name}"
    new_file_path = File.join(BASE_DIR, new_filename)

    # Rename the file with the correct number of skulls
    if new_filename != filename
      puts "Renaming file to: #{new_filename}" # Debugging
      File.rename(file_path, new_file_path)
      file_path = new_file_path # Update the file_path to reflect the rename
    end
  end

  # Archive the file if it has reached 6 or more days old
  if days_old >= 6
    archived_path = File.join(ARCHIVED_DIR, File.basename(file_path))
    puts "Archiving file: #{file_path} to #{archived_path}" # Debugging
    begin
      FileUtils.mv(file_path, archived_path)
      puts "File successfully archived: #{archived_path}" # Debugging
    rescue => e
      puts "Error archiving file: #{e.message}" # Debugging
    end
  end
end