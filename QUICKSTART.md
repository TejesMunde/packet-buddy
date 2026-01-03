# PacketBuddy - Quick Start Guide

## Installation (5 minutes)

### 1. Set up Python environment

```bash
cd packet-buddy
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Optional: Configure NeonDB

If you want cloud sync, set your database URL:

```bash
export NEON_DB_URL="postgresql://user:pass@host.neon.tech/db?sslmode=require"
```

Or add to `~/.packetbuddy/config.toml`:

```toml
[database]
neon_url = "your-connection-string"
```

### 3. Start the service

```bash
python -m src.api.server
```

**Dashboard**: <http://127.0.0.1:7373/dashboard>

## Daily Usage

### View current stats (CLI)

```bash
# Activate venv first
source venv/bin/activate

# Today's usage
python -m src.cli.main today

# Lifetime summary
python -m src.cli.main summary

# This month's breakdown
python -m src.cli.main month

# Export data
python -m src.cli.main export --format csv
```

### Access dashboard (Web)

Open <http://127.0.0.1:7373/dashboard> in your browser.

**Features:**

- Real-time upload/download speed (updates every 2s)
- Today's total usage
- Lifetime statistics
- Monthly chart with navigation
- Upload vs Download distribution

## Background Service Setup

### macOS

```bash
# Edit the plist file
nano service/macos/com.packetbuddy.plist

# Update YOUR_USERNAME and YOUR_NEON_DB_URL_HERE

# Install
cp service/macos/com.packetbuddy.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.packetbuddy.plist
launchctl start com.packetbuddy.daemon

# Check logs
tail -f ~/.packetbuddy/stdout.log
```

### Windows

```powershell
# Open PowerShell as Administrator
cd service/windows
.\install-service.ps1 -NeonDbUrl "your-db-url"

# Check status
Get-ScheduledTask -TaskName "PacketBuddy"
```

## API Endpoints

Base URL: `http://127.0.0.1:7373/api`

- `GET /health` - Service status
- `GET /live` - Current speed
- `GET /today` - Today's usage
- `GET /summary` - Lifetime total
- `GET /month?month=2026-01` - Monthly breakdown
- `GET /range?from=2026-01-01&to=2026-01-31` - Date range
- `GET /export?format=json` - Export data

## Troubleshooting

### Service won't start

```bash
# Check if port 7373 is in use
lsof -i :7373

# View error logs
tail -f ~/.packetbuddy/stderr.log
```

### Dashboard not loading

```bash
# Test API
curl http://127.0.0.1:7373/api/health

# Check if server is running
ps aux | grep "src.api.server"
```

### High resource usage

Edit `~/.packetbuddy/config.toml`:

```toml
[monitoring]
poll_interval = 2  # Reduce polling frequency
```

## Data Location

- **Database**: `~/.packetbuddy/packetbuddy.db`
- **Config**: `~/.packetbuddy/config.toml`
- **Device ID**: `~/.packetbuddy/device_id`
- **Logs**: `~/.packetbuddy/*.log`

## Uninstall

### macOS

```bash
launchctl unload ~/Library/LaunchAgents/com.packetbuddy.plist
rm ~/Library/LaunchAgents/com.packetbuddy.plist
rm -rf ~/.packetbuddy
```

### Windows

```powershell
Unregister-ScheduledTask -TaskName "PacketBuddy" -Confirm:$false
Remove-Item -Recurse -Force ~\.packetbuddy
```

---

**Need help?** Check the full [README.md](README.md) for detailed documentation.
