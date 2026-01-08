# Windows Task Scheduler Fix

## Problem

PacketBuddy was working when started from Command Prompt but failing when run via Windows Task Scheduler.

## Root Cause

When running from Command Prompt, the virtual environment is properly activated with all environment variables set. However, Task Scheduler was executing Python directly without:

- Setting `PYTHONPATH` environment variable
- Properly configuring the working directory
- Activating the virtual environment context

This caused Python to fail finding the `src` module, resulting in `ModuleNotFoundError`.

## Solution

Created a dedicated launcher script (`run-service.bat`) that:

1. Sets the correct working directory

## Solution Implemented

### 1. Created Launcher Script (`run-service.bat`)

A dedicated script that properly sets up the environment before starting the service:

- Sets working directory
- Configures `PYTHONPATH` to point to the project root
- Uses `pythonw.exe` (windowless Python) for headless operation
- Runs the server module with proper environment setup

### 2. Updated Setup Scripts

- **setup.bat**: Now uses launcher script instead of complex inline command
- **install-service.ps1**: Updated to use launcher script for consistency
- **start.bat**: Enhanced with better error handling and fallback logic

### 3. Auto-Open Dashboard

All setup and start scripts now automatically open the dashboard in your default browser after the service starts successfully:

- **setup.bat**: Opens dashboard after initial setup
- **start.bat**: Opens dashboard when manually starting service
- **install-service.ps1**: Opens dashboard after PowerShell installation
- **Scheduled task**: Runs silently on login (no browser pop-up)

### 4. Added Documentation

- Comprehensive fix guide: `docs/WINDOWS_TASK_SCHEDULER_FIX.md`
- Updated README.md with troubleshooting section

## Files Modified

### 1. `run-service.bat` (NEW)

Dedicated launcher script used by Task Scheduler to properly initialize the environment before starting the service.

### 2. `service/windows/setup.bat`

Updated to create scheduled task using the launcher script instead of complex inline commands.

### 3. `service/windows/install-service.ps1`

Updated PowerShell installer to use the launcher script for consistency.

### 4. `start.bat`

Enhanced to first try Task Scheduler, then fall back to direct execution using the launcher script.

## How to Apply the Fix

### For Existing Installations

1. **Re-run the setup** (Recommended):

   ```batch
   cd path\to\packet-buddy
   service\windows\setup.bat
   ```

   This will recreate the scheduled task with the correct configuration.

2. **Manual fix** (Advanced):

   ```batch
   # Delete old task
   schtasks /delete /tn "PacketBuddy" /f
   
   # Create new task with launcher script
   cd path\to\packet-buddy
   schtasks /create /tn "PacketBuddy" /tr "%CD%\run-service.bat" /sc onlogon /rl highest /f
   
   # Start the task
   schtasks /run /tn "PacketBuddy"
   ```

### For New Installations

Simply run the setup script as normal:

```batch
service\windows\setup.bat
```

## Verification

After applying the fix, verify it works:

1. **Check Task Scheduler**:

   ```batch
   schtasks /query /tn "PacketBuddy" /v
   ```

2. **Start the task**:

   ```batch
   schtasks /run /tn "PacketBuddy"
   ```

3. **Wait 5-10 seconds**, then check if the service is running:

   ```batch
   curl http://127.0.0.1:7373/api/health
   ```

   Or open in browser: <http://127.0.0.1:7373/dashboard>

4. **Check Task Scheduler GUI**:
   - Press `Win + R`, type `taskschd.msc`, press Enter
   - Find "PacketBuddy" in the task list
   - Right-click → Run
   - Check "Last Run Result" should show "The operation completed successfully (0x0)"

## Troubleshooting

### Task shows "Running" but dashboard doesn't load

- Check Task Scheduler → PacketBuddy → History tab for error details
- Ensure virtual environment exists: `venv\Scripts\pythonw.exe`
- Manually run: `run-service.bat` to see error messages

### "Access Denied" errors

- Re-run setup.bat as Administrator
- Ensure you have permission to create scheduled tasks

### Python not found

- Ensure Python 3.11+ is installed
- Verify virtual environment: `venv\Scripts\python.exe --version`
- Re-run setup to recreate venv

### Service starts but stops immediately

- Check if port 7373 is already in use
- Review logs in `%USERPROFILE%\.packetbuddy\`
- Try running manually: `python -m src.api.server` from project directory

## Technical Details

### Why the launcher script works

```batch
# Sets working directory
cd /d "%PROJECT_DIR%"

# Critical: Sets PYTHONPATH so Python can find 'src' module
set "PYTHONPATH=%PROJECT_DIR%"

# Uses venv's Python (with all dependencies)
"%PROJECT_DIR%\venv\Scripts\pythonw.exe" -m src.api.server
```

### Why inline commands failed

Task Scheduler has issues with:

- Complex command chains with `&&`
- Environment variable expansion in command arguments
- Proper escaping of quotes and special characters
- Setting environment variables within the task command

The launcher script approach is more reliable and maintainable.

## Additional Notes

- The service now uses `pythonw.exe` (windowless Python) to run silently in the background
- Task is set to run at highest privileges to ensure network monitoring permissions
- Task auto-starts on user logon
- If the task fails, it will auto-retry 3 times with 1-minute intervals

## Support

If you continue experiencing issues:

1. Check the Task Scheduler history for detailed error logs
2. Run `run-service.bat` manually to see console output
3. Ensure antivirus isn't blocking Python execution
4. Verify Windows Firewall allows Python network access
