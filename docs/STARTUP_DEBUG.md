# 🐛 Debug - Problème de Démarrage

## ✅ Corrections Appliquées

### 1. Logs de Debug Ajoutés

Des logs détaillés ont été ajoutés dans :
- ✅ `main.dart` - Flux principal de démarrage
- ✅ `dependencies.dart` - Initialisation des dépendances
- ✅ `sync_queue_service.dart` - Initialisation de la file de sync
- ✅ `api_order_pull_service.dart` - Initialisation du pull API
- ✅ `notification_sound_service.dart` - Service de notification

### 2. Correction du SyncController

Le problème principal était que **SyncController** se lançait automatiquement dans `onInit()` **avant que l'utilisateur ne soit connecté**, ce qui causait :
- Tentative de synchronisation sans token valide
- Blocage dans la file d'attente
- Échec du démarrage

**Solution appliquée :**
```dart
// AVANT (❌)
@override
void onInit() {
  super.onInit();
  _start();  // ❌ Lance le sync immédiatement
}

// APRÈS (✅)
// Don't auto-start sync on init - wait for user to login first
// Sync will be started when user logs in via startSyncAfterLogin()
```

### 3. Points de Vérification

Le démarrage suit maintenant ce flux :

```
🚀 [MAIN] Starting app initialization...
✅ [MAIN] Orientation set
📦 [MAIN] Initializing DatabaseService...
✅ [MAIN] DatabaseService initialized
🖼️ [MAIN] Initializing ImageCacheService...
✅ [MAIN] ImageCacheService initialized
🌱 [MAIN] Running startup seeders...
✅ [MAIN] Startup seeders completed
🔧 [MAIN] Initializing dependency injection...
  🔑 [DEP] Initializing AuthSessionService...
  ✅ [DEP] AuthSessionService initialized
  ⚙️ [DEP] Initializing AppSettingsService...
  ✅ [DEP] AppSettingsService initialized
  🌐 [DEP] Creating ApiClient...
  ✅ [DEP] ApiClient created
  📦 [DEP] Creating Repositories...
  ✅ [DEP] Repositories created
  👤 [DEP] Creating Controllers...
  ✅ [DEP] Controllers created
  🔄 [DEP] Initializing SyncQueueService...
  ✅ [DEP] SyncQueueService initialized
  📥 [DEP] Initializing ApiOrderPullService...
  ✅ [DEP] ApiOrderPullService initialized
  🔔 [DEP] Initializing NotificationSoundService...
  ✅ [DEP] NotificationSoundService initialized
  🔄 [DEP] Creating SyncController...
  ✅ [DEP] SyncController created
✅ [MAIN] Dependency injection completed
🎬 [MAIN] Running app...
```

## 🔍 Comment Utiliser les Logs

Lancez l'application et observez les logs dans la console :

```bash
flutter run -v
```

Ou dans Xcode pour iOS :
```
Product → Run → Regarder la console
```

## 🚨 Si le Démarrage Échoue Toujours

Repérez le **dernier message "✅"** dans les logs :

1. **Bloqué après "DatabaseService initialized"**
   - Problème : Isar DB corrompue
   - Solution : Effacer les données de l'app
   ```bash
   flutter clean
   rm -rf ~/Library/Application\ Support/caisse1
   ```

2. **Bloqué après "AuthSessionService initialized"**
   - Problème : Fichier de session corrompu
   - Solution : Supprimer le fichier de session
   ```dart
   // Dans le simulateur, exécuter :
   await AuthSessionService.instance.clearSession();
   ```

3. **Bloqué après "SyncQueueService initialized"**
   - Problème : File de sync trop volumineuse
   - Solution : Vider la file manuellement
   ```dart
   // Ajouter temporairement dans main.dart
   SyncQueueService.instance._queue.clear();
   ```

4. **Bloqué après "ApiOrderPullService initialized"**
   - Problème : Fichier d'état API corrompu
   - Solution : Supprimer le fichier d'état
   ```dart
   final file = File('${dir.path}/api_orders_sync_state.json');
   if (await file.exists()) await file.delete();
   ```

## 📊 Métriques de Performance

Après correction, le démarrage devrait prendre :

| Étape | Temps Cible |
|-------|-------------|
| DatabaseService | < 500ms |
| ImageCacheService | < 200ms |
| Seeders | < 300ms |
| Dependency Injection | < 1000ms |
| **TOTAL** | **< 2 secondes** |

## 🛠️ Prochaines Étapes

1. **Lancer l'application** avec `flutter run`
2. **Copier les logs** complets
3. **Identifier** où ça bloque (dernier "✅")
4. **Appliquer** la solution correspondante

## 📝 Notes Importantes

- **NE PAS** supprimer les logs de debug avant d'avoir identifié le problème
- **NE PAS** mettre en production avec les logs activés
- **APRÈS** résolution, retirer tous les `print()` et garder uniquement `appLogger`
