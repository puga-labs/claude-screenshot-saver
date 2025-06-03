' InstallSilent.vbs
' Silent installer without console window

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get current directory
strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Create startup shortcut
strStartupFolder = objShell.SpecialFolders("Startup")
strShortcutPath = strStartupFolder & "\ScreenshotWSL.lnk"

Set objShortcut = objShell.CreateShortcut(strShortcutPath)
objShortcut.TargetPath = strPath & "\Start.vbs"
objShortcut.WorkingDirectory = strPath
objShortcut.IconLocation = "imageres.dll,76"
objShortcut.Description = "Screenshot WSL - Save screenshots to WSL with path in clipboard"
objShortcut.Save

' Start the application
objShell.Run """" & strPath & "\Start.vbs""", 0, False

' Show success message
MsgBox "Screenshot WSL installed successfully!" & vbCrLf & vbCrLf & _
       "Look for the icon in system tray (near clock)" & vbCrLf & vbCrLf & _
       "• RED icon = OFF" & vbCrLf & _
       "• GREEN icon = ON" & vbCrLf & vbCrLf & _
       "Double-click to toggle, right-click for menu.", _
       vbInformation, "Installation Complete"