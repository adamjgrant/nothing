require 'minitest/autorun'
require 'fileutils'
require 'date'

class AddOverdueEmojiTest < Minitest::Test
  def setup
    # Create a test environment
    @test_root = File.expand_path('../../../../test', __dir__)
    FileUtils.rm_rf(@test_root) # Clear any previous test setup
    FileUtils.mkdir_p(@test_root)

    # Create test files
    @overdue_file = File.join(@test_root, "#{(Date.today - 1).strftime('%Y%m%d')}.my task.md")
    @overdue_with_emoji_file = File.join(@test_root, "#{(Date.today - 1).strftime('%Y%m%d')}.⚠️my task.md")
    @due_today_file = File.join(@test_root, "#{Date.today.strftime('%Y%m%d')}.due today task.md")
    @future_file = File.join(@test_root, "#{(Date.today + 1).strftime('%Y%m%d')}.future task.md")
    @non_date_file = File.join(@test_root, "Task without date.md")

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

    # Verify overdue file is renamed with ⚠️ added to the task name
    expected_overdue_file = File.join(@test_root, "#{(Date.today - 1).strftime('%Y%m%d')}.⚠️my task.md")
    assert File.exist?(expected_overdue_file), "The overdue file was not renamed correctly."
    refute File.exist?(@overdue_file), "The original overdue file still exists."

    # Verify overdue file with existing ⚠️ emoji remains unchanged
    assert File.exist?(@overdue_with_emoji_file), "The overdue file already tagged with ⚠️ should remain unchanged."

    # Verify due today file remains unchanged
    assert File.exist?(@due_today_file), "The due-today file should remain unchanged."

    # Verify future file remains unchanged
    assert File.exist?(@future_file), "The future file should remain unchanged."

    # Verify non-date file remains unchanged
    assert File.exist?(@non_date_file), "The non-date file should remain unchanged."
  end
end