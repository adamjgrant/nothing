# amnesia.rb
# This extension gradually "erases" tasks over time based on their last modified date.
# Rules:
# 1. If the last modified date of a task file is more than 3 days old, add a skull emoji
#    (💀) in front of the title portion of the filename (not the date in the filename).
# 2. For each additional day, add one more skull in front of the existing skulls.
# 3. Once a filename has four skulls (💀💀💀💀), move the task to the 'archived' directory.
#
# To activate this extension, move it out of the 'inactive' folder and into the 'extensions' folder.

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

  if days_old > 3
    # Count existing skulls in the title
    skulls_match = filename.match(/^(💀+)/)
    existing_skulls = skulls_match ? skulls_match[1].length : 0

    puts "Existing skulls: #{existing_skulls}" # Debugging

    if existing_skulls < 4
      new_skulls = '💀' * (existing_skulls + 1)
      new_filename = "#{new_skulls}#{filename.gsub(/^(💀+)/, '')}"
      puts "Renaming to: #{new_filename}" # Debugging
      File.rename(file_path, File.join(BASE_DIR, new_filename))
    elsif existing_skulls == 4
      # Move the file to the archived directory
      archived_path = File.join(ARCHIVED_DIR, filename)
      puts "Archiving: #{archived_path}" # Debugging
      FileUtils.mv(file_path, archived_path)
    end
  end
end