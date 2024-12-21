require 'minitest/autorun'
require 'fileutils'
require 'date'

class ConvertDayToDateTest < Minitest::Test
  def setup
    # Create a test environment
    @test_root = File.expand_path('../../../../test', __dir__)
    @later_dir = File.join(@test_root, '_later')
    FileUtils.mkdir_p(@test_root)
    FileUtils.mkdir_p(@later_dir)

    # Create test files in the main directory
    @today_file = File.join(@test_root, "today.mow lawn.txt")
    @tomorrow_file = File.join(@test_root, "Tomorrow.clean house.txt")
    @irrelevant_file = File.join(@test_root, "Do laundry.txt")

    File.write(@today_file, "Task content for today")
    File.write(@tomorrow_file, "Task content for tomorrow")
    File.write(@irrelevant_file, "Task content for irrelevant file")

    # Create test files in the _later directory
    @later_today_file = File.join(@later_dir, "today.water plants.txt")
    @later_tomorrow_file = File.join(@later_dir, "Tomorrow.organize books.txt")
    @later_irrelevant_file = File.join(@later_dir, "Read a book.txt")

    File.write(@later_today_file, "Task content for today in _later")
    File.write(@later_tomorrow_file, "Task content for tomorrow in _later")
    File.write(@later_irrelevant_file, "Task content for irrelevant file in _later")
  end

  def test_convert_today_to_date
    # Run the extension
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify today's file is renamed correctly in the main directory
    expected_today_file = File.join(@test_root, "#{Date.today.strftime('%Y%m%d')}.mow lawn.txt")
    assert File.exist?(expected_today_file), "The 'today' file in the main directory was not renamed correctly."
    refute File.exist?(@today_file), "The original 'today' file in the main directory still exists."

    # Verify tomorrow's file is renamed correctly in the main directory
    expected_tomorrow_file = File.join(@test_root, "#{(Date.today + 1).strftime('%Y%m%d')}.clean house.txt")
    assert File.exist?(expected_tomorrow_file), "The 'tomorrow' file in the main directory was not renamed correctly."
    refute File.exist?(@tomorrow_file), "The original 'tomorrow' file in the main directory still exists."

    # Verify irrelevant file remains unchanged in the main directory
    assert File.exist?(@irrelevant_file), "The irrelevant file in the main directory should remain unchanged."

    # Verify today's file is renamed correctly in the _later directory
    expected_later_today_file = File.join(@later_dir, "#{Date.today.strftime('%Y%m%d')}.water plants.txt")
    assert File.exist?(expected_later_today_file), "The 'today' file in the _later directory was not renamed correctly."
    refute File.exist?(@later_today_file), "The original 'today' file in the _later directory still exists."

    # Verify tomorrow's file is renamed correctly in the _later directory
    expected_later_tomorrow_file = File.join(@later_dir, "#{(Date.today + 1).strftime('%Y%m%d')}.organize books.txt")
    assert File.exist?(expected_later_tomorrow_file), "The 'tomorrow' file in the _later directory was not renamed correctly."
    refute File.exist?(@later_tomorrow_file), "The original 'tomorrow' file in the _later directory still exists."

    # Verify irrelevant file remains unchanged in the _later directory
    assert File.exist?(@later_irrelevant_file), "The irrelevant file in the _later directory should remain unchanged."
  end
end