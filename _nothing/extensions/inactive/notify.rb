#!/usr/bin/env ruby
# notify.rb
#
# This extension monitors files whose first part (YYYY-MM-DD+HHMM+) ends with a '+'.
# When it finds such files that haven't been processed before, it sends an OS notification
# and records them in a meta file.
#
# File format examples that trigger notifications:
#   2024-12-20+1200+.mytask.txt   (Will trigger)
#   2024-12-20.normal-task.txt    (Won't trigger)
#   task.txt                      (Won't trigger)
#
# Usage:
#   ruby notify.rb <root_directory> [test]
#   - Replace <root_directory> with the path to process
#   - Optional 'test' parameter for testing without sending actual notifications

require 'fileutils'
require 'date'

# Force UTF-8 encoding
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

def has_date_first_part?(filename)
  first_part = filename.split('.')[0]
  return false unless first_part
  
  # Check if the first 10 characters match YYYY-MM-DD format
  return false unless first_part.length >= 10
  date_str = first_part[0..9]
  
  begin
    Date.strptime(date_str, '%Y-%m-%d')
    true
  rescue ArgumentError
    false
  end
end

def send_notification(title, message)
  case RbConfig::CONFIG['host_os']
  when /darwin/i
    system('osascript', '-e', "display notification \"#{message}\" with title \"#{title}\"")
  when /linux/i
    system('notify-send', title, message)
  when /mswin|mingw|cygwin/i
    system('powershell', '-Command', "Add-Type -AssemblyName System.Windows.Forms; $notify = New-Object System.Windows.Forms.NotifyIcon; $notify.Icon = [System.Drawing.SystemIcons]::Information; $notify.Visible = $true; $notify.ShowBalloonTip(0, '#{title}', '#{message}', [System.Windows.Forms.ToolTipIcon]::None)")
  end
end

def process_directory(root_dir, test_mode = false)
  meta_file = File.join(root_dir, 'notify-meta.txt')
  
  File.write(meta_file, '') if !File.exist?(meta_file)

  # Read existing notifications
  notified_files = File.readlines(meta_file, chomp: true)
  
  # Find files that need notification
  new_notifications = []
  
  Dir.foreach(root_dir) do |filename|
    next if filename == '.' || filename == '..'
    next if filename.start_with?('.') # Skip hidden files
    
    # Check if file has a date first part and ends with +
    if has_date_first_part?(filename) && filename.split('.')[0].end_with?('+')
      next if notified_files.include?(filename)
      new_notifications << filename
    end
  end
  
  if test_mode
    # In test mode, just print the files that would trigger notifications
    return new_notifications
  end
  
  # Process new notifications
  new_notifications.each do |filename|
    # Send OS notification
    title = "Task Notification"
    message = "Task due: #{filename}"
    send_notification(title, message) unless test_mode
    
    # Add to meta file
    File.open(meta_file, 'a') do |f|
      f.puts(filename)
    end
  end
end

# Main execution
if __FILE__ == $0
  root_dir = ARGV[0] || Dir.pwd
  test_mode = ARGV[1] == 'test'
  
  process_directory(root_dir, test_mode)
end