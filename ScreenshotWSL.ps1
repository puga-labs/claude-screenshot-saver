# ScreenshotWSL.ps1
# Enhanced tray application with auto-save mode toggle

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Hide PowerShell console window
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@
$consolePtr = [Win32]::GetConsoleWindow()
[Win32]::ShowWindow($consolePtr, 0) # 0 = SW_HIDE

# Global settings
$script:autoSaveEnabled = $false
$script:lastImageHash = ""

# Create notification icon
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:notifyIcon.Text = "Screenshot WSL - OFF"
$script:notifyIcon.Visible = $true

# Create simple icon (red/green circle)
function Create-Icon {
    param($color)
    $bitmap = New-Object System.Drawing.Bitmap 16, 16
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = 'AntiAlias'
    
    # Draw circle
    $brush = New-Object System.Drawing.SolidBrush $color
    $graphics.FillEllipse($brush, 1, 1, 14, 14)
    
    # Draw border
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), 1
    $graphics.DrawEllipse($pen, 1, 1, 14, 14)
    
    $graphics.Dispose()
    return [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
}

# Set initial icon
$script:iconOff = Create-Icon ([System.Drawing.Color]::Red)
$script:iconOn = Create-Icon ([System.Drawing.Color]::Green)
$script:notifyIcon.Icon = $script:iconOff

# Function to save screenshot
function Save-ScreenshotToWSL {
    if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
        $image = [System.Windows.Forms.Clipboard]::GetImage()
        
        if ($image) {
            try {
                # Settings
                $wslHome = (wsl.exe bash -c 'echo $HOME' 2>$null).Trim()
                $screenshotDir = "$wslHome/.screenshots"
                
                # Ensure directory exists
                wsl.exe bash -c "mkdir -p ~/.screenshots" 2>$null
                
                $windowsPath = (wsl.exe wslpath -w "$screenshotDir" 2>$null).Trim()
                
                # Generate filename and save
                $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss-fff"
                $filename = "screenshot_$timestamp.png"
                $filepath = Join-Path $windowsPath $filename
                $image.Save($filepath, [System.Drawing.Imaging.ImageFormat]::Png)
                
                # Copy WSL path to clipboard
                $wslPath = "$screenshotDir/$filename"
                [System.Windows.Forms.Clipboard]::SetText($wslPath)
                
                # Show balloon notification
                $script:notifyIcon.ShowBalloonTip(2000, "Screenshot Saved", $wslPath, [System.Windows.Forms.ToolTipIcon]::Info)
                
                return $true
            }
            catch {
                $script:notifyIcon.ShowBalloonTip(2000, "Error", $_.Exception.Message, [System.Windows.Forms.ToolTipIcon]::Error)
                return $false
            }
        }
    }
    return $false
}

# Function to monitor clipboard
function Start-ClipboardMonitor {
    Register-ObjectEvent -InputObject ([System.Windows.Forms.Clipboard]) -EventName 'ClipboardUpdate' -Action {
        if ($script:autoSaveEnabled) {
            if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
                # Calculate hash to avoid duplicates
                $image = [System.Windows.Forms.Clipboard]::GetImage()
                if ($image) {
                    $memoryStream = New-Object System.IO.MemoryStream
                    $image.Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)
                    $imageBytes = $memoryStream.ToArray()
                    $currentHash = [System.BitConverter]::ToString(
                        [System.Security.Cryptography.SHA256]::Create().ComputeHash($imageBytes)
                    )
                    $memoryStream.Dispose()
                    
                    if ($currentHash -ne $script:lastImageHash) {
                        $script:lastImageHash = $currentHash
                        Save-ScreenshotToWSL
                    }
                }
            }
        }
    }
}

# Timer for clipboard monitoring (fallback method)
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500
$timer.Add_Tick({
    if ($script:autoSaveEnabled) {
        if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
            $image = [System.Windows.Forms.Clipboard]::GetImage()
            if ($image) {
                $memoryStream = New-Object System.IO.MemoryStream
                $image.Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)
                $imageBytes = $memoryStream.ToArray()
                $currentHash = [System.BitConverter]::ToString(
                    [System.Security.Cryptography.SHA256]::Create().ComputeHash($imageBytes)
                )
                $memoryStream.Dispose()
                
                if ($currentHash -ne $script:lastImageHash) {
                    $script:lastImageHash = $currentHash
                    Save-ScreenshotToWSL
                }
            }
        }
    }
})
$timer.Start()

# Function to toggle auto-save
function Toggle-AutoSave {
    $script:autoSaveEnabled = -not $script:autoSaveEnabled
    
    if ($script:autoSaveEnabled) {
        $script:notifyIcon.Icon = $script:iconOn
        $script:notifyIcon.Text = "Screenshot WSL - ON"
        $script:notifyIcon.ShowBalloonTip(1000, "Auto-save ON", "Screenshots will be saved automatically", [System.Windows.Forms.ToolTipIcon]::Info)
    }
    else {
        $script:notifyIcon.Icon = $script:iconOff
        $script:notifyIcon.Text = "Screenshot WSL - OFF"
        $script:notifyIcon.ShowBalloonTip(1000, "Auto-save OFF", "Screenshots stay in clipboard", [System.Windows.Forms.ToolTipIcon]::Info)
    }
}

# Function to open screenshots folder
function Open-ScreenshotsFolder {
    try {
        $wslHome = (wsl.exe bash -c 'echo $HOME' 2>$null).Trim()
        $screenshotDir = "$wslHome/.screenshots"
        $windowsPath = (wsl.exe wslpath -w "$screenshotDir" 2>$null).Trim()
        
        if (Test-Path $windowsPath) {
            Start-Process explorer.exe -ArgumentList $windowsPath
        }
        else {
            $script:notifyIcon.ShowBalloonTip(2000, "Error", "Screenshots folder not found", [System.Windows.Forms.ToolTipIcon]::Error)
        }
    }
    catch {
        $script:notifyIcon.ShowBalloonTip(2000, "Error", $_.Exception.Message, [System.Windows.Forms.ToolTipIcon]::Error)
    }
}

# Function to clear all screenshots
function Clear-Screenshots {
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Delete all screenshots?`nThis cannot be undone!", 
        "Confirm Delete", 
        [System.Windows.Forms.MessageBoxButtons]::YesNo, 
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            wsl.exe bash -c "rm -f ~/.screenshots/*.png" 2>$null
            $script:notifyIcon.ShowBalloonTip(2000, "Cleared", "All screenshots deleted", [System.Windows.Forms.ToolTipIcon]::Info)
        }
        catch {
            $script:notifyIcon.ShowBalloonTip(2000, "Error", $_.Exception.Message, [System.Windows.Forms.ToolTipIcon]::Error)
        }
    }
}

# Create context menu
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

# Toggle item
$toggleItem = New-Object System.Windows.Forms.ToolStripMenuItem
$toggleItem.Text = "Auto-save: OFF"
$toggleItem.Add_Click({ 
    Toggle-AutoSave
    if ($script:autoSaveEnabled) {
        $toggleItem.Text = "Auto-save: ON"
        $toggleItem.Checked = $true
    }
    else {
        $toggleItem.Text = "Auto-save: OFF"
        $toggleItem.Checked = $false
    }
})
$contextMenu.Items.Add($toggleItem)

$contextMenu.Items.Add("-") # Separator

# Manual save
$contextMenu.Items.Add("Save Screenshot Now", $null, {
    if (Save-ScreenshotToWSL) {
        # Success notification already shown in function
    }
    else {
        $script:notifyIcon.ShowBalloonTip(2000, "No Image", "No screenshot in clipboard", [System.Windows.Forms.ToolTipIcon]::Warning)
    }
})

# Open folder
$contextMenu.Items.Add("Open Screenshots Folder", $null, {
    Open-ScreenshotsFolder
})

# Clear screenshots
$contextMenu.Items.Add("Clear All Screenshots", $null, {
    Clear-Screenshots
})

$contextMenu.Items.Add("-") # Separator

# Exit
$contextMenu.Items.Add("Exit", $null, {
    $timer.Stop()
    $timer.Dispose()
    $script:notifyIcon.Visible = $false
    $script:notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$script:notifyIcon.ContextMenuStrip = $contextMenu

# Double-click toggles auto-save
$script:notifyIcon.Add_MouseDoubleClick({
    Toggle-AutoSave
    if ($script:autoSaveEnabled) {
        $toggleItem.Text = "Auto-save: ON"
        $toggleItem.Checked = $true
    }
    else {
        $toggleItem.Text = "Auto-save: OFF"
        $toggleItem.Checked = $false
    }
})

# Show initial tooltip
$script:notifyIcon.ShowBalloonTip(3000, "Screenshot WSL", "Right-click for menu`nDouble-click to toggle auto-save", [System.Windows.Forms.ToolTipIcon]::Info)

# Create application context and run
$appContext = New-Object System.Windows.Forms.ApplicationContext
[System.Windows.Forms.Application]::Run($appContext)