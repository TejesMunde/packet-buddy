# PacketBuddy Codebase Overview

**Last Updated:** 2026-01-08

This document provides a comprehensive overview of the PacketBuddy codebase for AI assistants and developers.

---

## Project Summary

**PacketBuddy** is a cross-platform network usage monitoring tool that:

- Tracks upload/download bandwidth in real-time
- Stores data locally in SQLite with optional cloud sync (NeonDB)
- Provides a web dashboard for visualization
- Runs as a background service on Windows, macOS, and Linux
- Uses <40MB RAM and <0.5% CPU

---

## Directory Structure

```
packet-buddy/
├── .agent/                    # AI assistant documentation
│   ├── codebase.md           # This file - complete codebase overview
│   ├── architecture.md       # System architecture details
│   ├── evolution.md          # Project evolution history
│   ├── maintenance_manual.md # Maintenance and troubleshooting
│   └── ui_standards.md       # Dashboard UI/UX standards
│
├── dashboard/                 # Web dashboard (static files)
│   ├── index.html            # Main dashboard page
│   ├── app.js                # Dashboard JavaScript logic
│   ├── style.css             # Dashboard styles
│   └── favicon.png           # Favicon
│
├── docs/                      # Documentation
│   ├── WINDOWS_TASK_SCHEDULER_FIX.md  # Windows Task Scheduler fix guide
│   └── WINDOWS_FIX_SUMMARY.md         # Quick fix summary
│
├── service/                   # Platform-specific service installers
│   ├── windows/
│   │   ├── setup.bat         # Windows setup wizard
│   │   ├── setup.ps1         # PowerShell setup script
│   │   └── install-service.ps1  # PowerShell service installer
│   ├── macos/
│   │   ├── setup.sh          # macOS setup script
│   │   └── com.packetbuddy.plist  # LaunchAgent plist
│   └── linux/
│       ├── setup.sh          # Linux setup script
│       └── packetbuddy.service.template  # systemd service template
│
├── src/                       # Python source code
│   ├── api/                  # FastAPI server and routes
│   │   ├── server.py         # Main FastAPI application
│   │   └── routes.py         # API endpoint definitions
│   │
│   ├── cli/                  # Command-line interface
│   │   └── main.py           # CLI commands (pb today, pb summary, etc.)
│   │
│   ├── core/                 # Core business logic
│   │   ├── device.py         # Device identification
│   │   ├── monitor.py        # Network monitoring (psutil)
│   │   ├── storage.py        # SQLite database operations
│   │   └── sync.py           # NeonDB cloud sync
│   │
│   └── utils/                # Utility modules
│       ├── config.py         # Configuration management (TOML)
│       ├── formatters.py     # Data formatting utilities
│       └── updater.py        # Auto-update functionality
│
├── config.example.toml        # Example configuration file
├── requirements.txt           # Python dependencies
├── setup.py                   # Package setup configuration
├── pb                         # Unix launcher script
├── pb.cmd                     # Windows launcher script
├── run-service.bat            # Windows service launcher (NEW)
├── start.bat                  # Windows service starter
├── stop.bat                   # Windows service stopper
├── README.md                  # Main documentation
├── QUICKSTART.md              # Quick start guide
├── CONTRIBUTING.md            # Contribution guidelines
└── LICENSE                    # MIT License

```

---

## Core Components

### 1. Network Monitor (`src/core/monitor.py`)

**Purpose:** Continuously polls network interface statistics and detects data usage.

**Key Features:**

- Uses `psutil.net_io_counters()` to read bytes sent/received
- Polls every 1 second (configurable)
- Detects counter resets (system sleep/resume)
- Filters anomalies (>1GB/s spikes indicate driver glitches)
- Auto-detects primary network interface

**Key Functions:**

- `start()` - Starts monitoring loop
- `stop()` - Gracefully stops monitoring
- `_get_network_stats()` - Reads current network counters
- `_detect_interface()` - Auto-detects active network interface

**Data Flow:**

```
psutil → Monitor → Storage (SQLite) → Sync (NeonDB)
                ↓
              API Server → Dashboard
```

---

### 2. Storage Layer (`src/core/storage.py`)

**Purpose:** Manages local SQLite database for network usage data.

**Database Schema:**

```sql
CREATE TABLE network_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    bytes_sent INTEGER NOT NULL,
    bytes_received INTEGER NOT NULL,
    device_id TEXT NOT NULL,
    synced INTEGER DEFAULT 0
);

CREATE TABLE device_info (
    device_id TEXT PRIMARY KEY,
    hostname TEXT,
    platform TEXT,
    created_at TEXT
);
```

**Key Features:**

- Batch writes (every 30 seconds) to reduce disk I/O
- Transaction-safe operations
- Automatic device ID generation (UUID)
- Query methods for today, month, lifetime stats

**Key Functions:**

- `write_usage(bytes_sent, bytes_received)` - Writes usage data
- `get_today_usage()` - Returns today's stats
- `get_month_usage(year, month)` - Returns monthly breakdown
- `get_lifetime_usage()` - Returns all-time totals

---

### 3. Cloud Sync (`src/core/sync.py`)

**Purpose:** Optional synchronization with NeonDB (PostgreSQL) for multi-device tracking.

**Key Features:**

- Syncs every 60 seconds (configurable)
- Only syncs unsynced records (`synced = 0`)
- Automatic retry with exponential backoff
- Works offline (buffers locally)
- Uses environment variable `NEON_DB_URL`

**NeonDB Schema:**

```sql
CREATE TABLE IF NOT EXISTS network_usage (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    bytes_sent BIGINT NOT NULL,
    bytes_received BIGINT NOT NULL,
    device_id TEXT NOT NULL,
    hostname TEXT,
    platform TEXT
);

CREATE INDEX IF NOT EXISTS idx_device_timestamp 
ON network_usage(device_id, timestamp);
```

**Key Functions:**

- `start()` - Starts sync loop
- `stop()` - Stops sync
- `_sync_batch()` - Syncs unsynced records to NeonDB

---

### 4. FastAPI Server (`src/api/server.py`)

**Purpose:** HTTP server that serves the dashboard and provides REST API.

**Configuration:**

- Host: `127.0.0.1` (localhost only for security)
- Port: `7373` (configurable)
- CORS: Enabled for development

**Background Tasks:**

- Starts monitor on server startup
- Starts sync (if enabled) on server startup
- Graceful shutdown handling

**Key Features:**

- Serves static dashboard files from `/dashboard`
- Root (`/`) redirects to `/dashboard/`
- API endpoints under `/api`

---

### 5. API Routes (`src/api/routes.py`)

**Endpoints:**

| Endpoint | Method | Description | Response Time |
|----------|--------|-------------|---------------|
| `/api/health` | GET | Service status & device info | <10ms |
| `/api/live` | GET | Current upload/download speed | <10ms |
| `/api/today` | GET | Today's total usage | <50ms |
| `/api/month?month=YYYY-MM` | GET | Monthly breakdown by day | <100ms |
| `/api/range?from=DATE&to=DATE` | GET | Custom date range | <200ms |
| `/api/summary` | GET | Lifetime totals | <50ms |
| `/api/export?format=json\|csv` | GET | Export all data | Varies |
| `/api/export/llm` | GET | LLM-friendly export | <100ms |

**Response Format:**

```json
{
  "bytes_sent": 125829120,
  "bytes_received": 524288000,
  "total_bytes": 650117120,
  "human_readable": {
    "sent": "120.00 MB",
    "received": "500.00 MB",
    "total": "620.00 MB"
  },
  "cost": {
    "sent": {"cost": 0.90, "cost_formatted": "₹0.90"},
    "received": {"cost": 3.75, "cost_formatted": "₹3.75"},
    "total": {"cost": 4.88, "cost_formatted": "₹4.88"}
  }
}
```

---

### 6. Dashboard (`dashboard/`)

**Technology Stack:**

- Vanilla HTML/CSS/JavaScript
- Chart.js for visualizations
- No build process required

**Key Features:**

- Real-time speed monitor (updates every 2s)
- Today's usage stats (updates every 30s)
- Lifetime stats (updates every 60s)
- Monthly bar chart (interactive)
- Upload/Download pie chart
- Dark theme optimized

**JavaScript Functions:**

- `loadLiveStats()` - Fetches current speed
- `loadTodayStats()` - Fetches today's usage
- `loadLifetimeStats()` - Fetches lifetime totals
- `loadMonthlyData()` - Fetches monthly breakdown
- `initCharts()` - Initializes Chart.js charts

---

### 7. CLI (`src/cli/main.py`)

**Purpose:** Command-line interface for quick stats and service management.

**Commands:**

```bash
pb today          # Today's usage
pb summary        # Lifetime stats
pb month          # Current month breakdown
pb range --from DATE --to DATE  # Custom range
pb export --format csv          # Export data
pb service start/stop/restart   # Service control
pb update                       # Check for updates
```

**Implementation:**

- Uses `argparse` for command parsing
- Calls storage methods directly
- Formats output with `tabulate` for tables

---

## Platform-Specific Service Setup

### Windows

**Mechanism:** Windows Task Scheduler

**Files:**

- `service/windows/setup.bat` - Main setup wizard
- `service/windows/install-service.ps1` - PowerShell installer
- `run-service.bat` - Service launcher script (NEW - fixes Task Scheduler issues)

**How It Works:**

1. Setup creates a scheduled task named "PacketBuddy"
2. Task triggers on user logon
3. Task runs `run-service.bat` which:
   - Sets working directory
   - Sets `PYTHONPATH` environment variable
   - Runs `pythonw.exe -m src.api.server` (windowless Python)

**Recent Fix (2026-01-08):**

- Created dedicated `run-service.bat` launcher script
- Fixes issue where service worked from command prompt but not Task Scheduler
- Problem was missing `PYTHONPATH` and improper environment setup
- See `docs/WINDOWS_TASK_SCHEDULER_FIX.md` for details

**Service Control:**

```batch
schtasks /run /tn "PacketBuddy"     # Start
schtasks /end /tn "PacketBuddy"     # Stop
schtasks /query /tn "PacketBuddy"   # Status
```

---

### macOS

**Mechanism:** LaunchAgent (launchd)

**Files:**

- `service/macos/setup.sh` - Setup script
- `service/macos/com.packetbuddy.plist` - LaunchAgent configuration

**How It Works:**

1. Setup copies plist to `~/Library/LaunchAgents/`
2. LaunchAgent loads on user login
3. Runs `python -m src.api.server` with proper environment

**Service Control:**

```bash
launchctl load ~/Library/LaunchAgents/com.packetbuddy.plist
launchctl unload ~/Library/LaunchAgents/com.packetbuddy.plist
launchctl kickstart -k gui/$(id -u)/com.packetbuddy.daemon
```

---

### Linux

**Mechanism:** systemd user service

**Files:**

- `service/linux/setup.sh` - Setup script
- `service/linux/packetbuddy.service.template` - systemd service template

**How It Works:**

1. Setup creates service file in `~/.config/systemd/user/`
2. Enables service to start on login
3. Runs `python -m src.api.server`

**Service Control:**

```bash
systemctl --user start packetbuddy.service
systemctl --user stop packetbuddy.service
systemctl --user restart packetbuddy.service
systemctl --user status packetbuddy.service
```

---

## Configuration System

**File Location:** `~/.packetbuddy/config.toml`

**Format:** TOML (Tom's Obvious, Minimal Language)

**Default Configuration:**

```toml
[api]
host = "127.0.0.1"
port = 7373
cors_enabled = true

[monitoring]
poll_interval = 1
batch_write_interval = 30
interface = "auto"

[sync]
enabled = false
interval = 60

[cost]
rate_per_gb = 7.50
currency = "INR"
```

**Loading Priority:**

1. User config: `~/.packetbuddy/config.toml`
2. Project config: `config.example.toml`
3. Hardcoded defaults in `src/utils/config.py`

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     User's Computer                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Network Interface (OS Kernel)                       │  │
│  │  - Tracks bytes sent/received                        │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │                                         │
│                   ▼                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  psutil Library                                      │  │
│  │  - Reads kernel network counters                     │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │                                         │
│                   ▼                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Monitor (src/core/monitor.py)                       │  │
│  │  - Polls every 1 second                              │  │
│  │  - Calculates delta (current - previous)            │  │
│  │  - Filters anomalies                                 │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │                                         │
│                   ▼                                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Storage (src/core/storage.py)                       │  │
│  │  - Batch writes to SQLite every 30s                  │  │
│  │  - Database: ~/.packetbuddy/packetbuddy.db          │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │                                         │
│                   ├─────────────────────────────────────┐   │
│                   │                                     │   │
│                   ▼                                     ▼   │
│  ┌──────────────────────────────┐  ┌─────────────────────┐ │
│  │  Sync (src/core/sync.py)     │  │  API Server         │ │
│  │  - Syncs to NeonDB every 60s │  │  (FastAPI)          │ │
│  │  - Optional                  │  │  - Port 7373        │ │
│  └──────────────┬───────────────┘  └─────────┬───────────┘ │
│                 │                            │             │
│                 ▼                            ▼             │
│  ┌──────────────────────────┐  ┌──────────────────────┐   │
│  │  NeonDB (PostgreSQL)     │  │  Dashboard           │   │
│  │  - Cloud database        │  │  (HTML/CSS/JS)       │   │
│  │  - Multi-device sync     │  │  - Chart.js          │   │
│  └──────────────────────────┘  └──────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Algorithms

### 1. Network Usage Calculation

```python
# Pseudocode
previous_sent = 0
previous_received = 0

while monitoring:
    current = psutil.net_io_counters()
    
    # Calculate delta
    delta_sent = current.bytes_sent - previous_sent
    delta_received = current.bytes_recv - previous_received
    
    # Handle counter reset (sleep/resume)
    if delta_sent < 0 or delta_received < 0:
        # Reset counters, skip this sample
        previous_sent = current.bytes_sent
        previous_received = current.bytes_recv
        continue
    
    # Filter anomalies (>1GB/s is likely a glitch)
    if delta_sent > 1_000_000_000 or delta_received > 1_000_000_000:
        # Skip this sample
        continue
    
    # Store valid data
    storage.write_usage(delta_sent, delta_received)
    
    # Update previous values
    previous_sent = current.bytes_sent
    previous_received = current.bytes_recv
    
    sleep(poll_interval)
```

### 2. Batch Writing

```python
# Pseudocode
write_buffer = []
last_write_time = now()

def write_usage(sent, received):
    write_buffer.append((timestamp, sent, received))
    
    if now() - last_write_time >= batch_write_interval:
        flush_buffer()

def flush_buffer():
    db.execute("BEGIN TRANSACTION")
    for record in write_buffer:
        db.execute("INSERT INTO network_usage VALUES (?)", record)
    db.execute("COMMIT")
    write_buffer.clear()
    last_write_time = now()
```

### 3. Cloud Sync

```python
# Pseudocode
def sync_to_neondb():
    # Get unsynced records
    unsynced = local_db.query("SELECT * FROM network_usage WHERE synced = 0")
    
    if not unsynced:
        return
    
    try:
        # Bulk insert to NeonDB
        neon_db.bulk_insert(unsynced)
        
        # Mark as synced in local DB
        local_db.execute("UPDATE network_usage SET synced = 1 WHERE id IN (?)", unsynced.ids)
    except NetworkError:
        # Retry later with exponential backoff
        retry_after = min(60 * (2 ** retry_count), 3600)
        sleep(retry_after)
```

---

## Dependencies

**Core Dependencies:**

```txt
fastapi==0.104.1        # Web framework
uvicorn==0.24.0         # ASGI server
psutil==5.9.6           # System monitoring
toml==0.10.2            # Configuration parsing
tabulate==0.9.0         # CLI table formatting
psycopg2-binary==2.9.9  # PostgreSQL driver (for NeonDB)
```

**Why These Dependencies:**

- **FastAPI**: Modern, fast web framework with automatic API docs
- **uvicorn**: High-performance ASGI server
- **psutil**: Cross-platform system monitoring (network, CPU, memory)
- **toml**: Simple configuration file format
- **tabulate**: Beautiful CLI tables
- **psycopg2**: PostgreSQL driver for NeonDB sync

---

## Common Development Tasks

### Running Locally

```bash
# Activate virtual environment
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows

# Run server
python -m src.api.server

# Run CLI
python -m src.cli.main today
```

### Testing API Endpoints

```bash
# Health check
curl http://127.0.0.1:7373/api/health

# Live stats
curl http://127.0.0.1:7373/api/live

# Today's usage
curl http://127.0.0.1:7373/api/today

# Export data
curl http://127.0.0.1:7373/api/export?format=json > data.json
```

### Database Inspection

```bash
# Open SQLite database
sqlite3 ~/.packetbuddy/packetbuddy.db

# View schema
.schema

# Query today's data
SELECT * FROM network_usage 
WHERE date(timestamp) = date('now', 'localtime');

# View device info
SELECT * FROM device_info;
```

### Adding New API Endpoint

1. Add route in `src/api/routes.py`:

```python
@router.get("/my-endpoint")
async def my_endpoint():
    data = storage.get_my_data()
    return {"result": data}
```

1. Add storage method in `src/core/storage.py`:

```python
def get_my_data(self):
    cursor = self.conn.execute("SELECT * FROM ...")
    return cursor.fetchall()
```

1. Test endpoint:

```bash
curl http://127.0.0.1:7373/api/my-endpoint
```

---

## Troubleshooting Guide

### Service Not Starting

**Check logs:**

```bash
# Windows
type %USERPROFILE%\.packetbuddy\stderr.log

# macOS/Linux
tail -f ~/.packetbuddy/stderr.log
```

**Common issues:**

- Port 7373 already in use → Change port in config
- Python not found → Verify venv activation
- Module not found → Check PYTHONPATH

### High Resource Usage

**Reduce polling frequency:**

```toml
[monitoring]
poll_interval = 2  # Instead of 1
batch_write_interval = 60  # Instead of 30
```

### Database Corruption

**Rebuild database:**

```bash
# Backup first
cp ~/.packetbuddy/packetbuddy.db ~/.packetbuddy/backup.db

# Delete and reinitialize
rm ~/.packetbuddy/packetbuddy.db
python -c "from src.core.storage import storage; storage.get_device_id()"
```

---

## Security Considerations

1. **API binds to localhost only** (`127.0.0.1`)
   - Not accessible from network
   - No authentication needed

2. **No sensitive data collection**
   - Only bytes sent/received
   - No URLs, IPs, or personal data

3. **Environment variables for secrets**
   - `NEON_DB_URL` stored in environment, not code

4. **SQLite file permissions**
   - Database file readable only by user

---

## Future Enhancements

**Potential features:**

- Per-application tracking (requires root/admin)
- Bandwidth limits with alerts
- Historical trend analysis
- Mobile app (React Native)
- Docker container deployment
- Prometheus metrics export

---

## Testing

**Manual Testing Checklist:**

- [ ] Service starts successfully
- [ ] Dashboard loads at <http://127.0.0.1:7373/dashboard>
- [ ] Live stats update every 2 seconds
- [ ] Today's stats are accurate
- [ ] Monthly chart displays correctly
- [ ] Export functionality works (CSV/JSON)
- [ ] Service auto-starts on login
- [ ] Service survives system sleep/resume
- [ ] NeonDB sync works (if enabled)
- [ ] CLI commands work (`pb today`, etc.)

**Test Data Generation:**

```bash
# Generate network traffic for testing
curl -o /dev/null https://speed.cloudflare.com/__down?bytes=100000000
```

---

## Performance Benchmarks

**Typical Performance:**

- CPU: 0.2-0.5%
- RAM: 28-40 MB
- Disk I/O: ~5 KB/s
- API response time: <50ms (most endpoints)

**Stress Test Results:**

- Handles 1000+ API requests/second
- Database supports 10+ years of data
- Sync handles 10,000+ records/batch

---

## Version History

**v1.0.0** (2026-01-08)

- ✅ Cross-platform support (Windows, macOS, Linux)
- ✅ Real-time monitoring
- ✅ Web dashboard
- ✅ CLI interface
- ✅ Optional cloud sync
- ✅ Auto-update functionality
- ✅ Windows Task Scheduler fix

---

## Contact & Support

- **GitHub**: [instax-dutta/packet-buddy](https://github.com/instax-dutta/packet-buddy)
- **Issues**: [GitHub Issues](https://github.com/instax-dutta/packet-buddy/issues)
- **Discussions**: [GitHub Discussions](https://github.com/instax-dutta/packet-buddy/discussions)

---

**For AI Assistants:** This document provides complete context for understanding and working with the PacketBuddy codebase. Use this information to help users with setup, troubleshooting, feature development, and general questions about the project.
