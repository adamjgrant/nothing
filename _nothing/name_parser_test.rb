require 'minitest/autorun'
require_relative 'name_parser'
require "date"

class NameParserTest < Minitest::Test
  def setup
    today = Date.today

    # Calculate the next Monday (future Monday)
    next_monday = today + (1 - today.wday + 7) % 7
    
    # Example dynamic date calculations
    @computed_dates = {
      "monday" => next_monday.strftime('%Y-%m-%d'),
      "today" => today.strftime('%Y-%m-%d'),
      "tomorrow" => (today + 1).strftime('%Y-%m-%d'),
      "3d" => (today + 3).strftime('%Y-%m-%d')
    }
    
    # Test cases for filenames with all permutations
    @test_cases = {
      '■2024-01-01+1800+.■my task.1w-mo-we.txt' => {
        "date-decorators" => ["■"],
        "date" => "2024-01-01",
        "time" => "1800",
        "notify" => true,
        "name-decorators" => ["■"],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      '■2024-01-01+.my task.txt' => {
        "date-decorators" => ["■"],
        "date" => "2024-01-01",
        "time" => nil,
        "notify" => true,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      '■2024-01-01.my task.1w-mo-we.txt' => {
        "date-decorators" => ["■"],
        "date" => "2024-01-01",
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      '■2024-01-01.my task.txt' => {
        "date-decorators" => ["■"],
        "date" => "2024-01-01",
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      '■monday+.my task.1w-mo-we.txt' => {
        "date-decorators" => ["■"],
        "date" => @computed_dates["monday"],
        "time" => nil,
        "notify" => true,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      '■monday+.my task.txt' => {
        "date-decorators" => ["■"],
        "date" => @computed_dates["monday"],
        "time" => nil,
        "notify" => true,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      '■monday+.■my task.txt' => {
        "date-decorators" => ["■"],
        "date" => @computed_dates["monday"],
        "time" => nil,
        "notify" => true,
        "name-decorators" => ["■"],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      '■monday.my task.1w-mo-we.txt' => {
        "date-decorators" => ["■"],
        "date" => @computed_dates["monday"],
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      '■monday.my task.txt' => {
        "date-decorators" => ["■"],
        "date" => @computed_dates["monday"],
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      '■3d+.my task.1w-mo-we.txt' => {
        "date-decorators" => ["■"],
        "date" => @computed_dates["3d"],
        "time" => nil,
        "notify" => true,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      '■3d+.my task.txt' => {
        "date-decorators" => ["■"],
        "date" => @computed_dates["3d"],
        "time" => nil,
        "notify" => true,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      '■3d.my task.1w-mo-we.txt' => {
        "date-decorators" => ["■"],
        "date" => @computed_dates["3d"],
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      '■3d.my task.txt' => {
        "date-decorators" => ["■"],
        "date" => @computed_dates["3d"],
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      '2024-01-01+.my task.1w-mo-we.txt' => {
        "date-decorators" => [],
        "date" => "2024-01-01",
        "time" => nil,
        "notify" => true,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      '2024-01-01+.my task.txt' => {
        "date-decorators" => [],
        "date" => "2024-01-01",
        "time" => nil,
        "notify" => true,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      '2024-01-01.my task.1w-mo-we.txt' => {
        "date-decorators" => [],
        "date" => "2024-01-01",
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      'monday.my task.txt' => {
        "date-decorators" => [],
        "date" => @computed_dates["monday"],
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      '3d+.my task.1w-mo-we.txt' => {
        "date-decorators" => [],
        "date" => @computed_dates["3d"],
        "time" => nil,
        "notify" => true,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      '3d+.my task.txt' => {
        "date-decorators" => [],
        "date" => @computed_dates["3d"],
        "time" => nil,
        "notify" => true,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      '3d.my task.1w-mo-we.txt' => {
        "date-decorators" => [],
        "date" => @computed_dates["3d"],
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      '3d.my task.txt' => {
        "date-decorators" => [],
        "date" => @computed_dates["3d"],
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      'today.my task.txt' => {
        "date-decorators" => [],
        "date" => @computed_dates["today"],
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
      'tomorrow.my task.txt' => {
        "date-decorators" => [],
        "date" => @computed_dates["tomorrow"],
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => nil,
        "extension" => "txt"
      },
    }

    @filename_with_date = "■2024-01-01.my-task.txt"
    @filename_with_time = "■2024-01-01+1500.my-task.txt"
    @filename_without_date = "my-task.txt"
  end

  def test_filename_parsing
    @test_cases.each do |filename, expected_output|
      parser = NameParser.new(filename)
      assert_equal expected_output["date-decorators"], parser.date_decorators, "Failed on #{filename} (date-decorators)"
      assert_equal expected_output["date"], parser.date, "Failed on #{filename} (date)"

      if expected_output["time"] == nil
        assert_nil parser.time, "Failed on #{filename} (time)"
      else
        assert_equal expected_output["time"], parser.time, "Failed on #{filename} (time)"
      end

      assert_equal expected_output["notify"], parser.notify, "Failed on #{filename} (notify)"
      assert_equal expected_output["name-decorators"], parser.name_decorators, "Failed on #{filename} (name-decorators)"
      assert_equal expected_output["name"], parser.name, "Failed on #{filename} (name)"

      if expected_output["repeat-logic"] == nil
        assert_nil parser.repeat_logic, "Failed on #{filename} (repeat-logic)"
      else
        assert_equal expected_output["repeat-logic"], parser.repeat_logic, "Failed on #{filename} (repeat-logic)"
      end

      assert_equal expected_output["extension"], parser.extension, "Failed on #{filename} (extension)"
    end
  end

  def test_modify_filename_with_days
    parser = NameParser.new(@filename_with_date)
    new_filename = parser.modify_filename_with_time("3d")
    assert_equal "■2024-01-04.my-task.txt", new_filename, "Adding 3 days failed"
  end

  def test_modify_filename_with_weeks
    parser = NameParser.new(@filename_with_date)
    new_filename = parser.modify_filename_with_time("2w")
    assert_equal "■2024-01-15.my-task.txt", new_filename, "Adding 2 weeks failed"
  end

  def test_modify_filename_with_months
    parser = NameParser.new(@filename_with_date)
    new_filename = parser.modify_filename_with_time("1m")
    assert_equal "■2024-02-01.my-task.txt", new_filename, "Adding 1 month failed"
  end

  def test_modify_filename_with_years
    parser = NameParser.new(@filename_with_date)
    new_filename = parser.modify_filename_with_time("1y")
    assert_equal "■2025-01-01.my-task.txt", new_filename, "Adding 1 year failed"
  end

  def test_modify_filename_without_date
    parser = NameParser.new(@filename_without_date)
    new_filename = parser.modify_filename_with_time("7d")
    expected_date = (Date.today + 7).strftime('%Y-%m-%d')
    assert_equal "#{expected_date}.my-task.txt", new_filename, "Adding 7 days to a file without a date failed"
  end

  def test_modify_filename_with_date_and_time
    parser = NameParser.new(@filename_with_time)
    new_filename = parser.modify_filename_with_time("1w")
    assert_equal "■2024-01-08+1500.my-task.txt", new_filename, "Adding 1 week to a file with date and time failed"
  end

  def test_modify_filename_invalid_modification_string
    parser = NameParser.new(@filename_with_date)
    assert_raises(ArgumentError) { parser.modify_filename_with_time("invalid") }
  end

  def test_modify_filename_no_change
    parser = NameParser.new(@filename_with_date)
    new_filename = parser.modify_filename_with_time("0d")
    assert_equal @filename_with_date, new_filename, "Adding 0 days should not modify the filename"
  end

  def test_modify_filename_with_days_and_time
    parser = NameParser.new(@filename_with_date)
    new_filename = parser.modify_filename_with_time("3d+1400")
    assert_equal "■2024-01-04+1400.my-task.txt", new_filename, "Adding 3 days and setting time to 14:00 failed"
  end
  
  def test_modify_filename_with_weeks_and_time
    parser = NameParser.new(@filename_with_date)
    new_filename = parser.modify_filename_with_time("2w+0930")
    assert_equal "■2024-01-15+0930.my-task.txt", new_filename, "Adding 2 weeks and setting time to 09:30 failed"
  end
  
  def test_modify_filename_with_date_and_modification_time
    parser = NameParser.new(@filename_with_time)
    new_filename = parser.modify_filename_with_time("1d+1830")
    assert_equal "■2024-01-02+1830.my-task.txt", new_filename, "Adding 1 day and changing time to 18:30 failed"
  end
  
  def test_modify_filename_with_no_time_in_modification
    parser = NameParser.new(@filename_with_time)
    new_filename = parser.modify_filename_with_time("1w")
    assert_equal "■2024-01-08+1500.my-task.txt", new_filename, "Adding 1 week without changing time failed"
  end
  
  def test_modify_filename_without_date_and_time_modification
    parser = NameParser.new(@filename_without_date)
    new_filename = parser.modify_filename_with_time("7d+1200")
    expected_date = (Date.today + 7).strftime('%Y-%m-%d')
    assert_equal "#{expected_date}+1200.my-task.txt", new_filename, "Adding 7 days and setting time to 12:00 for a file without date failed"
  end

  def test_modify_filename_with_hours
    parser = NameParser.new(@filename_with_date)
    new_filename = parser.modify_filename_with_time("3h")
    assert_equal "■2024-01-01+0300.my-task.txt", new_filename, "Adding 3 hours to a file with a date but no time failed"
  end
  
  def test_modify_filename_with_hours_and_existing_time
    parser = NameParser.new(@filename_with_time)
    new_filename = parser.modify_filename_with_time("5h")
    assert_equal "■2024-01-01+2000.my-task.txt", new_filename, "Adding 5 hours to a file with an existing time failed"
  end
  
  def test_modify_filename_with_hours_and_no_date_or_time
    parser = NameParser.new(@filename_without_date)
    new_filename = parser.modify_filename_with_time("7h")
    expected_date = Date.today.strftime('%Y-%m-%d')
    assert_equal "#{expected_date}+0700.my-task.txt", new_filename, "Adding 7 hours to a file with no date or time failed"
  end
  
  def test_modify_filename_with_hours_and_midnight_default
    parser = NameParser.new(@filename_with_date)
    new_filename = parser.modify_filename_with_time("2h")
    assert_equal "■2024-01-01+0200.my-task.txt", new_filename, "Adding 2 hours with default midnight time failed"
  end
  
  def test_modify_filename_with_hours_and_complex_modification
    parser = NameParser.new(@filename_with_date)
    new_filename = parser.modify_filename_with_time("1d+3h")
    assert_equal "■2024-01-02+0300.my-task.txt", new_filename, "Adding 1 day and 3 hours failed"
  end
  
  def test_modify_filename_with_hours_no_time_no_date
    parser = NameParser.new(@filename_without_date)
    new_filename = parser.modify_filename_with_time("0h")
    expected_date = Date.today.strftime('%Y-%m-%d')
    assert_equal "#{expected_date}+0000.my-task.txt", new_filename, "Adding 0 hours with no date or time failed"
  end
end