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

    # Add to the existing `setup` method
    @directories = %w[_later _archived _push-1d _push-1w _push-rand].map do |dir|
      path = File.join(@test_root, dir)
      FileUtils.mkdir_p(path)
      path
    end

    @directories.each do |dir|
      # Dynamically determine the prefix based on the directory
      prefix = dir == @test_root ? "today" : "tomorrow"
  
      filename = "#{prefix}.nlp-mytask.txt"
      file_path = File.join(dir, filename)
      File.write(file_path, "Test content for #{filename}")
    end
  end

  def test_convert_day_to_date
    # Run the extension
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify "today" and "tomorrow" files
    expected_today_file = File.join(@test_root, "#{Date.today.strftime('%Y-%m-%d')}.mow lawn.txt")
    assert File.exist?(expected_today_file), "The 'today' file in the main directory was not renamed correctly."
    refute File.exist?(@today_file), "The original 'today' file in the main directory still exists."

    expected_tomorrow_file = File.join(@test_root, "#{(Date.today + 1).strftime('%Y-%m-%d')}.clean house.txt")
    assert File.exist?(expected_tomorrow_file), "The 'tomorrow' file in the main directory was not renamed correctly."
    refute File.exist?(@tomorrow_file), "The original 'tomorrow' file in the main directory still exists."

    # Verify "1d" file
    expected_one_day_file = File.join(@test_root, "#{(Date.today + 1).strftime('%Y-%m-%d')}.exercise.txt")
    assert File.exist?(expected_one_day_file), "The '1d' file in the main directory was not renamed correctly."
    refute File.exist?(@one_day_file), "The original '1d' file in the main directory still exists."

    # Verify "2w" file
    expected_two_weeks_file = File.join(@test_root, "#{(Date.today + 14).strftime('%Y-%m-%d')}.plan trip.txt")
    assert File.exist?(expected_two_weeks_file), "The '2w' file in the main directory was not renamed correctly."
    refute File.exist?(@two_weeks_file), "The original '2w' file in the main directory still exists."

    # Verify "3m" file
    expected_three_months_file = File.join(@test_root, "#{(Date.today >> 3).strftime('%Y-%m-%d')}.submit project.txt")
    assert File.exist?(expected_three_months_file), "The '3m' file in the main directory was not renamed correctly."
    refute File.exist?(@three_months_file), "The original '3m' file in the main directory still exists."

    # Verify "1y" file
    expected_one_year_file = File.join(@test_root, "#{(Date.today >> 12).strftime('%Y-%m-%d')}.renew passport.txt")
    assert File.exist?(expected_one_year_file), "The '1y' file in the main directory was not renamed correctly."
    refute File.exist?(@one_year_file), "The original '1y' file in the main directory still exists."

    # Verify irrelevant file remains unchanged in the main directory
    assert File.exist?(@irrelevant_file), "The irrelevant file in the main directory should remain unchanged."

    # Verify files in the _later directory
    expected_later_today_file = File.join(@later_dir, "#{Date.today.strftime('%Y-%m-%d')}.water plants.txt")
    assert File.exist?(expected_later_today_file), "The 'today' file in the _later directory was not renamed correctly."
    refute File.exist?(@later_today_file), "The original 'today' file in the _later directory still exists."

    expected_later_tomorrow_file = File.join(@later_dir, "#{(Date.today + 1).strftime('%Y-%m-%d')}.organize books.txt")
    assert File.exist?(expected_later_tomorrow_file), "The 'tomorrow' file in the _later directory was not renamed correctly."
    refute File.exist?(@later_tomorrow_file), "The original 'tomorrow' file in the _later directory still exists."

    expected_later_two_weeks_file = File.join(@later_dir, "#{(Date.today + 14).strftime('%Y-%m-%d')}.meeting prep.txt")
    assert File.exist?(expected_later_two_weeks_file), "The '2w' file in the _later directory was not renamed correctly."
    refute File.exist?(@later_two_weeks_file), "The original '2w' file in the _later directory still exists."

    # Verify irrelevant file remains unchanged in the _later directory
    assert File.exist?(@later_irrelevant_file), "The irrelevant file in the _later directory should remain unchanged."
  end

  def test_convert_current_day_to_next_week_date
    # Get the current day name (e.g., "Monday", "Tuesday")
    current_day_name = Date.today.strftime('%A')
  
    # Create a test file dynamically named with the current day of the week
    test_file = File.join(@test_root, "#{current_day_name}.dynamic task.txt")
    File.write(test_file, "Task content for dynamic current day")
  
    # Run the extension
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
  
    # Calculate the date for the next occurrence of the current day (7 days from now)
    next_week_same_day = Date.today + 7
  
    # Expected file path
    expected_file = File.join(@test_root, "#{next_week_same_day.strftime('%Y-%m-%d')}.dynamic task.txt")
    assert File.exist?(expected_file), "The '#{current_day_name}' file was not renamed to next week's date."
    refute File.exist?(test_file), "The original '#{current_day_name}' file still exists in the main directory."
  end

  def test_convert_tomorrows_day_to_date
    # Get tomorrow's day name (e.g., "Tuesday", if today is Monday)
    tomorrow_day_name = (Date.today + 1).strftime('%A')
  
    # Create a test file dynamically named with tomorrow's day of the week
    test_file = File.join(@test_root, "#{tomorrow_day_name}.dynamic task.txt")
    File.write(test_file, "Task content for tomorrow's day")
  
    # Run the extension
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
  
    # Calculate tomorrow's date
    tomorrows_date = Date.today + 1
  
    # Expected file path
    expected_file = File.join(@test_root, "#{tomorrows_date.strftime('%Y-%m-%d')}.dynamic task.txt")
    assert File.exist?(expected_file), "The '#{tomorrow_day_name}' file was not renamed to tomorrow's date."
    refute File.exist?(test_file), "The original '#{tomorrow_day_name}' file still exists in the main directory."
  end

  def test_nlp_on_multiple_directories
    system("ruby #{@nlp_extension_path} #{@test_root}")
  
    # Debug: List files in each directory before assertions
    @directories.each do |dir|
      puts "DEBUG: Files in #{dir}: #{Dir.glob(File.join(dir, '*'))}"
    end
  
    @directories.each do |dir|
      # Dynamically determine the prefix based on the directory
      prefix = dir == @test_root ? "today" : "tomorrow"
  
      filename = "#{prefix}.nlp-mytask.txt"
      file_path = File.join(dir, filename)
  
      # Expected filename after processing
      expected_date = prefix == "today" ? Date.today.strftime('%Y-%m-%d') : (Date.today + 1).strftime('%Y-%m-%d')
      expected_filename = "#{expected_date}.nlp-mytask.txt"
      expected_file_path = File.join(dir, expected_filename)

      refute File.exist?(file_path),
             "File in #{dir} was not renamed correctly to #{expected_filename}. Found #{file_path}."
     
      assert File.exist?(expected_file_path),
             "File in #{dir} was not renamed correctly to #{expected_filename}."
    end
  end

  def test_nlp_does_not_process_sys_directory
    sys_dir = File.join(@test_root, '_sys')
    FileUtils.mkdir_p(sys_dir)
  
    filename = "today.mytask.txt"
    file_path = File.join(sys_dir, filename)
    File.write(file_path, "Test content for #{filename}")
  
    system("ruby #{@nlp_extension_path} #{@test_root}")
  
    # File should remain unchanged in _sys
    assert File.exist?(file_path), "File in _sys directory was incorrectly processed."
  end
end