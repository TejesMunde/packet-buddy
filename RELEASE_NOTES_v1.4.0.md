# PacketBuddy v1.4.0 - Export Overhaul & Peak Speed Fix

## Release Date: January 22, 2026

---

## 🎉 Major Improvements

### 1. **Fixed Peak Speed Counter Reset Issue** ✅
**Problem:** Peak speed counter was resetting to 0 every time the dashboard was refreshed.

**Root Cause:** The JavaScript variable `peakSpeed` was initialized to 0 on every page load, and the sync logic used `Math.max()` which didn't properly initialize from server data.

**Solution:** Modified `loadTodayStats()` in `dashboard/app.js` to directly set `peakSpeed` from the server's stored value instead of using `Math.max()`. Now the peak speed persists correctly across page refreshes.

**Files Changed:**
- `dashboard/app.js` (lines 173-182)

---

### 2. **Comprehensive Export System Overhaul** 🚀

#### New Export Formats

##### **HTML Year Wrap-Up Export** 🎉
- Beautiful, shareable HTML report with gradient backgrounds
- Spotify-style year-end summary
- Includes:
  - Current year's total data usage
  - All-time statistics
  - Monthly breakdown with cards
  - Peak speed records
  - Most active day highlights
  - Fun comparisons (DVD/CD equivalents)
- Fully styled with glassmorphism effects
- Print-friendly CSS
- Access via: `/api/export?format=html` or "Year Wrap-Up" button

##### **Enhanced JSON Export** 📊
- Comprehensive structured data including:
  - Device metadata
  - Tracking period information
  - Summary statistics (totals, averages, peak speeds)
  - Monthly summaries with peak speeds
  - Daily data with peak speeds
  - Human-readable formatted values
- Perfect for programmatic analysis
- Access via: `/api/export?format=json`

##### **Improved CSV Export** 📥
- Now includes peak speed data for each day
- Columns: date, bytes_sent, bytes_received, total_bytes, peak_speed
- Uses daily aggregates instead of raw logs for better performance
- Access via: `/api/export?format=csv`

##### **Enhanced LLM-Friendly Export** 🤖
- Completely rewritten markdown report
- Includes:
  - Current year highlights section
  - All-time statistics
  - Records & achievements
  - Speed records
  - Fun comparisons (DVDs, CDs, HD movies)
  - Monthly breakdown with peak speeds
  - Recent 30-day activity with peak speeds
  - AI analysis context and suggested prompts
  - Structured JSON summary
- Perfect for creating year wrap-ups with ChatGPT/Claude
- Access via: `/api/export/llm`

---

### 3. **New Storage Methods** 💾

Added comprehensive data retrieval methods to support enhanced exports:

- `get_all_daily_aggregates()` - Get all daily data with peak speeds
- `get_monthly_summaries()` - Get monthly totals with peak speeds and days tracked
- `get_overall_peak_speed()` - Get the highest speed ever recorded
- `get_tracking_stats()` - Get first/last tracked dates and total days

**Files Changed:**
- `src/core/storage.py` (added 60+ lines of new methods)

---

### 4. **Dashboard Enhancements** 🎨

- Added new "Year Wrap-Up" button to control panel
- Button triggers beautiful HTML export
- Positioned between "Export CSV" and "LLM Export"

**Files Changed:**
- `dashboard/index.html` (added new button)
- `dashboard/app.js` (added event listener)

---

## 📋 Technical Details

### API Endpoints

| Endpoint | Format | Description |
|----------|--------|-------------|
| `/api/export?format=csv` | CSV | Daily data with peak speeds |
| `/api/export?format=json` | JSON | Comprehensive structured data |
| `/api/export?format=html` | HTML | Beautiful year wrap-up report |
| `/api/export?format=llm` | Markdown | LLM-friendly analysis report |
| `/api/export/llm` | Markdown | Same as above (direct endpoint) |

### Database Schema
No schema changes required - all new features use existing tables:
- `daily_aggregates` (already has peak_speed column from v1.3.2)
- `usage_logs` (for raw data)
- `monthly_aggregates` (for monthly summaries)

---

## 🐛 Bug Fixes

1. **Peak Speed Reset**: Fixed dashboard peak speed resetting on page refresh
2. **Double fetchone() Call**: Fixed bug in `get_tracking_stats()` that called `fetchone()` twice

---

## 📁 Files Modified

### Core Files
- `src/core/storage.py` - Added 5 new methods for comprehensive data retrieval
- `src/api/routes.py` - Complete export system rewrite (400+ lines)

### Dashboard Files
- `dashboard/app.js` - Fixed peak speed sync logic, added HTML export button handler
- `dashboard/index.html` - Added "Year Wrap-Up" button

### Version Files
- `VERSION` - Updated to 1.4.0

---

## 🎯 User Benefits

### For Year-End Summaries
- **One-Click Year Wrap-Up**: Beautiful HTML report perfect for sharing
- **Comprehensive Statistics**: All the data needed for internet usage analysis
- **LLM-Ready**: Export optimized for creating custom wrap-ups with AI

### For Data Analysis
- **Rich JSON Export**: Structured data with all statistics
- **Peak Speed Tracking**: Now included in all exports
- **Monthly Summaries**: Easy to analyze trends over time

### For Reliability
- **Persistent Peak Speed**: No more losing peak speed data on refresh
- **Accurate Tracking**: All statistics properly calculated and stored

---

## 🚀 Usage Examples

### Creating a Year Wrap-Up

1. **Quick HTML Report**:
   - Click "Year Wrap-Up" button in dashboard
   - Opens beautiful HTML report in browser
   - Save or print for sharing

2. **AI-Powered Wrap-Up**:
   - Click "LLM Export" button
   - Copy markdown to ChatGPT/Claude
   - Use prompt: "Create a fun, Spotify-style year wrap-up based on this data"

3. **Custom Analysis**:
   - Export JSON format
   - Use in Python/JavaScript for custom visualizations
   - All data includes peak speeds and human-readable formats

---

## 🔄 Migration Notes

- **No database migration needed** - All new features use existing schema
- **Backward compatible** - Old export endpoints still work
- **No config changes required** - Everything works out of the box

---

## 📊 Export Format Comparison

| Feature | CSV | JSON | HTML | LLM |
|---------|-----|------|------|-----|
| Peak Speeds | ✅ | ✅ | ✅ | ✅ |
| Monthly Summary | ❌ | ✅ | ✅ | ✅ |
| Human Readable | ❌ | ✅ | ✅ | ✅ |
| Visual Design | ❌ | ❌ | ✅ | ❌ |
| AI-Optimized | ❌ | ❌ | ❌ | ✅ |
| Shareable | ✅ | ❌ | ✅ | ✅ |
| Programmatic | ✅ | ✅ | ❌ | ❌ |

---

## 🎨 HTML Export Features

The new HTML export creates a stunning year wrap-up with:

- **Gradient Background**: Purple-to-blue gradient with glassmorphism
- **Responsive Grid**: Adapts to different screen sizes
- **Animated Cards**: Hover effects on stat cards
- **Monthly Breakdown**: Grid of monthly cards with emojis
- **Highlights Section**: Most active day, ratios, fun comparisons
- **Print-Friendly**: Clean black-on-white when printed
- **No Dependencies**: Pure HTML/CSS, works offline

---

## 💡 Future Enhancements

Potential additions for future versions:
- PDF export option
- Chart/graph generation in exports
- Custom date range exports
- Comparison between time periods
- Email export scheduling

---

## 🙏 Acknowledgments

This release addresses the user's core motivation for creating PacketBuddy: creating comprehensive year-end summaries of internet usage. The export system is now robust, flexible, and produces beautifully formatted data perfect for sharing and analysis.

---

**Version**: 1.4.0  
**Release Date**: January 22, 2026  
**Previous Version**: 1.3.3
