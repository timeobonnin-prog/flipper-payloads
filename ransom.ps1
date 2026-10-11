# --- Fake Ransomware (simulation uniquement) ---
# Affiche un faux écran de rançon, ne touche à AUCUN fichier

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Crée une fenêtre plein écran
$form = New-Object System.Windows.Forms.Form
$form.WindowState = 'Maximized'
$form.FormBorderStyle = 'None'
$form.TopMost = $true
$form.BackColor = 'Black'
$form.KeyPreview = $true

# Empêche la fermeture avec Alt+F4 / Échap
$form.Add_KeyDown({ $_.SuppressKeyPress = $true })
$form.Add_FormClosing({ $_.Cancel = $true })

# Message de rançon
$title = New-Object System.Windows.Forms.Label
$title.Text = "Ooops, your files have been encrypted!"
$title.ForeColor = 'Red'
$title.Font = New-Object System.Drawing.Font("Arial", 32, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(200, 100)
$form.Controls.Add($title)

$msg = New-Object System.Windows.Forms.Label
$msg.Text = @"
Tous vos documents, photos, vidéos et bases de données ont été chiffrés.

Pour récupérer vos fichiers, vous devez payer 0.5 Bitcoin à l'adresse suivante :
1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7Q

Après le paiement, envoyez la preuve à : decrypt@fake-ransom.onion

Vous avez 72 heures. Passé ce délai, la clé de déchiffrement sera détruite.

⚠️ Ceci est une SIMULATION. Aucun fichier n'a été touché.
   Change ton fond d'écran, redémarre, ou appuie sur ALT+F4 après 5 secondes.
"@
$msg.ForeColor = 'White'
$msg.Font = New-Object System.Drawing.Font("Consolas", 14)
$msg.AutoSize = $true
$msg.Location = New-Object System.Drawing.Point(200, 200)
$form.Controls.Add($msg)

# Compte à rebours
$timerLabel = New-Object System.Windows.Forms.Label
$timerLabel.ForeColor = 'Yellow'
$timerLabel.Font = New-Object System.Drawing.Font("Consolas", 24, [System.Drawing.FontStyle]::Bold)
$timerLabel.AutoSize = $true
$timerLabel.Location = New-Object System.Drawing.Point(200, 500)
$form.Controls.Add($timerLabel)

$countdown = 10
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $script:countdown--
    $timerLabel.Text = "Temps restant : $script:countdown secondes"
    if ($script:countdown -le 0) {
        $timer.Stop()
        $form.FormClosing = $null
        $form.Close()
    }
})
$timerLabel.Text = "Temps restant : $countdown secondes"
$timer.Start()

# Joue un son stressant (bip système)
[System.Media.SystemSounds]::Hand.Play()

# Affiche la fenêtre (bloque jusqu'à fermeture)
$form.ShowDialog() | Out-Null
