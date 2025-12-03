#!/bin/bash
# Vibes OBS Complete Template Installer for Mac
# Installs scene collection, profile, scripts, and Aitum settings
# Version 1.0

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear
echo "================================================================"
echo "   Vibes OBS Complete Template Installer for Mac"
echo "   Installing your complete recording setup..."
echo "================================================================"
echo ""

# Check if OBS is installed
OBS_PATH=~/Library/Application\ Support/obs-studio
if [ ! -d "$OBS_PATH" ]; then
    echo -e "${RED}[ERROR]${NC} OBS Studio not found!"
    echo ""
    echo "Please install OBS Studio first from:"
    echo "https://obsproject.com/"
    echo ""
    echo "After installing OBS, run this installer again."
    echo ""
    exit 1
fi

echo -e "${GREEN}[OK]${NC} OBS Studio installation found!"
echo ""

# Check if OBS is running
if pgrep -x "OBS" > /dev/null; then
    echo -e "${YELLOW}[WARNING]${NC} OBS Studio is currently running!"
    echo ""
    echo "Please CLOSE OBS Studio before continuing."
    echo "This installer needs to modify OBS files."
    echo ""
    read -p "Press Enter after closing OBS..."
    echo ""
    
    # Check again
    if pgrep -x "OBS" > /dev/null; then
        echo -e "${RED}[ERROR]${NC} OBS is still running. Please close it and try again."
        exit 1
    fi
    
    echo -e "${GREEN}[OK]${NC} OBS is now closed. Continuing installation..."
    echo ""
fi

# Create necessary directories
echo -e "${BLUE}[INFO]${NC} Preparing OBS directories..."
mkdir -p "$OBS_PATH/basic/scenes"
mkdir -p "$OBS_PATH/basic/profiles"
mkdir -p "$OBS_PATH/scripts"
echo -e "${GREEN}[OK]${NC} Directories ready"
echo ""

# Install Scene Collection
echo -e "${CYAN}[STEP 1/5]${NC} Installing scene collection..."
if [ -f "obs-files/vibes-tutorial-template.json" ]; then
    cp "obs-files/vibes-tutorial-template.json" "$OBS_PATH/basic/scenes/"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${NC} Scene collection installed: vibes-tutorial-template"
    else
        echo -e "${RED}[ERROR]${NC} Failed to copy scene collection"
    fi
else
    echo -e "${YELLOW}[WARNING]${NC} Scene collection file not found: obs-files/vibes-tutorial-template.json"
fi
echo ""

# Install Profile
echo -e "${CYAN}[STEP 2/5]${NC} Installing recording profile..."
if [ -f "obs-files/vibes-recording-profile.zip" ]; then
    unzip -o "obs-files/vibes-recording-profile.zip" -d "$OBS_PATH/basic/profiles/" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${NC} Recording profile installed: vibes-recording-profile"
    else
        echo -e "${RED}[ERROR]${NC} Failed to extract profile"
    fi
else
    echo -e "${YELLOW}[WARNING]${NC} Profile file not found: obs-files/vibes-recording-profile.zip"
fi
echo ""

# Install Zoom Script
echo -e "${CYAN}[STEP 3/5]${NC} Installing auto-zoom script..."
if [ -f "scripts/obs-zoom-typing-working.lua" ]; then
    cp "scripts/obs-zoom-typing-working.lua" "$OBS_PATH/scripts/"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[OK]${NC} Zoom script installed: obs-zoom-typing-working.lua"
    else
        echo -e "${RED}[ERROR]${NC} Failed to copy zoom script"
    fi
else
    echo -e "${YELLOW}[WARNING]${NC} Zoom script not found: scripts/obs-zoom-typing-working.lua"
fi
echo ""

# Check for Aitum Vertical
echo -e "${CYAN}[STEP 4/5]${NC} Checking for Aitum Vertical plugin..."
AITUM_PATH=~/Library/Application\ Support/aitum-vertical
if [ -d "$AITUM_PATH" ]; then
    echo -e "${GREEN}[OK]${NC} Aitum Vertical plugin detected"
    echo ""
    
    # Install Aitum settings if they exist
    if [ -f "aitum-vertical/config.json" ]; then
        echo -e "${BLUE}[INFO]${NC} Installing Aitum Vertical settings..."
        cp "aitum-vertical/config.json" "$AITUM_PATH/"
        
        if [ -d "aitum-vertical/layouts" ]; then
            mkdir -p "$AITUM_PATH/layouts"
            cp -r "aitum-vertical/layouts/"* "$AITUM_PATH/layouts/" 2>/dev/null
        fi
        echo -e "${GREEN}[OK]${NC} Aitum Vertical settings installed"
    else
        echo -e "${BLUE}[INFO]${NC} No Aitum settings to install"
    fi
else
    echo -e "${BLUE}[INFO]${NC} Aitum Vertical plugin not installed"
    echo ""
    echo "If you want to record vertical videos:"
    echo "1. Download Aitum Vertical from: https://aitum.tv/download/vertical/"
    echo "2. Install the plugin"
    echo "3. Run this installer again to apply vertical settings"
fi
echo ""

# Configure script autoload
echo -e "${CYAN}[STEP 5/5]${NC} Configuring script autoload..."
if [ -f "scripts/obs-zoom-typing-working.lua" ]; then
    if [ ! -f "$OBS_PATH/global.ini" ]; then
        echo -e "${BLUE}[INFO]${NC} Creating global.ini for script autoload"
        cat > "$OBS_PATH/global.ini" << EOF
[ScriptTool]
Scripts=obs-zoom-typing-working.lua
EOF
    fi
    echo -e "${GREEN}[OK]${NC} Script configured to autoload"
else
    echo -e "${BLUE}[INFO]${NC} Skipping script autoload configuration"
fi
echo ""

# Installation complete
clear
echo "================================================================"
echo "   Installation Complete!"
echo "================================================================"
echo ""
echo "What was installed:"
echo -e "  ${GREEN}[✓]${NC} Scene Collection: vibes-tutorial-template"
echo -e "  ${GREEN}[✓]${NC} Recording Profile: vibes-recording-profile"
echo -e "  ${GREEN}[✓]${NC} Auto-Zoom Script: obs-zoom-typing-working.lua"
if [ -d "$AITUM_PATH" ]; then
    echo -e "  ${GREEN}[✓]${NC} Aitum Vertical: Settings configured"
else
    echo -e "  ${YELLOW}[ ]${NC} Aitum Vertical: Not installed"
fi
echo ""
echo "================================================================"
echo "   Quick Start Guide"
echo "================================================================"
echo ""
echo "STEP 1: Open OBS Studio"
echo ""
echo "STEP 2: Select your template"
echo "   - Scene Collection menu > vibes-tutorial-template"
echo "   - Profile menu > vibes-recording-profile"
echo ""
echo "STEP 3: Configure your display"
echo "   - Right-click 'Desktop' source > Properties"
echo "   - Select your monitor from dropdown"
echo "   - Click OK"
echo ""
echo "STEP 4: (Optional) Configure webcam"
echo "   - Right-click 'Webcam' source > Properties"
echo "   - Select your camera"
echo "   - Click OK"
echo ""
echo "STEP 5: Verify zoom script"
echo "   - Tools > Scripts"
echo "   - Check that obs-zoom-typing-working.lua is loaded"
echo "   - Make sure 'Enable Auto-Zoom on Click' is checked"
echo "   - Set 'Zoom Source' to 'Desktop'"
echo ""
echo "STEP 6: Start Recording!"
echo "   - Click 'Start Recording'"
echo "   - Use your app - zoom happens automatically"
echo "   - Click 'Stop Recording' when done"
echo ""
if [ ! -d "$AITUM_PATH" ]; then
    echo "================================================================"
    echo "   Optional: Install Aitum Vertical for Vertical Videos"
    echo "================================================================"
    echo ""
    echo "To record both horizontal and vertical simultaneously:"
    echo "1. Download: https://aitum.tv/download/vertical/"
    echo "2. Install and restart OBS"
    echo "3. View > Docks > Aitum Vertical"
    echo "4. Run this installer again to apply settings"
    echo ""
fi
echo "================================================================"
echo ""
echo -e "${YELLOW}Note:${NC} On Mac, typing detection doesn't work due to API limitations."
echo "However, auto-zoom on clicks works perfectly!"
echo ""
echo "================================================================"
echo ""
echo "Your recording setup is ready!"
echo ""
