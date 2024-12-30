# push.rb
# Extension to process files in _push-1d, _push-1w, and _push-rand directories.
# It increments the dates on tasks based on the directory rules and moves them to _later.
# 
# Usage:
# - Place a task in _push-1d to add 1 day to its date and move to _later.
# - Place a task in _push-1w to add 7 days to its date and move to _later.
# - Place a task in _push-rand to add a random number of days (1-10) and move to _later.

require 'fileutils'
require 'date'
require_relative '../name_parser'

# Constants for directory names
PUSH_1D = '_push-1d'
PUSH_1W = '_push-1w'
PUSH_RAND = '_push-rand'
LATER = '_later'

# Ensure necessary directories exist
def ensure_directories(root_dir)
  push_rand_dir = File.join(root_dir, PUSH_RAND)
  Dir.mkdir(push_rand_dir) unless Dir.exist?(push_rand_dir)
end

def process_push_directories(root_dir)
  later_dir = File.join(root_dir, LATER)
  Dir.mkdir(later_dir) unless Dir.exist?(later_dir)

  # Find all _push-* directories
  Dir.foreach(root_dir) do |entry|
    next unless entry.start_with?('_push-')
    dir_path = File.join(root_dir, entry)
    next unless Dir.exist?(dir_path)

    random = true if entry == PUSH_RAND
    modification_string = entry.gsub("_push-", "")

    # Process files in the directory
    Dir.foreach(dir_path) do |file|
      next if file == '.' || file == '..'
      file_path = File.join(dir_path, file)
      is_directory = File.directory?(file_path)
      filename = File.basename(file_path)
      parser = NameParser.new(filename)
      # Push should always add to dates that are today/now or in the future
      # so we need to check if the date is in the past. If it is, let's set it to today.
      parser_date = Date.parse(parser.date) if parser.date
      if parser_date && parser_date < Date.today
        # Use a modification string to add the appropriate number of days based on the current parser.date value
        days_to_add = (Date.today - parser_date).to_i
        _modification_string = "#{days_to_add}d"
        parser = NameParser.new(parser.modify_filename_with_time(_modification_string))
      end
      
      modification_string = "#{rand(1..10)}d" if random

      # Similarly, we should make sure the time is in the future if the date is also set to today and the modification is for hours
      # without days.
      parser_time = Time.parse(parser.time.insert(2, ":")) if parser.time
      if parser_date == Date.today && parser_time && parser_time < Time.now && modification_string.match?(/\d+h/)
        parser.time = Time.now.strftime("%H%M")
      end

      new_filename = parser.modify_filename_with_time(modification_string)
      new_path = File.join(later_dir, new_filename)
      FileUtils.mv(file_path, new_path)
    end
  end
end

# Entry point
if __FILE__ == $0
  root_dir = ARGV[0] || Dir.pwd
  ensure_directories(root_dir)
  process_push_directories(root_dir)
end