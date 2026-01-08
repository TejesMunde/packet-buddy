# PacketBuddy - Quick Reference for AI Assistants

**Last Updated:** 2026-01-08

This is a quick reference guide for AI assistants helping users with PacketBuddy.

---

## What is PacketBuddy?

**Ultra-lightweight network usage tracker** that:

- Monitors upload/download bandwidth in real-time
- Runs silently in background (<40MB RAM, <0.5% CPU)
- Provides web dashboard at `http://127.0.0.1:7373/dashboard`
- Works on Windows, macOS, and Linux
- Stores data locally (SQLite) with optional cloud sync (NeonDB)

---

## Quick Setup Commands

### Windows

```batch
# Clone repo
git clone https://github.com/instax-dutta/packet-buddy.git
cd packet-buddy

# Run setup as Administrator
service\windows\setup.bat

# Access dashboard
start http://127.0.0.1:7373/dashboard
```

### macOS

```bash
git clone https://github.com/instax-dutta/packet-buddy.git
cd packet-buddy
chmod +x service/macos/setup.sh
./service/macos/setup.sh
open http://127.0.0.1:7373/dashboard
```

### Linux

```bash
git clone https://github.com/instax-dutta/packet-buddy.git
cd packet-buddy
bash service/linux/setup.sh
xdg-open http://127.0.0.1:7373/dashboard
```

---

## Common Issues & Solutions

### 1. Windows: Service Not Starting from Task Scheduler

**Symptoms:** Works from command prompt, fails from Task Scheduler

**Solution:**

```batch
# Re-run setup as Administrator
service\windows\setup.bat
```

**Details:** See `docs/WINDOWS_TASK_SCHEDULER_FIX.md`

**Root Cause:** Missing PYTHONPATH environment variable. Fixed with dedicated `run-service.bat` launcher script.

---

### 2. Dashboard Not Loading

**Check if service is running:**

```bash
curl http://127.0.0.1:7373/api/health
```

**Start service:**

```batch
# Windows
schtasks /run /tn "PacketBuddy"

# macOS
launchctl kickstart -k gui/$(id -u)/com.packetbuddy.daemon

# Linux
systemctl --user start packetbuddy.service
```

---

### 3. Port Already in Use

**Error:** `Address already in use: 127.0.0.1:7373`

**Solution:** Edit `~/.packetbuddy/config.toml`:

```toml
[api]
port = 8080  # Change to any available port
```

Then restart service.

---

### 4. Python Not Found (Windows)

**Solution:**

1. Download Python 3.11+ from [python.org](https://www.python.org/downloads/)
2. During installation, check "Add Python to PATH"
3. Restart Command Prompt
4. Verify: `python --version`

---

## File Locations

| Item | Windows | macOS/Linux |
|------|---------|-------------|
| Config | `%USERPROFILE%\.packetbuddy\config.toml` | `~/.packetbuddy/config.toml` |
| Database | `%USERPROFILE%\.packetbuddy\packetbuddy.db` | `~/.packetbuddy/packetbuddy.db` |
| Logs | `%USERPROFILE%\.packetbuddy\stderr.log` | `~/.packetbuddy/stderr.log` |

---

## Service Control Commands

### Windows

```batch
schtasks /run /tn "PacketBuddy"      # Start
schtasks /end /tn "PacketBuddy"      # Stop
schtasks /query /tn "PacketBuddy"    # Status
```

### macOS

```bash
launchctl load ~/Library/LaunchAgents/com.packetbuddy.plist    # Start
launchctl unload ~/Library/LaunchAgents/com.packetbuddy.plist  # Stop
launchctl list | grep packetbuddy                              # Status
```

### Linux

```bash
systemctl --user start packetbuddy.service    # Start
systemctl --user stop packetbuddy.service     # Stop
systemctl --user status packetbuddy.service   # Status
```

---

## CLI Commands

```bash
pb today          # Today's usage
pb summary        # Lifetime stats
pb month          # Current month breakdown
pb export         # Export data
pb service start  # Start service
pb service stop   # Stop service
pb update         # Check for updates
```

---

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `/api/health` | Service status |
| `/api/live` | Current speed |
| `/api/today` | Today's usage |
| `/api/month?month=YYYY-MM` | Monthly breakdown |
| `/api/summary` | Lifetime totals |
| `/api/export?format=csv` | Export data |

---

## Configuration

**File:** `~/.packetbuddy/config.toml`

```toml
[api]
host = "127.0.0.1"
port = 7373

[monitoring]
poll_interval = 1          # Seconds between checks
batch_write_interval = 30  # Seconds between DB writes

[sync]
enabled = false            # Set to true for NeonDB sync

[cost]
rate_per_gb = 7.50        # Cost per GB in ₹ (INR)
```

---

## Multi-Device Setup

1. Create NeonDB account at [neon.tech](https://neon.tech)
2. Get connection string
3. Set environment variable:

   ```bash
   # macOS/Linux
   export NEON_DB_URL="postgresql://user:pass@host.neon.tech/db?sslmode=require"
   
   # Windows
   setx NEON_DB_URL "postgresql://user:pass@host.neon.tech/db?sslmode=require"
   ```

4. Run setup on each device

---

## Key Files in Codebase

| File | Purpose |
|------|---------|
| `src/core/monitor.py` | Network monitoring (psutil) |
| `src/core/storage.py` | SQLite database operations |
| `src/core/sync.py` | NeonDB cloud sync |
| `src/api/server.py` | FastAPI server |
| `src/api/routes.py` | API endpoints |
| `src/cli/main.py` | CLI commands |
| `dashboard/index.html` | Web dashboard |
| `run-service.bat` | Windows service launcher (NEW) |

---

## Recent Changes (2026-01-08)

### Windows Task Scheduler Fix

**Problem:** Service worked from command prompt but not Task Scheduler

**Solution:**

- Created `run-service.bat` launcher script
- Sets `PYTHONPATH` environment variable
- Updated `setup.bat` and `install-service.ps1` to use launcher

**Files Modified:**

- ✅ `run-service.bat` (NEW)
- ✅ `service/windows/setup.bat`
- ✅ `service/windows/install-service.ps1`
- ✅ `start.bat`
- ✅ `docs/WINDOWS_TASK_SCHEDULER_FIX.md` (NEW)

---

## Uninstall Instructions

### Windows

```batch
schtasks /delete /tn "PacketBuddy" /f
rmdir /s /q %USERPROFILE%\.packetbuddy
```

### macOS

```bash
launchctl unload ~/Library/LaunchAgents/com.packetbuddy.plist
rm ~/Library/LaunchAgents/com.packetbuddy.plist
rm -rf ~/.packetbuddy
```

### Linux

```bash
systemctl --user stop packetbuddy.service
systemctl --user disable packetbuddy.service
rm ~/.config/systemd/user/packetbuddy.service
rm -rf ~/.packetbuddy
```

---

## Performance Specs

- **CPU Usage:** 0.2-0.5%
- **RAM Usage:** 28-40 MB
- **Disk I/O:** ~5 KB/s
- **Network Overhead:** ~1 KB/30s (sync)
- **API Response Time:** <50ms

---

## Privacy & Security

**Data Collected:**

- ✅ Bytes sent/received
- ✅ Timestamps
- ✅ Device ID (UUID)

**NOT Collected:**

- ❌ Websites visited
- ❌ App names
- ❌ IP addresses
- ❌ DNS queries
- ❌ Personal information

**Security:**

- 🔒 API binds to localhost only
- 🔒 No external network access
- 🔒 TLS encryption for NeonDB
- 🔒 Environment variables for credentials

---

## When to Use Each Documentation File

- **`README.md`** - User-facing setup and usage guide
- **`.agent/codebase.md`** - Complete codebase overview for development
- **`.agent/architecture.md`** - System design and technical architecture
- **`.agent/quick-reference.md`** - This file - quick troubleshooting
- **`docs/WINDOWS_TASK_SCHEDULER_FIX.md`** - Detailed Windows fix guide

---

## Common User Questions

### Q: Does it slow down my internet?

**A:** No. PacketBuddy only reads network statistics, doesn't intercept traffic.

### Q: Can I track multiple devices?

**A:** Yes, with optional NeonDB cloud sync (free tier).

### Q: How accurate is it?

**A:** Very accurate - reads kernel-level network statistics directly from OS.

### Q: Does it work offline?

**A:** Yes, local tracking works 100% offline. Cloud sync requires internet.

### Q: How do I export my data?

**A:** Use `pb export --format csv` or visit `/api/export?format=csv`

---

## Debugging Tips

### View Logs

```bash
# Windows
type %USERPROFILE%\.packetbuddy\stderr.log

# macOS/Linux
tail -f ~/.packetbuddy/stderr.log
```

### Test API

```bash
curl http://127.0.0.1:7373/api/health
curl http://127.0.0.1:7373/api/today
```

### Check Database

```bash
sqlite3 ~/.packetbuddy/packetbuddy.db
.schema
SELECT * FROM network_usage ORDER BY timestamp DESC LIMIT 10;
```

### Manual Start (for debugging)

```bash
cd packet-buddy
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows
python -m src.api.server
```

---

## Support Resources

- **GitHub Repo:** [instax-dutta/packet-buddy](https://github.com/instax-dutta/packet-buddy)
- **Issues:** [GitHub Issues](https://github.com/instax-dutta/packet-buddy/issues)
- **Discussions:** [GitHub Discussions](https://github.com/instax-dutta/packet-buddy/discussions)

---

**For AI Assistants:** Use this quick reference for common user questions and troubleshooting. For deeper technical questions, refer to `codebase.md` and `architecture.md`.
