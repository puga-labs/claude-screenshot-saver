# ClaudeCodeScreenshotSaver.ps1
# Enhanced tray application with single instance check and proper resource management

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Check for existing instance
$mutex = New-Object System.Threading.Mutex($false, "Global\ClaudeCodeScreenshotSaver_Mutex")
$hasHandle = $false
try {
    $hasHandle = $mutex.WaitOne(0, $false)
    if (-not $hasHandle) {
        [System.Windows.Forms.MessageBox]::Show(
            "Claude Code Screenshot Saver is already running!`nCheck your system tray.", 
            "Already Running", 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        exit
    }
}
catch {
    Write-Error "Failed to check for existing instance: $_"
    exit
}

# Hide PowerShell console window
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll")]
        public static extern bool DestroyIcon(IntPtr hIcon);
    }
"@
$consolePtr = [Win32]::GetConsoleWindow()
[Win32]::ShowWindow($consolePtr, 0) # 0 = SW_HIDE

# Global settings
$script:autoSaveEnabled = $false
$script:lastImageHash = ""
$script:configFile = "$env:APPDATA\ClaudeCodeScreenshotSaver\config.json"
$script:config = $null
$script:iconHandles = @()

# Default config
$defaultConfig = @{
    screenshotDir = "/home/$($env:USERNAME)/.screenshots"
}

# Load or create config
function Load-Config {
    $configDir = Split-Path $script:configFile -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    if (Test-Path $script:configFile) {
        try {
            $script:config = Get-Content $script:configFile | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to load config: $_. Using default config."
            $script:config = $defaultConfig
            Save-Config
        }
    }
    else {
        $script:config = $defaultConfig
        Save-Config
    }
}

function Save-Config {
    try {
        $script:config | ConvertTo-Json | Out-File $script:configFile -Force
    }
    catch {
        Write-Error "Failed to save config: $_"
    }
}

# Load config on start
Load-Config

# Create notification icon
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:notifyIcon.Text = "Claude Code Screenshot Saver - OFF"
$script:notifyIcon.Visible = $true

# Create simple icon (red/green circle) with proper resource management
function Create-Icon {
    param($color)
    
    $bitmap = $null
    $graphics = $null
    $brush = $null
    $pen = $null
    
    try {
        $bitmap = New-Object System.Drawing.Bitmap 16, 16
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.SmoothingMode = 'AntiAlias'
        
        # Draw circle
        $brush = New-Object System.Drawing.SolidBrush $color
        $graphics.FillEllipse($brush, 1, 1, 14, 14)
        
        # Draw border
        $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Black), 1
        $graphics.DrawEllipse($pen, 1, 1, 14, 14)
        
        $hicon = $bitmap.GetHicon()
        $script:iconHandles += $hicon
        $icon = [System.Drawing.Icon]::FromHandle($hicon)
        return $icon
    }
    finally {
        if ($pen) { $pen.Dispose() }
        if ($brush) { $brush.Dispose() }
        if ($graphics) { $graphics.Dispose() }
        if ($bitmap) { $bitmap.Dispose() }
    }
}

$script:iconOff = Create-Icon ([System.Drawing.Color]::Red)
$script:iconOn = Create-Icon ([System.Drawing.Color]::Green)
$script:notifyIcon.Icon = $script:iconOff

# Function to sanitize paths for shell execution
function Get-SanitizedPath {
    param($path)
    # Escape single quotes and other shell metacharacters
    return $path -replace "'", "'\''"
}

# Function to get Windows path for saving
function Get-WindowsPath {
    $dir = $script:config.screenshotDir
    
    try {
        if ($dir -like "/*") {
            # Check if WSL is available
            $wslCheck = & wsl.exe --version 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "WSL is not available or not running"
            }
            
            # WSL path
            $sanitizedDir = Get-SanitizedPath $dir
            $windowsPath = (& wsl.exe wslpath -w "$sanitizedDir" 2>&1)
            if ($LASTEXITCODE -ne 0 -or -not $windowsPath) {
                throw "Failed to convert WSL path: $windowsPath"
            }
            $windowsPath = $windowsPath.Trim()
            
            # Ensure WSL directory exists
            $result = & wsl.exe bash -c "mkdir -p '$sanitizedDir'" 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to create WSL directory: $result"
            }
        }
        else {
            # Windows path
            $windowsPath = $dir
            if (-not (Test-Path $windowsPath)) {
                New-Item -ItemType Directory -Path $windowsPath -Force | Out-Null
            }
        }
        return $windowsPath
    }
    catch {
        throw "Path error: $_"
    }
}

# Function to save screenshot with proper resource management
function Save-ScreenshotToWSL {
    param([bool]$silent = $false)
    
    $image = $null
    try {
        if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
            $image = [System.Windows.Forms.Clipboard]::GetImage()
            
            if ($image) {
                try {
                    $windowsPath = Get-WindowsPath
                    
                    # Generate filename and save
                    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss-fff"
                    $filename = "screenshot_$timestamp.png"
                    $filepath = Join-Path $windowsPath $filename
                    $image.Save($filepath, [System.Drawing.Imaging.ImageFormat]::Png)
                    
                    # Copy path to clipboard
                    if ($script:config.screenshotDir -like "/*") {
                        # WSL path
                        $clipboardPath = "$($script:config.screenshotDir)/$filename"
                    }
                    else {
                        # Windows path
                        $clipboardPath = $filepath
                    }
                    
                    # Use invoke to handle clipboard access safely
                    [System.Windows.Forms.Clipboard]::SetText($clipboardPath)
                    
                    # Show notification unless silent
                    if (-not $silent) {
                        $script:notifyIcon.ShowBalloonTip(2000, "Screenshot Saved", $clipboardPath, [System.Windows.Forms.ToolTipIcon]::Info)
                    }
                    
                    return $true
                }
                catch {
                    if (-not $silent) {
                        $script:notifyIcon.ShowBalloonTip(2000, "Error", $_.Exception.Message, [System.Windows.Forms.ToolTipIcon]::Error)
                    }
                    return $false
                }
            }
        }
        return $false
    }
    finally {
        if ($image) {
            $image.Dispose()
        }
    }
}

# Timer for clipboard monitoring
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500
$timer.Add_Tick({
    if ($script:autoSaveEnabled) {
        $image = $null
        $memoryStream = $null
        $sha256 = $null
        
        try {
            if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
                $image = [System.Windows.Forms.Clipboard]::GetImage()
                if ($image) {
                    $memoryStream = New-Object System.IO.MemoryStream
                    $image.Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)
                    $imageBytes = $memoryStream.ToArray()
                    
                    $sha256 = [System.Security.Cryptography.SHA256]::Create()
                    $hashBytes = $sha256.ComputeHash($imageBytes)
                    $currentHash = [System.BitConverter]::ToString($hashBytes)
                    
                    if ($currentHash -ne $script:lastImageHash) {
                        $script:lastImageHash = $currentHash
                        Save-ScreenshotToWSL -silent $true
                    }
                }
            }
        }
        catch {
            # Log error silently to avoid spamming
            Write-Warning "Timer error: $_"
        }
        finally {
            if ($sha256) { $sha256.Dispose() }
            if ($memoryStream) { $memoryStream.Dispose() }
            if ($image) { $image.Dispose() }
        }
    }
})

# Function to toggle auto-save
function Toggle-AutoSave {
    $script:autoSaveEnabled = -not $script:autoSaveEnabled
    
    if ($script:autoSaveEnabled) {
        $script:notifyIcon.Icon = $script:iconOn
        $script:notifyIcon.Text = "Claude Code Screenshot Saver - ON"
        $script:notifyIcon.ShowBalloonTip(1000, "Auto-save ON", "Screenshots will be saved automatically", [System.Windows.Forms.ToolTipIcon]::Info)
        $timer.Start()
    }
    else {
        $script:notifyIcon.Icon = $script:iconOff
        $script:notifyIcon.Text = "Claude Code Screenshot Saver - OFF"
        $script:notifyIcon.ShowBalloonTip(1000, "Auto-save OFF", "Screenshots stay in clipboard", [System.Windows.Forms.ToolTipIcon]::Info)
        $timer.Stop()
    }
}

# Function to open screenshots folder
function Open-ScreenshotsFolder {
    try {
        $windowsPath = Get-WindowsPath
        Start-Process explorer.exe -ArgumentList $windowsPath
    }
    catch {
        $script:notifyIcon.ShowBalloonTip(2000, "Error", $_.Exception.Message, [System.Windows.Forms.ToolTipIcon]::Error)
    }
}

# Function to clear all screenshots
function Clear-Screenshots {
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Delete all screenshots in:`n$($script:config.screenshotDir)`n`nThis cannot be undone!", 
        "Confirm Delete", 
        [System.Windows.Forms.MessageBoxButtons]::YesNo, 
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            if ($script:config.screenshotDir -like "/*") {
                # WSL path - use sanitized path
                $sanitizedDir = Get-SanitizedPath $script:config.screenshotDir
                $result = & wsl.exe bash -c "find '$sanitizedDir' -name '*.png' -type f -delete" 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to delete files: $result"
                }
            }
            else {
                # Windows path
                $pngFiles = Get-ChildItem "$($script:config.screenshotDir)\*.png" -ErrorAction SilentlyContinue
                if ($pngFiles) {
                    Remove-Item $pngFiles -Force -ErrorAction Stop
                }
            }
            $script:notifyIcon.ShowBalloonTip(2000, "Cleared", "All screenshots deleted", [System.Windows.Forms.ToolTipIcon]::Info)
        }
        catch {
            $script:notifyIcon.ShowBalloonTip(2000, "Error", $_.Exception.Message, [System.Windows.Forms.ToolTipIcon]::Error)
        }
    }
}

# Function to change folder
function Change-Folder {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Change Screenshot Folder"
    $form.Size = New-Object System.Drawing.Size(500, 200)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Enter folder path (Windows or WSL format):"
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(460, 20)
    $form.Controls.Add($label)
    
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Text = $script:config.screenshotDir
    $textBox.Location = New-Object System.Drawing.Point(10, 50)
    $textBox.Size = New-Object System.Drawing.Size(380, 20)
    $form.Controls.Add($textBox)
    
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Text = "Browse..."
    $browseButton.Location = New-Object System.Drawing.Point(400, 48)
    $browseButton.Size = New-Object System.Drawing.Size(70, 23)
    $browseButton.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $textBox.Text = $folderBrowser.SelectedPath
        }
    })
    $form.Controls.Add($browseButton)
    
    $exampleLabel = New-Object System.Windows.Forms.Label
    $exampleLabel.Text = "Examples: C:\Screenshots or /home/user/screenshots"
    $exampleLabel.Location = New-Object System.Drawing.Point(10, 80)
    $exampleLabel.Size = New-Object System.Drawing.Size(460, 20)
    $exampleLabel.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($exampleLabel)
    
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(310, 120)
    $okButton.Size = New-Object System.Drawing.Size(75, 23)
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okButton)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(395, 120)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancelButton)
    
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    
    if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $newPath = $textBox.Text.Trim()
        if ($newPath) {
            # Validate the path before saving
            try {
                $script:config.screenshotDir = $newPath
                # Test if we can access the path
                $testPath = Get-WindowsPath
                Save-Config
                $script:notifyIcon.ShowBalloonTip(2000, "Folder Changed", "Screenshots will be saved to:`n$newPath", [System.Windows.Forms.ToolTipIcon]::Info)
            }
            catch {
                # Revert to previous path
                Load-Config
                [System.Windows.Forms.MessageBox]::Show(
                    "Invalid path: $_", 
                    "Error", 
                    [System.Windows.Forms.MessageBoxButtons]::OK, 
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            }
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

# Change folder
$contextMenu.Items.Add("Change Folder...", $null, {
    Change-Folder
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
    
    # Clean up icon handles
    foreach ($handle in $script:iconHandles) {
        [Win32]::DestroyIcon($handle)
    }
    
    if ($hasHandle) {
        $mutex.ReleaseMutex()
    }
    $mutex.Dispose()
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
$script:notifyIcon.ShowBalloonTip(3000, "Claude Code Screenshot Saver", "Right-click for menu`nDouble-click to toggle auto-save", [System.Windows.Forms.ToolTipIcon]::Info)

# Start timer (will only tick if auto-save is enabled)
$timer.Start()

# Create application context and run
$appContext = New-Object System.Windows.Forms.ApplicationContext
[System.Windows.Forms.Application]::Run($appContext)