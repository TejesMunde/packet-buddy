# PacketBuddy - AI Assistant Documentation Index

**Last Updated:** 2026-01-08

This directory contains comprehensive documentation for AI assistants (ChatGPT, Claude, Gemini, etc.) to help users with PacketBuddy.

---

## 📚 Documentation Files

### 1. **quick-reference.md** - START HERE

**Purpose:** Quick troubleshooting and common issues  
**Use When:** User has a problem or question  
**Contains:**

- Common issues and solutions
- Service control commands
- File locations
- API endpoints
- Recent changes summary

**Best For:** Fast answers to user questions

---

### 2. **codebase.md** - COMPREHENSIVE OVERVIEW

**Purpose:** Complete codebase documentation  
**Use When:** Need to understand how the code works  
**Contains:**

- Directory structure
- Component descriptions
- Data flow diagrams
- Key algorithms
- Dependencies
- Development tasks
- Testing guide

**Best For:** Development questions, feature requests, debugging

---

### 3. **architecture.md** - TECHNICAL DEEP DIVE

**Purpose:** System architecture and design decisions  
**Use When:** Need to understand why things work the way they do  
**Contains:**

- High-level architecture
- Component architecture
- Data flow architecture
- Concurrency model
- Error handling strategy
- Security architecture
- Performance optimizations
- Technology stack rationale

**Best For:** Architectural questions, performance optimization, design discussions

---

### 4. **evolution.md** - PROJECT HISTORY

**Purpose:** Project evolution and decision history  
**Use When:** Understanding past decisions and changes  
**Contains:**

- Project timeline
- Major milestones
- Design decisions
- Lessons learned

**Best For:** Context on why certain decisions were made

---

### 5. **maintenance_manual.md** - OPERATIONS GUIDE

**Purpose:** Maintenance and operational procedures  
**Use When:** Need to maintain or troubleshoot the system  
**Contains:**

- Routine maintenance tasks
- Backup procedures
- Update procedures
- Monitoring and alerts
- Common failure modes

**Best For:** System administration, maintenance tasks

---

### 6. **ui_standards.md** - DASHBOARD DESIGN

**Purpose:** Dashboard UI/UX standards and guidelines  
**Use When:** Working on dashboard improvements  
**Contains:**

- Design principles
- Color scheme
- Typography
- Component standards
- Accessibility guidelines

**Best For:** Dashboard development, UI/UX questions

---

## 🎯 Quick Decision Tree

**User asks about...**

### Setup/Installation Issues

→ **quick-reference.md** (Common Issues section)  
→ If Windows-specific: Also check `../docs/WINDOWS_TASK_SCHEDULER_FIX.md`

### How to use PacketBuddy

→ **quick-reference.md** (CLI Commands, API Endpoints)  
→ For detailed guide: `../README.md`

### How PacketBuddy works internally

→ **codebase.md** (Components, Data Flow)

### Why PacketBuddy was designed this way

→ **architecture.md** (Design Decisions, Technology Stack)

### Adding a new feature

→ **codebase.md** (Development Tasks)  
→ **architecture.md** (Component Architecture)

### Performance issues

→ **architecture.md** (Performance Optimizations)  
→ **quick-reference.md** (Configuration)

### Dashboard customization

→ **ui_standards.md** (Design Guidelines)  
→ **codebase.md** (Dashboard section)

### Historical context

→ **evolution.md** (Project History)

### Maintenance tasks

→ **maintenance_manual.md** (Operations Guide)

---

## 🚀 Getting Started as an AI Assistant

### Step 1: Understand the Basics

Read **quick-reference.md** first. This gives you:

- What PacketBuddy is
- Common issues and solutions
- Quick commands
- Recent changes

### Step 2: Deep Dive (If Needed)

For complex questions, consult:

- **codebase.md** for implementation details
- **architecture.md** for design rationale

### Step 3: Provide Accurate Help

- Always check recent changes (in quick-reference.md)
- Provide platform-specific commands
- Include verification steps
- Link to relevant documentation

---

## 📝 Key Information for AI Assistants

### Project Overview

- **Name:** PacketBuddy
- **Type:** Network usage monitoring tool
- **Platforms:** Windows, macOS, Linux
- **Language:** Python 3.11+
- **Framework:** FastAPI
- **Database:** SQLite (local) + NeonDB (optional cloud sync)
- **Dashboard:** Vanilla HTML/CSS/JS + Chart.js

### Core Functionality

1. Monitors network usage via `psutil`
2. Stores data in local SQLite database
3. Optionally syncs to NeonDB for multi-device tracking
4. Serves web dashboard on `http://127.0.0.1:7373`
5. Runs as background service (auto-starts on login)

### Recent Major Fix (2026-01-08)

**Windows Task Scheduler Issue:**

- **Problem:** Service worked from command prompt but not Task Scheduler
- **Cause:** Missing PYTHONPATH environment variable
- **Solution:** Created `run-service.bat` launcher script
- **Files:** See `docs/WINDOWS_FIX_SUMMARY.md`

### Common User Pain Points

1. **Windows:** Task Scheduler not starting service
2. **All Platforms:** Dashboard not loading (service not running)
3. **All Platforms:** Port 7373 already in use
4. **Windows:** Python not found / not in PATH

### Quick Fixes

```bash
# Check if service is running
curl http://127.0.0.1:7373/api/health

# Start service (Windows)
schtasks /run /tn "PacketBuddy"

# Start service (macOS)
launchctl kickstart -k gui/$(id -u)/com.packetbuddy.daemon

# Start service (Linux)
systemctl --user start packetbuddy.service
```

---

## 🎓 Best Practices for AI Assistants

### DO

✅ Check **quick-reference.md** first for common issues  
✅ Provide platform-specific commands  
✅ Include verification steps  
✅ Link to detailed documentation when needed  
✅ Mention recent changes if relevant  
✅ Provide complete, working solutions  

### DON'T

❌ Assume user's platform (always ask or provide all options)  
❌ Provide outdated information (check recent changes)  
❌ Skip verification steps  
❌ Overcomplicate simple issues  
❌ Ignore error messages user provides  

---

## 📂 Related Documentation

### In Root Directory

- **README.md** - Main user-facing documentation (LLM-friendly)
- **QUICKSTART.md** - Quick setup guide
- **CONTRIBUTING.md** - Contribution guidelines

### In docs/ Directory

- **WINDOWS_TASK_SCHEDULER_FIX.md** - Detailed Windows fix guide
- **WINDOWS_FIX_SUMMARY.md** - Quick summary of Windows fix

---

## 🔄 Keeping Documentation Updated

When helping users, if you notice:

- New common issues → Should be added to **quick-reference.md**
- Code changes → Should be reflected in **codebase.md**
- Design changes → Should be reflected in **architecture.md**
- UI changes → Should be reflected in **ui_standards.md**

Suggest to the user that they update the relevant documentation.

---

## 📞 Support Resources

- **GitHub:** [instax-dutta/packet-buddy](https://github.com/instax-dutta/packet-buddy)
- **Issues:** [GitHub Issues](https://github.com/instax-dutta/packet-buddy/issues)
- **Discussions:** [GitHub Discussions](https://github.com/instax-dutta/packet-buddy/discussions)

---

## 🎯 Success Metrics

When helping users, aim for:

- ✅ Issue resolved in <5 minutes
- ✅ User understands the solution
- ✅ Solution is sustainable (not a temporary workaround)
- ✅ User knows how to prevent the issue in future

---

**For AI Assistants:** This index helps you quickly find the right documentation for any user question. Start with quick-reference.md for most questions, and dive deeper into codebase.md or architecture.md as needed.

**Last Updated:** 2026-01-08 - Windows Task Scheduler fix and LLM-friendly documentation overhaul
