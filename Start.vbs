' Start.vbs
' Launches Claude Code Screenshot Saver without console window

On Error Resume Next
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get script path with proper handling
strScriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
If Right(strScriptDir, 1) <> "\" Then strScriptDir = strScriptDir & "\"
scriptPath = strScriptDir & "ClaudeCodeScreenshotSaver.ps1"

' Verify PowerShell script exists
If Not objFSO.FileExists(scriptPath) Then
    MsgBox "PowerShell script not found: " & scriptPath, vbCritical, "Launch Error"
    WScript.Quit
End If

' Launch with proper error handling
objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & scriptPath & """", 0, False

If Err.Number <> 0 Then
    MsgBox "Failed to launch application: " & Err.Description, vbCritical, "Launch Error"
    WScript.Quit
End If
On Error GoTo 0