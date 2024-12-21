require 'minitest/autorun'
require 'fileutils'
require 'date'

class ConvertDayToDateTest < Minitest::Test
  def setup
    # Create a test environment
    @test_root = File.expand_path('../../../../test', __dir__)
    FileUtils.mkdir_p(@test_root)

    # Create test files
    @today_file = File.join(@test_root, "today.mow lawn.txt")
    @tomorrow_file = File.join(@test_root, "Tomorrow.clean house.txt")
    @irrelevant_file = File.join(@test_root, "Do laundry.txt")

    File.write(@today_file, "Task content for today")
    File.write(@tomorrow_file, "Task content for tomorrow")
    File.write(@irrelevant_file, "Task content for irrelevant file")
  end

  def test_convert_today_to_date
    # Run the extension
    extension_path = File.expand_path('../../convert_day_to_date.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify today's file is renamed correctly
    expected_today_file = File.join(@test_root, "#{Date.today.strftime('%Y%m%d')}.mow lawn.txt")
    assert File.exist?(expected_today_file), "The 'today' file was not renamed correctly."
    refute File.exist?(@today_file), "The original 'today' file still exists."

    # Verify tomorrow's file is renamed correctly
    expected_tomorrow_file = File.join(@test_root, "#{(Date.today + 1).strftime('%Y%m%d')}.clean house.txt")
    assert File.exist?(expected_tomorrow_file), "The 'tomorrow' file was not renamed correctly."
    refute File.exist?(@tomorrow_file), "The original 'tomorrow' file still exists."

    # Verify irrelevant file remains unchanged
    assert File.exist?(@irrelevant_file), "The irrelevant file should remain unchanged."
  end
end