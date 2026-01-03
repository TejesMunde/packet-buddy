#!/bin/bash

# PacketBuddy One-Time Automated Setup for macOS
# This script does EVERYTHING - just run it once!

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fancy header
clear
echo -e "${PURPLE}"
echo "═══════════════════════════════════════════════════════"
echo "           📊 PacketBuddy Setup Wizard"
echo "═══════════════════════════════════════════════════════"
echo -e "${NC}"
echo ""
echo -e "${CYAN}Ultra-lightweight network usage tracker${NC}"
echo -e "${CYAN}This will take about 2 minutes...${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo -e "${BLUE}📁 Project directory: $PROJECT_DIR${NC}"
echo ""

# Step 1: Check Python
echo -e "${YELLOW}[1/8]${NC} Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python 3 not found${NC}"
    echo ""
    echo "Please install Python 3.11+ from:"
    echo "  https://www.python.org/downloads/"
    echo ""
    echo "Or use Homebrew: brew install python@3.11"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo -e "${GREEN}✓ Python $PYTHON_VERSION found${NC}"
echo ""

# Step 2: Create virtual environment
echo -e "${YELLOW}[2/8]${NC} Setting up Python virtual environment..."
cd "$PROJECT_DIR"

if [ -d "venv" ]; then
    echo -e "${YELLOW}→ Virtual environment already exists, skipping${NC}"
else
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
fi
echo ""

# Step 3: Install dependencies
echo -e "${YELLOW}[3/8]${NC} Installing dependencies..."
source venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt
echo -e "${GREEN}✓ All dependencies installed${NC}"
echo ""

# Step 4: Create config directory
echo -e "${YELLOW}[4/8]${NC} Creating configuration directory..."
CONFIG_DIR="$HOME/.packetbuddy"
mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_DIR/config.toml" ]; then
    cp config.example.toml "$CONFIG_DIR/config.toml"
    echo -e "${GREEN}✓ Configuration file created${NC}"
else
    echo -e "${YELLOW}→ Configuration file already exists${NC}"
fi
echo ""

# Step 5: Optional NeonDB setup
echo -e "${YELLOW}[5/8]${NC} Cloud sync configuration..."
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Multi-Device Cloud Sync (Optional)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Do you want to enable cloud sync with NeonDB?"
echo "This allows you to track multiple devices (Mac + PC) in one database."
echo ""
echo -e "${GREEN}Benefits:${NC}"
echo "  • Track all your devices in one place"
echo "  • Free tier supports 10GB (enough for years)"
echo "  • Automatic cloud backup"
echo ""
echo -e "${YELLOW}Note:${NC} If skipped, PacketBuddy works perfectly with local-only tracking."
echo ""
read -p "Enable cloud sync? (y/n) [n]: " -n 1 -r
echo ""

NEON_URL=""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}📝 Please enter your NeonDB connection string:${NC}"
    echo -e "${CYAN}(Format: postgresql://user:pass@host.neon.tech/db?sslmode=require)${NC}"
    echo ""
    echo "Don't have one? Get it free at: https://neon.tech"
    echo ""
    read -p "NeonDB URL: " NEON_URL
    
    if [ ! -z "$NEON_URL" ]; then
        # Add to shell profile
        SHELL_PROFILE="$HOME/.zshrc"
        if [ -f "$HOME/.bash_profile" ]; then
            SHELL_PROFILE="$HOME/.bash_profile"
        fi
        
        # Remove old entry if exists
        if grep -q "NEON_DB_URL" "$SHELL_PROFILE" 2>/dev/null; then
            sed -i '' '/NEON_DB_URL/d' "$SHELL_PROFILE"
        fi
        
        # Add new entry
        echo "" >> "$SHELL_PROFILE"
        echo "# PacketBuddy NeonDB Connection" >> "$SHELL_PROFILE"
        echo "export NEON_DB_URL=\"$NEON_URL\"" >> "$SHELL_PROFILE"
        
        export NEON_DB_URL="$NEON_URL"
        echo -e "${GREEN}✓ NeonDB configured (will be active on next terminal session)${NC}"
    fi
else
    echo -e "${YELLOW}→ Skipping cloud sync (local-only mode)${NC}"
fi
echo ""

# Step 6: Initialize database
echo -e "${YELLOW}[6/8]${NC} Initializing database..."
python3 -c "from src.core.storage import storage; storage.get_device_id()" >/dev/null 2>&1
echo -e "${GREEN}✓ Database initialized${NC}"
echo ""

# Step 7: Create LaunchAgent
echo -e "${YELLOW}[7/8]${NC} Setting up auto-start service..."
PLIST_FILE="$HOME/Library/LaunchAgents/com.packetbuddy.plist"
mkdir -p "$HOME/Library/LaunchAgents"

# Get absolute path to Python in venv
VENV_PYTHON="$PROJECT_DIR/venv/bin/python"

# Create plist with correct paths
cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.packetbuddy.daemon</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$VENV_PYTHON</string>
        <string>-m</string>
        <string>src.api.server</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>$PROJECT_DIR</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
    </dict>
    
    <key>StandardOutPath</key>
    <string>$CONFIG_DIR/stdout.log</string>
    
    <key>StandardErrorPath</key>
    <string>$CONFIG_DIR/stderr.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>NEON_DB_URL</key>
        <string>${NEON_URL}</string>
    </dict>
    
    <key>ThrottleInterval</key>
    <integer>10</integer>
    
    <key>ProcessType</key>
    <string>Background</string>
    
    <key>Nice</key>
    <integer>10</integer>
</dict>
</plist>
EOF

echo -e "${GREEN}✓ LaunchAgent created${NC}"

# Load the service
launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE"
echo -e "${GREEN}✓ Service started${NC}"
echo ""

# Step 8: Test the service
echo -e "${YELLOW}[8/8]${NC} Testing service..."
echo ""
echo -e "${CYAN}Waiting for service to start...${NC}"
sleep 5

SUCCESS=false
for i in {1..6}; do
    if curl -s http://127.0.0.1:7373/api/health > /dev/null 2>&1; then
        SUCCESS=true
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

if [ "$SUCCESS" = true ]; then
    echo -e "${GREEN}✓ Service is running!${NC}"
else
    echo -e "${RED}⚠ Service may need a moment to start${NC}"
    echo -e "${YELLOW}Check logs: tail -f $CONFIG_DIR/stderr.log${NC}"
fi
echo ""

# Step 9: Make CLI shortcut executable and create global command
chmod +x "$PROJECT_DIR/pb"

echo ""
echo -e "${YELLOW}[Bonus]${NC} Setting up global 'pb' command..."
echo ""
echo "To use 'pb' from anywhere (instead of cd-ing to project dir),"
echo "we need to create a symlink in /usr/local/bin"
echo ""
read -p "Create global 'pb' command? (y/n) [y]: " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "Creating symlink (requires sudo)..."
    if sudo ln -sf "$PROJECT_DIR/pb" /usr/local/bin/pb 2>/dev/null; then
        echo -e "${GREEN}✓ Global 'pb' command created${NC}"
        echo -e "${GREEN}  You can now use 'pb today' from anywhere!${NC}"
        PB_COMMAND="pb"
    else
        echo -e "${YELLOW}→ Could not create global command${NC}"
        echo -e "${YELLOW}  Use: cd $PROJECT_DIR && ./pb today${NC}"
        PB_COMMAND="cd $PROJECT_DIR && ./pb"
    fi
else
    echo -e "${YELLOW}→ Skipped global command setup${NC}"
    PB_COMMAND="cd $PROJECT_DIR && ./pb"
fi

# Final success message
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}           ✓ PacketBuddy Setup Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${PURPLE}🎉 Your network usage is now being tracked 24/7!${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Quick Start:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}📊 Dashboard:${NC}"
echo "   open http://127.0.0.1:7373/dashboard"
echo ""
echo -e "${GREEN}📱 CLI Commands:${NC}"
if [ "$PB_COMMAND" = "pb" ]; then
    echo "   pb today        # Today's usage"
    echo "   pb summary      # Lifetime stats"
    echo "   pb month        # Monthly breakdown"
    echo "   pb export       # Download data"
else
    echo "   cd $PROJECT_DIR"
    echo "   ./pb today      # Today's usage"
    echo "   ./pb summary    # Lifetime stats"
    echo "   ./pb month      # Monthly breakdown"
fi
echo ""
echo -e "${GREEN}📁 Data Location:${NC}"
echo "   Database: $CONFIG_DIR/packetbuddy.db"
echo "   Config:   $CONFIG_DIR/config.toml"
echo "   Logs:     $CONFIG_DIR/*.log"
echo ""
echo -e "${GREEN}🔧 Service Control:${NC}"
echo "   Start:   launchctl start com.packetbuddy.daemon"
echo "   Stop:    launchctl stop com.packetbuddy.daemon"
echo "   Restart: launchctl kickstart -k gui/\\$(id -u)/com.packetbuddy.daemon"
echo "   Logs:    tail -f $CONFIG_DIR/stdout.log"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 Tip:${NC} The service will automatically start on every boot!"
echo -e "${YELLOW}💡 Tip:${NC} Resource usage: ~30MB RAM, <0.5% CPU"
echo ""
echo -e "${PURPLE}Happy tracking! 🚀${NC}"
echo ""
