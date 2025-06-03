# Claude Code Screenshot Saver

A lightweight Windows tray application that automatically saves screenshots from clipboard to WSL/Windows directories and copies the file path to clipboard for easy sharing.

## Features

- **Auto-save Mode**: Automatically saves screenshots when they appear in clipboard
- **Manual Save**: Save screenshots on demand from the tray menu
- **Dual Path Support**: Works with both WSL paths (`/home/user/screenshots`) and Windows paths (`C:\Screenshots`)
- **Smart Clipboard**: Replaces screenshot with file path in clipboard for easy pasting
- **Single Instance**: Prevents multiple instances from running simultaneously
- **Minimal UI**: Lives quietly in system tray with color-coded status (Red = OFF, Green = ON)

## Installation

1. **Prerequisites**:
   - Windows 10/11
   - WSL (Windows Subsystem for Linux) installed
   - PowerShell 5.0 or higher

2. **Install**:
   - Download the project files
   - Run `Install.vbs`
   - Choose your preferred screenshot folder (WSL or Windows path)
   - The application will start automatically

3. **The installer will**:
   - Create a startup shortcut (auto-start with Windows)
   - Create configuration file in `%APPDATA%\ClaudeCodeScreenshotSaver`
   - Start the application in system tray

## Usage

### Tray Icon
- **Red Circle**: Auto-save OFF - Screenshots remain in clipboard
- **Green Circle**: Auto-save ON - Screenshots are automatically saved

### Controls
- **Double-click tray icon**: Toggle auto-save mode ON/OFF
- **Right-click tray icon**: Open context menu

### Menu Options
1. **Auto-save: ON/OFF** - Toggle automatic screenshot saving
2. **Save Screenshot Now** - Manually save current clipboard image
3. **Open Screenshots Folder** - Open the folder containing saved screenshots
4. **Change Folder...** - Change where screenshots are saved
5. **Clear All Screenshots** - Delete all saved screenshots (with confirmation)
6. **Exit** - Close the application

### Workflow

#### Auto-save Mode (Green icon)
1. Take a screenshot (Win+Shift+S, PrintScreen, etc.)
2. Screenshot is automatically saved to your chosen folder
3. File path is copied to clipboard (e.g., `/home/user/.screenshots/screenshot_2025-06-02_15-30-45-123.png`)
4. Paste the path anywhere (Claude, terminal, chat, etc.)

#### Manual Mode (Red icon)
1. Take a screenshot
2. Screenshot stays in clipboard as image
3. Right-click tray icon → "Save Screenshot Now" when needed
4. File path replaces image in clipboard

## File Structure

```
Claude Code Screenshot Saver/
├── ClaudeCodeScreenshotSaver.ps1   # Main application script
├── Start.vbs                        # Silent launcher (no console window)
├── Install.vbs                      # Installer script
├── Uninstall.vbs                    # Uninstaller (removes all traces)
├── Launch Claude Code Screenshot Saver.vbs  # Quick launcher
└── README.md                        # This file
```

## Configuration

Settings are stored in: `%APPDATA%\ClaudeCodeScreenshotSaver\config.json`

Example configuration:
```json
{
    "screenshotDir": "/home/username/.screenshots"
}
```

## Changing Screenshot Folder

1. Right-click tray icon → "Change Folder..."
2. Enter new path:
   - WSL format: `/home/username/my-screenshots`
   - Windows format: `C:\Users\Username\Pictures\Screenshots`
3. Click OK

## Uninstallation

1. Run `Uninstall.vbs`
2. This will:
   - Stop the application
   - Remove startup shortcut
   - Delete configuration folder
   - Remove all application traces

## Troubleshooting

### Application won't start
- Check if WSL is installed: Run `wsl --version` in Command Prompt
- Ensure PowerShell execution policy allows scripts

### Screenshots not saving
- Verify the screenshot folder exists and is writable
- Check if WSL is running (for WSL paths)
- Try changing to a Windows path if WSL path fails

### Multiple tray icons
- The application prevents multiple instances
- If you see the "already running" message, check your system tray
- Restart your computer if icons persist

### Path not copying to clipboard
- Ensure you have an image in clipboard before saving
- Try manual save from menu to test functionality

## Tips

- Use WSL paths for seamless integration with Claude and terminal workflows
- The timestamp format ensures unique filenames and easy sorting
- Screenshots are saved as PNG for best quality
- Original screenshot remains in `.screenshots` folder even after clearing from menu

## License

Free to use and modify.