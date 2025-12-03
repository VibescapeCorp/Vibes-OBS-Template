# Package Your Existing OBS Setup - Complete Export Guide

You've already created your perfect setup. Now let's package it so users get EXACTLY what you have!

---

## 📦 What You're Exporting

Since you already have:
- ✅ Horizontal scene configured
- ✅ Vertical scene configured (Aitum Vertical)
- ✅ Recording settings optimized
- ✅ Everything tested and working

We'll export ALL of it!

---

## 🚀 PART 1: Export Your Complete Setup

### Step 1: Export Scene Collection

1. **Scene Collection menu → Export**
2. Choose location (e.g., Desktop)
3. Name it: `vibes-tutorial-template.json`

**This exports:**
- All your scenes (horizontal + vertical)
- All sources (Desktop, Webcam, Mic)
- All filters and positioning
- Scene structure
- Source settings

### Step 2: Export Profile (Recording Settings)

1. **Profile menu → Export**
2. Choose location (same as scene collection)
3. Name it: `vibes-recording-profile.zip`

**This exports:**
- Recording quality settings
- Encoder settings (NVENC/x264/etc)
- Audio settings
- Output settings
- Video resolution/FPS
- All your optimized settings!

### Step 3: Export Aitum Vertical Settings

**Aitum Vertical stores settings separately!**

**Windows:**
```
C:\Users\[YourName]\AppData\Roaming\aitum-vertical\
```

**Mac:**
```
~/Library/Application Support/aitum-vertical/
```

Look for:
- `config.json` - Main Aitum settings
- `layouts/` folder - Your vertical layouts

Copy these files to include in your package.

### Step 4: Note Your Script Settings

Write down your zoom script settings:
```
Zoom Duration: 2000ms
Zoom Factor: 1.5x
Min Click Distance: 100px
Stay Zoomed While Typing: YES
Follow Text Caret: YES
```

We'll include these in the README.

---

## 📁 PART 2: Create Distribution Package

### Package Structure:

```
vibes-obs-complete-template/
├── README.md
├── QUICK-START.md
├── LICENSE
├── install-windows.bat (enhanced)
├── install-mac.sh (enhanced)
│
├── obs-files/
│   ├── vibes-tutorial-template.json (scene collection)
│   └── vibes-recording-profile.zip (profile)
│
├── scripts/
│   └── obs-zoom-typing-working.lua
│
├── aitum-vertical/ (optional - requires plugin)
│   ├── config.json
│   └── layouts/
│       └── vibes-vertical.json
│
└── screenshots/
    ├── horizontal-scene.png
    └── vertical-scene.png
```

---

## 🔧 PART 3: Create Enhanced Installers

### Enhanced Windows Installer (install-windows.bat)

```batch
@echo off
:: Vibes OBS Complete Template Installer
:: Installs scene collection, profile, scripts, and Aitum settings

color 0A
echo ================================================================
echo    Vibes OBS Complete Template Installer
echo ================================================================
echo.

:: Check OBS installation
if not exist "%APPDATA%\obs-studio" (
    echo [ERROR] OBS Studio not found!
    echo Please install OBS Studio from: https://obsproject.com/
    pause
    exit /b 1
)

echo [OK] OBS Studio found!
echo.

:: Create directories
echo [INFO] Creating directories...
if not exist "%APPDATA%\obs-studio\basic\scenes" mkdir "%APPDATA%\obs-studio\basic\scenes"
if not exist "%APPDATA%\obs-studio\basic\profiles" mkdir "%APPDATA%\obs-studio\basic\profiles"
if not exist "%APPDATA%\obs-studio\scripts" mkdir "%APPDATA%\obs-studio\scripts"
echo [OK] Directories ready
echo.

:: Install Scene Collection
echo [INFO] Installing scene collection...
if exist "obs-files\vibes-tutorial-template.json" (
    copy /Y "obs-files\vibes-tutorial-template.json" "%APPDATA%\obs-studio\basic\scenes\" >nul
    echo [OK] Scene collection installed
) else (
    echo [WARNING] Scene collection not found
)
echo.

:: Install Profile
echo [INFO] Installing recording profile...
if exist "obs-files\vibes-recording-profile.zip" (
    :: Extract profile ZIP to profiles folder
    powershell -command "Expand-Archive -Path 'obs-files\vibes-recording-profile.zip' -DestinationPath '%APPDATA%\obs-studio\basic\profiles\' -Force"
    echo [OK] Recording profile installed
) else (
    echo [WARNING] Recording profile not found
)
echo.

:: Install Zoom Script
echo [INFO] Installing zoom script...
if exist "scripts\obs-zoom-typing-working.lua" (
    copy /Y "scripts\obs-zoom-typing-working.lua" "%APPDATA%\obs-studio\scripts\" >nul
    echo [OK] Zoom script installed
) else (
    echo [WARNING] Zoom script not found
)
echo.

:: Install Aitum Vertical Settings (optional)
echo [INFO] Checking for Aitum Vertical settings...
if exist "aitum-vertical\config.json" (
    if exist "%APPDATA%\aitum-vertical" (
        echo [INFO] Installing Aitum Vertical settings...
        copy /Y "aitum-vertical\config.json" "%APPDATA%\aitum-vertical\" >nul
        if exist "aitum-vertical\layouts" (
            xcopy /Y /E /I "aitum-vertical\layouts\*" "%APPDATA%\aitum-vertical\layouts\" >nul
        )
        echo [OK] Aitum Vertical settings installed
    ) else (
        echo [INFO] Aitum Vertical not installed - skipping settings
        echo       Install from: https://aitum.tv/download/vertical/
    )
) else (
    echo [INFO] No Aitum Vertical settings to install
)
echo.

:: Done!
echo ================================================================
echo    Installation Complete!
echo ================================================================
echo.
echo What was installed:
echo   - Scene Collection: vibes-tutorial-template
echo   - Recording Profile: vibes-recording-profile
echo   - Zoom Script: obs-zoom-typing-working.lua
echo   - Aitum Settings: (if plugin installed)
echo.
echo Next steps:
echo.
echo 1. Open OBS Studio
echo.
echo 2. Select Scene Collection:
echo    Scene Collection menu ^> vibes-tutorial-template
echo.
echo 3. Select Profile:
echo    Profile menu ^> vibes-recording-profile
echo.
echo 4. Load Script:
echo    Tools ^> Scripts ^> Check that obs-zoom-typing-working.lua
echo    is loaded and enabled
echo.
echo 5. Configure your display:
echo    Right-click "Desktop" source ^> Properties ^> Select monitor
echo.
echo 6. (Optional) If using Aitum Vertical:
echo    View ^> Docks ^> Aitum Vertical
echo    Your vertical layout is already configured!
echo.
echo 7. Start Recording!
echo.
echo ================================================================
echo.
pause
```

### Enhanced Mac Installer (install-mac.sh)

```bash
#!/bin/bash
# Vibes OBS Complete Template Installer for Mac

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================================================"
echo "   Vibes OBS Complete Template Installer for Mac"
echo "================================================================"
echo ""

# Check OBS installation
OBS_PATH=~/Library/Application\ Support/obs-studio
if [ ! -d "$OBS_PATH" ]; then
    echo -e "${RED}[ERROR]${NC} OBS Studio not found!"
    echo "Please install OBS Studio from: https://obsproject.com/"
    exit 1
fi

echo -e "${GREEN}[OK]${NC} OBS Studio found!"
echo ""

# Create directories
echo -e "${BLUE}[INFO]${NC} Creating directories..."
mkdir -p "$OBS_PATH/basic/scenes"
mkdir -p "$OBS_PATH/basic/profiles"
mkdir -p "$OBS_PATH/scripts"
echo -e "${GREEN}[OK]${NC} Directories ready"
echo ""

# Install Scene Collection
echo -e "${BLUE}[INFO]${NC} Installing scene collection..."
if [ -f "obs-files/vibes-tutorial-template.json" ]; then
    cp "obs-files/vibes-tutorial-template.json" "$OBS_PATH/basic/scenes/"
    echo -e "${GREEN}[OK]${NC} Scene collection installed"
else
    echo -e "${YELLOW}[WARNING]${NC} Scene collection not found"
fi
echo ""

# Install Profile
echo -e "${BLUE}[INFO]${NC} Installing recording profile..."
if [ -f "obs-files/vibes-recording-profile.zip" ]; then
    unzip -o "obs-files/vibes-recording-profile.zip" -d "$OBS_PATH/basic/profiles/" > /dev/null 2>&1
    echo -e "${GREEN}[OK]${NC} Recording profile installed"
else
    echo -e "${YELLOW}[WARNING]${NC} Recording profile not found"
fi
echo ""

# Install Zoom Script
echo -e "${BLUE}[INFO]${NC} Installing zoom script..."
if [ -f "scripts/obs-zoom-typing-working.lua" ]; then
    cp "scripts/obs-zoom-typing-working.lua" "$OBS_PATH/scripts/"
    echo -e "${GREEN}[OK]${NC} Zoom script installed"
else
    echo -e "${YELLOW}[WARNING]${NC} Zoom script not found"
fi
echo ""

# Install Aitum Vertical Settings (optional)
echo -e "${BLUE}[INFO]${NC} Checking for Aitum Vertical settings..."
AITUM_PATH=~/Library/Application\ Support/aitum-vertical
if [ -f "aitum-vertical/config.json" ]; then
    if [ -d "$AITUM_PATH" ]; then
        echo -e "${BLUE}[INFO]${NC} Installing Aitum Vertical settings..."
        cp "aitum-vertical/config.json" "$AITUM_PATH/"
        if [ -d "aitum-vertical/layouts" ]; then
            cp -r "aitum-vertical/layouts/"* "$AITUM_PATH/layouts/" 2>/dev/null
        fi
        echo -e "${GREEN}[OK]${NC} Aitum Vertical settings installed"
    else
        echo -e "${BLUE}[INFO]${NC} Aitum Vertical not installed - skipping settings"
        echo "      Install from: https://aitum.tv/download/vertical/"
    fi
else
    echo -e "${BLUE}[INFO]${NC} No Aitum Vertical settings to install"
fi
echo ""

# Done!
echo "================================================================"
echo "   Installation Complete!"
echo "================================================================"
echo ""
echo "What was installed:"
echo "  - Scene Collection: vibes-tutorial-template"
echo "  - Recording Profile: vibes-recording-profile"
echo "  - Zoom Script: obs-zoom-typing-working.lua"
echo "  - Aitum Settings: (if plugin installed)"
echo ""
echo "Next steps:"
echo ""
echo "1. Open OBS Studio"
echo ""
echo "2. Select Scene Collection:"
echo "   Scene Collection menu > vibes-tutorial-template"
echo ""
echo "3. Select Profile:"
echo "   Profile menu > vibes-recording-profile"
echo ""
echo "4. Load Script:"
echo "   Tools > Scripts > Check that obs-zoom-typing-working.lua"
echo "   is loaded and enabled"
echo ""
echo "5. Configure your display:"
echo "   Right-click 'Desktop' source > Properties > Select monitor"
echo ""
echo "6. (Optional) If using Aitum Vertical:"
echo "   View > Docks > Aitum Vertical"
echo "   Your vertical layout is already configured!"
echo ""
echo "7. Start Recording!"
echo ""
echo "================================================================"
echo ""
echo "Note: Typing detection doesn't work on Mac, but auto-zoom does!"
echo ""
```

---

## 📝 PART 4: Create Comprehensive README

### README.md (Enhanced)

```markdown
# Vibes Complete Recording Template for OBS

Professional tutorial recording setup with pre-configured horizontal + vertical scenes.

## ✨ What You Get

This is the EXACT setup used for Vibes tutorial recording:

- ✅ **Pre-configured horizontal scene** (1920x1080)
- ✅ **Pre-configured vertical scene** (1080x1920) 
- ✅ **Optimized recording settings** (quality, bitrate, encoder)
- ✅ **Auto-zoom on clicks** (no hotkeys needed!)
- ✅ **Smart typing detection** (Windows - stays zoomed while typing)
- ✅ **Aitum Vertical integration** (record both formats simultaneously)

## 🎯 Requirements

**Required:**
- OBS Studio 30+ - [Download](https://obsproject.com/)
- Windows 10+ or macOS 10.15+

**Optional (for vertical video):**
- Aitum Vertical plugin - [Download](https://aitum.tv/download/vertical/)

## 🚀 Installation (2 Minutes)

### Automatic Installation (Recommended)

**Windows:**
1. Extract the ZIP file
2. Double-click `install-windows.bat`
3. Open OBS Studio
4. Everything is already configured!

**Mac:**
1. Extract the ZIP file
2. Open Terminal in the extracted folder
3. Run: `sh install-mac.sh`
4. Open OBS Studio
5. Everything is already configured!

### Manual Installation

If the installer doesn't work:

1. **Import Scene Collection:**
   - OBS → Scene Collection → Import
   - Select `obs-files/vibes-tutorial-template.json`

2. **Import Profile:**
   - OBS → Profile → Import
   - Select `obs-files/vibes-recording-profile.zip`

3. **Load Script:**
   - OBS → Tools → Scripts → Click [+]
   - Select `scripts/obs-zoom-typing-working.lua`

4. **Configure Display:**
   - Right-click "Desktop" source → Properties
   - Select your monitor → OK

## 🎬 First Recording

1. **Open OBS Studio**
2. **Select the template:**
   - Scene Collection: `vibes-tutorial-template`
   - Profile: `vibes-recording-profile`
3. **Configure your display:**
   - Right-click "Desktop" source → Properties → Select monitor
4. **Click Start Recording**
5. **Use your app normally** - zoom happens automatically!
6. **Click Stop Recording**

Your video is saved in your Videos folder!

## 🎯 What Each Scene Does

### Horizontal Scene (1920x1080)
Perfect for:
- YouTube tutorials
- Desktop software demos
- Website walkthroughs

**Sources:**
- Desktop (full screen with auto-zoom)
- Webcam (bottom-right corner)
- Microphone (audio)

### Vertical Scene (1080x1920)
Perfect for:
- TikTok videos
- Instagram Reels
- YouTube Shorts

**Requires:** Aitum Vertical plugin

**Sources:**
- Desktop (center, cropped for vertical)
- Webcam (top or bottom)
- Microphone (audio)

## ⚙️ Recording Settings (Pre-configured)

Your template comes with optimized settings:

**Video:**
- Resolution: 1920x1080 (horizontal) / 1080x1920 (vertical)
- FPS: 30 (smooth, good file size)
- Encoder: Hardware encoding (NVENC/VT when available)
- Bitrate: 12000 Kbps (high quality)

**Audio:**
- Sample Rate: 48 kHz
- Bitrate: 192 kbps
- Format: AAC

**Output:**
- Format: MP4
- Location: Videos folder

## 🔧 Zoom Script Settings (Pre-configured)

The auto-zoom feature is already configured:

**Current Settings:**
- Zoom on left click: ✅ YES
- Zoom duration: 2000ms (2 seconds)
- Zoom factor: 1.5x
- Stay zoomed while typing: ✅ YES (Windows)
- Follow text caret: ✅ YES (Windows)

**To adjust:**
1. Tools → Scripts
2. Select `obs-zoom-typing-working.lua`
3. Modify settings as desired

## 🎥 Recording with Aitum Vertical

If you installed Aitum Vertical:

1. **View → Docks → Aitum Vertical**
2. **Both canvases appear** (horizontal + vertical)
3. **Click Start Recording**
4. **Get TWO videos automatically:**
   - `recording_horizontal.mp4` (1920x1080)
   - `recording_vertical.mp4` (1080x1920)

Record once, get both formats! 🎉

## 🎓 Tips for Great Recordings

1. **Clean your desktop** - Close unnecessary apps
2. **Disable notifications** - Use Do Not Disturb mode
3. **Test first** - Record 30 seconds to verify
4. **Check audio levels** - Speak and watch the meter
5. **Good lighting** - If using webcam
6. **Plan your demo** - Know what you'll show

## 🔧 Customization

### Reposition Webcam
1. Click webcam source
2. Drag to desired location
3. Resize with corner handles

### Change Zoom Duration
1. Tools → Scripts → obs-zoom-typing-working.lua
2. Zoom Duration: 2000ms → change to desired value
3. Click "Reload Scripts"

### Adjust Recording Quality
1. Settings → Output
2. Video Bitrate: 12000 → change as needed
   - 8000 = Good quality, smaller files
   - 12000 = High quality (current)
   - 20000 = Maximum quality, larger files

### Change Recording Location
1. Settings → Output
2. Recording Path: Browse to desired folder

## 🔍 Troubleshooting

### Zoom doesn't work
- Check: Tools → Scripts → "Enable Auto-Zoom" is ON
- Check: Zoom Source is set to "Desktop"
- Check: Using Display Capture (not Window Capture)

### Black screen on Desktop
- Right-click Desktop source → Properties
- Re-select your display → OK
- If still black, try different display mode

### No audio
- Check: Microphone shows levels in OBS mixer
- Check: Settings → Audio → Mic/Aux is selected
- Check: Microphone isn't muted

### Aitum Vertical not working
- Install plugin: https://aitum.tv/download/vertical/
- Restart OBS after installing
- View → Docks → Aitum Vertical

### Profile settings not applied
- Profile menu → Select "vibes-recording-profile"
- If not in list: Profile → Import → select ZIP file

## 🌐 Platform Differences

| Feature | Windows | Mac |
|---------|---------|-----|
| Auto-zoom on click | ✅ Full | ✅ Full |
| Stays zoomed while typing | ✅ Yes | ❌ No* |
| Follows text caret | ✅ Yes | ❌ No* |
| Aitum Vertical | ✅ Yes | ✅ Yes |
| Hardware encoding | ✅ NVENC/AMD | ✅ VideoToolbox |

*Mac limitation: Typing detection uses Windows-specific APIs

## 📊 File Sizes (10-minute recording)

With default settings (12000 Kbps):
- Horizontal (1920x1080): ~900 MB
- Vertical (1080x1920): ~900 MB
- Both: ~1.8 GB total

## 📞 Support

Need help?
- Email: support@gotvibes.app
- Discord: [Your Discord link]
- GitHub Issues: [Your GitHub repo]

## 📄 License

MIT License - Free to use and modify

## 🎉 You're Ready!

Everything is pre-configured and ready to go:
1. Open OBS
2. Select the scene collection
3. Start recording
4. Zoom happens automatically!

**Enjoy creating amazing tutorials!** 🚀

---

Made with ❤️ by Vibescape Corp for the Vibes community
```

---

## 📸 PART 5: Add Screenshots

Take these screenshots to include:

1. **horizontal-scene.png**
   - Your horizontal scene in OBS
   - Show sources panel with all sources
   - Show the layout

2. **vertical-scene.png**
   - Your vertical scene setup
   - Aitum Vertical panel visible
   - Both canvases side-by-side

3. **script-settings.png**
   - Tools → Scripts window
   - Show zoom script loaded
   - Show settings configured

4. **final-recording.png**
   - Show recording in progress
   - Display capture visible
   - Webcam visible
   - Green "Recording" indicator

---

## 📦 PART 6: Final Package

Your complete distribution folder:

```
vibes-obs-complete-template/
├── README.md (comprehensive guide)
├── QUICK-START.md
├── LICENSE
├── install-windows.bat (enhanced installer)
├── install-mac.sh (enhanced installer)
│
├── obs-files/
│   ├── vibes-tutorial-template.json (YOUR scene collection)
│   └── vibes-recording-profile.zip (YOUR profile export)
│
├── scripts/
│   └── obs-zoom-typing-working.lua
│
├── aitum-vertical/ (if you use it)
│   ├── config.json (YOUR Aitum config)
│   └── layouts/
│       └── vibes-vertical.json (YOUR vertical layout)
│
└── screenshots/
    ├── horizontal-scene.png
    ├── vertical-scene.png
    ├── script-settings.png
    └── final-recording.png
```

---

## ✅ Final Checklist

Before distributing:

- [ ] Exported scene collection from OBS
- [ ] Exported profile from OBS
- [ ] Copied Aitum Vertical settings (if using)
- [ ] Created enhanced installers
- [ ] Updated README with your exact settings
- [ ] Took screenshots of your setup
- [ ] Tested installer on fresh OBS install
- [ ] Created ZIP file
- [ ] Tested ZIP extracts correctly

---

## 🚀 Users Will Get EXACTLY Your Setup

When users run the installer:
1. ✅ Your scenes appear in OBS
2. ✅ Your recording settings are applied
3. ✅ Zoom script is loaded
4. ✅ Aitum Vertical layouts configured
5. ✅ Everything ready to record!

**They literally just open OBS and see YOUR setup!** 🎉

---

## 📏 Package Size

Expected size of your complete package:

```
Scene collection (.json):        ~10-20 KB
Profile (.zip):                  ~5-10 KB
Zoom script (.lua):              ~24 KB
Aitum config:                    ~2-5 KB
README & docs:                   ~20-30 KB
Screenshots (4 images):          ~1-2 MB
Installer scripts:               ~5 KB
------------------------
Total ZIP file:                  ~2-3 MB
```

Still very lightweight!

---

## 🎉 Done!

Your users will:
1. Download ZIP
2. Run installer
3. Open OBS
4. See YOUR EXACT setup
5. Start recording immediately!

**No configuration needed - they get your complete setup instantly!** 🚀
