# 🐬 Flipper Payloads

Collection de payloads BadUSB pour Flipper Zero, conçus pour Windows 10/11.
Ce dépôt regroupe des scripts éducatifs, de reconnaissance et de tests de sécurité.

---

## ⚠️ AVERTISSEMENT — À LIRE AVANT TOUTE UTILISATION

> **Ce dépôt est fourni à des fins strictement éducatives et de tests de sécurité autorisés.**

- 🚫 **N'utilise JAMAIS ces scripts sur un appareil qui ne t'appartient pas.**
- 🚫 **N'utilise JAMAIS ces scripts sans autorisation écrite du propriétaire.**
- ⚖️ En France, l'accès non autorisé à un système informatique est puni par
  **l'article 323-1 du Code pénal** (jusqu'à 3 ans de prison et 100 000 € d'amende).
- ⚖️ Dans d'autres pays, des lois similaires s'appliquent (CFAA aux USA, Computer
  Misuse Act au UK, etc.).
- 👤 **Tu es seul responsable** de l'usage que tu fais de ces scripts.
- 🛡️ **Aucun script de ce dépôt ne modifie, supprime ou chiffre des fichiers.**
  Tous sont en lecture seule ou en simulation.

**En clonant, téléchargeant ou utilisant ce dépôt, tu acceptes ces conditions.**

---

## 📋 Contenu du dépôt

| Fichier | Description | Effet |
|---|---|---|
| `audit.ps1` | Audit système complet + envoi Telegram | Lecture seule |
| `troll.ps1` | Change le fond d'écran + ouvre une vidéo | Farce inoffensive |
| `ransom.ps1` | Faux ransomware (simulation théâtrale) | Aucun fichier touché |

---

## 🧩 Prérequis

- **Flipper Zero** avec un firmware récent (Momentum, Unleashed, Xtreme…)
- **Câble USB** (le Flipper doit être en mode HID/clavier)
- **Carte microSD** dans le Flipper
- **Windows 10 ou 11** sur la machine cible (la tienne !)
- **PowerShell 5.1+** (installé par défaut)
- **curl.exe** (inclus dans Windows 10 1803+)
- Un **bot Telegram** avec son token et ton chat ID (pour l'envoi des rapports)

---

## 🚀 Installation pas à pas

### 1. Configurer le bot Telegram

1. Sur Telegram, cherche **@BotFather** → `/newbot` → suis les étapes.
2. Copie le **token** (format `1234567890:AAH...`).
3. Cherche **@userinfobot** → envoie `/start` → récupère ton **chat ID** (numérique).
4. Envoie `/start` à ton bot pour l'activer.

### 2. Personnaliser les scripts

Dans chaque script `.ps1`, remplace :

```powershell
$token  = "TON_TOKEN_ICI"
$chatid = "TON_CHAT_ID_ICI"
