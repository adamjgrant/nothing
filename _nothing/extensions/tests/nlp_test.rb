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
    @directories = %w[_later _done _push-1d _push-1w _push-rand].map do |dir|
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
    # Run the extension
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
  
    # Debug: List files in each directory before assertions
    @directories.each do |dir|
      # puts "DEBUG: Files in #{dir}: #{Dir.glob(File.join(dir, '*'))}"
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

  def test_nlp_does_not_process_nothing_directory
    nothing_dir = File.join(@test_root, '_nothing')
    FileUtils.mkdir_p(nothing_dir)
  
    filename = "today.mytask.txt"
    file_path = File.join(nothing_dir, filename)
    File.write(file_path, "Test content for #{filename}")
  
    # Run the extension
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
  
    # File should remain unchanged in _nothing
    assert File.exist?(file_path), "File in _nothing directory was incorrectly processed."
  end

  def test_convert_day_to_date_with_time
    # Create test files with time values
    @today_with_time_file = File.join(@test_root, "today+0300.mytask.txt")
    @tomorrow_with_time_file = File.join(@test_root, "tomorrow+1430.mytask.txt")
    @three_days_with_time_file = File.join(@test_root, "3d+1500.mytask.txt")
  
    File.write(@today_with_time_file, "Task content for today with time")
    File.write(@tomorrow_with_time_file, "Task content for tomorrow with time")
    File.write(@three_days_with_time_file, "Task content for 3 days from now with time")
  
    # Run the extension
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
  
    # Verify "today+HHMM" file
    expected_today_file = File.join(@test_root, "#{Date.today.strftime('%Y-%m-%d')}+0300.mytask.txt")
    assert File.exist?(expected_today_file), "The 'today+HHMM' file in the main directory was not renamed correctly."
    refute File.exist?(@today_with_time_file), "The original 'today+HHMM' file in the main directory still exists."
  
    # Verify "tomorrow+HHMM" file
    expected_tomorrow_file = File.join(@test_root, "#{(Date.today + 1).strftime('%Y-%m-%d')}+1430.mytask.txt")
    assert File.exist?(expected_tomorrow_file), "The 'tomorrow+HHMM' file in the main directory was not renamed correctly."
    refute File.exist?(@tomorrow_with_time_file), "The original 'tomorrow+HHMM' file in the main directory still exists."
  
    # Verify "3d+HHMM" file
    expected_three_days_file = File.join(@test_root, "#{(Date.today + 3).strftime('%Y-%m-%d')}+1500.mytask.txt")
    assert File.exist?(expected_three_days_file), "The '3d+HHMM' file in the main directory was not renamed correctly."
    refute File.exist?(@three_days_with_time_file), "The original '3d+HHMM' file in the main directory still exists."
  end
  
  def test_directory_with_shortcut_prefix
    dir_name_today = "today.project-folder-nlp"
    dir_name_tomorrow = "tomorrow.project-folder-nlp"
    dir_path_today = File.join(@test_root, dir_name_today)
    dir_path_tomorrow = File.join(@test_root, dir_name_tomorrow)
    
    FileUtils.mkdir_p(dir_path_today)
    FileUtils.mkdir_p(dir_path_tomorrow)
    
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify the directories are renamed correctly
    expected_today_dir = "#{Date.today.strftime('%Y-%m-%d')}.project-folder-nlp"
    expected_tomorrow_dir = "#{(Date.today + 1).strftime('%Y-%m-%d')}.project-folder-nlp"
    
    assert Dir.exist?(File.join(@test_root, expected_today_dir)), "Directory with 'today' prefix should be renamed correctly."
    assert Dir.exist?(File.join(@test_root, expected_tomorrow_dir)), "Directory with 'tomorrow' prefix should be renamed correctly."
  end

  def test_directory_with_relative_date
    dir_name = "3d.project-folder"
    dir_path = File.join(@test_root, dir_name)
    FileUtils.mkdir_p(dir_path)
    
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
    
    # Verify the directory is renamed correctly
    expected_dir_name = "#{(Date.today + 3).strftime('%Y-%m-%d')}.project-folder"
    expected_dir_path = File.join(@test_root, expected_dir_name)
    assert Dir.exist?(expected_dir_path), "Directory with relative date should be renamed correctly."
  end

  def test_later_directory
    # Test that a file called "today.mytask.txt" in the _later directory is processed
    later_today_file = File.join(@later_dir, "today.mytask.txt")
    File.write(later_today_file, "Test content for today.mytask.txt")
    
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
    
    # Verify the file is renamed correctly
    expected_today_file = File.join(@test_root, "#{Date.today.strftime('%Y-%m-%d')}.mytask.txt")
    assert File.exist?(expected_today_file), "File in _later directory should be renamed correctly."
  end

  def test_later_directory_with_directory
    # Do the same test as above, but with a directory in the _later directory
    later_today_dir = File.join(@later_dir, "today.project-folder")
    FileUtils.mkdir_p(later_today_dir)

    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify the directory is renamed correctly
    expected_today_dir = File.join(@test_root, "#{Date.today.strftime('%Y-%m-%d')}.project-folder")
    assert Dir.exist?(expected_today_dir), "Directory in _later directory should be renamed correctly."
  end

  def test_any_push_directory
    # Test that in a folder called _push-5d, a file called "today.mytask.txt" is processed and scheduled for today + 5 days.
    push_5d_dir = File.join(@test_root, "_push-5d")
    FileUtils.mkdir_p(push_5d_dir)
    
    today_file = File.join(push_5d_dir, "today.mytask.txt")
    File.write(today_file, "Test content for today.mytask.txt")
    
    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
    
    # Verify the file is renamed correctly
    expected_today_file = File.join(@test_root, "#{(Date.today + 5).strftime('%Y-%m-%d')}.mytask.txt")
    assert File.exist?(expected_today_file), "File in _push-5d directory should be renamed correctly."
  end

  def test_any_push_directory_with_directory
    # Do the same test as above, but with a directory in the _push-5d directory
    push_5d_dir = File.join(@test_root, "_push-5d")
    FileUtils.mkdir_p(push_5d_dir)

    today_dir = File.join(push_5d_dir, "today.project-folder")
    FileUtils.mkdir_p(today_dir)

    extension_path = File.expand_path('../../extensions/nlp.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify the directory is renamed correctly
    expected_today_dir = File.join(@test_root, "#{(Date.today + 5).strftime('%Y-%m-%d')}.project-folder")
    assert Dir.exist?(expected_today_dir), "Directory in _push-5d directory should be renamed correctly."
  end
end
