@echo off
REM This file is kept for compatibility
REM Use InstallSilent.vbs for silent installation
start "" "%~dp0InstallSilent.vbs"
exit
echo Installing Screenshot WSL Tray Tool...
echo.

REM Create startup shortcut
set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "shortcutPath=%startupFolder%\ScreenshotWSL.lnk"

powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%shortcutPath%'); $Shortcut.TargetPath = '%~dp0Start.vbs'; $Shortcut.WorkingDirectory = '%~dp0'; $Shortcut.IconLocation = 'imageres.dll,76'; $Shortcut.Description = 'Screenshot WSL - Save screenshots to WSL with path in clipboard'; $Shortcut.Save()"

REM Start the application
start "" "%~dp0Start.vbs"

echo.
echo Installation complete!
echo.
echo Look for the icon in system tray (near clock)
echo.
echo Usage:
echo - Icon color: RED = OFF, GREEN = ON
echo - Double-click tray icon: Toggle auto-save mode
echo - Right-click tray icon: Full menu with options
echo.
echo Menu options:
echo - Auto-save ON/OFF: Toggle automatic screenshot saving
echo - Save Screenshot Now: Manual save from clipboard
echo - Open Screenshots Folder: Quick access to saved files
echo - Clear All Screenshots: Delete all saved screenshots
echo.
echo The tool will start automatically with Windows.
echo.
pause