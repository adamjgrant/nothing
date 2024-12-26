#!/usr/bin/env ruby
# housekeeper.rb
#
# This extension cleans up old files in the _done directory.
# It deletes any files that haven't been modified in the last 6 months.
#
# Usage:
#   ruby housekeeper.rb <root_directory>
#   - Replace <root_directory> with the path to process
#   - If no directory is provided, the current working directory is used

require 'fileutils'
require 'date'

# Force UTF-8 encoding
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Constants
SIX_MONTHS_IN_SECONDS = 6 * 30 * 24 * 60 * 60

def process_directory(directory)
  Dir.foreach(directory) do |entry|
    next if entry == '.' || entry == '..'
    next if entry.start_with?('.') # Skip hidden files/directories
    
    full_path = File.join(directory, entry)
    
    if File.directory?(full_path)
      # Recursively process subdirectories
      process_directory(full_path)
    elsif File.file?(full_path)
      # Check file age
      file_age = Time.now - File.mtime(full_path)
      
      if file_age > SIX_MONTHS_IN_SECONDS
        begin
          File.delete(full_path)
          # puts "Deleted old file: #{full_path}" # Debugging output
        rescue => e
          puts "Error deleting file #{full_path}: #{e.message}"
        end
      end
    end
  end
end

# Main execution
if __FILE__ == $0
  root_dir = ARGV[0] || Dir.pwd
  done_dir = File.join(root_dir, '_done')
  
  if Dir.exist?(done_dir)
    process_directory(done_dir)
  end
end