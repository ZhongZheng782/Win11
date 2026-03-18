Set objShell = CreateObject("WScript.Shell")
strArgs = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & WScript.Arguments(0) & """"
objShell.Run strArgs, 0, False
