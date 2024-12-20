#!/usr/bin/env ruby
require 'fileutils'
require 'date'

BASE_DIR = File.expand_path(File.dirname(__FILE__))
LATER_DIR = File.join(BASE_DIR, 'later')
ARCHIVED_DIR = File.join(BASE_DIR, 'archived')
SYS_DIR = File.join(BASE_DIR, 'sys')
EXTENSIONS_DIR = File.join(BASE_DIR, 'extensions')
ACTIVITY_LOG = File.join(SYS_DIR, 'activity.log')
ERROR_LOG = File.join(SYS_DIR, 'error.log')

# Ensure directories exist
[ LATER_DIR, ARCHIVED_DIR, SYS_DIR, EXTENSIONS_DIR ].each do |dir|
  Dir.mkdir(dir) unless Dir.exist?(dir)
end

today = Date.today

begin
  Dir.foreach(LATER_DIR) do |filename|
    next if filename == '.' || filename == '..'

    # Filename format: "<task>.<YYYYMMDD>.<ext>" or "<task>.<ext>"
    parts = filename.split('.')
    if parts.size >= 3
      potential_date_str = parts[-2]
      if potential_date_str.match?(/^\d{8}$/)
        due_date = parse_yyyymmdd(potential_date_str)
        if due_date && due_date <= today
          from_path = File.join(LATER_DIR, filename)
          to_path = File.join(BASE_DIR, filename)
          FileUtils.mv(from_path, to_path)
          File.open(ACTIVITY_LOG, 'a') do |f|
            f.puts "#{Time.now} Moved #{filename} from 'later' to '#{BASE_DIR}'."
          end
        end
      end
    end
  end

  # After processing tasks, run any extension scripts
  run_extensions
rescue => e
  File.open(ERROR_LOG, 'a') do |f|
    f.puts "#{Time.now} Error: #{e.message}"
    f.puts e.backtrace
  end
end

def parse_yyyymmdd(str)
  year = str[0..3].to_i
  month = str[4..5].to_i
  day = str[6..7].to_i
  Date.new(year, month, day) rescue nil
end

def run_extensions
  Dir.glob(File.join(EXTENSIONS_DIR, '*.rb')).each do |extension_file|
    begin
      load extension_file
      File.open(ACTIVITY_LOG, 'a') do |f|
        f.puts "#{Time.now} Ran extension: #{File.basename(extension_file)}"
      end
    rescue => e
      File.open(ERROR_LOG, 'a') do |f|
        f.puts "#{Time.now} Error running extension #{File.basename(extension_file)}: #{e.message}"
        f.puts e.backtrace
      end
    end
  end
end