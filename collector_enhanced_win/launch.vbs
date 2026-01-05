' Enhanced Collector - Stealth Launcher (Backend Edition)
' Runs launch.bat silently in background

On Error Resume Next

Set objShell = CreateObject("WScript.Shell")

' Try to run batch file hidden
objShell.Run "cmd /c """ & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\launch.bat""", 0, False

' If error occurred, try fallback
If Err.Number <> 0 Then
    ' Run visibly as fallback
    objShell.Run """" & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\launch.bat""", 1, False
End If

Set objShell = Nothing
