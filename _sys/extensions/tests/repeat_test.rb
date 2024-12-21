require 'minitest/autorun'
require 'date'

class RepeatingTaskTest < Minitest::Test
  def setup
    # Existing test directories
    @test_root = File.expand_path('../../../../test', __dir__)
    @archived_dir = File.join(@test_root, '_archived')
    @later_dir = File.join(@test_root, '_later')
    @root_dir = @test_root

    # Test files for various formats with dynamic dates
    @today = Date.today
    @daily_repeating_file = File.join(@archived_dir, "#{(@today - 3).strftime('%Y%m%d')}.mytask-three-days.3d.txt")
    @strict_daily_repeating_file = File.join(@root_dir, "#{@today.strftime('%Y%m%d')}.mytask-eight-days-strict.@8d.txt")

    @weekly_repeating_file = File.join(@archived_dir, "#{(@today - 14).strftime('%Y%m%d')}.mytask-two-weeks.2w.txt")
    @strict_weekly_repeating_file = File.join(@root_dir, "#{@today.strftime('%Y%m%d')}.mytask-five-weeks-strict.@5w.txt")

    @monthly_repeating_file = File.join(@archived_dir, "#{(@today << 3).strftime('%Y%m%d')}.mytask-three-months.3m.txt")
    @strict_monthly_repeating_file = File.join(@root_dir, "#{@today.strftime('%Y%m%d')}.mytask-six-months-strict.@6m.txt")

    @weekday_repeating_file = File.join(@archived_dir, "#{(@today - (@today.wday - 1)).strftime('%Y%m%d')}.mytask-monday.monday.txt")
    @strict_weekday_repeating_file = File.join(@root_dir, "#{@today.strftime('%Y%m%d')}.mytask-friday-strict.@friday.txt")

    # Write test content dynamically
    [
      @daily_repeating_file, @strict_daily_repeating_file,
      @weekly_repeating_file, @strict_weekly_repeating_file,
      @monthly_repeating_file, @strict_monthly_repeating_file,
      @weekday_repeating_file, @strict_weekday_repeating_file
    ].each { |file| File.write(file, "Test content for #{File.basename(file)}") }

    # Run the extension once
    extension_path = File.expand_path('../../extensions/repeat.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")
  end

  # Helper to check file existence in multiple directories
  def file_exists?(filename)
    [@later_dir, @root_dir].any? { |dir| File.exist?(File.join(dir, filename)) }
  end

  def test_daily_repeating_task
    # Verify default daily repetition
    expected_daily_file = File.join(@later_dir, "#{(@today).strftime('%Y%m%d')}.mytask-three-days.3d.txt")
    assert File.exist?(expected_daily_file), "Daily repeating task was not created."

    # Verify strict daily repetition
    expected_strict_daily_file = File.join(@later_dir, "#{(@today + 8).strftime('%Y%m%d')}.mytask-eight-days-strict.@8d.txt")
    assert File.exist?(expected_strict_daily_file), "Strict daily repeating task was not created."
  end

  def test_weekly_repeating_task
    # Verify default weekly repetition
    expected_weekly_file = File.join(@later_dir, "#{(@today).strftime('%Y%m%d')}.mytask-two-weeks.2w.txt")
    assert File.exist?(expected_weekly_file), "Weekly repeating task was not created."

    # Verify strict weekly repetition
    expected_strict_weekly_file = File.join(@later_dir, "#{(@today + 35).strftime('%Y%m%d')}.mytask-five-weeks-strict.@5w.txt")
    assert File.exist?(expected_strict_weekly_file), "Strict weekly repeating task was not created."
  end

  def test_monthly_repeating_task
    # Extract the date from the original file for default monthly repetition
    base_date = Date.strptime(File.basename(@monthly_repeating_file).split('.').first, '%Y%m%d')
    expected_monthly_file = File.join(@later_dir, "#{(base_date >> 3).strftime('%Y%m%d')}.mytask-three-months.3m.txt")
    assert File.exist?(expected_monthly_file), "Monthly repeating task was not created."
  
    # Extract the date from the original file for strict monthly repetition
    strict_base_date = Date.strptime(File.basename(@strict_monthly_repeating_file).split('.').first, '%Y%m%d')
    expected_strict_monthly_file = File.join(@later_dir, "#{(strict_base_date >> 6).strftime('%Y%m%d')}.mytask-six-months-strict.@6m.txt")
    assert File.exist?(expected_strict_monthly_file), "Strict monthly repeating task was not created."
  end

  def test_weekday_repeating_task
    # Verify default weekday repetition
    next_monday = @today + (1 - @today.wday + 7) # Calculate next Monday
    expected_weekday_file = File.join(@later_dir, "#{next_monday.strftime('%Y%m%d')}.mytask-monday.monday.txt")
    assert File.exist?(expected_weekday_file), "Weekday repeating task for Monday was not created."

    # Verify strict weekday repetition
    next_friday = @today + (5 - @today.wday + 7) # Calculate next Friday
    expected_strict_weekday_file = File.join(@later_dir, "#{next_friday.strftime('%Y%m%d')}.mytask-friday-strict.@friday.txt")
    assert File.exist?(expected_strict_weekday_file), "Strict weekday repeating task for Friday was not created."
  end
end