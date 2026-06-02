# 🔄 Configuration de la synchronisation des commandes

## Problème actuel
Les commandes créées dans la caisse ne se synchronisent pas avec le backend car **aucun token API n'est configuré**.

## ✅ Solution rapide

### 1. Obtenir un token API

**Méthode recommandée : Utiliser le script automatique**

```bash
# Dans le terminal
cd /Users/macbookpro/Documents/caisse1-main
./scripts/generate_api_token.sh
```

Le script vous guidera pour :
- Voir les utilisateurs existants
- Générer un token pour un utilisateur
- OU créer un nouvel utilisateur admin

**Méthode manuelle : Via Laravel Tinker**

```bash
# 1. Trouvez le chemin de votre backend Laravel
# Ex: /Users/macbookpro/Developer/laravel-pos

# 2. Ouvrez Tinker
cd /chemin/vers/votre/backend/laravel
php artisan tinker

# 3. Dans Tinker, listez les utilisateurs
>>> App\Models\User::all(['id','name','phone','role'])

# 4. Générez un token pour un utilisateur
>>> $user = App\Models\User::find(1); // Remplacez 1 par l'ID
>>> $user->tokens()->delete();
>>> $token = $user->createToken('pos-sync')->plainTextToken
>>> echo $token;
```

**Méthode API : Via curl (si vous connaissez les identifiants)**

```bash
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"VOTRE_PHONE","password":"VOTRE_MDP"}'
```

### 2. Lancer l'application avec le token

**Pour macOS :**
```bash
cd /Users/macbookpro/Documents/caisse1-main

# Remplacez VOTRE_TOKEN_ICI par le token obtenu
flutter run -d macos \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=API_TOKEN=VOTRE_TOKEN_ICI
```

**Pour Windows (dans le terminal Windows) :**
```cmd
cd C:\Users\macbookpro\Developer\caisse1-main

flutter run -d windows ^
  --dart-define=API_BASE_URL=http://localhost:8000 ^
  --dart-define=API_TOKEN=VOTRE_TOKEN_ICI
```

### 3. Vérifier la synchronisation

Après le lancement :
1. Connectez-vous avec un compte admin/staff
2. Créez une commande test
3. Ouvrez la console (logs) et cherchez :
   - `🔄 [SYNC NEW] Order #X enqueued for sync`
   - `✅ [SYNC] Immediate sync completed`
4. Vérifiez dans votre backend que la commande apparaît

---

## 🔍 Debug pas à pas

### Vérifier la connectivité backend

```bash
# Test sans token (doit répondre 401)
curl -i http://localhost:8000/api/orders

# Test avec token (doit répondre 200)
curl -i http://localhost:8000/api/orders \
  -H "Authorization: Bearer VOTRE_TOKEN_ICI"
```

### Logs à surveiller

Dans la console Flutter, cherchez ces messages :

**✅ Sync fonctionne :**
```
🔄 [SYNC NEW] Order #123 enqueued for sync (new)
📤 [SYNCQ] Flushing queue (1 items)...
✅ [SYNCQ] Sent item orders:upsert:123 => 200
✅ [SYNC] Immediate sync completed
```

**❌ Sync échoue :**
```
❌ [SYNCQ] HTTP error: 401 Unauthorized
❌ [SYNCQ] Request failed: Exception: HTTP 401
⚠️ [SYNC] Skipped: No user logged in
```

---

## 🛠️ Commandes utiles

### Lancer en mode debug avec logs détaillés

```bash
flutter run -d macos \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=API_TOKEN=VOTRE_TOKEN_ICI \
  --dart-define=DEBUG_MODE=true
```

### Forcer une synchronisation manuelle

Dans l'application :
1. Allez dans les paramètres (si disponible)
2. Cliquez sur "Synchroniser maintenant"
3. Ou attendez 60 secondes (sync auto)

### Vider la file d'attente de sync (en cas de blocage)

```dart
// Dans la console Flutter DevTools
import 'package:caisse_1/services/sync_queue_service.dart';
await SyncQueueService.instance.clearQueue();
```

---

## 📊 Architecture de synchronisation

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUX DE SYNCHRONISATION                   │
└─────────────────────────────────────────────────────────────┘

1. Création commande (POS)
   ↓
2. Sauvegarde locale (Isar DB)
   - channel: 'pos'
   - isFromApi: false
   - sourceLocalId: <id local>
   ↓
3. Ajout à la file d'attente (SyncQueueService)
   - Fichier: /sync_queue.json
   ↓
4. Envoi au backend (toutes les 45-60s)
   POST http://localhost:8000/api/orders
   Headers: Authorization: Bearer <token>
   ↓
5. Backend crée la commande
   - remote_id: <id backend>
   - source_local_id: <id local>
   ↓
6. Prochaine sync pull : récupère la commande
   - Marquée comme isFromApi: true
   - Ne sera pas renvoyée au backend

┌─────────────────────────────────────────────────────────────┐
│                    COMMANDES SITE WEB                        │
└─────────────────────────────────────────────────────────────┘

1. Commande créée sur le site web
   ↓
2. Backend Laravel crée la commande
   - channel: 'web' ou 'api'
   ↓
3. Sync pull (toutes les 60s)
   GET http://localhost:8000/api/orders
   ↓
4. Création locale dans la caisse
   - channel: 'api'
   - isFromApi: true
   - Notification sonore si status = 'pending'

```

---

## ⚠️ Problèmes courants

### 1. "401 Unauthorized"
**Cause** : Token invalide ou expiré  
**Solution** : Régénérer un token et relancer avec `--dart-define=API_TOKEN=...`

### 2. "Connection refused"
**Cause** : Backend non démarré  
**Solution** : 
```bash
# Vérifier que le backend tourne
curl http://localhost:8000/api/health

# Démarrer Laravel (exemple)
cd /path/to/backend && php artisan serve
```

### 3. Commandes non synchronisées après redémarrage
**Cause** : File d'attente corrompue  
**Solution** :
```bash
# Supprimer les fichiers de sync (l'appli n'est pas lancée)
rm ~/Library/Application\ Support/caisse_1/sync_queue.json
rm ~/Library/Application\ Support/caisse_1/orders_sync_state.json
```

### 4. Sync ne démarre pas
**Cause** : Utilisateur non connecté  
**Solution** : Se connecter avec un compte admin/staff d'abord

---

## 📝 Notes techniques

- **Intervalle de sync auto** : 60 secondes
- **File d'attente** : Persistée dans `/sync_queue.json`
- **Retry max** : 3 tentatives avec backoff exponentiel
- **Dead letter queue** : Items échoués → `/sync_dead_letter_queue.json`
- **Status supportés** : pending, confirmed, preparing, ready, delivered, cancelled

---

## 🔗 Fichiers clés

- `/lib/controllers/sync_controller.dart` : Orchestrateur de sync
- `/lib/services/sync_queue_service.dart` : File d'attente outbound
- `/lib/services/api_order_pull_service.dart` : Récupération inbound
- `/lib/data/app_constants.dart` : Configuration URL/Token
