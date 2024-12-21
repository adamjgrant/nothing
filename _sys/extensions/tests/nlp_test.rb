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
    @one_day_file = File.join(@test_root, "1d.exercise.txt")
    @two_weeks_file = File.join(@test_root, "2w.plan trip.txt")
    @three_months_file = File.join(@test_root, "3m.submit project.txt")
    @one_year_file = File.join(@test_root, "1y.renew passport.txt")
    @irrelevant_file = File.join(@test_root, "Do laundry.txt")

    File.write(@today_file, "Task content for today")
    File.write(@tomorrow_file, "Task content for tomorrow")
    File.write(@one_day_file, "Task content for 1 day from now")
    File.write(@two_weeks_file, "Task content for 2 weeks from now")
    File.write(@three_months_file, "Task content for 3 months from now")
    File.write(@one_year_file, "Task content for 1 year from now")
    File.write(@irrelevant_file, "Task content for irrelevant file")

    # Create test files in the _later directory
    @later_today_file = File.join(@later_dir, "today.water plants.txt")
    @later_tomorrow_file = File.join(@later_dir, "Tomorrow.organize books.txt")
    @later_two_weeks_file = File.join(@later_dir, "2w.meeting prep.txt")
    @later_irrelevant_file = File.join(@later_dir, "Read a book.txt")

    File.write(@later_today_file, "Task content for today in _later")
    File.write(@later_tomorrow_file, "Task content for tomorrow in _later")
    File.write(@later_two_weeks_file, "Task content for 2 weeks from now in _later")
    File.write(@later_irrelevant_file, "Task content for irrelevant file in _later")
  end

  def test_convert_day_to_date
    # Run the extension
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify "today" and "tomorrow" files
    expected_today_file = File.join(@test_root, "#{Date.today.strftime('%Y%m%d')}.mow lawn.txt")
    assert File.exist?(expected_today_file), "The 'today' file in the main directory was not renamed correctly."
    refute File.exist?(@today_file), "The original 'today' file in the main directory still exists."

    expected_tomorrow_file = File.join(@test_root, "#{(Date.today + 1).strftime('%Y%m%d')}.clean house.txt")
    assert File.exist?(expected_tomorrow_file), "The 'tomorrow' file in the main directory was not renamed correctly."
    refute File.exist?(@tomorrow_file), "The original 'tomorrow' file in the main directory still exists."

    # Verify "1d" file
    expected_one_day_file = File.join(@test_root, "#{(Date.today + 1).strftime('%Y%m%d')}.exercise.txt")
    assert File.exist?(expected_one_day_file), "The '1d' file in the main directory was not renamed correctly."
    refute File.exist?(@one_day_file), "The original '1d' file in the main directory still exists."

    # Verify "2w" file
    expected_two_weeks_file = File.join(@test_root, "#{(Date.today + 14).strftime('%Y%m%d')}.plan trip.txt")
    assert File.exist?(expected_two_weeks_file), "The '2w' file in the main directory was not renamed correctly."
    refute File.exist?(@two_weeks_file), "The original '2w' file in the main directory still exists."

    # Verify "3m" file
    expected_three_months_file = File.join(@test_root, "#{(Date.today >> 3).strftime('%Y%m%d')}.submit project.txt")
    assert File.exist?(expected_three_months_file), "The '3m' file in the main directory was not renamed correctly."
    refute File.exist?(@three_months_file), "The original '3m' file in the main directory still exists."

    # Verify "1y" file
    expected_one_year_file = File.join(@test_root, "#{(Date.today >> 12).strftime('%Y%m%d')}.renew passport.txt")
    assert File.exist?(expected_one_year_file), "The '1y' file in the main directory was not renamed correctly."
    refute File.exist?(@one_year_file), "The original '1y' file in the main directory still exists."

    # Verify irrelevant file remains unchanged in the main directory
    assert File.exist?(@irrelevant_file), "The irrelevant file in the main directory should remain unchanged."

    # Verify files in the _later directory
    expected_later_today_file = File.join(@later_dir, "#{Date.today.strftime('%Y%m%d')}.water plants.txt")
    assert File.exist?(expected_later_today_file), "The 'today' file in the _later directory was not renamed correctly."
    refute File.exist?(@later_today_file), "The original 'today' file in the _later directory still exists."

    expected_later_tomorrow_file = File.join(@later_dir, "#{(Date.today + 1).strftime('%Y%m%d')}.organize books.txt")
    assert File.exist?(expected_later_tomorrow_file), "The 'tomorrow' file in the _later directory was not renamed correctly."
    refute File.exist?(@later_tomorrow_file), "The original 'tomorrow' file in the _later directory still exists."

    expected_later_two_weeks_file = File.join(@later_dir, "#{(Date.today + 14).strftime('%Y%m%d')}.meeting prep.txt")
    assert File.exist?(expected_later_two_weeks_file), "The '2w' file in the _later directory was not renamed correctly."
    refute File.exist?(@later_two_weeks_file), "The original '2w' file in the _later directory still exists."

    # Verify irrelevant file remains unchanged in the _later directory
    assert File.exist?(@later_irrelevant_file), "The irrelevant file in the _later directory should remain unchanged."
  end
end