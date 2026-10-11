# --- Fake Ransomware v2 (simulation) ---
# Mot de passe pour fermer : ransom
# Ne touche à AUCUN fichier

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Cache la barre des tâches en couvrant tout l'écran
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.WindowState = 'Normal'
$form.Bounds = $screen
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.BackColor = 'Black'
$form.KeyPreview = $true

# Bloque toutes les touches sauf celles qu'on autorise
$form.Add_KeyDown({
    if ($_.KeyCode -ne 'Return') { $_.SuppressKeyPress = $true; $_.Handled = $true }
})

# Bloque la fermeture (Alt+F4, croix, etc.)
$form.Add_FormClosing({ $_.Cancel = $true })

# Repositionne la fenêtre si jamais elle perd le focus (fenêtre "collante")
$form.Add_Deactivate({
    $form.TopMost = $false
    $form.TopMost = $true
    $form.Activate()
})

# Titre
$title = New-Object System.Windows.Forms.Label
$title.Text = "OOPS, YOUR FILES HAVE BEEN ENCRYPTED!"
$title.ForeColor = 'Red'
$title.Font = New-Object System.Drawing.Font("Consolas", 28, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(50, 50)
$form.Controls.Add($title)

# Message principal
$msg = New-Object System.Windows.Forms.Label
$msg.Text = @"
Tous vos documents, photos, vidéos et bases de données ont été chiffrés.

Pour récupérer vos fichiers, vous devez payer 0.5 Bitcoin à l'adresse :
1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7Q

Après paiement, envoyez la preuve à : decrypt@fake-ransom.onion

Vous avez 72 heures. Passé ce délai, la clé sera détruite.
"@
$msg.ForeColor = 'White'
$msg.Font = New-Object System.Drawing.Font("Consolas", 14)
$msg.AutoSize = $true
$msg.Location = New-Object System.Drawing.Point(50, 150)
$form.Controls.Add($msg)

# Compte à rebours
$timerLabel = New-Object System.Windows.Forms.Label
$timerLabel.ForeColor = 'Yellow'
$timerLabel.Font = New-Object System.Drawing.Font("Consolas", 22, [System.Drawing.FontStyle]::Bold)
$timerLabel.AutoSize = $true
$timerLabel.Location = New-Object System.Drawing.Point(50, 350)
$form.Controls.Add($timerLabel)

$script:countdown = 300
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $script:countdown--
    $m = [math]::Floor($script:countdown / 60)
    $s = $script:countdown % 60
    $timerLabel.Text = "Temps restant : {0:00}:{1:00}" -f $m, $s
    if ($script:countdown -le 0) {
        $timer.Stop()
        $form.FormClosing = $null
        $form.Close()
    }
})
$timerLabel.Text = "Temps restant : 05:00"
$timer.Start()

# Champ de mot de passe pour fermer
$pwdLabel = New-Object System.Windows.Forms.Label
$pwdLabel.Text = "Entrez la clé de déchiffrement (ou mot de passe) :"
$pwdLabel.ForeColor = 'Gray'
$pwdLabel.Font = New-Object System.Drawing.Font("Consolas", 12)
$pwdLabel.AutoSize = $true
$pwdLabel.Location = New-Object System.Drawing.Point(50, 450)
$form.Controls.Add($pwdLabel)

$pwdBox = New-Object System.Windows.Forms.TextBox
$pwdBox.Location = New-Object System.Drawing.Point(50, 480)
$pwdBox.Size = New-Object System.Drawing.Size(400, 30)
$pwdBox.Font = New-Object System.Drawing.Font("Consolas", 14)
$pwdBox.UseSystemPasswordChar = $true
$pwdBox.BackColor = 'Black'
$pwdBox.ForeColor = 'White'
$form.Controls.Add($pwdBox)

$pwdBox.Add_KeyDown({
    if ($_.KeyCode -eq 'Return') {
        if ($pwdBox.Text -eq "ransom") {
            $timer.Stop()
            $form.FormClosing = $null
            $form.Close()
        } else {
            $pwdBox.Text = ""
            [System.Media.SystemSounds]::Hand.Play()
        }
    }
})

# Son d'alarme
[System.Media.SystemSounds]::Hand.Play()

# Affiche la fenêtre
$form.ShowDialog() | Out-Null
