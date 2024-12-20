# Nothing - A Simple To-Do List Directory Manager with Extensions

**Nothing** is a simple system for managing a to-do list as files in a directory. It automatically moves tasks due today or earlier out of `later/` into the main directory. It also supports "extensions" — custom Ruby scripts you can place in the `extensions/` directory to be run after each execution.

## How It Works

1. **Directory Structure:**
   - `later/`: Place tasks scheduled for a future date.  
   - `archived/`: For manually archiving tasks once done (not auto-managed).  
   - `sys/`: Logs (`activity.log`, `error.log`) and test utilities.
   - `extensions/`: Ruby scripts placed here will be run after the main script finishes its task management. Initially empty.

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

## Running the Script

1. To run the script:
   ```bash
   ruby nothing.rb