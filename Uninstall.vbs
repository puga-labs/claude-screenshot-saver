' Uninstall.vbs
' Uninstaller for Claude Code Screenshot Saver

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Confirm uninstallation
If MsgBox("Are you sure you want to uninstall Claude Code Screenshot Saver?", vbYesNo + vbQuestion, "Confirm Uninstall") <> vbYes Then
    WScript.Quit
End If

' Kill PowerShell processes running our script
On Error Resume Next
objShell.Run "taskkill /F /IM powershell.exe /FI ""WINDOWTITLE eq ClaudeCodeScreenshotSaver*""", 0, True
On Error GoTo 0

' Remove startup shortcut
strStartupFolder = objShell.SpecialFolders("Startup")
strShortcutPath = strStartupFolder & "\ClaudeCodeScreenshotSaver.lnk"

On Error Resume Next
If objFSO.FileExists(strShortcutPath) Then
    objFSO.DeleteFile strShortcutPath
    If Err.Number <> 0 Then
        MsgBox "Warning: Could not remove startup shortcut: " & Err.Description, vbExclamation, "Uninstall Warning"
        Err.Clear
    End If
End If
On Error GoTo 0

' Remove configuration folder
strConfigDir = objShell.ExpandEnvironmentStrings("%APPDATA%") & "\ClaudeCodeScreenshotSaver"
On Error Resume Next
If objFSO.FolderExists(strConfigDir) Then
    objFSO.DeleteFolder strConfigDir, True
    If Err.Number <> 0 Then
        MsgBox "Warning: Could not remove configuration folder: " & Err.Description & vbCrLf & vbCrLf & _
               "You may need to manually delete: " & strConfigDir, vbExclamation, "Uninstall Warning"
        Err.Clear
    End If
End If
On Error GoTo 0

' Show success message
MsgBox "Claude Code Screenshot Saver uninstalled successfully!" & vbCrLf & vbCrLf & _
       "All settings and shortcuts have been removed.", _
       vbInformation, "Uninstall Complete"