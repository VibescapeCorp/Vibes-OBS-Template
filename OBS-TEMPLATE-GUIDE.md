# OBS Template Creation Guide for Vibes Recording

## 📦 What Gets Saved in an OBS Template

OBS templates are called **Scene Collections**. They save:

✅ **Scenes** - All your scenes and layouts
✅ **Sources** - Webcam, Display Capture, etc.
✅ **Filters** - Crop filters, color correction, etc.
✅ **Scene structure** - Layout, positioning, sizing
✅ **Source settings** - Resolution, FPS, audio settings
✅ **Transitions** - Scene transitions, stingers

❌ **NOT Saved:**
- Scripts (need to be distributed separately)
- Plugins (users must install Aitum Vertical separately)
- Absolute file paths (users will need to relink sources)

---

## 🎬 Creating Your Template

### Step 1: Set Up Your Perfect Scene

#### Create Scene: "Vibes Tutorial - Horizontal"

**Sources (bottom to top):**

1. **Display Capture**
   - Name: `Desktop`
   - Capture: Full screen or specific display
   - Position: 0, 0
   - Size: 1920x1080 (fill canvas)

2. **Webcam** (optional)
   - Name: `Webcam`
   - Position: Bottom-right corner
   - Size: 360x640 (or 320x180 if horizontal webcam)
   - Add filter: Chroma Key (if using green screen)

3. **Microphone/Audio**
   - Name: `Mic/Aux`
   - Your USB mic or audio interface

**Important:** The Lua script will automatically add a crop filter to the Desktop source, so don't add one manually.

#### Scene Settings:
```
Canvas Resolution: 1920x1080
FPS: 30 or 60
Video Format: NV12 or I420
```

---

### Step 2: Set Up Aitum Vertical (If Using)

1. Install Aitum Vertical plugin
2. Enable in OBS: View → Docks → Aitum Vertical
3. Create vertical version:
   - Canvas: 1080x1920
   - Link to horizontal scene
   - Reposition webcam for vertical layout

**Note:** Users will need to install Aitum Vertical separately - it doesn't export with the scene collection.

---

### Step 3: Load the Zoom Script

1. OBS → Tools → Scripts
2. Click [+]
3. Select `obs-zoom-typing-working.lua`
4. Configure settings:
   ```
   ✅ Enable Auto-Zoom on Click: ON
   Zoom Source: Desktop
   Zoom on Left Click: YES
   Zoom Duration: 2000ms
   Min Click Distance: 100px
   
   ⌨️ Stay Zoomed While Typing: YES (Windows)
   Follow Text Caret: YES (Windows)
   Typing Timeout: 1000ms
   
   Zoom Factor: 1.5
   Zoom Animation Speed: 400ms
   ```

**Important:** Scripts don't export with Scene Collections - you'll need to package the script file separately.

---

### Step 4: Configure Recording Settings

#### Recording Settings (Settings → Output):
```
Output Mode: Advanced
Recording:
  Type: Standard
  Recording Path: [User's videos folder]
  Recording Format: mp4
  
  Video Encoder: 
    - Windows: NVIDIA NVENC H.264 (if you have NVIDIA GPU)
    - Mac: Apple VT H264 Hardware Encoder
    - Fallback: x264
  
  Video Bitrate: 12000 Kbps (1080p) or 20000 Kbps (higher quality)
  
  Audio Encoder: AAC
  Audio Bitrate: 192 kbps
```

#### Video Settings (Settings → Video):
```
Base Resolution: 1920x1080
Output Resolution: 1920x1080
FPS: 30 or 60 (match your preference)
```

#### Audio Settings (Settings → Audio):
```
Sample Rate: 48 kHz
Channels: Stereo
```

---

### Step 5: Export Your Scene Collection

#### Method 1: Export Scene Collection (Recommended)

1. **Scene Collection → Export**
   ```
   OBS → Scene Collection → Export
   - Choose location
   - Saves as: [Name].json
   ```

2. **This exports:**
   - All scenes and sources
   - All filters and settings
   - Scene structure and positioning
   - Recording settings
   - Audio/Video settings

#### Method 2: Manual File Copy (Advanced)

OBS stores scene collections in:

**Windows:**
```
%APPDATA%\obs-studio\basic\scenes\[CollectionName].json
```

**Mac:**
```
~/Library/Application Support/obs-studio/basic/scenes/[CollectionName].json
```

**Linux:**
```
~/.config/obs-studio/basic/scenes/[CollectionName].json
```

---

## 📦 Package Your Template for Distribution

### Create Distribution Package:

```
Vibes-OBS-Template/
├── README.md (installation instructions)
├── obs-zoom-typing-working.lua (the script)
├── vibes-tutorial-template.json (scene collection)
└── screenshots/
    ├── final-setup.png
    └── scene-layout.png
```

---

### README.md Template:

```markdown
# Vibes Tutorial Recording Template for OBS

## What's Included

- Pre-configured scene for tutorial recording
- Auto-zoom on click functionality
- Perfect for software demonstrations
- Works with both horizontal and vertical recording

## Installation

### Step 1: Install OBS Studio

Download: https://obsproject.com/

### Step 2: Install Aitum Vertical (Optional - for vertical video)

Download: https://aitum.tv/download/vertical/

### Step 3: Import Scene Collection

1. Open OBS Studio
2. Scene Collection → Import
3. Select `vibes-tutorial-template.json`
4. Click "Import"

### Step 4: Install Zoom Script

1. OBS → Tools → Scripts
2. Click [+] button
3. Select `obs-zoom-typing-working.lua`
4. Script will load automatically

### Step 5: Configure Your Sources

1. Select "Vibes Tutorial - Horizontal" scene
2. Right-click "Desktop" source → Properties
3. Select your display/monitor
4. (Optional) Right-click "Webcam" source → Properties
5. Select your camera

### Step 6: Configure Zoom Script

1. OBS → Tools → Scripts
2. Select "obs-zoom-typing-working.lua"
3. Settings:
   - Zoom Source: Select "Desktop"
   - ✅ Enable Auto-Zoom on Click
   - Configure duration and sensitivity as desired

### Step 7: Start Recording!

1. Click "Start Recording" button
2. Use your application - zoom happens automatically on clicks
3. Click "Stop Recording" when done

## Recording Settings

Pre-configured for high-quality 1080p recording:
- Resolution: 1920x1080
- FPS: 30
- Format: MP4
- Codec: Hardware encoding (when available)

## Troubleshooting

**Script doesn't zoom:**
- Make sure "Desktop" source is selected in script settings
- Check "Enable Auto-Zoom on Click" is ON
- Verify you're using Display Capture (not Window Capture)

**Sources show black screen:**
- Right-click each source → Properties
- Re-select your display/camera

**Aitum Vertical not working:**
- Make sure plugin is installed
- Restart OBS after installing plugin
- Enable dock: View → Docks → Aitum Vertical

## Support

For issues or questions, visit: [your support link]
```

---

## 🚀 Distribution Methods

### Method 1: GitHub Repository (Recommended)

```bash
# Create repository
Vibes-OBS-Template/
├── README.md
├── LICENSE
├── obs-zoom-typing-working.lua
├── vibes-tutorial-template.json
└── screenshots/
```

Users download and follow README.

### Method 2: ZIP Download

Package everything in a ZIP file:
```
vibes-obs-template.zip
└── [all files from above]
```

Host on your website or GitHub releases.

### Method 3: Installer Script

Create a simple installer script:

**Windows (install.bat):**
```batch
@echo off
echo Installing Vibes OBS Template...

:: Copy script to OBS scripts folder
set OBS_SCRIPTS=%APPDATA%\obs-studio\scripts
if not exist "%OBS_SCRIPTS%" mkdir "%OBS_SCRIPTS%"
copy obs-zoom-typing-working.lua "%OBS_SCRIPTS%"

:: Copy scene collection
set OBS_SCENES=%APPDATA%\obs-studio\basic\scenes
if not exist "%OBS_SCENES%" mkdir "%OBS_SCENES%"
copy vibes-tutorial-template.json "%OBS_SCENES%"

echo Installation complete!
echo.
echo Next steps:
echo 1. Open OBS Studio
echo 2. Scene Collection → Select "vibes-tutorial-template"
echo 3. Tools → Scripts → Load "obs-zoom-typing-working.lua"
echo.
pause
```

**Mac (install.sh):**
```bash
#!/bin/bash
echo "Installing Vibes OBS Template..."

# Copy script
OBS_SCRIPTS=~/Library/Application\ Support/obs-studio/scripts
mkdir -p "$OBS_SCRIPTS"
cp obs-zoom-typing-working.lua "$OBS_SCRIPTS/"

# Copy scene collection
OBS_SCENES=~/Library/Application\ Support/obs-studio/basic/scenes
mkdir -p "$OBS_SCENES"
cp vibes-tutorial-template.json "$OBS_SCENES/"

echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Open OBS Studio"
echo "2. Scene Collection → Select 'vibes-tutorial-template'"
echo "3. Tools → Scripts → Load 'obs-zoom-typing-working.lua'"
```

---

## 📝 User Instructions Document

Create `QUICK-START.md`:

```markdown
# Vibes OBS Template - Quick Start

## 🎬 First Time Setup (5 minutes)

### 1. Install Required Software

**Install OBS Studio:**
- Download: https://obsproject.com/
- Install and launch

**Install Aitum Vertical (Optional - for vertical videos):**
- Download: https://aitum.tv/download/vertical/
- Restart OBS after installing

### 2. Import Template

1. Download and extract `vibes-obs-template.zip`
2. Open OBS Studio
3. **Scene Collection → Import**
4. Select `vibes-tutorial-template.json`
5. Template loads automatically!

### 3. Install Zoom Script

1. **Tools → Scripts**
2. Click **[+]** button
3. Select `obs-zoom-typing-working.lua`
4. In settings, set **Zoom Source: Desktop**
5. Check **✅ Enable Auto-Zoom on Click**

### 4. Configure Your Display

1. Right-click **Desktop** source → **Properties**
2. Select your monitor/display
3. Click **OK**

### 5. (Optional) Configure Webcam

1. Right-click **Webcam** source → **Properties**
2. Select your camera
3. Click **OK**
4. Drag to reposition if needed

## 🎥 Recording Your First Video

1. Click **Start Recording** (or press your hotkey)
2. Use your Vibes app normally
3. Clicks will automatically zoom - no hotkeys needed!
4. Click **Stop Recording** when done

**Your video is saved in:** Videos folder (or configured location)

## ⚙️ Customization

### Adjust Zoom Settings:

**Tools → Scripts → obs-zoom-typing-working.lua:**

```
Zoom Duration: How long zoom stays (2000ms default)
Zoom Factor: How much to zoom (1.5x default)
Min Click Distance: Minimum pixels between zooms (100px)
```

### Adjust Recording Quality:

**Settings → Output:**

```
Video Bitrate: 
  - 12000 Kbps = Good quality
  - 20000 Kbps = High quality
  - 30000 Kbps = Maximum quality
```

### Change Recording Location:

**Settings → Output → Recording Path**

## 🎓 Tips for Great Recordings

1. **Test first** - Do a 30-second test recording
2. **Clean desktop** - Close unnecessary windows
3. **Close notifications** - Enable Do Not Disturb
4. **Check audio** - Speak and watch audio meter
5. **Use Display Capture** - Not Window Capture

## 📊 What Each Source Does

- **Desktop** - Captures your screen (zoom happens here)
- **Webcam** - Shows you (optional)
- **Mic/Aux** - Records your voice

## 🔧 Troubleshooting

**Zoom doesn't work:**
- Tools → Scripts → Check "Enable Auto-Zoom" is ON
- Make sure "Desktop" is selected as Zoom Source

**Black screen:**
- Right-click Desktop source → Properties
- Re-select your display

**No audio:**
- Settings → Audio
- Check microphone is selected
- Verify it's not muted in OBS mixer

**Webcam doesn't show:**
- Right-click Webcam source → Properties
- Select your camera device

## 🎉 You're Ready!

Your template is configured and ready to record professional tutorial videos for Vibes!

**Recording workflow:**
1. Start Recording
2. Demo your app (zoom is automatic)
3. Stop Recording
4. Done!

Enjoy! 🚀
```

---

## 🎁 Bonus: Create Multiple Templates

You can create variations for different use cases:

### Template 1: "Vibes Tutorial - Software Demo"
- Full screen display capture
- Small webcam corner
- Auto-zoom enabled

### Template 2: "Vibes Tutorial - Full Face"
- Large webcam (50% screen)
- Display capture (50% screen)
- Auto-zoom on display only

### Template 3: "Vibes Tutorial - Screen Only"
- Full screen display
- No webcam
- Maximum space for software

Export each as separate scene collections.

---

## 📤 Hosting Your Template

### Option 1: GitHub

Create a repository:
```
https://github.com/yourname/vibes-obs-template
```

Users can clone or download ZIP.

### Option 2: Your Website

Host on Vibes website:
```
https://gotvibes.app/resources/obs-template/
```

Create a download page with:
- Template files
- Installation instructions
- Video tutorial
- Screenshots

### Option 3: Direct Download

Use a file host:
- Google Drive (public link)
- Dropbox (public link)
- Your own CDN

---

## 🎬 Creating a Video Tutorial

Record a quick setup video showing:

1. **Download** (0:00-0:30)
   - Where to download template
   - What's included

2. **Installation** (0:30-2:00)
   - Import scene collection
   - Load script
   - Configure display

3. **First Recording** (2:00-3:00)
   - Start recording
   - Show auto-zoom in action
   - Stop recording

4. **Customization** (3:00-4:00)
   - Adjust zoom settings
   - Change recording quality
   - Reposition webcam

Upload to YouTube and link in README.

---

## ✅ Pre-Distribution Checklist

Before sharing your template:

- [ ] Test import on fresh OBS install
- [ ] Verify all sources load correctly
- [ ] Test script works after import
- [ ] Check recording settings are optimal
- [ ] Create clear README with steps
- [ ] Add screenshots of final setup
- [ ] Test on Windows AND Mac (if possible)
- [ ] Include license file (MIT recommended)
- [ ] Add support contact info

---

## 🎉 Final Package Structure

```
vibes-obs-template/
├── README.md                           (Main instructions)
├── QUICK-START.md                      (Simple guide)
├── LICENSE                             (MIT license)
├── obs-zoom-typing-working.lua         (Zoom script)
├── vibes-tutorial-template.json        (Scene collection)
├── screenshots/
│   ├── 01-import-scene.png
│   ├── 02-load-script.png
│   ├── 03-final-setup.png
│   └── 04-recording.png
├── install-windows.bat                 (Optional: Windows installer)
└── install-mac.sh                      (Optional: Mac installer)
```

---

## 📊 What Users Need to Install

**Required:**
- OBS Studio (free) - https://obsproject.com/

**Optional:**
- Aitum Vertical (free) - for vertical videos
- Hardware GPU for encoding (NVIDIA/AMD/Intel)

**Included in template:**
- Scene collection (pre-configured)
- Zoom script (no additional install)

---

## 🚀 Summary

**Creating template:**
1. Set up perfect OBS scene
2. Configure zoom script
3. Export scene collection
4. Package with script file
5. Create installation guide

**Users get:**
- Pre-configured scenes
- Auto-zoom functionality
- Professional recording settings
- Easy setup (5 minutes)

**Distribution:**
- GitHub repository (best for open source)
- Website download (best for control)
- ZIP file (simplest for users)

Your Vibes users can now set up professional tutorial recording in minutes! 🎉
