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
On Error Resume Next
Set objExec = objShell.Exec("wsl.exe whoami")
If Err.Number = 0 And Not objExec Is Nothing Then
    strWSLUser = objExec.StdOut.ReadAll()
    strWSLUser = Replace(strWSLUser, vbCrLf, "")
    strWSLUser = Replace(strWSLUser, vbLf, "")
Else
    strWSLUser = "user"
End If
On Error GoTo 0

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
On Error Resume Next
If Not objFSO.FolderExists(strConfigDir) Then
    objFSO.CreateFolder(strConfigDir)
    If Err.Number <> 0 Then
        MsgBox "Failed to create configuration directory: " & Err.Description, vbCritical, "Installation Error"
        WScript.Quit
    End If
End If
On Error GoTo 0

' Create config.json
strConfigFile = strConfigDir & "\config.json"
On Error Resume Next
' Properly escape JSON string
strEscapedFolder = Replace(strFolder, "\", "\\")
strEscapedFolder = Replace(strEscapedFolder, """", "\""")
Set objFile = objFSO.CreateTextFile(strConfigFile, True)
objFile.WriteLine "{""screenshotDir"":""" & strEscapedFolder & """}"
objFile.Close
If Err.Number <> 0 Then
    MsgBox "Failed to create configuration file: " & Err.Description, vbCritical, "Installation Error"
    WScript.Quit
End If
On Error GoTo 0

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
strStartScript = strPath & "\Start.vbs"
If objFSO.FileExists(strStartScript) Then
    objShell.Run """" & strStartScript & """", 0, False
Else
    MsgBox "Start script not found: " & strStartScript, vbCritical, "Installation Error"
    WScript.Quit
End If

' Show success message
MsgBox "Claude Code Screenshot Saver installed successfully!" & vbCrLf & vbCrLf & _
       "• Screenshot folder: " & strFolder & vbCrLf & _
       "• Look for icon in system tray" & vbCrLf & vbCrLf & _
       "Icon colors: RED = OFF, GREEN = ON" & vbCrLf & _
       "Double-click to toggle, right-click for menu", _
       vbInformation, "Installation Complete"