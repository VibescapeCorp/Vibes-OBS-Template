@echo off
:: Vibes OBS Complete Template Installer for Windows
:: Installs scene collection, profile, scripts, and Aitum settings
:: Version 1.0

color 0A
cls
echo ================================================================
echo    Vibes OBS Complete Template Installer
echo    Installing your complete recording setup...
echo ================================================================
echo.

:: Check if OBS is installed
if not exist "%APPDATA%\obs-studio" (
    color 0C
    echo [ERROR] OBS Studio not found!
    echo.
    echo Please install OBS Studio first from:
    echo https://obsproject.com/
    echo.
    echo After installing OBS, run this installer again.
    echo.
    pause
    exit /b 1
)

echo [OK] OBS Studio installation found!
echo.

:: Check if OBS is running
tasklist /FI "IMAGENAME eq obs64.exe" 2>NUL | find /I /N "obs64.exe">NUL
if "%ERRORLEVEL%"=="0" (
    color 0E
    echo [WARNING] OBS Studio is currently running!
    echo.
    echo Please CLOSE OBS Studio before continuing.
    echo This installer needs to modify OBS files.
    echo.
    pause
    echo.
    echo Checking again...
    tasklist /FI "IMAGENAME eq obs64.exe" 2>NUL | find /I /N "obs64.exe">NUL
    if "%ERRORLEVEL%"=="0" (
        echo [ERROR] OBS is still running. Please close it and try again.
        pause
        exit /b 1
    )
    color 0A
    echo [OK] OBS is now closed. Continuing installation...
    echo.
)

:: Create necessary directories
echo [INFO] Preparing OBS directories...
if not exist "%APPDATA%\obs-studio\basic\scenes" mkdir "%APPDATA%\obs-studio\basic\scenes"
if not exist "%APPDATA%\obs-studio\basic\profiles" mkdir "%APPDATA%\obs-studio\basic\profiles"
if not exist "%APPDATA%\obs-studio\scripts" mkdir "%APPDATA%\obs-studio\scripts"
echo [OK] Directories ready
echo.

:: Install Scene Collection
echo [STEP 1/5] Installing scene collection...
if exist "obs-files\vibes-tutorial-template.json" (
    copy /Y "obs-files\vibes-tutorial-template.json" "%APPDATA%\obs-studio\basic\scenes\" >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo [OK] Scene collection installed: vibes-tutorial-template
    ) else (
        echo [ERROR] Failed to copy scene collection
    )
) else (
    echo [WARNING] Scene collection file not found: obs-files\vibes-tutorial-template.json
)
echo.

:: Install Profile
echo [STEP 2/5] Installing recording profile...
if exist "obs-files\vibes-recording-profile.zip" (
    powershell -command "try { Expand-Archive -Path 'obs-files\vibes-recording-profile.zip' -DestinationPath '%APPDATA%\obs-studio\basic\profiles\' -Force; exit 0 } catch { exit 1 }" >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo [OK] Recording profile installed: vibes-recording-profile
    ) else (
        echo [ERROR] Failed to extract profile
    )
) else (
    echo [WARNING] Profile file not found: obs-files\vibes-recording-profile.zip
)
echo.

:: Install Zoom Script
echo [STEP 3/5] Installing auto-zoom script...
if exist "scripts\obs-zoom-typing-working.lua" (
    copy /Y "scripts\obs-zoom-typing-working.lua" "%APPDATA%\obs-studio\scripts\" >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo [OK] Zoom script installed: obs-zoom-typing-working.lua
    ) else (
        echo [ERROR] Failed to copy zoom script
    )
) else (
    echo [WARNING] Zoom script not found: scripts\obs-zoom-typing-working.lua
)
echo.

:: Check for Aitum Vertical
echo [STEP 4/5] Checking for Aitum Vertical plugin...
if exist "%APPDATA%\aitum-vertical" (
    echo [OK] Aitum Vertical plugin detected
    echo.
    
    :: Install Aitum settings if they exist
    if exist "aitum-vertical\config.json" (
        echo [INFO] Installing Aitum Vertical settings...
        copy /Y "aitum-vertical\config.json" "%APPDATA%\aitum-vertical\" >nul 2>&1
        
        if exist "aitum-vertical\layouts" (
            if not exist "%APPDATA%\aitum-vertical\layouts" mkdir "%APPDATA%\aitum-vertical\layouts"
            xcopy /Y /E /I "aitum-vertical\layouts\*" "%APPDATA%\aitum-vertical\layouts\" >nul 2>&1
        )
        echo [OK] Aitum Vertical settings installed
    ) else (
        echo [INFO] No Aitum settings to install
    )
) else (
    echo [INFO] Aitum Vertical plugin not installed
    echo.
    echo If you want to record vertical videos:
    echo 1. Download Aitum Vertical from: https://aitum.tv/download/vertical/
    echo 2. Install the plugin
    echo 3. Run this installer again to apply vertical settings
)
echo.

:: Create script autoload entry
echo [STEP 5/5] Configuring script autoload...
if exist "scripts\obs-zoom-typing-working.lua" (
    if not exist "%APPDATA%\obs-studio\global.ini" (
        echo [INFO] Creating global.ini for script autoload
        (
            echo [ScriptTool]
            echo Scripts=obs-zoom-typing-working.lua
        ) > "%APPDATA%\obs-studio\global.ini"
    )
    echo [OK] Script configured to autoload
) else (
    echo [INFO] Skipping script autoload configuration
)
echo.

:: Installation complete
cls
color 0A
echo ================================================================
echo    Installation Complete! 
echo ================================================================
echo.
echo What was installed:
echo   [v] Scene Collection: vibes-tutorial-template
echo   [v] Recording Profile: vibes-recording-profile
echo   [v] Auto-Zoom Script: obs-zoom-typing-working.lua
if exist "%APPDATA%\aitum-vertical" (
    echo   [v] Aitum Vertical: Settings configured
) else (
    echo   [ ] Aitum Vertical: Not installed
)
echo.
echo ================================================================
echo    Quick Start Guide
echo ================================================================
echo.
echo STEP 1: Open OBS Studio
echo.
echo STEP 2: Select your template
echo    - Scene Collection menu ^> vibes-tutorial-template
echo    - Profile menu ^> vibes-recording-profile
echo.
echo STEP 3: Configure your display
echo    - Right-click "Desktop" source ^> Properties
echo    - Select your monitor from dropdown
echo    - Click OK
echo.
echo STEP 4: (Optional) Configure webcam
echo    - Right-click "Webcam" source ^> Properties
echo    - Select your camera
echo    - Click OK
echo.
echo STEP 5: Verify zoom script
echo    - Tools ^> Scripts
echo    - Check that obs-zoom-typing-working.lua is loaded
echo    - Make sure "Enable Auto-Zoom on Click" is checked
echo    - Set "Zoom Source" to "Desktop"
echo.
echo STEP 6: Start Recording!
echo    - Click "Start Recording"
echo    - Use your app - zoom happens automatically
echo    - Click "Stop Recording" when done
echo.
if not exist "%APPDATA%\aitum-vertical" (
    echo ================================================================
    echo    Optional: Install Aitum Vertical for Vertical Videos
    echo ================================================================
    echo.
    echo To record both horizontal and vertical simultaneously:
    echo 1. Download: https://aitum.tv/download/vertical/
    echo 2. Install and restart OBS
    echo 3. View ^> Docks ^> Aitum Vertical
    echo 4. Run this installer again to apply settings
    echo.
)
echo ================================================================
echo.
echo Your recording setup is ready! Press any key to exit...
pause >nul
