' Uninstall.vbs
' Uninstaller for Claude Code Screenshot Saver

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Kill PowerShell processes running our script
On Error Resume Next
objShell.Run "taskkill /F /IM powershell.exe /FI ""WINDOWTITLE eq *ClaudeCodeScreenshotSaver*""", 0, True
On Error GoTo 0

' Remove startup shortcut
strStartupFolder = objShell.SpecialFolders("Startup")
strShortcutPath = strStartupFolder & "\ClaudeCodeScreenshotSaver.lnk"

If objFSO.FileExists(strShortcutPath) Then
    objFSO.DeleteFile strShortcutPath
End If

' Remove configuration folder
strConfigDir = objShell.ExpandEnvironmentStrings("%APPDATA%") & "\ClaudeCodeScreenshotSaver"
If objFSO.FolderExists(strConfigDir) Then
    objFSO.DeleteFolder strConfigDir, True
End If

' Show success message
MsgBox "Claude Code Screenshot Saver uninstalled successfully!" & vbCrLf & vbCrLf & _
       "All settings and shortcuts have been removed.", _
       vbInformation, "Uninstall Complete"