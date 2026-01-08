Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get script directory
strScriptPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
strPSScript = strScriptPath & "\launch.ps1"

' Run PowerShell script hidden (window style 0 = hidden)
objShell.Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -File """ & strPSScript & """", 0, True

Set objShell = Nothing
Set objFSO = Nothing
