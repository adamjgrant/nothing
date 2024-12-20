# Nothing - A Simple To-Do List Directory Manager with Extensions

**Nothing** is a simple system for managing a to-do list as files in a directory. It automatically moves tasks due today or earlier out of `later/` into the main directory. It also supports "extensions" — custom Ruby scripts you can place in the `extensions/` directory to be run after each execution.

## How It Works

1. **Directory Structure:**
   - `later/`: Place tasks scheduled for a future date.  
   - `archived/`: For manually archiving tasks once done (not auto-managed).  
   - `sys/`: Logs (`activity.log`, `error.log`) and test utilities.
   - `extensions/`: Ruby scripts placed here will be run after the main script finishes its task management. Initially empty.

2. **Date Format for Tasks:**
   To schedule a task: