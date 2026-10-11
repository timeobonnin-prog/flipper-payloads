# --- System Audit Pro ---
# Génère un rapport HTML complet du système
# Ne modifie RIEN, lit seulement les informations

$reportPath = "$env:TEMP\audit_report.html"
$user = $env:USERNAME
$pc = $env:COMPUTERNAME
$date = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

# === Fonction pour échapper le HTML ===
function HtmlEncode($s) {
    if ($null -eq $s) { return "" }
    return [System.Web.HttpUtility]::HtmlEncode($s.ToString())
}
Add-Type -AssemblyName System.Web

# === Collecte des données ===
Write-Host "[*] Collecte en cours..." -ForegroundColor Cyan

# Système
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$uptime = (Get-Date) - $os.LastBootUpTime

# CPU & RAM
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)

# Disques
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"

# Réseau
$interfaces = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike '127.*' }
$wifi = (netsh wlan show interfaces) -match '^\s+SSID' | Select-Object -First 1

# Utilisateurs
$users = Get-CimInstance Win32_UserAccount -Filter "LocalAccount=True" |
    Select-Object Name, FullName, Disabled, Lockout

# Programmes installés (top 20)
$software = @()
$paths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach ($path in $paths) {
    $software += Get-ItemProperty $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName } |
        Select-Object DisplayName, DisplayVersion, Publisher
}
$software = $software | Sort-Object DisplayName -Unique | Select-Object -First 20

# Processus
$processes = Get-Process | Sort-Object CPU -Descending |
    Select-Object -First 10 Name, Id, CPU, @{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB,1)}}

# Sécurité
$defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
$firewall = Get-NetFirewallProfile -ErrorAction SilentlyContinue |
    Select-Object Name, Enabled

# === Génération du HTML ===
$html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Audit Système - $pc</title>
<style>
body { font-family: 'Segoe UI', Arial, sans-serif; background: #1e1e2e; color: #cdd6f4; margin: 0; padding: 20px; }
.container { max-width: 1200px; margin: 0 auto; }
h1 { color: #89b4fa; border-bottom: 3px solid #89b4fa; padding-bottom: 10px; }
h2 { color: #f9e2af; margin-top: 30px; border-left: 4px solid #f9e2af; padding-left: 10px; }
table { width: 100%; border-collapse: collapse; margin: 10px 0; background: #313244; border-radius: 8px; overflow: hidden; }
th { background: #45475a; color: #f9e2af; padding: 10px; text-align: left; }
td { padding: 8px 10px; border-bottom: 1px solid #45475a; }
tr:hover { background: #45475a; }
.info-box { background: #313244; padding: 15px; border-radius: 8px; margin: 10px 0; border-left: 4px solid #89b4fa; }
.label { color: #a6adc8; font-weight: bold; }
.value { color: #cdd6f4; }
.good { color: #a6e3a1; }
.bad { color: #f38ba8; }
.warn { color: #fab387; }
.header-box { background: linear-gradient(135deg, #89b4fa, #cba6f7); padding: 20px; border-radius: 10px; margin-bottom: 20px; color: #1e1e2e; }
.footer { text-align: center; color: #6c7086; margin-top: 40px; padding: 20px; font-size: 12px; }
</style>
</head>
<body>
<div class="container">
<div class="header-box">
<h1 style="color: #1e1e2e; border: none; margin: 0;">🔍 Rapport d'Audit Système</h1>
<p style="margin: 5px 0 0 0;"><strong>$pc</strong> — Utilisateur : <strong>$user</strong> — $date</p>
</div>

<h2>💻 Système d'exploitation</h2>
<div class="info-box">
<div><span class="label">Nom :</span> <span class="value">$(HtmlEncode $os.Caption)</span></div>
<div><span class="label">Version :</span> <span class="value">$(HtmlEncode $os.Version)</span></div>
<div><span class="label">Architecture :</span> <span class="value">$(HtmlEncode $os.OSArchitecture)</span></div>
<div><span class="label">Installé le :</span> <span class="value">$($os.InstallDate)</span></div>
<div><span class="label">Dernier démarrage :</span> <span class="value">$($os.LastBootUpTime)</span></div>
<div><span class="label">Uptime :</span> <span class="value">$($uptime.Days)j $($uptime.Hours)h $($uptime.Minutes)m</span></div>
</div>

<h2>⚙️ Matériel</h2>
<table>
<tr><th>Composant</th><th>Détail</th></tr>
<tr><td>CPU</td><td>$(HtmlEncode $cpu.Name) ($($cpu.NumberOfCores) cœurs / $($cpu.NumberOfLogicalProcessors) threads)</td></tr>
<tr><td>RAM totale</td><td>$ramGB GB</td></tr>
<tr><td>Fabricant</td><td>$(HtmlEncode $cs.Manufacturer)</td></tr>
<tr><td>Modèle</td><td>$(HtmlEncode $cs.Model)</td></tr>
<tr><td>BIOS</td><td>$(HtmlEncode $bios.Manufacturer) $(HtmlEncode $bios.SMBIOSBIOSVersion)</td></tr>
<tr><td>Numéro de série</td><td>$(HtmlEncode $bios.SerialNumber)</td></tr>
</table>

<h2>💾 Disques</h2>
<table>
<tr><th>Lettre</th><th>Nom</th><th>Total</th><th>Libre</th><th>Utilisation</th></tr>
"@

foreach ($d in $disks) {
    $totalGB = [math]::Round($d.Size / 1GB, 2)
    $freeGB = [math]::Round($d.FreeSpace / 1GB, 2)
    $usedPct = [math]::Round((($d.Size - $d.FreeSpace) / $d.Size) * 100, 1)
    $colorClass = if ($usedPct -gt 90) { "bad" } elseif ($usedPct -gt 75) { "warn" } else { "good" }
    $html += "<tr><td>$($d.DeviceID)</td><td>$(HtmlEncode $d.VolumeName)</td><td>$totalGB GB</td><td>$freeGB GB</td><td class='$colorClass'>$usedPct%</td></tr>"
}
$html += "</table>"

# Réseau
$html += @"
<h2>🌐 Réseau</h2>
<table>
<tr><th>Interface</th><th>Adresse IP</th><th>Passerelle</th><th>DNS</th></tr>
"@
foreach ($i in $interfaces) {
    $dns = (Get-DnsClientServerAddress -InterfaceIndex $i.InterfaceIndex -ErrorAction SilentlyContinue).ServerAddresses -join ", "
    $html += "<tr><td>$(HtmlEncode $i.InterfaceAlias)</td><td>$($i.IPAddress)</td><td>$(HtmlEncode $i.InterfaceAlias)</td><td>$(HtmlEncode $dns)</td></tr>"
}
$html += "</table>"

if ($wifi) {
    $html += "<div class='info-box'><span class='label'>Wi-Fi connecté :</span> <span class='value'>$(HtmlEncode ($wifi -replace '^\s+SSID\s+:\s+', ''))</span></div>"
}

# Utilisateurs
$html += @"
<h2>👤 Comptes utilisateurs locaux</h2>
<table>
<tr><th>Nom</th><th>Nom complet</th><th>État</th></tr>
"@
foreach ($u in $users) {
    $state = if ($u.Disabled) { "<span class='bad'>Désactivé</span>" } else { "<span class='good'>Actif</span>" }
    $html += "<tr><td>$(HtmlEncode $u.Name)</td><td>$(HtmlEncode $u.FullName)</td><td>$state</td></tr>"
}
$html += "</table>"

# Sécurité
$html += "<h2>🛡️ Sécurité</h2><div class='info-box'>"
if ($defender) {
    $avState = if ($defender.AntivirusEnabled) { "<span class='good'>Activé</span>" } else { "<span class='bad'>Désactivé</span>" }
    $rtState = if ($defender.RealTimeProtectionEnabled) { "<span class='good'>Activée</span>" } else { "<span class='bad'>Désactivée</span>" }
    $html += "<div><span class='label'>Windows Defender :</span> $avState</div>"
    $html += "<div><span class='label'>Protection temps réel :</span> $rtState</div>"
    $html += "<div><span class='label'>Signatures :</span> $(HtmlEncode $defender.AntivirusSignatureVersion)</div>"
}
$html += "</div>"

if ($firewall) {
    $html += "<table><tr><th>Profil</th><th>État</th></tr>"
    foreach ($f in $firewall) {
        $state = if ($f.Enabled) { "<span class='good'>Activé</span>" } else { "<span class='bad'>Désactivé</span>" }
        $html += "<tr><td>$(HtmlEncode $f.Name)</td><td>$state</td></tr>"
    }
    $html += "</table>"
}

# Processus
$html += @"
<h2>⚡ Top 10 processus (CPU)</h2>
<table>
<tr><th>Nom</th><th>PID</th><th>CPU (s)</th><th>RAM (MB)</th></tr>
"@
foreach ($p in $processes) {
    $html += "<tr><td>$(HtmlEncode $p.Name)</td><td>$($p.Id)</td><td>$([math]::Round($p.CPU,1))</td><td>$($p.RAM_MB)</td></tr>"
}
$html += "</table>"

# Logiciels
$html += @"
<h2>📦 Programmes installés (top 20)</h2>
<table>
<tr><th>Nom</th><th>Version</th><th>Éditeur</th></tr>
"@
foreach ($s in $software) {
    $html += "<tr><td>$(HtmlEncode $s.DisplayName)</td><td>$(HtmlEncode $s.DisplayVersion)</td><td>$(HtmlEncode $s.Publisher)</td></tr>"
}
$html += "</table>"

$html += @"
<div class="footer">
Rapport généré par System Audit Pro • $date • Aucune modification effectuée sur le système
</div>
</div>
</body>
</html>
"@

# Écriture du rapport
$html | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "[+] Rapport généré : $reportPath" -ForegroundColor Green

# Ouvre le rapport dans le navigateur par défaut
Start-Process $reportPath
