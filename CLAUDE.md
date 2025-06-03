# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Code Screenshot Saver is a Windows tray application that automatically saves screenshots to WSL/Windows directories and copies the file path to clipboard. The application consists of:

- **PowerShell script** (`ClaudeCodeScreenshotSaver.ps1`) - Main application logic with system tray integration
- **VBScript launchers** - Silent execution wrappers to hide console windows
- **Installer/Uninstaller** - VBScript-based setup and removal utilities

## Key Architecture Concepts

### Single Instance Management
The application uses a mutex (`Global\ClaudeCodeScreenshotSaver_Mutex`) to prevent multiple instances from running simultaneously (ClaudeCodeScreenshotSaver.ps1:8-17).

### Dual Path Support
The application handles both WSL paths (e.g., `/home/user/.screenshots`) and Windows paths (e.g., `C:\Screenshots`). Path conversion is handled by the `Get-WindowsPath` function (ClaudeCodeScreenshotSaver.ps1:105-124) which:
- Uses `wsl.exe wslpath` for WSL-to-Windows path conversion
- Creates directories automatically in both environments

### Clipboard Monitoring
A timer checks the clipboard every 500ms for new images when auto-save is enabled. Image uniqueness is verified using SHA256 hash comparison to prevent duplicate saves (ClaudeCodeScreenshotSaver.ps1:173-196).

### Configuration Storage
Settings are stored in `%APPDATA%\ClaudeCodeScreenshotSaver\config.json` with automatic creation and fallback to defaults (ClaudeCodeScreenshotSaver.ps1:45-72).

## Common Development Tasks

### Testing the Application
```powershell
# Run directly (shows console)
powershell.exe -ExecutionPolicy Bypass -File ClaudeCodeScreenshotSaver.ps1

# Run silently (production mode)
.\Start.vbs
```

### Modifying System Tray Icons
Icons are created dynamically as colored circles (red/green) using System.Drawing (ClaudeCodeScreenshotSaver.ps1:79-102). To modify icon appearance, edit the `Create-Icon` function.

### Adding New Menu Items
Context menu items are defined starting at line 319 in ClaudeCodeScreenshotSaver.ps1. Follow the existing pattern:
```powershell
$contextMenu.Items.Add("Menu Text", $null, {
    # Action code here
})
```

### Debugging WSL Path Issues
Check WSL availability and path conversion:
```powershell
wsl.exe --version
wsl.exe wslpath -w "/home/user/.screenshots"
```

## Installation Process

The installer (Install.vbs):
1. Verifies WSL is installed
2. Gets WSL username via `wsl.exe whoami`
3. Creates config directory in %APPDATA%
4. Creates startup shortcut in Windows Startup folder
5. Launches the application

## Recent Security and Performance Updates

The application has been enhanced with:
1. **Proper resource disposal** - All GDI+ objects, images, and streams are disposed in try-finally blocks
2. **Path sanitization** - `Get-SanitizedPath` function prevents command injection in WSL commands
3. **Improved error handling** - Better error messages and fallback behavior
4. **Performance optimization** - Timer only runs when auto-save is enabled
5. **Icon handle cleanup** - DestroyIcon is called for unmanaged icon handles

## Testing Considerations

When testing changes:
- Kill existing PowerShell processes before restarting
- Check system tray for orphaned icons
- Verify clipboard monitoring with Print Screen or Win+Shift+S
- Test both WSL and Windows path formats
- Ensure single instance prevention works correctly
- Monitor memory usage for leaks during extended use