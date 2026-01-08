# PacketBuddy Architecture

**Last Updated:** 2026-01-08

This document describes the system architecture, design decisions, and technical implementation of PacketBuddy.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PacketBuddy System                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    Presentation Layer                     │ │
│  ├───────────────────────────────────────────────────────────┤ │
│  │  • Web Dashboard (HTML/CSS/JS + Chart.js)                │ │
│  │  • CLI Interface (Python argparse + tabulate)            │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│                              ▼                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                    Application Layer                      │ │
│  ├───────────────────────────────────────────────────────────┤ │
│  │  • FastAPI Server (HTTP API)                             │ │
│  │  • API Routes (REST endpoints)                           │ │
│  │  • Request/Response formatting                           │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│                              ▼                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                     Business Logic Layer                  │ │
│  ├───────────────────────────────────────────────────────────┤ │
│  │  • Network Monitor (psutil polling)                      │ │
│  │  • Data Validation & Filtering                           │ │
│  │  • Cost Calculation                                      │ │
│  │  • Device Management                                     │ │
│  └───────────────────────────────────────────────────────────┘ │
│                              │                                  │
│                              ▼                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                      Data Layer                           │ │
│  ├───────────────────────────────────────────────────────────┤ │
│  │  • Storage Manager (SQLite)                              │ │
│  │  • Sync Manager (NeonDB/PostgreSQL)                      │ │
│  │  • Configuration Manager (TOML)                          │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Architecture

### 1. Monitor Component

**Responsibility:** Continuously track network usage

**Design Pattern:** Observer Pattern

**Implementation:**

```python
class NetworkMonitor:
    def __init__(self):
        self.running = False
        self.previous_stats = None
        self.interface = self._detect_interface()
    
    async def start(self):
        """Main monitoring loop"""
        self.running = True
        while self.running:
            current = self._get_network_stats()
            delta = self._calculate_delta(current, self.previous_stats)
            
            if self._is_valid_delta(delta):
                await storage.write_usage(delta.sent, delta.received)
            
            self.previous_stats = current
            await asyncio.sleep(config.poll_interval)
```

**Key Design Decisions:**

1. **Async/await pattern** for non-blocking I/O
2. **Delta calculation** instead of absolute values
3. **Anomaly filtering** to prevent data corruption
4. **Interface auto-detection** for ease of use

---

### 2. Storage Component

**Responsibility:** Persist network usage data locally

**Design Pattern:** Repository Pattern

**Schema Design:**

```sql
-- Normalized schema for efficiency
CREATE TABLE network_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,           -- ISO 8601 format
    bytes_sent INTEGER NOT NULL,       -- Delta, not absolute
    bytes_received INTEGER NOT NULL,   -- Delta, not absolute
    device_id TEXT NOT NULL,           -- UUID v4
    synced INTEGER DEFAULT 0           -- Sync flag
);

-- Indexes for common queries
CREATE INDEX idx_timestamp ON network_usage(timestamp);
CREATE INDEX idx_device_timestamp ON network_usage(device_id, timestamp);
CREATE INDEX idx_synced ON network_usage(synced) WHERE synced = 0;

-- Device metadata
CREATE TABLE device_info (
    device_id TEXT PRIMARY KEY,
    hostname TEXT,
    platform TEXT,
    created_at TEXT
);
```

**Design Decisions:**

1. **Store deltas, not absolutes** - Reduces storage size, easier to aggregate
2. **Batch writes** - Reduces disk I/O from 1/sec to 1/30sec
3. **Sync flag** - Tracks which records need cloud sync
4. **Indexes** - Optimized for common query patterns (today, month, range)

---

### 3. Sync Component

**Responsibility:** Synchronize data to cloud (NeonDB)

**Design Pattern:** Eventual Consistency

**Architecture:**

```
Local SQLite (Source of Truth)
       │
       │ Every 60s
       ▼
   Sync Manager
       │
       │ Batch Insert
       ▼
NeonDB PostgreSQL (Aggregation)
```

**Sync Algorithm:**

```python
async def sync_batch():
    # Get unsynced records
    unsynced = local_db.query(
        "SELECT * FROM network_usage WHERE synced = 0 LIMIT 1000"
    )
    
    if not unsynced:
        return
    
    try:
        # Bulk insert to NeonDB
        await neon_db.bulk_insert(unsynced)
        
        # Mark as synced
        local_db.execute(
            "UPDATE network_usage SET synced = 1 WHERE id IN (?)",
            [r.id for r in unsynced]
        )
    except Exception as e:
        # Retry with exponential backoff
        await asyncio.sleep(min(60 * (2 ** retry_count), 3600))
```

**Design Decisions:**

1. **Local-first** - Works offline, syncs when online
2. **Batch sync** - Reduces API calls and network overhead
3. **Idempotent** - Safe to retry, no duplicate data
4. **Exponential backoff** - Graceful handling of network issues

---

### 4. API Server Component

**Responsibility:** Serve HTTP API and dashboard

**Design Pattern:** RESTful API

**Endpoint Design:**

```
GET /api/health          → Service status
GET /api/live            → Real-time speed
GET /api/today           → Today's usage
GET /api/month           → Monthly breakdown
GET /api/range           → Custom date range
GET /api/summary         → Lifetime totals
GET /api/export          → Data export
GET /dashboard/          → Web dashboard
```

**Response Format (Standardized):**

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

**Design Decisions:**

1. **Localhost only** - Security by default (no external access)
2. **CORS enabled** - Allows dashboard to work from file://
3. **Consistent response format** - Easy to parse and display
4. **Human-readable values** - Reduces client-side formatting

---

## Data Flow Architecture

### Write Path (Network Usage → Database)

```
1. psutil.net_io_counters()
   ↓
2. Monitor calculates delta
   ↓
3. Validate delta (no resets, no anomalies)
   ↓
4. Add to write buffer
   ↓
5. Every 30s: Batch write to SQLite
   ↓
6. Mark as unsynced (synced = 0)
   ↓
7. Every 60s: Sync to NeonDB (if enabled)
   ↓
8. Mark as synced (synced = 1)
```

### Read Path (Dashboard → API → Database)

```
1. Dashboard requests /api/today
   ↓
2. API route handler
   ↓
3. Storage.get_today_usage()
   ↓
4. SQL query: SELECT SUM(...) WHERE date(timestamp) = today
   ↓
5. Format response (bytes → human-readable)
   ↓
6. Calculate cost (bytes * rate_per_gb)
   ↓
7. Return JSON response
   ↓
8. Dashboard updates UI
```

---

## Service Architecture (Platform-Specific)

### Windows: Task Scheduler

```
User Login
    ↓
Task Scheduler triggers "PacketBuddy" task
    ↓
Executes: run-service.bat
    ↓
Sets PYTHONPATH=%PROJECT_DIR%
    ↓
Runs: pythonw.exe -m src.api.server
    ↓
FastAPI server starts (port 7373)
    ↓
Monitor and Sync start as background tasks
```

**Key Fix (2026-01-08):**

- Created `run-service.bat` to properly set environment
- Previous inline command failed due to missing PYTHONPATH
- Now works reliably from Task Scheduler

### macOS: LaunchAgent

```
User Login
    ↓
launchd loads ~/Library/LaunchAgents/com.packetbuddy.plist
    ↓
Executes: /path/to/venv/bin/python -m src.api.server
    ↓
Environment variables from plist
    ↓
Service runs in background
```

### Linux: systemd

```
User Login
    ↓
systemd --user loads packetbuddy.service
    ↓
Executes: /path/to/venv/bin/python -m src.api.server
    ↓
Environment variables from service file
    ↓
Service runs in background
```

---

## Concurrency Model

### Async/Await Architecture

```python
# Main event loop
async def main():
    # Start FastAPI server
    server_task = asyncio.create_task(run_server())
    
    # Start background services
    monitor_task = asyncio.create_task(monitor.start())
    sync_task = asyncio.create_task(sync.start())
    
    # Wait for all tasks
    await asyncio.gather(
        server_task,
        monitor_task,
        sync_task,
        return_exceptions=True
    )
```

**Benefits:**

- Non-blocking I/O
- Efficient resource usage
- Graceful shutdown
- Exception isolation

---

## Error Handling Strategy

### 1. Monitor Errors

```python
try:
    stats = psutil.net_io_counters()
except Exception as e:
    logger.error(f"Failed to read network stats: {e}")
    await asyncio.sleep(poll_interval)
    continue  # Skip this sample, try again
```

### 2. Storage Errors

```python
try:
    db.execute("INSERT INTO ...")
    db.commit()
except sqlite3.Error as e:
    logger.error(f"Database error: {e}")
    db.rollback()  # Rollback transaction
    # Data remains in buffer, will retry
```

### 3. Sync Errors

```python
try:
    await neon_db.bulk_insert(records)
except NetworkError as e:
    logger.warning(f"Sync failed: {e}")
    # Records remain unsynced, will retry later
    retry_count += 1
    await asyncio.sleep(min(60 * (2 ** retry_count), 3600))
```

### 4. API Errors

```python
@router.get("/api/today")
async def get_today():
    try:
        data = storage.get_today_usage()
        return format_response(data)
    except Exception as e:
        logger.error(f"API error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
```

---

## Security Architecture

### 1. Network Security

- **Bind to localhost only** (`127.0.0.1`)
- No external network access
- No authentication needed (local-only)

### 2. Data Privacy

- **No sensitive data collection**
  - Only bytes sent/received
  - No URLs, IPs, DNS queries
- **Local storage first**
  - SQLite database in user directory
  - Cloud sync is optional

### 3. Credential Management

- **Environment variables** for secrets
  - `NEON_DB_URL` not stored in code
- **No hardcoded credentials**
- **TLS for NeonDB** (sslmode=require)

---

## Performance Optimizations

### 1. Batch Writing

**Before:** 1 write/second = 86,400 writes/day

**After:** 1 write/30 seconds = 2,880 writes/day

**Benefit:** 97% reduction in disk I/O

### 2. Indexed Queries

```sql
-- Without index: O(n) scan
SELECT * FROM network_usage WHERE timestamp > '2026-01-01';

-- With index: O(log n) lookup
CREATE INDEX idx_timestamp ON network_usage(timestamp);
```

### 3. Connection Pooling

```python
# Reuse database connection
class Storage:
    def __init__(self):
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
    
    # Don't create new connection for each query
```

### 4. Async I/O

```python
# Non-blocking network I/O
async def sync_batch():
    async with aiohttp.ClientSession() as session:
        await session.post(neon_url, json=data)
```

---

## Scalability Considerations

### Current Limits

- **Database size:** ~1 MB/month/device
- **API throughput:** 1000+ req/s
- **Devices:** Unlimited (with NeonDB)
- **Data retention:** 10+ years on free tier

### Future Scaling

**If needed:**

1. Partition database by month
2. Archive old data to cold storage
3. Add caching layer (Redis)
4. Horizontal scaling with load balancer

---

## Deployment Architecture

### Development

```
Developer Machine
    ↓
python -m src.api.server
    ↓
http://127.0.0.1:7373
```

### Production (User Machine)

```
Windows: Task Scheduler
macOS: LaunchAgent
Linux: systemd
    ↓
Runs on boot
    ↓
Background service
    ↓
http://127.0.0.1:7373
```

### Multi-Device (Optional)

```
Device 1 (Windows) ──┐
Device 2 (macOS)   ──┼──→ NeonDB (PostgreSQL)
Device 3 (Linux)   ──┘
    ↓
Aggregated dashboard on any device
```

---

## Technology Stack Rationale

### Why Python?

- ✅ Cross-platform (Windows, macOS, Linux)
- ✅ Excellent libraries (psutil, FastAPI)
- ✅ Easy to maintain and extend
- ✅ Good performance for I/O-bound tasks

### Why FastAPI?

- ✅ Modern, fast web framework
- ✅ Automatic API documentation
- ✅ Async/await support
- ✅ Type hints and validation

### Why SQLite?

- ✅ Zero configuration
- ✅ Serverless (no daemon)
- ✅ ACID compliant
- ✅ Perfect for local storage

### Why NeonDB (PostgreSQL)?

- ✅ Free tier (10GB)
- ✅ Always-on database
- ✅ Serverless PostgreSQL
- ✅ Easy multi-device sync

### Why Chart.js?

- ✅ Lightweight (no React/Vue needed)
- ✅ Beautiful charts out of the box
- ✅ Responsive and interactive
- ✅ No build process required

---

## Design Principles

1. **Local-First**
   - Works 100% offline
   - Cloud sync is optional enhancement

2. **Zero Configuration**
   - Auto-detects network interface
   - Sensible defaults
   - One-command installation

3. **Privacy by Default**
   - Minimal data collection
   - Local storage first
   - No telemetry

4. **Cross-Platform**
   - Same codebase for all OS
   - Platform-specific service installers
   - Consistent user experience

5. **Lightweight**
   - <40MB RAM
   - <0.5% CPU
   - Minimal disk I/O

6. **Resilient**
   - Handles network interruptions
   - Survives system sleep/resume
   - Auto-recovery from crashes

---

## Future Architecture Improvements

### Potential Enhancements

1. **Microservices Architecture**
   - Separate monitor, API, sync into services
   - Communicate via message queue

2. **Event-Driven Architecture**
   - Use event bus for component communication
   - Better decoupling

3. **Plugin System**
   - Allow custom data sources
   - Extensible analytics

4. **Distributed Tracing**
   - OpenTelemetry integration
   - Better observability

---

**For AI Assistants:** This architecture document provides deep technical context for understanding PacketBuddy's design decisions, component interactions, and implementation details. Use this to help with architectural questions, performance optimization, and system design discussions.
