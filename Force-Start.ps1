# Force-Start.ps1
# Принудительный запуск без проверки mutex (для тестирования)

Write-Host "Принудительный запуск Claude Code Screenshot Saver..." -ForegroundColor Yellow

# Завершаем старые процессы
Get-Process powershell* | Where-Object { $_.MainWindowTitle -like "*ClaudeCodeScreenshotSaver*" } | Stop-Process -Force -ErrorAction SilentlyContinue

# Запускаем основной скрипт в скрытом окне
$scriptPath = Join-Path $PSScriptRoot "ClaudeCodeScreenshotSaver.ps1"

# Временно отключаем проверку mutex, заменив первые строки
$content = Get-Content $scriptPath -Raw
$modifiedContent = $content -replace '\$mutex = New-Object.*?\n.*?exit\s*\}', '# Mutex check temporarily disabled'

# Создаем временный файл
$tempScript = Join-Path $env:TEMP "ClaudeCodeScreenshotSaver_Temp.ps1"
$modifiedContent | Out-File $tempScript -Force

# Запускаем временный скрипт
Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$tempScript`"" -WindowStyle Hidden

Write-Host "Приложение запущено! Проверьте системный трей." -ForegroundColor Green
Start-Sleep -Seconds 3