@echo off
echo Stopping all PowerShell processes...
taskkill /F /IM powershell.exe 2>nul
timeout /t 2 >nul

echo Starting Claude Code Screenshot Saver...
start "" /MIN wscript.exe "%~dp0Start.vbs"

echo Done! Check your system tray for the icon.
timeout /t 3 >nul