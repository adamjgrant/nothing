require 'minitest/autorun'
require 'date'

class TestDueDateMovement < Minitest::Test
  def fuzzy_file_exists?(directory, base_filename)
    # Perform a fuzzy lookup in the specified directory
    Dir.entries(directory).any? do |file|
      file.gsub(/■/, '') == base_filename # Strip ■ emoji for comparison
    end
  end

  def fuzzy_dir_exists?(directory, base_dirname)
    # Perform a fuzzy lookup in the specified directory
    Dir.entries(directory).any? do |dir|
      dir.gsub(/■/, '') == base_dirname # Strip ■ emoji for comparison
    end
  end

  def fuzzy_log_match?(log_contents, expected_fragment)
    # Check if any line in the log contains the expected fragment, ignoring emojis
    log_contents.any? do |line|
      line.gsub(/■/, '').include?(expected_fragment)
    end
  end

  def setup
    # Create test task files in the 'later/' directory
    today_str = Date.today.strftime('%Y-%m-%d')
    yesterday_str = (Date.today - 1).strftime('%Y-%m-%d')
    tomorrow_str = (Date.today + 1).strftime('%Y-%m-%d')

    File.write(File.join(LATER_DIR, "#{yesterday_str}.Task overdue.txt"), "Overdue task")
    File.write(File.join(LATER_DIR, "#{today_str}.Task due today.txt"), "Due today task")
    File.write(File.join(LATER_DIR, "#{tomorrow_str}.Task due tomorrow.txt"), "Due tomorrow task")
    File.write(File.join(LATER_DIR, "Task no date.txt"), "No date task")
  end

  def test_due_date_movement
    # Run the main script with the test root directory
    system("ruby #{File.expand_path('./nothing.rb', __dir__)} #{TEST_ROOT}")
  
    # Verify overdue and due-today tasks were moved to the base directory
    assert fuzzy_file_exists?(TEST_ROOT, "#{(Date.today - 1).strftime('%Y-%m-%d')}.Task overdue.txt"),
           "Overdue task should have been moved to the base directory."
    assert fuzzy_file_exists?(TEST_ROOT, "#{Date.today.strftime('%Y-%m-%d')}.Task due today.txt"),
           "Due-today task should have been moved to the base directory."
  
    # Verify overdue and due-today tasks are no longer in '_later/'
    refute fuzzy_file_exists?(LATER_DIR, "#{(Date.today - 1).strftime('%Y-%m-%d')}.Task overdue.txt"),
           "Overdue task should no longer be in '_later'."
    refute fuzzy_file_exists?(LATER_DIR, "#{Date.today.strftime('%Y-%m-%d')}.Task due today.txt"),
           "Due-today task should no longer be in '_later'."
  
    # Verify future-dated tasks are moved back to '_later/'
    assert fuzzy_file_exists?(LATER_DIR, "#{(Date.today + 1).strftime('%Y-%m-%d')}.Task due tomorrow.txt"),
           "Tomorrow’s task should have been moved back to '_later'."
  
    # Verify no-date tasks remain in '_later/'
    assert fuzzy_file_exists?(LATER_DIR, "Task no date.txt"),
           "No-date task should remain in '_later'."
  
    overdue_task_fragment = "Moved #{(Date.today - 1).strftime('%Y-%m-%d')}.Task overdue.txt from '_later' to '#{TEST_ROOT}'"
    due_today_task_fragment = "Moved #{Date.today.strftime('%Y-%m-%d')}.Task due today.txt from '_later' to '#{TEST_ROOT}'"
    future_task_fragment = "Moved #{(Date.today + 1).strftime('%Y-%m-%d')}.Task due tomorrow.txt from '#{TEST_ROOT}' to '_later'"
  
    # Verify no error log was created
    refute File.exist?(ERROR_LOG), "Error log should not exist if no errors occurred."
  end

  def test_future_date_task_moved_to_later
    future_date = (Date.today + 3).strftime('%Y-%m-%d') # Three days in the future
    future_task = File.join(TEST_ROOT, "#{future_date}.Future task.txt")
  
    # Create a file in the root directory with a future date
    File.write(future_task, "Task content for a future task")
  
    # Run the script
    system("ruby #{File.expand_path('./nothing.rb', __dir__)} #{TEST_ROOT}")
  
    # Verify the task is moved to '_later'
    assert fuzzy_file_exists?(LATER_DIR, "#{future_date}.Future task.txt"),
           "Future-dated task should have been moved to '_later'."
  
    # Verify the task is no longer in the root directory
    refute fuzzy_file_exists?(TEST_ROOT, "#{future_date}.Future task.txt"),
           "Future-dated task should no longer be in the root directory."
  end

  def test_patrick_file
    today = Date.today.strftime('%Y-%m-%d')
    patrick_file = File.join(LATER_DIR, "#{today}+0001+.Patrick.1d.md")
    File.write(patrick_file, "Task content for a now task")

    # Run the script
    system("ruby #{File.expand_path('./nothing.rb', __dir__)} #{TEST_ROOT}")
    expected_file = "#{today}+1300+.Patrick.1d.md"

    assert File.exist?(File.join(TEST_ROOT, expected_file)), "File (#{expected_file}) from earlier today should be in root"
    refute File.exist?(File.join(LATER_DIR, expected_file)), "File (#{expected_file}) from earlier today should not be in later"
  end

  def test_time_based_movement
    # Set up a task with a date and time in the future
    future_time = Time.now + (2 * 60 * 60) # 2 hours from now
    future_date_str = future_time.strftime('%Y-%m-%d')
    future_time_str = future_time.strftime('%H%M')
    future_task = File.join(LATER_DIR, "#{future_date_str}+#{future_time_str}.Task future with time.txt")
  
    # Write the task file in '_later'
    File.write(future_task, "Task content for a future time task")
  
    # Run the script
    system("ruby #{File.expand_path('./nothing.rb', __dir__)} #{TEST_ROOT}")
  
    # Verify the task remains in '_later' because its time has not yet passed
    assert fuzzy_file_exists?(LATER_DIR, "#{future_date_str}+#{future_time_str}.Task future with time.txt"),
           "Future task with a specific time should remain in '_later' if its time has not yet passed."
  
    # Manually adjust the task time to simulate a past time
    past_time = Time.now - (2 * 60 * 60) # 2 hours ago
    past_date_str = past_time.strftime('%Y-%m-%d')
    past_time_str = past_time.strftime('%H%M')
    past_task = File.join(LATER_DIR, "#{past_date_str}+#{past_time_str}.Task past with time.txt")
    File.write(past_task, "Task content for a past time task")
  
    # Run the script again
    system("ruby #{File.expand_path('./nothing.rb', __dir__)} #{TEST_ROOT}")
  
    # Verify the past task is moved to the root because its time has passed
    assert fuzzy_file_exists?(TEST_ROOT, "#{past_date_str}+#{past_time_str}.Task past with time.txt"),
           "Past task with a specific time should be moved to the root if its time has passed."
  
    # Clean up
    File.delete(future_task) if File.exist?(future_task)
    File.delete(past_task) if File.exist?(past_task)
  end

  def test_copy_nothing_to_non_underscored_dirs
    # Set up the test environment
    subnothing_dir = File.join(TEST_ROOT, '_nothing')
    FileUtils.mkdir_p(subnothing_dir)
    File.write(File.join(subnothing_dir, 'sample.txt'), 'Sample content')

    # Non-underscored directories
    project_dir = File.join(TEST_ROOT, 'my project')
    old_project_dir = File.join(TEST_ROOT, 'my old project')
    another_project_dir = File.join(TEST_ROOT, 'another project')

    FileUtils.mkdir_p(project_dir)
    FileUtils.mkdir_p(old_project_dir)
    FileUtils.mkdir_p(another_project_dir)

    # Add an existing _nothing directory to one project
    FileUtils.mkdir_p(File.join(old_project_dir, '_nothing'))

    # Run the script
    nothing_script_path = File.expand_path('./nothing.rb', __dir__)
    system("ruby #{nothing_script_path} #{TEST_ROOT}")

    # Assertions
    assert Dir.exist?(File.join(project_dir, '_nothing')), "_nothing was not copied to 'my project'."
    assert Dir.exist?(File.join(another_project_dir, '_nothing')), "_nothing was not copied to 'another project'."
    refute Dir.exist?(File.join(old_project_dir, '_nothing', 'sample.txt')), "_nothing should not have been copied to 'my old project'."
  end

  def test_recursive_nothing_execution
    return # TODO: Performance concerns
    subnothing_dir = File.join(TEST_ROOT, '_nothing')
    # Create a test root directory
    subfolder_dir = File.join(TEST_ROOT, 'my project')
  
    # Set up the test environment
    # Create _nothing in the root directory
    FileUtils.mkdir_p(subnothing_dir)
    File.write(File.join(subnothing_dir, 'nothing.rb'), <<~RUBY)
      # Minimal nothing.rb script for testing
      Dir.foreach(Dir.pwd) do |file|
        next if file.start_with?('.') || File.directory?(file)
        if file =~ /today\\.task\\.txt$/
          new_name = "\#{Date.today.strftime('%Y-%m-%d')}.task.txt"
          File.rename(file, new_name) unless File.exist?(new_name)
        end
      end
    RUBY

    # Create a subfolder with its own _nothing
    FileUtils.mkdir_p(File.join(subfolder_dir, '_nothing'))
    File.write(File.join(subfolder_dir, '_nothing', 'nothing.rb'), <<~RUBY)
      # Minimal nothing.rb script for testing
      Dir.foreach(Dir.pwd) do |file|
        next if file.start_with?('.') || File.directory?(file)
        if file =~ /today\\.task\\.txt$/
          new_name = "\#{Date.today.strftime('%Y-%m-%d')}.task.txt"
          File.rename(file, new_name) unless File.exist?(new_name)
        end
      end
    RUBY

    # Add a task file to the subfolder
    task_file = File.join(subfolder_dir, 'today.task.txt')
    File.write(task_file, "Task content")

    # Run the script
    nothing_script_path = File.expand_path('./nothing.rb', __dir__)
    system("ruby #{nothing_script_path} #{TEST_ROOT}")

    # Assertions
    renamed_task_file = File.join(subfolder_dir, "#{Date.today.strftime('%Y-%m-%d')}.task.txt")
    assert File.exist?(renamed_task_file), "The task file in the subfolder was not renamed properly."
    refute File.exist?(task_file), "The original task file in the subfolder should not exist."
  end

  # Test case to verify directory task handling
  def test_directory_task_movement
    return # TODO: Performance concerns
    # Dynamically generate dates
    past_date = (Date.today - 1).strftime('%Y-%m-%d')
    future_date = (Date.today + 1).strftime('%Y-%m-%d')
  
    directory_with_past_date_filename = "#{past_date}.my-folder-task"
    directory_with_past_date = File.join(TEST_ROOT, directory_with_past_date_filename)
    FileUtils.mkdir_p(directory_with_past_date)
  
    directory_with_future_date_and_time = File.join(TEST_ROOT, "#{future_date}+1300.my-folder-task")
    FileUtils.mkdir_p(directory_with_future_date_and_time)
  
    nothing_script_path = File.expand_path('./nothing.rb', __dir__)
    # Run nothing.rb script
    system("ruby #{nothing_script_path} #{TEST_ROOT}")
  
    # Verify past-dated directory remains in the root directory
    assert fuzzy_dir_exists?(TEST_ROOT, directory_with_past_date_filename), "Directory task with a past date should remain in the root directory."
  
    # Verify future-dated directory with time is moved to _later
    moved_future_directory_with_time = File.join(LATER_DIR, "#{future_date}+1300.my-folder-task")
    assert Dir.exist?(moved_future_directory_with_time), "Directory task with future date and time should have been moved to _later."
  end

  def test_today_task_in_subfolder_moves_to_root_of_subfolder
    return # TODO: Performance concerns
    # Setup: Define directory structure and file paths
    project_dir = File.join(TEST_ROOT, 'My Project')
    later_subfolder = File.join(project_dir, '_later')
    FileUtils.mkdir_p(later_subfolder)
  
    # Create a task file for today in the subfolder
    today_date = Date.today.strftime('%Y-%m-%d')
    today_task = File.join(later_subfolder, "#{today_date}.should-not-be-in-later.txt")
    File.write(today_task, "Task content for today")
  
    # Run the script twice
    nothing_script_path = File.expand_path('./nothing.rb', __dir__)
    system("ruby #{nothing_script_path} #{TEST_ROOT}")
    system("ruby #{nothing_script_path} #{TEST_ROOT}")
  
    # Expected file path after the move
    expected_task_path = File.join(project_dir, "#{today_date}.should-not-be-in-later.txt")
  
    # Assertions
    assert File.exist?(expected_task_path), "Task for today should have been moved to the root of the subfolder."
    refute File.exist?(today_task), "Task for today should no longer be in '_later' subfolder."
  end
end