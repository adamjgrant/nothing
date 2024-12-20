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

# Accept a root directory as a command-line argument, defaulting to the current directory
root_dir = ARGV[0] || Dir.pwd

BASE_DIR = root_dir
ARCHIVED_DIR = File.join(BASE_DIR, 'archived')

# Ensure the archived directory exists
FileUtils.mkdir_p(ARCHIVED_DIR) unless Dir.exist?(ARCHIVED_DIR)

# Process all task files in the base directory
Dir.foreach(BASE_DIR) do |filename|
  next if filename == '.' || filename == '..'
  next unless filename.match?(/^\d{8}\./) || filename.match?(/^[^💀]+/) # Ensure it's a task file

  file_path = File.join(BASE_DIR, filename)
  next unless File.file?(file_path) # Skip directories or non-files

  last_modified = File.mtime(file_path)
  days_old = (Date.today - last_modified.to_date).to_i

  if days_old > 3
    title_start = filename.index('.') + 1
    title = filename[title_start..-1]

    # Count existing skulls in the title
    skulls_match = title.match(/^(💀+)/)
    existing_skulls = skulls_match ? skulls_match[1].length : 0

    if existing_skulls < 4
      new_skulls = '💀' * (existing_skulls + 1)
      new_filename = filename[0...title_start] + new_skulls + title.gsub(/^(💀+)/, '')
      File.rename(file_path, File.join(BASE_DIR, new_filename))
    elsif existing_skulls == 4
      # Move the file to the archived directory
      FileUtils.mv(file_path, File.join(ARCHIVED_DIR, filename))
    end
  end
end