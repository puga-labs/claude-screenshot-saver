@echo off
echo Uninstalling Screenshot WSL Tray Tool...
echo.

REM Kill PowerShell processes running our script
powershell -Command "Get-Process powershell | Where-Object {$_.MainWindowTitle -like '*ScreenshotWSL*'} | Stop-Process -Force" 2>nul

REM Remove startup shortcut
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ScreenshotWSL.lnk" 2>nul

echo.
echo Uninstall complete!
echo.
echo Note: If the tray icon is still visible, it will disappear after restart.
echo.
pause