# caisse_1

Application Flutter de caisse (POS) avec thèmes glassmorphism.

## Raccourcis Desktop (installation)

- **Windows** : après `flutter build windows`, lancer  
  `powershell -ExecutionPolicy Bypass -File scripts/create_shortcut_win.ps1 -ExePath "C:\chemin\vers\caisse_1.exe" -Name "Caisse POS"`  
  -> crée les raccourcis Bureau et Menu Démarrer.

- **macOS** : après avoir copié l’app dans `/Applications`, lancer  
  `bash scripts/create_shortcut_mac.sh "/Applications/Caisse.app" "Caisse POS"`  
  -> crée un alias sur le bureau. Pour apparaître dans Launchpad, l’app doit rester dans `/Applications`.

## Commandes utiles

- `flutter pub get`
- `flutter analyze`
- `flutter test`
