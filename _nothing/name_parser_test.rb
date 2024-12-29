require 'minitest/autorun'
require_relative 'name_parser'
require "date"

class NameParserTest < Minitest::Test
  def setup
    today = Date.today
    this_week_monday = today - today.wday + 1 # Start of the week (Monday)

    # Example dynamic date calculations
    @computed_dates = {
      "monday" => this_week_monday.strftime('%Y-%m-%d'),
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
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      'today.my task.txt' => {
        "date-decorators" => [],
        "date" => @computed_dates["3d"],
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
      'tomorrow.my task.txt' => {
        "date-decorators" => [],
        "date" => @computed_dates["3d"],
        "time" => nil,
        "notify" => false,
        "name-decorators" => [],
        "name" => "my task",
        "repeat-logic" => "1w-mo-we",
        "extension" => "txt"
      },
    }
  end

  def test_filename_parsing
    @test_cases.each do |filename, expected_output|
      parser = NameParser.new(filename)
      assert_equal expected_output["date-decorators"], parser.date_decorators, "Failed on #{filename} (date-decorators)"
      assert_equal expected_output["date"], parser.date, "Failed on #{filename} (date)"
      assert_equal expected_output["time"], parser.time, "Failed on #{filename} (time)"
      assert_equal expected_output["notify"], parser.notify, "Failed on #{filename} (notify)"
      assert_equal expected_output["name-decorators"], parser.name_decorators, "Failed on #{filename} (name-decorators)"
      assert_equal expected_output["name"], parser.name, "Failed on #{filename} (name)"
      assert_equal expected_output["repeat-logic"], parser.repeat_logic, "Failed on #{filename} (repeat-logic)"
      assert_equal expected_output["extension"], parser.extension, "Failed on #{filename} (extension)"
    end
  end
end