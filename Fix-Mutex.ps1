# Fix-Mutex.ps1
# Script to clear stuck mutex

Write-Host "Clearing Claude Code Screenshot Saver mutex..." -ForegroundColor Yellow

# Kill all PowerShell processes
Get-Process powershell* -ErrorAction SilentlyContinue | Stop-Process -Force

# Wait a bit
Start-Sleep -Seconds 2

# Try to create and release mutex
try {
    $mutex = New-Object System.Threading.Mutex($false, "Global\ClaudeCodeScreenshotSaver_Mutex")
    $acquired = $mutex.WaitOne(0, $false)
    
    if ($acquired) {
        Write-Host "Mutex successfully cleared!" -ForegroundColor Green
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    } else {
        Write-Host "Mutex is still locked. Please restart your computer." -ForegroundColor Red
    }
} catch {
    Write-Host "Error working with mutex: $_" -ForegroundColor Red
}

Write-Host "`nDone! Now try to run the application again." -ForegroundColor Green
Read-Host "Press Enter to close"