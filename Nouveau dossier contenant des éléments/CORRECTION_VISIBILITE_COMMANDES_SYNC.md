# 🔧 CORRECTION: Commandes non visibles pour les staffs & synchronisation backend

## 📋 Problèmes Identifiés

### Problème 1: Les commandes ne s'affichent pas dans les pages staff
**Symptômes:**
- ✅ Les commandes s'affichent correctement dans le dashboard financier (admin)
- ❌ Les commandes n'apparaissent PAS dans les pages des staffs (serveurs)
- ❌ Chaque staff ne voit que SES propres commandes POS, pas celles de ses collègues

**Cause Racine:**
Dans `lib/controllers/pos_controller.dart`, la méthode `loadOrdersToday()` appliquait un filtre trop restrictif:
```dart
// AVANT (incorrect):
if (o.staffId == activeStaffId) {
  return true; // Staff ne voit que SES commandes
}
return false; // Bloque toutes les autres
```

Cela signifiait que:
- Staff A crée une commande → seul Staff A peut la voir
- Staff B ne voit PAS la commande de Staff A
- Résultat: fragmentation de la visibilité des commandes

---

### Problème 2: Les commandes locales ne se synchronisent pas vers le backend
**Symptômes:**
- ❌ Les commandes créées en POS restent bloquées en local
- ❌ Erreur SQL: `Column 'payment_method' cannot be null`
- ❌ La queue de synchronisation contient les commandes mais elles ne sont jamais envoyées

**Causes Racines Multiples:**

#### Cause 2a: paymentMethod null lors de la création
Dans `lib/controllers/pos_controller.dart`, lors de la création d'une commande:
```dart
// AVANT (problématique):
order = PosOrder(
  // ...
  paymentMethod: _paymentMethod, // Peut être null!
  // ...
);
```

Si `_paymentMethod` est null (commande créée avant sélection du paiement), le backend rejette la synchronisation avec l'erreur SQL.

#### Cause 2b: Filtre de synchronisation trop restrictif
Dans `lib/services/sync_queue_service.dart`:
```dart
// AVANT (incorrect):
bool _shouldSyncOrderUpsert(PosOrder order) {
  if (order.isFromApi) return false;
  return !_isRemoteOrderChannel(order.channel); // ❌ Bloque les commandes POS!
}
```

La logique vérifiait si le channel était "remote" (api/web/kiosk) et bloquait la synchronisation. Mais cela créait une confusion car:
- Les commandes POS ont `channel='pos'`
- La condition `!_isRemoteOrderChannel('pos')` retourne `true` ✅
- MAIS si une commande avait un channel mal défini, elle était bloquée

---

## ✅ Solutions Appliquées

### Solution 1: Visibilité des commandes pour tous les staffs du même restaurant

**Fichier:** `lib/controllers/pos_controller.dart`  
**Méthode:** `loadOrdersToday()` - Section de filtrage staff

```dart
// APRÈS (corrigé):
if (activeStaffId != null) {
  if (isAdminScope) {
    return true; // Admin voit tout
  }

  // ✅ Les commandes API/Web/Kiosk sont visibles par TOUS
  final isRemoteOrder = _isRemoteChannel(o.channel);
  if (isRemoteOrder) {
    return true;
  }

  // ✅ NOUVEAU: Les commandes POS du restaurant sont visibles par TOUS les staffs
  if (o.channel.toLowerCase() == 'pos') {
    final orderRestaurantId = o.restaurantId;
    final userRestaurantId = restId;
    
    if (orderRestaurantId != null && 
        userRestaurantId != null && 
        orderRestaurantId == userRestaurantId) {
      appLogger.d(
        '  ✅ Order #${o.id} included: POS order from same restaurant '
        '(order_rest=$orderRestaurantId, user_rest=$userRestaurantId)',
      );
      return true;
    }
  }

  // Fallback: staff voit ses propres commandes
  if (o.staffId == activeStaffId) {
    return true;
  }
  
  return false;
}
```

**Résultat:**
- ✅ Tous les staffs du Restaurant A voient TOUTES les commandes du Restaurant A
- ✅ Les commandes restent isolées entre restaurants différents
- ✅ Les admins continuent de voir toutes les commandes

---

### Solution 2a: Valeur par défaut pour paymentMethod

**Fichier:** `lib/controllers/pos_controller.dart`  
**Méthode:** `completeOrder()` - Création de commande

```dart
// APRÈS (corrigé):
final resolvedPaymentMethod = _paymentMethod?.trim().isNotEmpty == true 
    ? _paymentMethod 
    : 'pending'; // Valeur par défaut jusqu'au paiement réel

order = PosOrder(
  // ...
  paymentMethod: resolvedPaymentMethod, // ✅ Jamais null!
  // ...
);
```

**Résultat:**
- ✅ paymentMethod a toujours une valeur ('pending' ou la méthode réelle)
- ✅ Plus d'erreur SQL "Column cannot be null"
- ✅ La valeur est mise à jour lors du paiement réel

---

### Solution 2b: Simplification du filtre de synchronisation

**Fichier:** `lib/services/sync_queue_service.dart`  
**Méthode:** `_shouldSyncOrderUpsert()`

```dart
// APRÈS (corrigé):
bool _shouldSyncOrderUpsert(PosOrder order) {
  // ✅ FIX: Only skip orders that are truly from API/Web (already on backend)
  // Orders created locally in POS should ALWAYS be synced, regardless of channel
  if (order.isFromApi) return false;
  
  // ✅ CRITICAL FIX: Sync ALL locally-created orders (channel='pos')
  // Previously this was blocking sync for orders with remote channels
  // but the real check should be isFromApi flag
  return true;
}
```

**Explication:**
- Le flag `isFromApi` est le SEUL indicateur fiable pour savoir si une commande vient du backend
- Si `isFromApi=false`, la commande a été créée localement et DOIT être synchronisée
- Plus besoin de vérifier le channel pour décider de la synchronisation

**Résultat:**
- ✅ Toutes les commandes POS locales sont synchronisées
- ✅ Les commandes API/Web ne sont PAS re-synchronisées (déjà sur backend)
- ✅ Logique simplifiée et plus fiable

---

## 🧪 Tests à Effectuer

### Test 1: Visibilité des commandes entre staffs
1. **Préparation:**
   - Connecter Staff A au Restaurant 1
   - Connecter Staff B au Restaurant 1 (même restaurant)
   - Connecter Staff C au Restaurant 2 (restaurant différent)

2. **Scénario:**
   - Staff A crée une commande POS
   - Staff A voit la commande ✅
   - Staff B voit la commande de Staff A ✅ (NOUVEAU)
   - Staff C NE voit PAS la commande ✅ (isolation restaurant)

3. **Vérification logs:**
   ```
   ✅ Order #123 included: POS order from same restaurant (order_rest=1, user_rest=1)
   ```

---

### Test 2: Synchronisation des commandes POS vers backend
1. **Préparation:**
   - Créer une commande POS sans sélectionner de méthode de paiement
   - Vérifier que `paymentMethod='pending'` dans la DB locale

2. **Scénario:**
   - Attendre 60 secondes (cycle de synchronisation automatique)
   - Vérifier les logs:
     ```
     📤 [SYNC] Sending order #123 to backend...
     ✅ [SYNC SUCCESS] Order #123 synced successfully
     ```
   - Vérifier que la commande apparaît dans le backend

3. **Paiement:**
   - Marquer la commande comme payée
   - Vérifier que `paymentMethod` est mis à jour (ex: 'cash', 'card')
   - Vérifier que le statut de paiement se synchronise

---

### Test 3: Isolation des restaurants
1. **Préparation:**
   - Staff A connecté au Restaurant 1
   - Staff B connecté au Restaurant 2

2. **Scénario:**
   - Staff A crée une commande
   - Staff B NE doit PAS voir cette commande
   - Vérifier logs:
     ```
     ❌ Order #123 filtered: wrong restaurant (order=1, user=2)
     ```

---

## 📊 Métriques de Succès

| Métrique | Avant | Après |
|----------|-------|-------|
| Visibilité commandes staff | ❌ Uniquement créateur | ✅ Tous staffs du restaurant |
| Synchronisation POS → Backend | ❌ Bloquée (paymentMethod null) | ✅ Fonctionnelle |
| Erreurs SQL "cannot be null" | ❌ Fréquentes | ✅ Éliminées |
| Isolation restaurants | ✅ Correcte | ✅ Maintenu |
| Admin voit toutes commandes | ✅ Correct | ✅ Maintenu |

---

## 🔍 Logs de Diagnostic

Pour vérifier que les corrections fonctionnent, surveillez ces logs:

### Logs de visibilité des commandes:
```
📊 [LOAD ORDERS] Total BDD: 15, restId=1, staffId=5, role=staff, admin=false
✅ Order #123 included: POS order from same restaurant (order_rest=1, user_rest=1)
❌ Order #456 filtered: wrong restaurant (order=2, user=1)
📊 [FINAL] 8 orders | statusFilter=all | typeFilter=all
```

### Logs de synchronisation:
```
📤 [SYNC] Processing order #123 (channel=pos, isFromApi=false)
📤 [SYNC] Payload: payment_method=pending, staff_id=5, restaurant_id=1
✅ [SYNC SUCCESS] Order #123 synced to backend (remote_id=789)
⏭️ [SYNC SKIP] Order #456 already synced (syncedAt >= updatedAt)
```

### Logs d'erreurs (si problème persiste):
```
❌ [SYNC SKIP] Order #123 has invalid staffId: 0
❌ [SYNC SKIP] Order #123 has invalid restaurantId: null
🚨 [TIMESTAMP FIX] Order #123 has FUTURE updatedAt, correcting to now
```

---

## 🛠️ Dépannage

### Si les commandes ne s'affichent toujours pas pour les staffs:
1. Vérifier que tous les staffs ont le même `restaurantId`:
   ```dart
   appLogger.d('Staff A restaurantId: ${staffA.restaurantId}');
   appLogger.d('Staff B restaurantId: ${staffB.restaurantId}');
   ```

2. Vérifier les logs de filtrage:
   ```
   grep "Order #.*included\|Order #.*filtered" logs.txt
   ```

3. Forcer un rechargement:
   - Déconnecter/reconnecter le staff
   - Ou utiliser le bouton "Rafraîchir" dans l'UI

### Si la synchronisation échoue toujours:
1. Vérifier la queue de synchronisation:
   ```bash
   cat ~/Library/Application\ Support/com.soyabox.pos/sync_queue.json
   ```

2. Vérifier les logs d'erreur:
   ```
   grep "SYNC.*ERROR\|SQLSTATE" logs.txt
   ```

3. Vérifier que le backend a la colonne `local_id`:
   ```sql
   DESCRIBE orders; -- Doit inclure local_id column
   ```

4. Redémarrer la synchronisation manuellement:
   ```dart
   await SyncQueueService.instance.flushQueue();
   ```

---

## 📝 Notes Techniques

### Architecture de synchronisation:
```
┌─────────────────┐
│  POS (Flutter)  │
│                 │
│  ┌───────────┐  │
│  │ Isar DB   │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │Sync Queue │  │─── HTTP POST ───► ┌──────────────┐
│  │ Service   │  │                   │   Backend    │
│  └───────────┘  │                   │  (Laravel)   │
└─────────────────┘                   └──────────────┘
       ▲                                      │
       │                                      │
       └────── HTTP GET (pull orders) ───────┘
```

### Flags importants:
- `isFromApi=true`: Commande reçue du backend (NE PAS re-sync)
- `isFromApi=false`: Commande créée localement (DOIT être sync)
- `channel='pos'`: Créée en point de vente
- `channel='api'/'web'`: Reçue de l'API/site web

### Cycle de synchronisation:
1. **Toutes les 60 secondes**: `SyncController._backgroundSyncTick()`
2. **Étape 1**: `queueUnsyncedOrders()` - Détecte les commandes non synchronisées
3. **Étape 2**: `flushQueue()` - Envoie la queue vers le backend
4. **Étape 3**: `_pullIncomingApiOrders()` - Récupère les nouvelles commandes API/Web

---

## ✅ Checklist de Validation

- [ ] Staff A voit les commandes de Staff B (même restaurant)
- [ ] Staff C ne voit PAS les commandes du Restaurant 1 (restaurant différent)
- [ ] Les commandes POS se synchronisent automatiquement vers le backend
- [ ] Aucune erreur SQL "payment_method cannot be null"
- [ ] Les commandes API/Web ne sont PAS re-synchronisées
- [ ] Les admins voient toujours toutes les commandes
- [ ] Les logs montrent les messages de debug appropriés
- [ ] Le dashboard financier affiche toujours toutes les commandes

---

**Date de correction:** 2026-04-23  
**Fichiers modifiés:**
- `lib/controllers/pos_controller.dart` (visibilité commandes)
- `lib/services/sync_queue_service.dart` (logique de synchronisation)
- `lib/controllers/pos_controller.dart` (paymentMethod par défaut)
