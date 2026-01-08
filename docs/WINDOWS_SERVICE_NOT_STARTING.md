# Windows Service Not Starting - Troubleshooting Guide

**Issue:** Dashboard shows "This site can't be reached - 127.0.0.1 refused to connect"

**Meaning:** The PacketBuddy service is NOT running.

---

## Quick Fix (Try This First)

### Step 1: Check if Service is Running

Open Command Prompt and run:

```batch
curl http://127.0.0.1:7373/api/health
```

**If you get an error:** Service is not running. Continue to Step 2.

**If you get a response:** Service is running, but browser issue. Try different browser or clear cache.

### Step 2: Check Task Scheduler

```batch
schtasks /query /tn "PacketBuddy" /v
```

Look for "Last Run Result". If it shows an error code, the service failed to start.

### Step 3: Run Service Manually (To See Errors)

```batch
cd path\to\packet-buddy
venv\Scripts\activate
python -m src.api.server
```

**This will show you the actual error!** Take a screenshot and share it.

---

## Common Causes & Solutions

### 1. Python Not Found

**Symptoms:**

- Setup.bat says "Python not found"
- Service won't start

**Solution:**

```batch
# Check if Python is installed
python --version

# If not found, download from:
# https://www.python.org/downloads/

# During installation, CHECK "Add Python to PATH"
```

### 2. Virtual Environment Not Created

**Symptoms:**

- `venv` folder doesn't exist
- Setup.bat failed

**Solution:**

```batch
cd packet-buddy
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Dependencies Not Installed

**Symptoms:**

- Error: "No module named 'fastapi'"
- Import errors

**Solution:**

```batch
cd packet-buddy
venv\Scripts\activate
pip install -r requirements.txt
```

### 4. Port 7373 Already in Use

**Symptoms:**

- Error: "Address already in use"
- Another service using port 7373

**Solution:**

**Option A:** Kill the process using port 7373

```batch
netstat -ano | findstr :7373
# Note the PID (last column)
taskkill /PID <PID> /F
```

**Option B:** Change PacketBuddy port

Edit `%USERPROFILE%\.packetbuddy\config.toml`:

```toml
[api]
port = 8080  # Or any other available port
```

Then access: `http://127.0.0.1:8080/dashboard`

### 5. Firewall Blocking Python

**Symptoms:**

- Service starts but can't connect
- Windows Firewall alert

**Solution:**

```batch
# Allow Python through firewall
# Windows will prompt when you first run the service
# Click "Allow access"

# Or manually add firewall rule:
netsh advfirewall firewall add rule name="PacketBuddy" dir=in action=allow program="%CD%\venv\Scripts\python.exe" enable=yes
```

### 6. Missing Config File

**Symptoms:**

- Error: "Config file not found"
- Service crashes on startup

**Solution:**

```batch
# Create config directory
mkdir %USERPROFILE%\.packetbuddy

# Copy example config
copy config.example.toml %USERPROFILE%\.packetbuddy\config.toml
```

### 7. Auto-Update Crash (Recent Issue)

**Symptoms:**

- Service worked before, stopped after update
- Error related to auto_update

**Solution:**

**Option A:** Disable auto-update temporarily

Edit `%USERPROFILE%\.packetbuddy\config.toml`:

```toml
[auto_update]
enabled = false
```

**Option B:** Update to latest version

```batch
cd packet-buddy
git pull origin main
service\windows\setup.bat
```

---

## Step-by-Step Diagnostic

Run these commands one by one and note where it fails:

### 1. Check Python

```batch
python --version
```

**Expected:** Python 3.11.0 or higher

### 2. Check Virtual Environment

```batch
cd packet-buddy
dir venv\Scripts\python.exe
```

**Expected:** File exists

### 3. Check Dependencies

```batch
venv\Scripts\python.exe -c "import fastapi; print('FastAPI OK')"
```

**Expected:** "FastAPI OK"

### 4. Check Config

```batch
dir %USERPROFILE%\.packetbuddy\config.toml
```

**Expected:** File exists

### 5. Check Port

```batch
netstat -ano | findstr :7373
```

**Expected:** Nothing (port is free) OR PacketBuddy process

### 6. Test Service Manually

```batch
venv\Scripts\activate
python -m src.api.server
```

**Expected:** "Starting PacketBuddy API server on <http://127.0.0.1:7373>"

### 7. Test API

```batch
# In another Command Prompt window:
curl http://127.0.0.1:7373/api/health
```

**Expected:** `{"status":"ok","hostname":"..."}`

---

## View Error Logs

### Check Service Logs

```batch
type %USERPROFILE%\.packetbuddy\stderr.log
```

### Check Task Scheduler History

1. Press `Win + R`
2. Type `taskschd.msc` and press Enter
3. Find "PacketBuddy" task
4. Click "History" tab
5. Look for errors

---

## Nuclear Option (Fresh Reinstall)

If nothing works, do a clean reinstall:

```batch
# 1. Stop and remove old service
schtasks /end /tn "PacketBuddy"
schtasks /delete /tn "PacketBuddy" /f

# 2. Backup your data
copy %USERPROFILE%\.packetbuddy\packetbuddy.db %USERPROFILE%\Desktop\packetbuddy-backup.db

# 3. Remove old installation
rmdir /s /q packet-buddy

# 4. Fresh install
git clone https://github.com/instax-dutta/packet-buddy.git
cd packet-buddy
service\windows\setup.bat

# 5. Restore your data (optional)
copy %USERPROFILE%\Desktop\packetbuddy-backup.db %USERPROFILE%\.packetbuddy\packetbuddy.db
```

---

## Get Help

If none of this works, please provide:

1. **Python version:** `python --version`
2. **Windows version:** `winver`
3. **Error logs:** `type %USERPROFILE%\.packetbuddy\stderr.log`
4. **Manual run output:** Screenshot of `python -m src.api.server`
5. **Task Scheduler status:** Screenshot of PacketBuddy task properties

Post this information in:

- GitHub Issues: <https://github.com/instax-dutta/packet-buddy/issues>
- GitHub Discussions: <https://github.com/instax-dutta/packet-buddy/discussions>

---

## Prevention

To avoid future issues:

1. ✅ **Keep Python updated** (but stay on 3.11+)
2. ✅ **Don't delete venv folder**
3. ✅ **Let auto-updates run** (they fix bugs)
4. ✅ **Check logs occasionally** (`stderr.log`)
5. ✅ **Backup database monthly** (`.packetbuddy\packetbuddy.db`)

---

**Last Updated:** 2026-01-08 - Added auto-update troubleshooting
