# 🧪 Guide de test rapide - Synchronisation utilisateurs

## 🚀 Lancement rapide

Copiez-collez cette commande dans votre terminal :

```bash
cd /Users/macbookpro/Documents/caisse1-main && \
flutter run -d macos \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=API_TOKEN=202|rcijFRypRHMJpJBmVoJgG1M53l8XGsvxpItNpuGu9ba2bf54
```

---

## 📋 Scénario de test 1 : Création d'utilisateur

### Étapes :

1. **Connectez-vous** avec le Super Admin
   - Téléphone : `0600000000`
   - Mot de passe : (votre mot de passe)

2. **Allez dans la gestion des utilisateurs**
   - Menu → Utilisateurs → Créer un utilisateur

3. **Créez un utilisateur test**
   ```
   Nom: Test Sync
   Email: test.sync@example.com
   Téléphone: 0699999999
   Rôle: staff
   Restaurant: (votre restaurant)
   Mot de passe: test123
   ```

4. **Vérifiez les logs** (dans la console Flutter)

   **Logs attendus :**
   ```
   ✅ User created locally with ID: 123
   📥 [USER QUEUE ADD] User test.sync@example.com (ID:123) queued for sync to backend
   📊 [USER QUEUE SCAN] Complete: added=1, skipped=X, queue_size=1
   📤 [SYNCQ] Flushing queue (1 items)...
   🚀 [SYNCQ] Sending item: users:upsert:test.sync@example.com
   ✅ [SYNCQ] Sent item users:upsert:test.sync@example.com => 200
   💾 [USER SYNC STATE] Saved sync state for User test.sync@example.com
   ```

5. **Vérifiez dans le backend Laravel**

   ```bash
   cd /Applications/MAMP/htdocs/soya_caisse_backend
   php artisan tinker
   
   >>> App\Models\User::where('email', 'test.sync@example.com')->first()
   ```

   **Résultat attendu :** L'utilisateur apparaît avec les bonnes informations

---

## 📋 Scénario de test 2 : Non-duplication

### Étapes :

1. **Modifiez l'utilisateur créé précédemment**
   - Changez le nom : "Test Sync MODIFIED"
   - Sauvegardez

2. **Attendez 60 secondes** (sync automatique)

3. **Vérifiez les logs**

   **Logs attendus :**
   ```
   ⏭️ [USER SYNC SKIP] User test.sync@example.com already synced
   ```
   
   OU (si modification détectée) :
   ```
   📥 [USER QUEUE ADD] User test.sync@example.com (ID:123) queued for sync to backend
   ✅ [SYNCQ] Sent item users:upsert:test.sync@example.com => 200
   ```

4. **Vérifiez dans le backend**

   ```bash
   cd /Applications/MAMP/htdocs/soya_caisse_backend
   php artisan tinker
   
   >>> App\Models\User::where('email', 'test.sync@example.com')->first()
   >>> // Vérifiez que le nom est "Test Sync MODIFIED"
   ```

   **Résultat attendu :** L'utilisateur a été mis à jour, PAS recréé

---

## 📋 Scénario de test 3 : Sync automatique périodique

### Étapes :

1. **Créez un deuxième utilisateur**
   ```
   Nom: Test Auto Sync
   Email: test.auto@example.com
   Téléphone: 0688888888
   Rôle: staff
   ```

2. **Ne faites rien pendant 60 secondes**

3. **Vérifiez les logs après 60 secondes**

   **Logs attendus :**
   ```
   🔄 [SYNC] Synchronisation automatique en cours
   📋 [USER QUEUE SCAN] Scanning X local users for sync to backend
   📥 [USER QUEUE ADD] User test.auto@example.com (ID:124) queued for sync to backend
   📊 [USER QUEUE SCAN] Complete: added=1, skipped=X, queue_size=1
   📤 [SYNCQ] Flushing queue (1 items)...
   ✅ [SYNCQ] Sent item users:upsert:test.auto@example.com => 200
   ```

---

## 📋 Scénario de test 4 : Commandes + Utilisateurs

### Étapes :

1. **Créez un utilisateur** (comme dans le test 1)

2. **Créez une commande** avec cet utilisateur

3. **Vérifiez que les 2 sont synchronisés**

   **Logs attendus :**
   ```
   📥 [USER QUEUE ADD] User test.sync@example.com (ID:123) queued for sync to backend
   📥 [QUEUE ADD] Order #456 queued for sync (updatedAt=...)
   📊 [USER QUEUE SCAN] Complete: added=1, skipped=X
   📊 [QUEUE SCAN] Complete: added=1, skipped=X
   📤 [SYNCQ] Flushing queue (2 items)...
   ✅ [SYNCQ] Sent item users:upsert:test.sync@example.com => 200
   ✅ [SYNCQ] Sent item orders:upsert:456 => 200
   ```

---

## 🔍 Debug rapide

### Voir la file d'attente

Ajoutez ce code temporaire dans `pos_controller.dart` (méthode `createOrder`) :

```dart
// Après la création de l'utilisateur
final queue = SyncQueueService.instance.queue;
final usersInQueue = queue.where((item) => 
  item['entity'] == 'users'
).toList();
appLogger.i('📊 Users in queue: ${usersInQueue.length}');
usersInQueue.forEach((item) {
  final email = item['payload']?['email'];
  appLogger.i('   └─ User: $email');
});
```

### Vider l'état de sync

```bash
# Arrêtez l'application Flutter d'abord !
rm ~/Library/Application\ Support/caisse_1/users_sync_state.json
```

### Forcer une sync manuelle

Si vous avez un bouton "Sync Now" dans les paramètres, utilisez-le.
Sinon, attendez 60 secondes (sync auto).

---

## ✅ Checklist de validation

- [ ] Lancement de l'appli avec token OK
- [ ] Connexion Super Admin OK
- [ ] Création utilisateur test OK
- [ ] Logs de sync utilisateur visibles OK
- [ ] Utilisateur présent dans le backend OK
- [ ] Modification utilisateur OK
- [ ] Pas de duplication OK
- [ ] Sync auto après 60s OK
- [ ] Commandes + utilisateurs synchronisés OK

---

## 🐛 Problèmes courants

### "401 Unauthorized"

**Cause :** Token expiré ou invalide

**Solution :**
```bash
# Régénérer un token
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan tinker

>>> $user = App\Models\User::find(23);
>>> $user->tokens()->delete();
>>> $token = $user->createToken('pos-sync')->plainTextToken
>>> echo $token;
```

Puis relancez avec le nouveau token.

### "Connection refused"

**Cause :** Backend Laravel non démarré

**Solution :**
```bash
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan serve
```

### "No users in queue"

**Cause :** Utilisateurs déjà synchronisés

**Solution :**
```bash
# Vider l'état de sync
rm ~/Library/Application\ Support/caisse_1/users_sync_state.json
# Redémarrez l'appli
```

---

## 📊 Exemple de session réussie

```bash
# Terminal 1 : Backend
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan serve

# Terminal 2 : Flutter
cd /Users/macbookpro/Documents/caisse1-main
flutter run -d macos \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=API_TOKEN=202|rcijFRypRHMJpJBmVoJgG1M53l8XGsvxpItNpuGu9ba2bf54

# Dans l'application :
# 1. Login avec 0600000000
# 2. Créer utilisateur test.sync@example.com
# 3. Attendre 60 secondes

# Console Flutter :
✅ User created locally with ID: 45
📥 [USER QUEUE ADD] User test.sync@example.com (ID:45) queued for sync to backend
📊 [USER QUEUE SCAN] Complete: added=1, skipped=4, queue_size=1
📤 [SYNCQ] Flushing queue (1 items)...
🚀 [SYNCQ] Sending item: users:upsert:test.sync@example.com
✅ [SYNCQ] Sent item users:upsert:test.sync@example.com => 200
💾 [USER SYNC STATE] Saved sync state for User test.sync@example.com

# Terminal 3 : Vérification backend
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan tinker
>>> App\Models\User::where('email', 'test.sync@example.com')->first()
// ✅ Retourne l'utilisateur
```

---

**Date :** 2025-04-02  
**Statut :** ✅ PRÊT POUR TEST
