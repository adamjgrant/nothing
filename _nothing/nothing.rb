#!/usr/bin/env ruby

# Force UTF-8 encoding
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'fileutils'
require 'date'
require_relative './name_parser'

# Set the root directory to the provided argument or default to the current directory
root_dir = ARGV[0] || File.expand_path('..', __dir__)

# Ensure the script is running inside a folder named '_nothing'
unless File.basename(__dir__) == '_nothing'
  STDERR.puts "Error: This script must be run from inside a '_nothing' directory. Parent is #{File.basename(__dir__)}"
  exit 1
end

BASE_DIR = root_dir.force_encoding('UTF-8')
LATER_DIR = File.join(BASE_DIR, '_later')
DONE_DIR = File.join(BASE_DIR, '_done')
NOTHING_DIR = File.join(BASE_DIR, '_nothing')
EXTENSIONS_DIR = File.join(NOTHING_DIR, 'extensions')
INACTIVE_EXTENSIONS_DIR = File.join(EXTENSIONS_DIR, 'inactive')
EXTENSIONS_TESTS_DIR = File.join(EXTENSIONS_DIR, 'tests')

# Ensure directories exist and include a .keep file
[ LATER_DIR, DONE_DIR, NOTHING_DIR, EXTENSIONS_DIR, INACTIVE_EXTENSIONS_DIR, EXTENSIONS_TESTS_DIR ].each do |dir|
  unless Dir.exist?(dir)
    Dir.mkdir(dir)
  end

  # Add a .keep file to the directory
  keep_file = File.join(dir, '.keep')
  FileUtils.touch(keep_file) unless File.exist?(keep_file)
end

# Delete install_nothing.sh if it exists
install_script = File.join(BASE_DIR, 'install_nothing.sh')
File.delete(install_script) if File.exist?(install_script)

# Set the current date
today = Date.today

# Always run nlp.rb first if it exists
nlp_script_path = File.join(EXTENSIONS_DIR, 'nlp.rb')
if File.exist?(nlp_script_path)
  system("ruby \"#{nlp_script_path}\" \"#{root_dir}\"")
end

def run_extensions(root_dir)
  Dir.glob(File.join(EXTENSIONS_DIR, '*.rb')).each do |extension_file|
    # Skip nlp.rb since it was already run
    next if File.basename(extension_file) == 'nlp.rb'
    system("ruby \"#{extension_file}\" \"#{root_dir}\"")
  end
end

moved_tasks = false

# Check tasks in _later for due tasks
Dir.foreach(LATER_DIR) do |filename|
  next if filename == '.' || filename == '..'

  entry_path = File.join(LATER_DIR, filename).force_encoding('UTF-8')

  # Parse the optional date prefix
  parser = NameParser.new(filename)
  due_date_as_date = Date.strptime(parser.date, '%Y-%m-%d') unless parser.date.nil?
  time = Time.strptime(parser.time, '%H%M') unless parser.time.nil?
  if time.nil? && due_date_as_date
    due_date = Time.new(due_date_as_date.year, due_date_as_date.month, due_date_as_date.day)
  elsif due_date_as_date
    due_date = Time.new(due_date_as_date.year, due_date_as_date.month, due_date_as_date.day, time.hour, time.min)
  else
    due_date = nil
  end

  if due_date && due_date <= Time.now
    if File.directory?(entry_path)
      to_path = File.join(BASE_DIR, filename)
      FileUtils.mv(entry_path, to_path) if !Dir.exist?(to_path)
      # Change modified time to now
      FileUtils.touch(to_path)
    else
      from_path = entry_path
      to_path = File.join(BASE_DIR, filename)
      FileUtils.mv(from_path, to_path)
      # Change modified time to now
      FileUtils.touch(to_path)
    end
    moved_tasks = true
  end
end

# Check tasks in BASE_DIR for future tasks and move them to _later
Dir.foreach(BASE_DIR) do |filename|
  next if filename == '.' || filename == '..'
  next if filename.start_with?('_') # Skip special directories like _later, _done, _nothing

  entry_path = File.join(BASE_DIR, filename).force_encoding('UTF-8')

  # Parse the optional date prefix
  parser = NameParser.new(filename)
  due_date_as_date = Date.strptime(parser.date, '%Y-%m-%d') unless parser.date.nil?
  time = Time.strptime(parser.time, '%H%M') unless parser.time.nil?
  if time.nil? && due_date_as_date
    due_date = Time.new(due_date_as_date.year, due_date_as_date.month, due_date_as_date.day)
  elsif due_date_as_date
    due_date = Time.new(due_date_as_date.year, due_date_as_date.month, due_date_as_date.day, time.hour, time.min)
  else
    due_date = nil
  end

  if due_date && due_date > Time.now
    if File.directory?(entry_path)
      to_path = File.join(LATER_DIR, filename)
      FileUtils.mv(entry_path, to_path)
    else
      from_path = entry_path
      to_path = File.join(LATER_DIR, filename)
      FileUtils.mv(from_path, to_path)
    end
    moved_tasks = true
  end
end

# Run any extension scripts
run_extensions(BASE_DIR)

# Recursively process non-underscored directories
def process_non_underscored_dirs(base_dir)
  Dir.foreach(base_dir) do |entry|
    next if entry.start_with?('_') || entry == '.' || entry == '..'

    entry_path = File.join(base_dir, entry).force_encoding('UTF-8')

    if File.directory?(entry_path)
      # Copy _nothing folder if it doesn't exist
      target_nothing_dir = File.join(entry_path, '_nothing')
      unless Dir.exist?(target_nothing_dir)
        FileUtils.cp_r(NOTHING_DIR, target_nothing_dir)
      end

      # Run nothing.rb if it exists
      nothing_script_path = File.join(target_nothing_dir, 'nothing.rb')
      
      if File.exist?(nothing_script_path)
        system("LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 ruby \"#{nothing_script_path}\" \"#{entry_path}\"")
      elsif entry == "My Project" && !File.exist?(nothing_script_path)
        puts "DEBUG: script not found #{entry_path}"
      end
    end
  end
end

# Add this line before exiting the script
process_non_underscored_dirs(BASE_DIR)