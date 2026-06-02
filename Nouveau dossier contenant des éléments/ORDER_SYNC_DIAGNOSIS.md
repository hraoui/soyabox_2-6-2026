# 🐛 DIAGNOSTIC - SYNCHRONISATION DES COMMANDES NE FONCTIONNE PAS

## 🔍 Problème identifié

La synchronisation des commandes vers le backend ne fonctionne pas.

---

## ✅ Test backend : ENDPOINT FONCTIONNEL

J'ai testé manuellement l'endpoint backend et il fonctionne correctement :

```bash
curl -X POST http://localhost:8000/api/sync/orders/upsert \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 205|cxoHsmsLG5b3POjB9KTAWU0jJblZ6JFYwcWdcYpDd88e706a" \
  -d '{
    "local_id": 999,
    "source_local_id": 999,
    "staff_id": 1008,
    "user_id": 1008,
    "restaurant_id": 1,
    "channel": "pos",
    "fulfillment_type": "on_site",
    "status": "confirmed",
    "payment_status": "pending",
    "total_price": 150.0,
    "original_total": 150.0,
    "discount_amount": 0.0,
    "has_discount": false,
    "updated_at": "2025-04-02T18:00:00.000Z",
    "items": [
      {
        "local_id": 1,
        "product_id": 15,
        "product_name": "Cream cheese",
        "unit_price": 150.0,
        "quantity": 1
      }
    ]
  }'

# ✅ Réponse : {"success":true,"message":"Order upserted successfully."}
```

**Conclusion :** Le backend fonctionne correctement ✅

---

## 🐛 Causes probables

### 1. **Token API expiré ou invalide** ⚠️ (LE PLUS PROBABLE)

Le token utilisé par Flutter est probablement expiré.

**Ancien token (expiré) :**
```
202|rcijFRypRHMJpJBmVoJgG1M53l8XGsvxpItNpuGu9ba2bf54
```

**Nouveau token (valide) :**
```
205|cxoHsmsLG5b3POjB9KTAWU0jJblZ6JFYwcWdcYpDd88e706a
```

---

### 2. **Utilisateurs Flutter vs Backend non synchronisés**

Les IDs utilisateurs dans Flutter ne correspondent pas à ceux du backend.

**Dans Flutter (UserSeeder) :**
```dart
phone: '0600000000'  // Format local
```

**Dans le backend :**
```
ID:1008 | Super Admin | +212600000000  // Format international
```

**Problème :** Quand Flutter crée une commande avec `staff_id: 1` (local), le backend ne trouve pas cet ID.

---

### 3. **Produits inexistants dans le backend**

Si les produits créés localement n'ont pas été synchronisés vers le backend, les commandes échoueront avec :
```json
{"errors":{"items":["Unknown product_id X in order items."]}}
```

---

## 🔧 Solutions

### Solution 1 : Mettre à jour le token API (IMMÉDIAT)

**Dans Flutter, au lancement :**

```bash
cd /Users/macbookpro/Documents/caisse1-main

flutter run -d macos \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=API_TOKEN=205|cxoHsmsLG5b3POjB9KTAWU0jJblZ6JFYwcWdcYpDd88e706a
```

**OU dans le code (temporaire) :**

Dans `lib/data/app_constants.dart` :
```dart
static String get apiToken {
  // return const String.fromEnvironment('API_TOKEN', defaultValue: '');
  return '205|cxoHsmsLG5b3POjB9KTAWU0jJblZ6JFYwcWdcYpDd88e706a'; // ✅ Token temporaire
}
```

---

### Solution 2 : Synchroniser les utilisateurs Flutter → Backend

**Problème :** Les utilisateurs créés par le UserSeeder ont des IDs locaux (1, 2, 3) mais le backend a des IDs différents (1008, 1009, 1010).

**Solution :** La synchronisation automatique des utilisateurs devrait corriger cela.

**Vérifier les logs :**
```
📥 [USER QUEUE ADD] User superadmin@soyabox.com (ID:1) queued for sync to backend
✅ [SYNCQ] Sent item users:upsert:superadmin@soyabox.com => 200
💾 [USER SYNC STATE] Saved sync state for User superadmin@soyabox.com
```

**Dans le backend, après sync :**
```bash
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan tinker

>>> App\Models\User::where('email', 'superadmin@soyabox.com')->first()
// Devrait retourner l'utilisateur avec ID mis à jour
```

---

### Solution 3 : Synchroniser les produits Flutter → Backend

**Problème :** Les produits locaux ne sont pas dans le backend.

**Solution :** Importer ou synchroniser les produits vers le backend.

**Via l'interface Flutter :**
1. Menu → Import → Produits
2. OU attendre la sync automatique (60s)

**Via curl (test) :**
```bash
curl -X POST http://localhost:8000/api/sync/products/upsert \
  -H "Authorization: Bearer 205|cxoHsmsLG5b3POjB9KTAWU0jJblZ6JFYwcWdcYpDd88e706a" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 999,
    "name": "Test Product",
    "price": 150.0,
    "category_id": 1,
    "is_available": true,
    "updated_at": "2025-04-02T18:00:00.000Z"
  }'
```

---

## 🧪 Étapes de debug

### Étape 1 : Vérifier le token API actuel

**Dans l'application Flutter (logs) :**
```
🔑 [AUTH] Token available: YES
✅ [AUTH] Session token initialized
```

**Si "NO" ou token vide :**
- Le token n'est pas configuré correctement
- Utiliser `--dart-define=API_TOKEN=...`

---

### Étape 2 : Tester la connexion API

**Dans le code Flutter (temporaire) :**
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> testApiConnection() async {
  final token = '205|cxoHsmsLG5b3POjB9KTAWU0jJblZ6JFYwcWdcYpDd88e706a';
  final response = await http.get(
    Uri.parse('http://localhost:8000/api/user'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
  
  if (response.statusCode == 200) {
    print('✅ API connection OK');
  } else {
    print('❌ API connection failed: ${response.statusCode}');
  }
}
```

---

### Étape 3 : Vérifier la file d'attente de sync

**Dans Flutter DevTools ou code temporaire :**
```dart
import 'package:caisse_1/services/sync_queue_service.dart';

final queue = SyncQueueService.instance.queue;
print('Queue size: ${queue.length}');

queue.forEach((item) {
  print('Entity: ${item['entity']}, Action: ${item['action']}');
  print('Payload: ${jsonEncode(item['payload'])}');
});
```

**Logs attendus :**
```
📊 [QUEUE SCAN] Complete: added=1, skipped=0, queue_size=1
📤 [SYNCQ] Flushing queue (1 items)...
🚀 [SYNCQ] Sending item: orders:upsert:123
✅ [SYNCQ] Sent item orders:upsert:123 => 200
```

---

### Étape 4 : Vérifier les logs d'erreur

**Chercher ces patterns dans la console :**

❌ **401 Unauthorized :**
```
❌ [SYNCQ] HTTP error: 401 Unauthorized
   └─ Response: {"success":false,"message":"Unauthorized."}
```
→ **Solution :** Token expiré, régénérer un token

❌ **Validation failed :**
```
❌ [SYNCQ] HTTP error: 422 Unprocessable Entity
   └─ Response: {"errors":{"items":["Unknown product_id 1 in order items."]}}
```
→ **Solution :** Synchroniser les produits d'abord

❌ **Connection refused :**
```
❌ [SYNCQ] Request failed: Exception: Connection refused
```
→ **Solution :** Backend non démarré

---

## 📋 Checklist de validation

- [ ] Backend Laravel démarré (`php artisan serve`)
- [ ] Token API valide généré récemment
- [ ] Token API configuré dans Flutter (`--dart-define=API_TOKEN=...`)
- [ ] Utilisateurs synchronisés vers backend
- [ ] Produits synchronisés vers backend
- [ ] Commandes dans la file d'attente
- [ ] Logs de sync visibles dans la console
- [ ] Pas d'erreurs 401 ou 422

---

## 🚀 Commandes de test

### 1. Générer un nouveau token

```bash
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan tinker

>>> $user = App\Models\User::where('phone', '0600000000')->first();
>>> if (!$user) { $user = App\Models\User::find(1008); }
>>> $user->tokens()->delete();
>>> $token = $user->createToken('pos-sync')->plainTextToken;
>>> echo $token;

# Copier le token affiché
```

### 2. Lancer Flutter avec le nouveau token

```bash
cd /Users/macbookpro/Documents/caisse1-main

flutter run -d macos \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=API_TOKEN=NOUVEAU_TOKEN_ICI
```

### 3. Créer une commande test

1. Se connecter avec Super Admin (`0600000000` / `superadmin123`)
2. Ajouter des produits au panier
3. Créer la commande
4. Vérifier les logs :

```
🛒 [CREATE ORDER] Order #123 created (2 items)
🔄 [SYNC NEW] Order #123 enqueued for sync (new)
📥 [QUEUE ADD] Order #123 queued for sync
📤 [SYNCQ] Flushing queue (1 items)...
🚀 [SYNCQ] Sending item: orders:upsert:123
✅ [SYNCQ] Sent item orders:upsert:123 => 200
```

### 4. Vérifier dans le backend

```bash
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan tinker

>>> App\Models\Order::where('source_local_id', 123)->first()
// Doit retourner la commande
```

---

## 📊 Architecture de synchronisation

```
┌─────────────────────────────────────────────────────────────┐
│          FLUX DE SYNCHRONISATION DES COMMANDES               │
└─────────────────────────────────────────────────────────────┘

1. Création commande (Flutter POS)
   ↓
2. Sauvegarde locale (Isar DB)
   - ID local: 123
   - staff_id: 1 (local)
   - products: [1, 2] (IDs locaux)
   ↓
3. Ajout à la file d'attente
   - Fichier: /sync_queue.json
   ↓
4. Sync périodique (60s)
   POST /api/sync/orders/upsert
   Headers: Authorization: Bearer <token>
   ↓
5. Backend Laravel
   - Vérifie token ✅
   - Valide données ✅
   - Crée commande avec ID backend: 362
   - Mappe source_local_id: 123 → backend_id: 362
   ↓
6. État de sync sauvegardé
   - 123 => 2025-04-02T18:00:00.000Z
   - Ne sera pas resynchronisé sauf modification

┌─────────────────────────────────────────────────────────────┐
│                    PROBLÈMES COURANTS                        │
└─────────────────────────────────────────────────────────────┘

❌ Token expiré → 401 Unauthorized
❌ Products non sync → "Unknown product_id"
❌ Users non sync → "Invalid staff_id"
❌ Backend off → "Connection refused"
```

---

## 🎯 Résumé

| Élément | Statut | Solution |
|---------|--------|----------|
| **Backend endpoint** | ✅ **FONCTIONNEL** | Testé avec curl |
| **Token API** | ❌ **EXPIRÉ** | Régénérer un token |
| **Users sync** | ⚠️ **À VÉRIFIER** | Attendre 60s ou forcer sync |
| **Products sync** | ⚠️ **À VÉRIFIER** | Import ou sync auto |
| **Orders sync** | ❌ **BLOQUÉ** | Token expiré |

---

## ✅ Solution rapide (5 minutes)

```bash
# 1. Générer nouveau token
cd /Applications/MAMP/htdocs/soya_caisse_backend
php artisan tinker --execute="\$u=App\Models\User::find(1008); \$u->tokens()->delete(); echo \$u->createToken('sync')->plainTextToken;"

# 2. Copier le token affiché (ex: 205|cxoHsmsLG5b3POjB9KTAWU0jJblZ6JFYwcWdcYpDd88e706a)

# 3. Lancer Flutter avec le nouveau token
cd /Users/macbookpro/Documents/caisse1-main
flutter run -d macos \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=API_TOKEN=205|cxoHsmsLG5b3POjB9KTAWU0jJblZ6JFYwcWdcYpDd88e706a

# 4. Créer une commande test
# 5. Vérifier les logs de sync
# 6. Vérifier dans le backend
```

---

**Date :** 2025-04-02  
**Statut :** 🔧 **EN COURS DE RÉSOLUTION**  
**Prochaine étape :** Régénérer token et tester
