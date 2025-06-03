' UninstallSilent.vbs
' Silent uninstaller without console window

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Kill PowerShell processes running our script
On Error Resume Next
objShell.Run "taskkill /F /IM powershell.exe /FI ""WINDOWTITLE eq *ScreenshotWSL*""", 0, True
On Error GoTo 0

' Remove startup shortcut
strStartupFolder = objShell.SpecialFolders("Startup")
strShortcutPath = strStartupFolder & "\ScreenshotWSL.lnk"

If objFSO.FileExists(strShortcutPath) Then
    objFSO.DeleteFile strShortcutPath
End If

' Show success message
MsgBox "Screenshot WSL uninstalled successfully!" & vbCrLf & vbCrLf & _
       "Note: If the tray icon is still visible, it will disappear after restart.", _
       vbInformation, "Uninstall Complete"