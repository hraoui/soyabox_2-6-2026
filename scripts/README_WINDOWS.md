# 🪟 Windows Build & Installer Guide - Caisse POS

## 📋 Prérequis

### 1. **Flutter SDK**
```bash
# Vérifier l'installation
flutter doctor
```

### 2. **Visual Studio Build Tools**
- Télécharger: [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/)
- Installer: "Desktop development with C++"

### 3. **Inno Setup** (pour créer l'installateur .exe)
- Télécharger: [Inno Setup](https://jrsoftware.org/isdl.php)
- Installer par défaut dans: `C:\Program Files (x86)\Inno Setup 6`

---

## 🚀 Build Automatique (Recommandé)

Depuis la racine du projet :

```batch
scripts\build_windows.bat
```

Ce script :
1. Installe les dépendances Flutter
2. Compile l'application Windows en mode release
3. Crée l'installateur avec Inno Setup
4. Génère les raccourcis bureau/menu démarrer

---

## 🔧 Build Manuel

### Étape 1: Build de l'application
```batch
flutter pub get
flutter build windows --release
```

**Output:** `build\windows\x64\runner\Release\caisse_1.exe`

### Étape 2: Créer l'installateur (optionnel)

**Option A - Via ligne de commande :**
```batch
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" scripts\installer.iss
```

**Option B - Via l'interface Inno Setup :**
1. Ouvrir Inno Setup Compiler
2. Charger `scripts\installer.iss`
3. Click Build → Compile

**Output:** `build\windows\installer\CaissePOS-Setup-1.0.0.exe`

### Étape 3: Créer les raccourcis (optionnel)
```powershell
powershell -ExecutionPolicy Bypass -File scripts\create_shortcut_win.ps1
```

---

## 📁 Structure des fichiers

```
caisse1-main/
├── scripts/
│   ├── build_windows.bat      # Script de build automatique
│   ├── installer.iss          # Script Inno Setup
│   └── create_shortcut_win.ps1 # Script de raccourcis
├── build/
│   └── windows/
│       ├── x64/runner/Release/    # Exécutable
│       └── installer/             # Installateur .exe
└── ...
```

---

## ✅ Vérification du build

Après le build, vérifiez :

```batch
# Vérifier l'exécutable
dir build\windows\x64\runner\Release\caisse_1.exe

# Vérifier l'installateur (si Inno Setup utilisé)
dir build\windows\installer\CaissePOS-Setup-*.exe
```

---

## 🐛 Résolution de problèmes

### "Executable not found"
```batch
# Vérifier que le build Windows est supporté
flutter devices
flutter build windows --release -v
```

### "Inno Setup not found"
- Ajouter Inno Setup au PATH système
- Ou utiliser le chemin complet vers `ISCC.exe`

### Erreur de compilation Flutter
```batch
# Nettoyer et rebuild
flutter clean
flutter pub get
flutter build windows --release
```

---

## 📦 Distribution

### Fichiers à distribuer :
- **Option 1 (Recommandée):** `CaissePOS-Setup-1.0.0.exe` (installateur complet)
- **Option 2:** Dossier `Release\` complet (portable, tous les fichiers nécessaires)

### Installation silencieuse :
```batch
# Pour déploiement en masse
CaissePOS-Setup-1.0.0.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
```

---

## 🔐 Signature de code (Optionnel)

Pour signer l'installateur avec un certificat :

1. Modifier `installer.iss` :
```ini
[Setup]
SignTool=MySignTool
SignedUninstaller=yes
```

2. Créer `signtool.cmd` :
```batch
@echo off
signtool sign /f "cert.pfx" /p "password" /t "http://timestamp.digicert.com" %1
```

---

## 📞 Support

Pour toute question, consultez :
- [Flutter Windows Documentation](https://docs.flutter.dev/deployment/windows)
- [Inno Setup Documentation](https://jrsoftware.org/ishelp/)
