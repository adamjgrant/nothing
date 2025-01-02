require 'minitest/autorun'
require 'date'

class RepeatingTaskTest < Minitest::Test
  def run_extension
    # Run the extension once
    extension_path = File.expand_path('../../extensions/repeat.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
  end

  def setup
    # Existing test directories
    @test_root = File.expand_path('../../../../test', __dir__)
    @done_dir = File.join(@test_root, '_done')
    @later_dir = File.join(@test_root, '_later')
    @root_dir = @test_root

    # Test files for various formats with dynamic dates
    @today = Date.today
    @daily_repeating_file = File.join(@done_dir, "#{(@today - 3).strftime('%Y-%m-%d')}.mytask-three-days.3d.txt")
    @strict_daily_repeating_file = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.mytask-eight-days-strict.@8d.txt")

    @weekly_repeating_file = File.join(@done_dir, "#{(@today - 14).strftime('%Y-%m-%d')}.mytask-two-weeks.2w.txt")
    @strict_weekly_repeating_file = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.mytask-five-weeks-strict.@5w.txt")

    @monthly_repeating_file = File.join(@done_dir, "#{(@today << 3).strftime('%Y-%m-%d')}.mytask-three-months.3m.txt")
    @strict_monthly_repeating_file = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.mytask-six-months-strict.@6m.txt")

    # Dynamically calculate weekday names
    today_weekday_name = @today.strftime('%A').downcase # Current day of the week (e.g., "monday")
    next_weekday_name = (@today + 7).strftime('%A').downcase # Same weekday next week (e.g., "tuesday" next week)

    # Dynamic filenames
    @weekday_repeating_file = File.join(@done_dir, "#{@today.strftime('%Y-%m-%d')}.mytask-#{today_weekday_name}.#{today_weekday_name}.txt")
    @strict_weekday_repeating_file = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.mytask-#{next_weekday_name}-strict.@#{next_weekday_name}.txt")

    # Write test content dynamically
    [
      @daily_repeating_file, @strict_daily_repeating_file,
      @weekly_repeating_file, @strict_weekly_repeating_file,
      @monthly_repeating_file, @strict_monthly_repeating_file,
      @weekday_repeating_file, @strict_weekday_repeating_file
    ].each { |file| File.write(file, "Test content for #{File.basename(file)}") }

    @weekly_multi_day_file = File.join(@done_dir, "#{@today.strftime('%Y-%m-%d')}.task-multi-days.1w-tu-th-fr.txt")
    @strict_weekly_multi_day_file = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.task-strict-multi-days.@1w-tu-th-fr.txt")

    # Write test content dynamically
    [
      @weekly_multi_day_file, @strict_weekly_multi_day_file
    ].each { |file| File.write(file, "Test content for #{File.basename(file)}") }

    @monthly_specific_day_file = File.join(@done_dir, "#{@today.strftime('%Y-%m-%d')}.task-specific-day.1m-5.txt")
    @strict_monthly_specific_day_file = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.task-strict-specific-day.@1m-5.txt")

    @monthly_specific_weekday_file = File.join(@done_dir, "#{@today.strftime('%Y-%m-%d')}.task-specific-weekday.2m-2mo.txt")
    @strict_monthly_specific_weekday_file = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.task-strict-specific-weekday.@2m-2mo.txt")

    @monthly_default_first_weekday_file = File.join(@done_dir, "#{@today.strftime('%Y-%m-%d')}.task-default-first-weekday.1m-th.txt")
    @strict_monthly_default_first_weekday_file = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.task-strict-default-first-weekday.@1m-th.txt")

    # Write these files to simulate their presence in the appropriate directories
    [
    @monthly_specific_day_file, @strict_monthly_specific_day_file,
    @monthly_specific_weekday_file, @strict_monthly_specific_weekday_file,
    @monthly_default_first_weekday_file, @strict_monthly_default_first_weekday_file
    ].each { |file| File.write(file, "Test content for #{File.basename(file)}") }

    # User enters days out of order: "we-mo-su" (Wednesday, Monday, Sunday)
    unsorted_days_file = File.join(@done_dir, "#{@today.strftime('%Y-%m-%d')}.task-unsorted-days.1w-we-mo-su.txt")
    File.write(unsorted_days_file, "Test content for #{File.basename(unsorted_days_file)}")

    @daily_repeating_folder = File.join(@done_dir, "#{(@today - 3).strftime('%Y-%m-%d')}.folder-three-days.3d")
    @strict_daily_repeating_folder = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.folder-eight-days-strict.@8d")

    @weekly_repeating_folder = File.join(@done_dir, "#{(@today - 14).strftime('%Y-%m-%d')}.folder-two-weeks.2w")
    @strict_weekly_repeating_folder = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.folder-five-weeks-strict.@5w")

    # Create test folders
    [
      @daily_repeating_folder, @strict_daily_repeating_folder,
      @weekly_repeating_folder, @strict_weekly_repeating_folder
    ].each { |folder| FileUtils.mkdir_p(folder) }

    run_extension
  end

  # Helper to check file existence in multiple directories
  def file_exists?(filename)
    [@later_dir, @root_dir].any? { |dir| File.exist?(File.join(dir, filename)) }
  end

  def test_daily_repeating_task
    # Verify default daily repetition
    expected_daily_file = File.join(@later_dir, "#{(@today).strftime('%Y-%m-%d')}.mytask-three-days.3d.txt")
    assert File.exist?(expected_daily_file), "Daily repeating task was not created."

    # Verify strict daily repetition
    expected_strict_daily_file = File.join(@later_dir, "#{(@today + 8).strftime('%Y-%m-%d')}.mytask-eight-days-strict.@8d.txt")
    assert File.exist?(expected_strict_daily_file), "Strict daily repeating task was not created."
  end

  def test_weekly_repeating_task
    # Verify default weekly repetition
    expected_weekly_file = File.join(@later_dir, "#{(@today).strftime('%Y-%m-%d')}.mytask-two-weeks.2w.txt")
    assert File.exist?(expected_weekly_file), "Weekly repeating task was not created."

    # Verify strict weekly repetition
    expected_strict_weekly_file = File.join(@later_dir, "#{(@today + 35).strftime('%Y-%m-%d')}.mytask-five-weeks-strict.@5w.txt")
    assert File.exist?(expected_strict_weekly_file), "Strict weekly repeating task was not created."
  end

  def test_monthly_repeating_task
    # Extract the date from the original file for default monthly repetition
    base_date = Date.strptime(File.basename(@monthly_repeating_file).split('.').first, '%Y-%m-%d')
    expected_monthly_file = File.join(@later_dir, "#{(base_date >> 3).strftime('%Y-%m-%d')}.mytask-three-months.3m.txt")
    assert File.exist?(expected_monthly_file), "Monthly repeating task was not created."
  
    # Extract the date from the original file for strict monthly repetition
    strict_base_date = Date.strptime(File.basename(@strict_monthly_repeating_file).split('.').first, '%Y-%m-%d')
    expected_strict_monthly_file = File.join(@later_dir, "#{(strict_base_date >> 6).strftime('%Y-%m-%d')}.mytask-six-months-strict.@6m.txt")
    assert File.exist?(expected_strict_monthly_file), "Strict monthly repeating task was not created."
  end

  def test_weekday_repeating_task
    # Dynamically calculate today's and a future weekday name
    today_weekday_name = @today.strftime('%A').downcase # E.g., "saturday"
    next_weekday_name = (@today + 7).strftime('%A').downcase # Same weekday next week

    next_weekday = @today + 7
    expected_weekday_file = File.join(@later_dir, "#{next_weekday.strftime('%Y-%m-%d')}.mytask-#{today_weekday_name}.#{today_weekday_name}.txt")

    assert File.exist?(expected_weekday_file), "Weekday repeating task for #{today_weekday_name.capitalize} (#{expected_weekday_file}) was not created."
  
    # Verify strict weekday repetition
    strict_next_weekday = @today + 7 # Always one week later for strict repetition
    expected_strict_weekday_file = File.join(@later_dir, "#{strict_next_weekday.strftime('%Y-%m-%d')}.mytask-#{next_weekday_name}-strict.@#{next_weekday_name}.txt")
    assert File.exist?(expected_strict_weekday_file), "Strict weekday repeating task for #{next_weekday_name.capitalize} (#{expected_strict_weekday_file}) was not created."
  end

  def test_strict_repeating_task_with_future_base_date
    # Calculate [5d] dynamically
    future_date = @today + 5
    base_date_str = future_date.strftime('%Y-%m-%d')
    task_name = "James"
    repeat_rule = "@1w"
    extension = ".md"
  
    # Create the test file with [5d] as the base date
    future_file = File.join(@root_dir, "#{base_date_str}.#{task_name}.#{repeat_rule}#{extension}")
    File.write(future_file, "Test content for #{File.basename(future_file)}")
  
    # Run the extension
    extension_path = File.expand_path('../../extensions/repeat.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
  
    # Calculate the expected next file's date
    expected_next_date = future_date + 7
    expected_next_file = File.join(@later_dir, "#{expected_next_date.strftime('%Y-%m-%d')}.#{task_name}.#{repeat_rule}#{extension}")
  
    # Check if the next repeating file was created
    assert File.exist?(expected_next_file), "Strict repeating task with future base date was not created."
  end

  def test_weekly_single_day_repeating_task
    # Dynamically determine tomorrow's weekday name and shorthand
    tomorrow = @today + 1
    tomorrow_weekday_name = tomorrow.strftime('%A').downcase # E.g., "sunday"
    weekday_shorthand = case tomorrow_weekday_name
                        when "monday" then "mo"
                        when "tuesday" then "tu"
                        when "wednesday" then "we"
                        when "thursday" then "th"
                        when "friday" then "fr"
                        when "saturday" then "sa"
                        when "sunday" then "su"
                        end
  
    # Create test files dynamically based on tomorrow's weekday
    @weekly_single_day_file = File.join(@done_dir, "#{@today.strftime('%Y-%m-%d')}.task-#{tomorrow_weekday_name}.1w-#{weekday_shorthand}.txt")
    @strict_weekly_single_day_file = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.task-strict-#{tomorrow_weekday_name}.@1w-#{weekday_shorthand}.txt")
  
    # Write test content dynamically
    [
      @weekly_single_day_file, @strict_weekly_single_day_file
    ].each { |file| File.write(file, "Test content for #{File.basename(file)}") }

    run_extension
  
    # Calculate the next occurrence of tomorrow's weekday
    target_weekday = tomorrow.wday # Get tomorrow's weekday as an integer
    days_ahead = (target_weekday - @today.wday + 7) % 7
    days_ahead = 7 if days_ahead.zero? # Ensure it moves to next week if today is already the target weekday
    next_occurrence = @today + days_ahead
  
    # Expected file for default weekly repetition
    expected_weekly_file = File.join(@later_dir, "#{next_occurrence.strftime('%Y-%m-%d')}.task-#{tomorrow_weekday_name}.1w-#{weekday_shorthand}.txt")
    assert File.exist?(expected_weekly_file), "Weekly single-day repeating task for #{tomorrow_weekday_name.capitalize} was not created (#{expected_weekly_file})."
  
    # Expected file for strict weekly repetition
    strict_next_occurrence = @today + 1
    expected_file = "#{strict_next_occurrence.strftime('%Y-%m-%d')}.task-strict-#{tomorrow_weekday_name}.@1w-#{weekday_shorthand}.txt"
    expected_strict_weekly_file = File.join(@later_dir, expected_file)
    assert File.exist?(expected_strict_weekly_file), "Strict weekly single-day repeating task (#{expected_file}) for #{tomorrow_weekday_name.capitalize} was not created."
  end

  def test_weekly_multi_day_repeating_task
    # Calculate the next occurrences for Tuesday, Thursday, and Friday
    multi_days = { 
      "tu" => 2, # Tuesday
      "th" => 4, # Thursday
      "fr" => 5  # Friday
    }
  
    # Determine the first upcoming day
    next_days = multi_days.transform_values do |target_wday|
      days_ahead = (target_wday - @today.wday + 7) % 7
      days_ahead = 7 if days_ahead.zero? # Ensure it moves to next week if today is the target weekday
      @today + days_ahead
    end
  
    first_next_day = next_days.values.min
    first_next_day_name = next_days.key(first_next_day)
  
    # Verify that only the file for the first upcoming day is created
    expected_first_file = File.join(@later_dir, "#{first_next_day.strftime('%Y-%m-%d')}.task-multi-days.1w-tu-th-fr.txt")
    assert File.exist?(expected_first_file), "Weekly multi-day repeating task for #{first_next_day_name.upcase} was not created (#{expected_first_file})."
  
    # Ensure files for other days are not created yet
    next_days.each do |day_name, date|
      next if date == first_next_day # Skip the first day
      unexpected_file = File.join(@later_dir, "#{date.strftime('%Y-%m-%d')}.task-multi-days.1w-tu-th-fr.txt")
      refute File.exist?(unexpected_file), "Unexpected file created for #{day_name.upcase}: #{unexpected_file}"
    end
  
    # Verify strict format creates files for the correct strict cadence
    multi_days = { 
      "tu" => 2, # Tuesday
      "th" => 4, # Thursday
      "fr" => 5  # Friday
    }

    # Determine the next occurrence of each specified day
    strict_next_days = multi_days.transform_values do |target_wday|
      days_ahead = (target_wday - @today.wday + 7) % 7
      days_ahead = 7 if days_ahead.zero? # Move to the next week if today matches the target weekday
      @today + days_ahead
    end

    # Select the earliest next day
    strict_next_day = strict_next_days.values.min

    # Expected file for strict weekly repetition
    expected_strict_file = File.join(@later_dir, "#{strict_next_day.strftime('%Y-%m-%d')}.task-strict-multi-days.@1w-tu-th-fr.txt")
    assert File.exist?(expected_strict_file), "Strict weekly multi-day repeating task for next week was not created (#{expected_strict_file})."
  end

  def test_monthly_specific_day_repeating_task
    # Calculate the next occurrence of the 5th day one month from now
    base_date = Date.strptime(File.basename(@monthly_specific_day_file).split('.').first, '%Y-%m-%d')
    specific_day = 5
  
    # Increment the month by 1
    next_month = base_date >> 1
    next_specific_day = Date.new(next_month.year, next_month.month, specific_day)
  
    # Ensure the next specific day is valid (e.g., not beyond the end of the month)
    if next_specific_day.day != specific_day
      next_specific_day = Date.new(next_month.year, next_month.month + 1, specific_day)
    end
  
    # Expected file for default repetition
    expected_file = File.join(@later_dir, "#{next_specific_day.strftime('%Y-%m-%d')}.task-specific-day.1m-5.txt")
    assert File.exist?(expected_file), "Monthly specific day repeating task for 5th day was not created (#{expected_file})."
  
    # Expected file for strict repetition
    expected_strict_file = File.join(@later_dir, "#{next_specific_day.strftime('%Y-%m-%d')}.task-strict-specific-day.@1m-5.txt")
    assert File.exist?(expected_strict_file), "Strict monthly specific day repeating task for 5th day was not created."
  end

  def test_monthly_specific_weekday_repeating_task
    # Calculate the next occurrence of the 2nd Monday two months from now
    base_date = Date.strptime(File.basename(@monthly_specific_weekday_file).split('.').first, '%Y-%m-%d')
    next_month = base_date >> 2
    nth = 2
    weekday = 1 # Monday is 1
    next_specific_weekday = nth_weekday_of_month(next_month.year, next_month.month, nth, weekday)
    
    # Expected file for default repetition
    expected_file = File.join(@later_dir, "#{next_specific_weekday.strftime('%Y-%m-%d')}.task-specific-weekday.2m-2mo.txt")
    assert File.exist?(expected_file), "Monthly specific weekday repeating task for 2nd Monday was not created (#{expected_file})."
  
    # Expected file for strict repetition
    expected_strict_file = File.join(@later_dir, "#{next_specific_weekday.strftime('%Y-%m-%d')}.task-strict-specific-weekday.@2m-2mo.txt")
    assert File.exist?(expected_strict_file), "Strict monthly specific weekday repeating task for 2nd Monday was not created (#{expected_strict_file})."
  end
  
  # Helper Method for nth Weekday Calculation
  def nth_weekday_of_month(year, month, nth, weekday)
    first_day = Date.new(year, month, 1)
    first_weekday = first_day + ((weekday - first_day.wday + 7) % 7)
    first_weekday + ((nth - 1) * 7)
  end

  def test_monthly_default_first_weekday_repeating_task
    # Calculate the next occurrence of the 1st Thursday one month from now
    base_date = Date.strptime(File.basename(@monthly_default_first_weekday_file).split('.').first, '%Y-%m-%d')
    next_month = base_date >> 1
    nth = 1
    weekday = 4 # Thursday is 4
    next_first_weekday = nth_weekday_of_month(next_month.year, next_month.month, nth, weekday)
    
    # Expected file for default repetition
    expected_file = File.join(@later_dir, "#{next_first_weekday.strftime('%Y-%m-%d')}.task-default-first-weekday.1m-th.txt")
    assert File.exist?(expected_file), "Default monthly first weekday repeating task was not created (#{expected_file})."
  
    # Expected file for strict repetition
    expected_strict_file = File.join(@later_dir, "#{next_first_weekday.strftime('%Y-%m-%d')}.task-strict-default-first-weekday.@1m-th.txt")
    assert File.exist?(expected_strict_file), "Strict monthly first weekday repeating task was not created (#{expected_strict_file})."
  end

  def test_weekly_multi_day_repeating_task_with_unsorted_days
    # Expected sorted days: "mo-we-su" (Monday, Wednesday, Sunday)
    sorted_days = %w[mo we su]
    next_days = sorted_days.map do |day|
      target_wday = %w[su mo tu we th fr sa].index(day)
      days_ahead = (target_wday - @today.wday + 7) % 7
      days_ahead = 7 if days_ahead.zero? # Move to next week if today matches the target weekday
      @today + days_ahead
    end
  
    # Verify that only the file for the first upcoming day is created
    first_next_day = next_days.min
    first_next_day_name = sorted_days[next_days.index(first_next_day)]
    expected_first_file = File.join(@later_dir, "#{first_next_day.strftime('%Y-%m-%d')}.task-unsorted-days.1w-we-mo-su.txt")
    assert File.exist?(expected_first_file), "Weekly multi-day repeating task for #{first_next_day_name.upcase} was not created (#{expected_first_file})."
  
    # Ensure files for other days are not created yet
    next_days.each do |date|
      next if date == first_next_day # Skip the first day
      unexpected_file = File.join(@later_dir, "#{date.strftime('%Y-%m-%d')}.task-unsorted-days.1w-we-mo-su.txt")
      refute File.exist?(unexpected_file), "Unexpected file created for #{sorted_days[next_days.index(date)].upcase}: #{unexpected_file}"
    end
  end

  def test_repeating_task_with_time_created_yesterday
    # Create a task file with a time value created yesterday
    yesterday = @today - 1
    time_task_file = File.join(@done_dir, "#{yesterday.strftime('%Y-%m-%d')}+1300.task-with-time.1d.txt")
    File.write(time_task_file, "Test content for #{File.basename(time_task_file)}")
    
    # Run the extension
    run_extension
    
    # Expected file for the repeated task
    expected_file = File.join(@later_dir, "#{@today.strftime('%Y-%m-%d')}+1300.task-with-time.1d.txt")
    assert File.exist?(expected_file), "Repeated task for file created yesterday was not created correctly (#{expected_file})."
  end
  
  def test_strict_repeating_task_with_time_created_yesterday
    # Create a strict task file with a time value created yesterday
    yesterday = @today - 1
    strict_time_task_file = File.join(@root_dir, "#{yesterday.strftime('%Y-%m-%d')}+1300.task-strict-with-time.@1d.txt")
    File.write(strict_time_task_file, "Test content for #{File.basename(strict_time_task_file)}")
    
    # Run the extension
    run_extension
    
    # Expected file for the repeated task
    expected_strict_file = File.join(@later_dir, "#{@today.strftime('%Y-%m-%d')}+1300.task-strict-with-time.@1d.txt")
    assert File.exist?(expected_strict_file), "Strict repeated task for file created yesterday was not created correctly (#{expected_strict_file})."
  end

  def test_daily_repeating_folder
    # Verify default daily repetition
    expected_daily_folder = File.join(@later_dir, "#{(@today).strftime('%Y-%m-%d')}.folder-three-days.3d")
    assert Dir.exist?(expected_daily_folder), "Daily repeating folder was not created."
  
    # Verify strict daily repetition
    expected_strict_daily_folder = File.join(@later_dir, "#{(@today + 8).strftime('%Y-%m-%d')}.folder-eight-days-strict.@8d")
    assert Dir.exist?(expected_strict_daily_folder), "Strict daily repeating folder was not created."
  end

  def test_weekly_repeating_folder
    # Verify default weekly repetition
    expected_weekly_folder = File.join(@later_dir, "#{(@today).strftime('%Y-%m-%d')}.folder-two-weeks.2w")
    assert Dir.exist?(expected_weekly_folder), "Weekly repeating folder was not created."
  
    # Verify strict weekly repetition
    expected_strict_weekly_folder = File.join(@later_dir, "#{(@today + 35).strftime('%Y-%m-%d')}.folder-five-weeks-strict.@5w")
    assert Dir.exist?(expected_strict_weekly_folder), "Strict weekly repeating folder was not created."
  end

  def test_weekly_multi_day_repeating_folder
    # Add a multi-day weekly repeating folder
    multi_day_folder = File.join(@done_dir, "#{@today.strftime('%Y-%m-%d')}.multi-days-folder.1w-mo-we-fr")
    FileUtils.mkdir_p(multi_day_folder)

    run_extension
  
    # Calculate next occurrences for Monday, Wednesday, Friday
    multi_days = { 
      "mo" => 1, # Monday
      "we" => 3, # Wednesday
      "fr" => 5  # Friday
    }
  
    next_days = multi_days.transform_values do |target_wday|
      days_ahead = (target_wday - @today.wday + 7) % 7
      days_ahead = 7 if days_ahead.zero? # Skip today by advancing to the next week
      @today + days_ahead
    end
  
    first_next_day = next_days.values.min
  
    # Verify that only the first upcoming day is created
    expected_first_folder = File.join(@later_dir, "#{first_next_day.strftime('%Y-%m-%d')}.multi-days-folder.1w-mo-we-fr")
    assert Dir.exist?(expected_first_folder), "Multi-day weekly repeating folder was not created for the first upcoming day."
  end

  def test_monthly_specific_day_repeating_folder
    # Add a specific day monthly repeating folder
    specific_day_folder = File.join(@done_dir, "#{@today.strftime('%Y-%m-%d')}.specific-day-folder.1m-15")
    FileUtils.mkdir_p(specific_day_folder)

    run_extension
  
    # Calculate the next occurrence of the 15th day next month
    specific_day = 15
    # The numerical month plus one

    next_month = @today >> 1
    next_specific_day = Date.new(next_month.year, next_month.month, specific_day)

    # Verify that the next specific day folder is created
    expected_folder = File.join(@later_dir, "#{next_specific_day.strftime('%Y-%m-%d')}.specific-day-folder.1m-15")
    assert Dir.exist?(expected_folder), "Specific day monthly repeating folder was not created."
  end

  def test_strict_monthly_specific_day_repeating_folder
    # Add a strict specific day monthly repeating folder
    strict_specific_day_folder = File.join(@root_dir, "#{@today.strftime('%Y-%m-%d')}.strict-specific-day-folder.@1m-20")
    FileUtils.mkdir_p(strict_specific_day_folder)

    run_extension
  
    # Calculate the next occurrence of the 20th day next month
    specific_day = 20
    next_month = @today >> 1
    next_specific_day = Date.new(next_month.year, next_month.month, specific_day)
  
    # Verify that the next specific day folder is created
    expected_strict_folder = File.join(@later_dir, "#{next_specific_day.strftime('%Y-%m-%d')}.strict-specific-day-folder.@1m-20")
    assert Dir.exist?(expected_strict_folder), "Strict specific day monthly repeating folder was not created."
  end

  def test_six_hour_repeat_file
    # Create a file with a 6-hour repeat rule
    file_name = "#{@today.strftime('%Y-%m-%d')}+0600.task-six-hours.6h.txt"
    file_path = File.join(@done_dir, file_name)
    File.write(file_path, "Test content for #{file_name}")
  
    # Run the extension
    run_extension
  
    # Calculate the next occurrence 6 hours from now
    next_occurrence = Time.strptime("06:00", "%H:%M") + (6 * 3600)
    expected_file = File.join(@later_dir, "#{@today.strftime('%Y-%m-%d')}+#{next_occurrence.strftime('%H%M')}.task-six-hours.6h.txt")
  
    # Assert that the next occurrence file exists
    assert File.exist?(expected_file), "6-hour repeating file was not created (#{expected_file})."
  end

  def test_six_hour_repeat_folder
    # Create a folder with a 6-hour repeat rule
    folder_name = "#{@today.strftime('%Y-%m-%d')}+0600.folder-six-hours.6h"
    folder_path = File.join(@done_dir, folder_name)
    FileUtils.mkdir_p(folder_path)
  
    # Run the extension
    run_extension
  
    # Calculate the next occurrence 6 hours from now
    next_occurrence = Time.strptime("06:00", "%H:%M") + (6 * 3600)
    expected_folder = File.join(@later_dir, "#{@today.strftime('%Y-%m-%d')}+#{next_occurrence.strftime('%H%M')}.folder-six-hours.6h")
  
    # Assert that the next occurrence folder exists
    assert Dir.exist?(expected_folder), "6-hour repeating folder was not created (#{expected_folder})."
  end

  def test_six_hour_strict_repeat_file
    # Create a file with a strict 6-hour repeat rule
    file_name = "#{@today.strftime('%Y-%m-%d')}+0600.task-six-hours-strict.@6h.txt"
    file_path = File.join(@root_dir, file_name)
    File.write(file_path, "Test content for #{file_name}")
  
    # Run the extension
    run_extension
  
    # Calculate the next strict occurrence 6 hours from now
    next_occurrence = Time.strptime("06:00", "%H:%M") + (6 * 3600)
    expected_file = File.join(@later_dir, "#{@today.strftime('%Y-%m-%d')}+#{next_occurrence.strftime('%H%M')}.task-six-hours-strict.@6h.txt")
  
    # Assert that the next strict occurrence file exists
    assert File.exist?(expected_file), "Strict 6-hour repeating file was not created (#{expected_file})."
  end

  def test_six_hour_strict_repeat_folder
    # Create a folder with a strict 6-hour repeat rule
    folder_name = "#{@today.strftime('%Y-%m-%d')}+0600.folder-six-hours-strict.@6h"
    folder_path = File.join(@root_dir, folder_name)
    FileUtils.mkdir_p(folder_path)
  
    # Run the extension
    run_extension
  
    # Calculate the next strict occurrence 6 hours from now
    next_occurrence = Time.strptime("06:00", "%H:%M") + (6 * 3600)
    expected_folder = File.join(@later_dir, "#{@today.strftime('%Y-%m-%d')}+#{next_occurrence.strftime('%H%M')}.folder-six-hours-strict.@6h")
  
    # Assert that the next strict occurrence folder exists
    assert Dir.exist?(expected_folder), "Strict 6-hour repeating folder was not created (#{expected_folder})."
  end

  def test_six_hour_strict_repeat_folder_in_done
    # Create a folder with a strict 6-hour repeat rule
    folder_name = "#{@today.strftime('%Y-%m-%d')}+0600.folder-six-hours-strict-in-done.@6h"
    folder_path = File.join(@done_dir, folder_name)
    FileUtils.mkdir_p(folder_path)
  
    # Run the extension
    run_extension
  
    # Calculate the next strict occurrence 6 hours from now
    next_occurrence = Time.strptime("06:00", "%H:%M") + (6 * 3600)
    expected_folder = File.join(@later_dir, "#{@today.strftime('%Y-%m-%d')}+#{next_occurrence.strftime('%H%M')}.folder-six-hours-strict-in-done.@6h")
  
    # Assert that the next strict occurrence folder exists
    assert Dir.exist?(expected_folder), "Strict 6-hour repeating folder was not created (#{expected_folder})."
  end
end