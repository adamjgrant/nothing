# Nothing - A Simple To-Do List Directory Manager with Extensions

**Nothing** is a simple system for managing a to-do list as files in a directory. It automatically moves tasks due today or earlier out of `later/` into the main directory. It also supports "extensions" — custom Ruby scripts you can place in the `extensions/` directory to be run after each execution.

## How It Works

1. **Directory Structure:**
   - `later/`: Place tasks scheduled for a future date.  
   - `archived/`: For manually archiving tasks once done (not auto-managed).  
   - `sys/`: Logs (`activity.log`, `error.log`) and test utilities.
   - `extensions/`: Ruby scripts placed here will be run after the main script finishes its task management. Initially empty.
   - `extensions/inactive/`: Place extensions here to deactivate them.
   - `extensions/tests/`: Store test scripts for extensions here. These tests should be written to verify the functionality of individual extensions.

2. **Task File Naming:**
   Tasks can optionally start with a date in the `YYYYMMDD` format.  
   - **Example with Date:** `20241225.Buy Christmas Gifts.txt`  
   - **Example without Date:** `Buy Groceries.txt`

   Files with a date prefix are automatically sorted when listed in the directory, ensuring tasks are organized chronologically.

3. **Date-Based Movement:**
   - Tasks with a date in the past or today are moved from `later/` to the main directory.  
   - Tasks without a date remain in `later/` unless manually moved.

4. **Extensions:**
   - Place `.rb` files in the `extensions/` directory to extend functionality.
   - Extensions run after the main task-moving logic.

## How to Write an Extension

Extensions are Ruby scripts that add custom functionality to `nothing.rb`. They run automatically after the main task-moving logic completes. Extensions can include tests to verify their functionality and must adhere to the guidelines below for consistency.

### **Writing an Extension**
1. **File Placement:**
   - Place active extensions in the `extensions/` directory.
   - Place inactive extensions in the `extensions/inactive/` directory to disable them temporarily.
   - Use the `extensions/tests/` directory to store tests specific to your extension.

2. **Custom Root Directory:**
   - Extensions must accept a custom root directory as a command-line argument to ensure they can run in test environments.
   - Use this boilerplate code to determine the root directory:
     ```ruby
     root_dir = ARGV[0] || Dir.pwd
     ```

3. **Extension Behavior:**
   - Write your logic to manipulate files and directories using the root directory.
   - Avoid modifying the core directories (`later/`, `archived/`, `sys/`) unless necessary.
   - Log activity if your extension performs significant actions.

4. **Adding Tests for Your Extension:**
   - Create a test script in the `extensions/tests/` directory.
   - Your test script should define a class that inherits from `ExtensionTestBase` (defined in the main test framework).
   - Implement the `setup` method to prepare your environment and the `test_extensions` method to verify functionality.

### **Example Extension Script**
Below is a template for a simple extension:

```ruby
# my_extension_test.rb
require_relative '../../../sys/test'

class MyExtensionTest < ExtensionTestBase
  def setup
    super
    puts "Setting up test environment for MyExtension"
    # Add setup logic specific to your extension
  end

  def test_extensions
    puts "Running tests for MyExtension"
    # Add assertions and test logic for your extension
  end
end
```

Testing your extension

```bash
ruby sys/test.rb
```