# ✅ Synchronisation des utilisateurs - IMPLÉMENTATION TERMINÉE

## 📋 Résumé des modifications

La synchronisation des utilisateurs a été ajoutée pour fonctionner **uniquement dans le sens Flutter local → Backend Laravel**.

### 🔧 Fichiers modifiés

1. **`lib/services/sync_queue_service.dart`**
   - Ajout de `_usersSyncState` pour tracker les utilisateurs synchronisés
   - Ajout de `_usersStateFile` pour la persistance
   - Nouvelle méthode `queueUnsyncedUsers()` pour scanner les utilisateurs à synchroniser
   - Nouvelle méthode `_saveUsersSyncState()` pour sauvegarder l'état
   - Mise à jour de `_startPeriodicFlush()` pour inclure les utilisateurs
   - Mise à jour de `flushQueue()` pour sauvegarder l'état après sync réussie

2. **`lib/controllers/sync_controller.dart`**
   - Ajout de l'appel à `queueUnsyncedUsers()` dans `_syncInternal()`

---

## 🔄 Flux de synchronisation des utilisateurs

```
┌─────────────────────────────────────────────────────────────┐
│          SYNC UTILISATEURS (Local → Backend uniquement)      │
└─────────────────────────────────────────────────────────────┘

1. Création/Modification utilisateur dans Flutter
   ↓
2. Sauvegarde locale (Isar DB)
   ↓
3. Ajout automatique à la file d'attente (SyncQueueService)
   - Fichier: /users_sync_state.json
   - Clé: email (minuscule)
   ↓
4. Sync périodique (toutes les 60 secondes)
   POST http://localhost:8000/api/sync/users/upsert
   Headers: Authorization: Bearer <token>
   ↓
5. Backend Laravel crée/mette à jour l'utilisateur
   - Vérifie si email existe déjà
   - Update si existe, Create si nouveau
   ↓
6. État de sync sauvegardé
   - Email + timestamp sauvegardés
   - Ne sera pas resynchronisé sauf modification

┌─────────────────────────────────────────────────────────────┐
│                    CE QUI N'EST PAS FAIT                     │
└─────────────────────────────────────────────────────────────┘

❌ PAS de pull des utilisateurs du backend vers Flutter
❌ PAS de duplication si l'utilisateur existe déjà
❌ PAS de sync des utilisateurs "api" (ceux venant du backend)

```

---

## 🧪 Comment tester

### 1. Lancer l'application avec le token

```bash
cd /Users/macbookpro/Documents/caisse1-main

flutter run -d macos \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=API_TOKEN=202|rcijFRypRHMJpJBmVoJgG1M53l8XGsvxpItNpuGu9ba2bf54
```

### 2. Créer un utilisateur

1. Connectez-vous avec le Super Admin (0600000000)
2. Allez dans la gestion des utilisateurs
3. Créez un nouvel utilisateur test
4. Vérifiez les logs :

```
📥 [USER QUEUE ADD] User test@example.com (ID:123) queued for sync to backend
📤 [SYNCQ] Sent item users:upsert:test@example.com => 200
💾 [USER SYNC STATE] Saved sync state for User test@example.com
```

### 3. Vérifier dans le backend

```bash
# Dans un terminal
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan tinker

>>> App\Models\User::where('email', 'test@example.com')->first()
```

### 4. Tester la non-duplication

1. Modifiez l'utilisateur localement (changez le nom par exemple)
2. Attendez 60 secondes (sync auto)
3. Vérifiez que l'utilisateur est mis à jour dans le backend (pas recréé)

---

## 📊 Logs à surveiller

### ✅ Sync réussie

```
📋 [USER QUEUE SCAN] Scanning 5 local users for sync to backend
📥 [USER QUEUE ADD] User admin@example.com (ID:1) queued for sync to backend
📊 [USER QUEUE SCAN] Complete: added=1, skipped=4, queue_size=1
📤 [SYNCQ] Flushing queue (1 items)...
🚀 [SYNCQ] Sending item: users:upsert:admin@example.com
✅ [SYNCQ] Sent item users:upsert:admin@example.com => 200
💾 [USER SYNC STATE] Saved sync state for User admin@example.com
```

### ⏭️ Déjà synchronisé

```
⏭️ [USER SYNC SKIP] User admin@example.com already synced (syncedAt=2025-04-02T18:30:00Z >= updatedAt=2025-04-02T18:30:00Z)
📊 [USER QUEUE SCAN] Complete: added=0, skipped=5, queue_size=0
```

### ⏭️ Déjà dans la file

```
⏭️ [USER QUEUE SKIP] User admin@example.com already in queue, skipping
```

### ❌ Échec (401 Unauthorized)

```
❌ [SYNCQ] HTTP error: 401 Unauthorized
⚠️ [SYNCQ] Item users:upsert:admin@example.com failed, retry_count=1
```

---

## 🛠️ Commandes utiles

### Vider l'état de sync des utilisateurs

```bash
# Supprime le fichier d'état (à faire quand l'appli n'est pas lancée)
rm ~/Library/Application\ Support/caisse_1/users_sync_state.json
```

### Forcer une synchronisation manuelle

Dans l'application (si vous avez un bouton de sync manuelle) ou attendez 60 secondes.

### Voir les utilisateurs en file d'attente

Ajoutez ce code temporairement dans `pos_controller.dart` ou utilisez les DevTools :

```dart
import 'package:caisse_1/services/sync_queue_service.dart';

final queue = SyncQueueService.instance;
final usersInQueue = queue.queue
    .where((item) => item['entity'] == 'users')
    .toList();
print('Users in queue: ${usersInQueue.length}');
```

---

## 🔒 Sécurité

### Ce qui est synchronisé

✅ Champs synchronisés vers le backend :
- `id` (ID local Flutter)
- `name`
- `phone`
- `email` (clé unique)
- `password` (déjà hashée localement)
- `role`
- `restaurant_id`
- `pin_code`
- `badge_code`
- `is_active`
- `created_at`
- `updated_at`

### Ce qui N'EST PAS synchronisé

❌ Utilisateurs avec :
- Email vide ou null
- Déjà synchronisés (pas de modification)
- Déjà dans la file d'attente

---

## 🎯 Architecture

### Fichiers de persistance

```
~/Library/Application Support/caisse_1/
├── sync_queue.json              # File d'attente principale
├── sync_dead_letter_queue.json  # Items en échec répété
├── orders_sync_state.json       # État de sync des commandes
├── users_sync_state.json        # ✅ NOUVEAU: État de sync des utilisateurs
└── api_orders_sync_state.json   # État de sync des commandes API
```

### Format de `users_sync_state.json`

```json
{
  "admin@example.com": "2025-04-02T18:30:00.000Z",
  "serveur@test.com": "2025-04-02T18:35:00.000Z"
}
```

Clé = email (minuscule)  
Valeur = timestamp de la dernière sync réussie (ISO 8601)

---

## 🐛 Dépannage

### Problème : Les utilisateurs ne se synchronisent pas

**Vérifications :**

1. Token API valide ?
   ```bash
   curl -H "Authorization: Bearer VOTRE_TOKEN" http://localhost:8000/api/user
   ```

2. Utilisateurs dans la file ?
   ```dart
   print(SyncQueueService.instance.queue.length);
   ```

3. Logs d'erreur ?
   Cherchez `❌ [USER SYNC]` dans la console

### Problème : Doublons dans le backend

**Cause possible :** Email en casse différente

**Solution :** Le code normalise automatiquement les emails en minuscule :
```dart
final emailKey = user.email!.trim().toLowerCase();
```

### Problème : Sync state corrompu

**Solution :**
```bash
# Arrêtez l'application
rm ~/Library/Application\ Support/caisse_1/users_sync_state.json
# Redémarrez l'application
```

---

## 📝 Notes techniques

### Endpoint backend attendu

```
POST /api/sync/users/upsert
Headers:
  - Authorization: Bearer <token>
  - Content-Type: application/json
  - Accept: application/json

Body:
{
  "id": 123,
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "0612345678",
  "password": "$2y$10$...",
  "role": "staff",
  "restaurant_id": 1,
  "pin_code": "1234",
  "badge_code": "BADGE123",
  "is_active": true,
  "created_at": "2025-04-02T18:00:00.000Z",
  "updated_at": "2025-04-02T18:30:00.000Z"
}
```

### Réponse backend attendue

```json
{
  "success": true,
  "message": "User synced successfully",
  "user": { ... }
}
```

### Gestion des erreurs

- **401 Unauthorized** : Token invalide ou expiré → Retry plus tard
- **400 Bad Request** : Données invalides → Dead letter queue après 3 échecs
- **500 Server Error** : Erreur backend → Retry avec backoff exponentiel

---

## ✅ Checklist de validation

- [x] `queueUnsyncedUsers()` implémenté
- [x] `_saveUsersSyncState()` implémenté
- [x] `_usersStateFile` déclaré et initialisé
- [x] `_usersSyncState` map déclarée
- [x] `_usersSyncStateLock` lock déclaré
- [x] `queueUnsyncedUsers()` appelé dans `_syncInternal()`
- [x] `queueUnsyncedUsers()` appelé dans `_startPeriodicFlush()`
- [x] État sauvegardé après sync réussie dans `flushQueue()`
- [x] Détection des doublons par email
- [x] Skip si déjà synchronisé
- [x] Skip si email vide/null
- [x] Logs détaillés ajoutés

---

## 🚀 Prochaines étapes

1. ✅ Tester la création d'utilisateur
2. ✅ Vérifier la sync vers le backend
3. ✅ Vérifier l'absence de duplication
4. ✅ Tester la modification d'utilisateur
5. ✅ Vérifier que la sync update et ne recrée pas

---

**Date de mise à jour :** 2025-04-02  
**Version :** 1.0.0  
**Statut :** ✅ PRÊT POUR TEST
