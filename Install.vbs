' Install.vbs
' Installer for Claude Code Screenshot Saver

Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get current directory
strPath = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Check if WSL is available
On Error Resume Next
Set objExec = objShell.Exec("wsl.exe --version")
If Err.Number <> 0 Then
    MsgBox "WSL is not installed!" & vbCrLf & vbCrLf & _
           "Please install WSL first using: wsl --install", _
           vbCritical, "WSL Required"
    WScript.Quit
End If
On Error GoTo 0

' Get WSL username
Set objExec = objShell.Exec("wsl.exe whoami")
strWSLUser = objExec.StdOut.ReadAll()
strWSLUser = Replace(strWSLUser, vbCrLf, "")
strWSLUser = Replace(strWSLUser, vbLf, "")

' Default folder path
strDefaultPath = "/home/" & strWSLUser & "/.screenshots"

' Ask for folder path
strFolder = InputBox("Enter the folder path for saving screenshots:" & vbCrLf & vbCrLf & _
                     "Examples:" & vbCrLf & _
                     "• WSL path: /home/user/screenshots" & vbCrLf & _
                     "• Windows path: C:\Screenshots" & vbCrLf & vbCrLf & _
                     "Leave empty for default WSL path.", _
                     "Screenshot Folder", strDefaultPath)

' If cancelled, exit
If strFolder = "" Then
    strFolder = strDefaultPath
End If

' Save initial configuration
strConfigDir = objShell.ExpandEnvironmentStrings("%APPDATA%") & "\ClaudeCodeScreenshotSaver"
If Not objFSO.FolderExists(strConfigDir) Then
    objFSO.CreateFolder(strConfigDir)
End If

' Create config.json
strConfigFile = strConfigDir & "\config.json"
Set objFile = objFSO.CreateTextFile(strConfigFile, True)
objFile.WriteLine "{""screenshotDir"":""" & Replace(strFolder, "\", "\\") & """}"
objFile.Close

' Create startup shortcut
strStartupFolder = objShell.SpecialFolders("Startup")
strShortcutPath = strStartupFolder & "\ClaudeCodeScreenshotSaver.lnk"

Set objShortcut = objShell.CreateShortcut(strShortcutPath)
objShortcut.TargetPath = strPath & "\Start.vbs"
objShortcut.WorkingDirectory = strPath
objShortcut.IconLocation = "imageres.dll,76"
objShortcut.Description = "Claude Code Screenshot Saver - Save screenshots with WSL path in clipboard"
objShortcut.Save

' No desktop shortcut created

' Start the application
objShell.Run """" & strPath & "\Start.vbs""", 0, False

' Show success message
MsgBox "Claude Code Screenshot Saver installed successfully!" & vbCrLf & vbCrLf & _
       "• Screenshot folder: " & strFolder & vbCrLf & _
       "• Look for icon in system tray" & vbCrLf & vbCrLf & _
       "Icon colors: RED = OFF, GREEN = ON" & vbCrLf & _
       "Double-click to toggle, right-click for menu", _
       vbInformation, "Installation Complete"