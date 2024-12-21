require 'minitest/autorun'
require 'fileutils'
require 'date'

class RepeatingTaskTest < Minitest::Test
  def setup
    # Create test directories
    @test_root = File.expand_path('../../../../test', __dir__)
    @archived_dir = File.join(@test_root, '_archived')
    @later_dir = File.join(@test_root, '_later')

    FileUtils.rm_rf(@test_root)
    FileUtils.mkdir_p(@archived_dir)
    FileUtils.mkdir_p(@later_dir)

    # Test files for various formats
    @daily_repeating_file = File.join(@archived_dir, "20241220.mytask.3d.txt")
    @strict_daily_repeating_file = File.join(@archived_dir, "mytask.@8d.txt")

    @weekly_repeating_file = File.join(@archived_dir, "20241220.mytask.2w.txt")
    @strict_weekly_repeating_file = File.join(@archived_dir, "mytask.@5w.txt")

    @monthly_repeating_file = File.join(@archived_dir, "20241220.mytask.3m.txt")
    @strict_monthly_repeating_file = File.join(@archived_dir, "mytask.@6m.txt")

    @weekday_repeating_file = File.join(@archived_dir, "20241220.mytask.monday.txt")
    @strict_weekday_repeating_file = File.join(@archived_dir, "mytask.@friday.txt")

    # Ambiguous filenames
    @non_repeating_task_file = File.join(@archived_dir, "monday.txt")
    @non_repeating_with_date_file = File.join(@archived_dir, "20241201.3d.txt")
    @strict_repeating_task_file = File.join(@archived_dir, "20241201.mytask.@4w.txt")

    # Write test content
    [
      @daily_repeating_file, @strict_daily_repeating_file,
      @weekly_repeating_file, @strict_weekly_repeating_file,
      @monthly_repeating_file, @strict_monthly_repeating_file,
      @weekday_repeating_file, @strict_weekday_repeating_file,
      @non_repeating_task_file, @non_repeating_with_date_file,
      @strict_repeating_task_file
    ].each { |file| File.write(file, "Test content for #{File.basename(file)}") }
  end

  def test_daily_repeating_task
    extension_path = File.expand_path('../../extensions/repeating.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify default daily repetition
    expected_daily_file = File.join(@later_dir, "20241223.mytask.3d.txt")
    assert File.exist?(expected_daily_file), "Daily repeating task was not created."

    # Verify strict daily repetition
    expected_strict_daily_file = File.join(@later_dir, "20241228.mytask.@8d.txt")
    assert File.exist?(expected_strict_daily_file), "Strict daily repeating task was not created."
  end

  def test_weekly_repeating_task
    extension_path = File.expand_path('../../extensions/repeating.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify default weekly repetition
    expected_weekly_file = File.join(@later_dir, "20250103.mytask.2w.txt")
    assert File.exist?(expected_weekly_file), "Weekly repeating task was not created."

    # Verify strict weekly repetition
    expected_strict_weekly_file = File.join(@later_dir, "20250124.mytask.@5w.txt")
    assert File.exist?(expected_strict_weekly_file), "Strict weekly repeating task was not created."
  end

  def test_monthly_repeating_task
    extension_path = File.expand_path('../../extensions/repeating.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify default monthly repetition
    expected_monthly_file = File.join(@later_dir, "20250320.mytask.3m.txt")
    assert File.exist?(expected_monthly_file), "Monthly repeating task was not created."

    # Verify strict monthly repetition
    expected_strict_monthly_file = File.join(@later_dir, "20240620.mytask.@6m.txt")
    assert File.exist?(expected_strict_monthly_file), "Strict monthly repeating task was not created."
  end

  def test_weekday_repeating_task
    extension_path = File.expand_path('../../extensions/repeating.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify default weekday repetition
    next_monday = Date.parse("20241223")
    expected_weekday_file = File.join(@later_dir, "#{next_monday.strftime('%Y%m%d')}.mytask.monday.txt")
    assert File.exist?(expected_weekday_file), "Weekday repeating task for Monday was not created."

    # Verify strict weekday repetition
    next_friday = Date.parse("20241227")
    expected_strict_weekday_file = File.join(@later_dir, "#{next_friday.strftime('%Y%m%d')}.mytask.@friday.txt")
    assert File.exist?(expected_strict_weekday_file), "Strict weekday repeating task for Friday was not created."
  end

  def test_non_repeating_files
    extension_path = File.expand_path('../../extensions/repeating.rb', __dir__)
    system("ruby #{extension_path} #{@test_root}")

    # Verify non-repeating task "monday.txt" remains unchanged
    assert File.exist?(@non_repeating_task_file), "'monday.txt' should not be modified."

    # Verify non-repeating task "20241201.3d.txt" remains unchanged
    assert File.exist?(@non_repeating_with_date_file), "'20241201.3d.txt' should not be modified."

    # Verify strict repeating task "20241201.mytask.@4w.txt" is processed
    next_date = (Date.parse("20241201") + 28).strftime('%Y%m%d')
    expected_strict_repeating_file = File.join(@later_dir, "#{next_date}.mytask.@4w.txt")
    assert File.exist?(expected_strict_repeating_file), "'20241201.mytask.@4w.txt' should have a repeating instance created."
  end
end