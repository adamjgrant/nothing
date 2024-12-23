require 'minitest/autorun'
require 'fileutils'
require 'date'

class AddOverdueEmojiTest < Minitest::Test
  def setup
    # Create a test environment
    @test_root = File.expand_path('../../../../test', __dir__)
    FileUtils.mkdir_p(@test_root)

    # Create test files
    @overdue_file = File.join(@test_root, "#{(Date.today - 1).strftime('%Y-%m-%d')}.my task.md")
    @overdue_with_emoji_file = File.join(@test_root, "#{(Date.today - 1).strftime('%Y-%m-%d')}.«my task.md")
    @due_today_file = File.join(@test_root, "#{Date.today.strftime('%Y-%m-%d')}.due today task.md")
    @future_file = File.join(@test_root, "#{(Date.today + 1).strftime('%Y-%m-%d')}.future task.md")
    @non_date_file = File.join(@test_root, "Task without date.md")

    # Add test case for non-overdue file with warning emoji in root
    @non_overdue_with_emoji_in_root = File.join(@test_root, "#{(Date.today + 1).strftime('%Y-%m-%d')}.«non overdue task.md")
    File.write(@non_overdue_with_emoji_in_root, "Non-overdue task with warning emoji content")

    # Add test case for non-overdue file with warning emoji in _later
    @later_dir = File.join(@test_root, '_later')
    FileUtils.mkdir_p(@later_dir)
    @non_overdue_with_emoji_in_later = File.join(@later_dir, "#{(Date.today + 1).strftime('%Y-%m-%d')}.«non overdue task in later.md")
    File.write(@non_overdue_with_emoji_in_later, "Non-overdue task with warning emoji in later content")

    File.write(@overdue_file, "Overdue task content")
    File.write(@overdue_with_emoji_file, "Already tagged overdue task content")
    File.write(@due_today_file, "Due today task content")
    File.write(@future_file, "Future task content")
    File.write(@non_date_file, "Non-date task content")
  end

  def test_add_overdue_emoji
    # Run the extension
    extension_path = File.expand_path('../../extensions/overdue.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify overdue file is renamed with « added to the task name
    expected_overdue_file = File.join(@test_root, "#{(Date.today - 1).strftime('%Y-%m-%d')}.«my task.md")
    assert File.exist?(expected_overdue_file), "The overdue file was not renamed correctly."
    refute File.exist?(@overdue_file), "The original overdue file still exists."

    # Verify overdue file with existing « emoji remains unchanged
    assert File.exist?(@overdue_with_emoji_file), "The overdue file already tagged with « should remain unchanged."

    # Verify due today file remains unchanged
    assert File.exist?(@due_today_file), "The due-today file should remain unchanged."

    # Verify future file remains unchanged
    assert File.exist?(@future_file), "The future file should remain unchanged."

    # Verify non-date file remains unchanged
    assert File.exist?(@non_date_file), "The non-date file should remain unchanged."
  end

  def test_remove_warning_emoji_from_non_overdue_in_root
    # Run the extension
    extension_path = File.expand_path('../../extensions/overdue.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify the warning emoji is removed for non-overdue task in root
    expected_file = File.join(@test_root, "#{(Date.today + 1).strftime('%Y-%m-%d')}.non overdue task.md")
    assert File.exist?(expected_file), "The warning emoji was not removed for non-overdue task in root."
    refute File.exist?(@non_overdue_with_emoji_in_root), "The original file with warning emoji in root still exists."
  end

  def test_remove_warning_emoji_from_non_overdue_in_later
    # Run the extension
    extension_path = File.expand_path('../../extensions/overdue.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify the warning emoji is removed for non-overdue task in _later
    expected_file = File.join(@later_dir, "#{(Date.today + 1).strftime('%Y-%m-%d')}.non overdue task in later.md")
    assert File.exist?(expected_file), "The warning emoji was not removed for non-overdue task in _later."
    refute File.exist?(@non_overdue_with_emoji_in_later), "The original file with warning emoji in _later still exists."
  end

  def test_remove_warning_emoji_from_future_task_in_later_with_repeating_rule
    # Create the test file in _later
    future_repeating_file_with_emoji = File.join(
      @later_dir,
      "#{(Date.today >> 1).strftime('%Y-%m-%d')}.«Patrick.1d.md"
    )
    File.write(future_repeating_file_with_emoji, "Future repeating task with warning emoji in later content")
  
    # Run the extension
    extension_path = File.expand_path('../../extensions/overdue.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
  
    # Verify the warning emoji is removed for future task with repeating rule in _later
    expected_file = File.join(
      @later_dir,
      "#{(Date.today >> 1).strftime('%Y-%m-%d')}.Patrick.1d.md"
    )
    assert File.exist?(expected_file), "The warning emoji was not removed for the future repeating task in _later."
    refute File.exist?(future_repeating_file_with_emoji), "The original file with warning emoji in _later still exists."
  end

  def test_add_overdue_emoji_with_time_component
    # Create test files with a time component
    overdue_with_time_file = File.join(@test_root, "#{(Date.today - 1).strftime('%Y-%m-%d')}+1200.my task.md")
    due_today_with_time_file = File.join(@test_root, "#{Date.today.strftime('%Y-%m-%d')}+2359.my task.md")
    future_with_time_file = File.join(@test_root, "#{(Date.today + 1).strftime('%Y-%m-%d')}+1200.future task.md")
  
    File.write(overdue_with_time_file, "Overdue task with time component content")
    File.write(due_today_with_time_file, "Due today task with time component content")
    File.write(future_with_time_file, "Future task with time component content")
  
    # Run the extension
    extension_path = File.expand_path('../../extensions/overdue.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
  
    # Verify overdue file with time component is renamed with « added to the task name
    expected_overdue_with_time_file = File.join(@test_root, "#{(Date.today - 1).strftime('%Y-%m-%d')}+1200.«my task.md")
    assert File.exist?(expected_overdue_with_time_file), "The overdue file with time component was not renamed correctly."
    refute File.exist?(overdue_with_time_file), "The original overdue file with time component still exists."
  
    # Verify due today file with time component remains unchanged
    assert File.exist?(due_today_with_time_file), "The due-today file with time component should remain unchanged."
  
    # Verify future file with time component remains unchanged
    assert File.exist?(future_with_time_file), "The future file with time component should remain unchanged."
  end
end