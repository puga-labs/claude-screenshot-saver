' Launch Claude Code Screenshot Saver.vbs
' Quick launcher for the application

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get current directory
strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Launch the application
strStartScript = strPath & "\Start.vbs"
If objFSO.FileExists(strStartScript) Then
    On Error Resume Next
    objShell.Run """" & strStartScript & """", 0, False
    If Err.Number <> 0 Then
        MsgBox "Failed to launch application: " & Err.Description, vbCritical, "Launch Error"
        WScript.Quit
    End If
    On Error GoTo 0
    
    ' Show notification (without system modal)
    MsgBox "Claude Code Screenshot Saver is starting..." & vbCrLf & vbCrLf & _
           "Look for the icon in your system tray (near clock)." & vbCrLf & _
           "• RED circle = OFF" & vbCrLf & _
           "• GREEN circle = ON", _
           vbInformation, "Claude Code Screenshot Saver"
Else
    MsgBox "Start script not found: " & strStartScript, vbCritical, "Launch Error"
    WScript.Quit
End If