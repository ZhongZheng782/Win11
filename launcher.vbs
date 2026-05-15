Set objShell = CreateObject("WScript.Shell")
strArgs = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & WScript.Arguments(0) & """"
Dim i
For i = 1 To WScript.Arguments.Count - 1
    strArgs = strArgs & " " & WScript.Arguments(i)
Next
objShell.Run strArgs, 0, False
