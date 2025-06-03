' Launch Claude Code Screenshot Saver.vbs
' Quick launcher for the application

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get current directory
strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Launch the application
objShell.Run """" & strPath & "\Start.vbs""", 0, False

' Show notification
MsgBox "Claude Code Screenshot Saver is starting..." & vbCrLf & vbCrLf & _
       "Look for the icon in your system tray (near clock)." & vbCrLf & _
       "• RED circle = OFF" & vbCrLf & _
       "• GREEN circle = ON", _
       vbInformation + vbSystemModal, "Claude Code Screenshot Saver", 3