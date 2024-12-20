require_relative '../../../../sys/test'

class AmnesiaExtensionTest < ExtensionTestBase
  def setup
    super
    puts "Setting up test environment for AmnesiaExtensionTest"
    
    # Create test files with generic names
    @three_days_ago_file = File.join(test_root, "Task three days old.txt")
    @four_days_ago_file = File.join(test_root, "Task four days old.txt")
    @today_file = File.join(test_root, "Task created today.txt")
  
    # Write task content and set modification times
    File.write(@three_days_ago_file, "Task content")
    FileUtils.touch(@three_days_ago_file, mtime: (Date.today - 3).to_time)
  
    File.write(@four_days_ago_file, "Task content")
    FileUtils.touch(@four_days_ago_file, mtime: (Date.today - 4).to_time)
  
    File.write(@today_file, "Task content")
    FileUtils.touch(@today_file)
  
    puts "Contents of TEST_ROOT after setup:"
    puts Dir.glob("#{test_root}/**/*").join("\n")
  end

  def test_extensions
    # Run the amnesia extension
    amnesia_extension_path = File.join(test_root, 'extensions', 'amnesia.rb')
    system("ruby #{amnesia_extension_path} #{test_root}")
  
    # Verify that the three-days-old file remains unchanged (less than 4 days old)
    assert File.exist?(@three_days_ago_file), "The file modified three days ago should remain unchanged."
  
    # Verify that the four-days-old file has one skull emoji
    skull_file = File.join(test_root, "💀Task four days old.txt")
    assert File.exist?(skull_file), "The file modified four days ago should have one skull emoji."
  
    # Simulate additional days and verify skull increments
    FileUtils.touch(skull_file, mtime: (Date.today - 5).to_time)
    system("ruby #{amnesia_extension_path} #{test_root}")
  
    two_skulls_file = File.join(test_root, "💀💀Task four days old.txt")
    assert File.exist?(two_skulls_file), "The file should now have two skull emojis."
  
    # Simulate additional days to trigger archiving
    2.times do |i|
      FileUtils.touch(two_skulls_file, mtime: (Date.today - (6 + i)).to_time)
      system("ruby #{amnesia_extension_path} #{test_root}")
    end
  
    archived_file = File.join(File.join(test_root, 'archived'), "💀💀💀💀Task four days old.txt")
    assert File.exist?(archived_file), "The file should be moved to archived with four skull emojis."
  
    # Verify that today's file remains untouched
    assert File.exist?(@today_file), "The file created today should remain untouched."
  end
end