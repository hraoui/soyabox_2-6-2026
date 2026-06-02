# Installation Process

## 1. Prérequis

- Flutter SDK installé (`flutter --version`)
- Xcode (macOS/iOS), Android Studio + SDK (Android)
- Dépendances système Flutter desktop selon ta plateforme

## 2. Installation locale

```bash
flutter clean
flutter pub get
```

## 3. Lancer en dev

```bash
flutter run
```

Pour desktop macOS:

```bash
flutter run -d macos
```

Pour web:

```bash
flutter run -d chrome
```

## 4. Launcher Icon

Le fichier source de l'icône est:

`assets/branding/app_icon.png` (1024x1024)

Après remplacement de ce fichier, régénérer les icônes:

```bash
flutter pub get
dart run flutter_launcher_icons
```

Les plateformes couvertes par la config actuelle:

- Android
- iOS
- macOS
- Windows
- Web

## 5. Build installation

### Android APK

```bash
flutter build apk --release
```

Fichier généré:
`build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

Fichier généré:
`build/app/outputs/bundle/release/app-release.aab`

### iOS (archive via Xcode)

```bash
flutter build ios --release
```

Ensuite ouvrir `ios/Runner.xcworkspace` dans Xcode pour archive/signing.

### macOS

```bash
flutter build macos --release
```

### Windows

Le build Windows doit être fait sur un PC Windows (ou CI Windows), pas depuis macOS.

```bash
flutter build windows --release
```

Le binaire portable est dans:
`build/windows/x64/runner/Release/`

Important: déployer tout le dossier `Release`, pas seulement `caisse_1.exe`.

### Windows Setup.exe (installateur)

Installer Inno Setup sur la machine Windows de build, puis exécuter:

```powershell
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\windows\soyabox_pos.iss
```

Fichier généré:
`build/windows/installer/SOYABOX_POS_Setup.exe`

### Web

```bash
flutter build web --release
```
