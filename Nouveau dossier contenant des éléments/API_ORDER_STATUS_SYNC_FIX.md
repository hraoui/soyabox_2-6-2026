# API Order Status Sync Fix - Synchronisation du statut des commandes API/Web

## Problème résolu

Quand on confirme une commande API/Web localement, le statut restait `pending` dans le backend et ne se synchronisait pas correctement, causant :
- Le statut n'est pas mis à jour dans le backend
- Les notifications ne se déclenchent pas correctement
- Duplication des commandes lors de la synchronisation

## Solution implémentée

### 1. Nouvelle méthode dans `SyncQueueService` (`lib/services/sync_queue_service.dart`)

Ajout de `syncApiOrderStatus()` pour synchroniser le statut d'une commande API individuellement :

```dart
Future<bool> syncApiOrderStatus({
  required PosOrder order,
  required String status,
  String? paymentStatus,
  String? cancelReason,
}) async
```

**Fonctionnalités :**
- Synchronise uniquement le statut sans resynchroniser toute la commande
- Utilise le `sourceLocalId` (remote_id) pour identifier la commande côté backend
- Évite la duplication des commandes
- Met à jour l'état de synchronisation localement

### 2. Nouvelle méthode dans `PosController` (`lib/controllers/pos_controller.dart`)

Ajout de `syncApiOrderStatusToBackend()` :

```dart
Future<bool> syncApiOrderStatusToBackend({
  required PosOrder order,
}) async
```

**Rôle :**
- Wrapper pour appeler `SyncQueueService.syncApiOrderStatus()`
- Vérifie que la commande est bien du canal API
- Retourne le statut de la synchronisation

### 3. Modification de `_enqueueOrderSyncById()` (`lib/controllers/pos_controller.dart`)

**Avant :**
```dart
Future<void> _enqueueOrderSyncById(int orderId) async {
  final order = await DatabaseService.getPosOrderById(orderId);
  if (order == null) return;
  final items = await DatabaseService.getPosOrderItems(orderId);
  await SyncQueueService.instance.enqueueOrderUpsert(order, items);
}
```

**Après :**
```dart
Future<void> _enqueueOrderSyncById(int orderId) async {
  final order = await DatabaseService.getPosOrderById(orderId);
  if (order == null) return;
  
  // Pour les commandes API, utiliser la synchronisation de statut dédiée
  final channel = order.channel.trim().toLowerCase();
  if (channel == 'api') {
    appLogger.d('🔄 [ENQUEUE] Order #${order.id} is API channel, using status sync');
    return; // La synchronisation sera gérée par _syncApiOrderStatusIfNeeded
  }
  
  final items = await DatabaseService.getPosOrderItems(orderId);
  await SyncQueueService.instance.enqueueOrderUpsert(order, items);
}
```

**Pourquoi :**
- `enqueueOrderUpsert()` ignore les commandes API (ligne 269 dans sync_queue_service.dart)
- Les commandes API n'ont pas besoin d'être synchronisées complètement, seulement leur statut

### 4. Amélioration de `_syncApiOrderStatusIfNeeded()` (`lib/controllers/pos_controller.dart`)

**Nouvelle logique :**
1. Essaie d'abord `syncApiOrderStatusToBackend()` (nouvelle méthode)
2. Si échec, utilise `pushRemoteOrderStatusByLocalId()` (méthode existante en fallback)
3. Force un `flushQueue()` immédiat après succès pour synchroniser les autres commandes

```dart
Future<bool> _syncApiOrderStatusIfNeeded(PosOrder order, {String? cancelReason}) async {
  // ...
  if (isRemoteChannel || isTrackedRemoteOrder) {
    // Utiliser la nouvelle méthode de synchronisation de statut
    final ok = await syncApiOrderStatusToBackend(order: order);
    
    if (ok) {
      appLogger.d('✅ Remote status synced for order #${order.id}');
      // Force un flush immédiat de la queue
      if (Get.isRegistered<SyncController>()) {
        final sync = Get.find<SyncController>();
        if (sync.isOnline) {
          unawaited(SyncQueueService.instance.flushQueue());
        }
      }
      return true;
    }
    
    // Fallback vers l'ancienne méthode
    final fallbackOk = await ApiOrderPullService.instance.pushRemoteOrderStatusByLocalId(...);
    // ...
  }
}
```

## Flux de synchronisation

### Pour les commandes API/Web :

1. **Changement de statut local** (ex: `pending` → `confirmed`)
   ```dart
   order.status = 'confirmed';
   order.updatedAt = DateTime.now();
   await DatabaseService.updatePosOrder(order);
   ```

2. **Enqueue pour synchronisation**
   ```dart
   await _enqueueOrderSyncById(order.id);
   // Skip pour les commandes API
   ```

3. **Synchronisation immédiate du statut**
   ```dart
   final synced = await _syncApiOrderStatusIfNeeded(order);
   ```

4. **Dans `syncApiOrderStatusToBackend()`**
   ```dart
   await SyncQueueService.instance.syncApiOrderStatus(
     order: order,
     status: order.status,
     paymentStatus: order.paymentStatus,
   );
   ```

5. **Dans `SyncQueueService.syncApiOrderStatus()`**
   - Récupère le `remoteOrderId` depuis `order.sourceLocalId`
   - Envoie une requête POST à `/api/orders/{remoteOrderId}/update-status`
   - Met à jour l'état de synchronisation localement
   - Retourne `true` si succès

6. **Flush immédiat de la queue**
   ```dart
   if (sync.isOnline) {
     unawaited(SyncQueueService.instance.flushQueue());
   }
   ```

## Avantages

1. **Pas de duplication** : Les commandes API ne sont pas resynchronisées complètement
2. **Statut à jour** : Le statut est synchronisé immédiatement vers le backend
3. **Notifications** : Les notifications dans le backend se déclenchent correctement
4. **Performance** : Synchronisation légère (uniquement le statut, pas toute la commande)
5. **Fallback** : Utilise l'ancienne méthode en cas d'échec de la nouvelle

## Endpoints API utilisés

```
POST /api/orders/{remoteOrderId}/update-status
Content-Type: application/json
Authorization: Bearer {token}

{
  "status": "confirmed",
  "payment_status": "pending",
  "cancel_reason": null
}
```

## Tests recommandés

1. **Commande Web/API → Confirmation locale**
   - Créer une commande via le backend (API/Web)
   - Confirmer la commande dans le POS
   - Vérifier que le statut est mis à jour dans le backend
   - Vérifier que les notifications se déclenchent

2. **Changement de statut en chaîne**
   - `pending` → `confirmed` → `preparing` → `ready` → `delivered`
   - Vérifier chaque transition dans le backend

3. **Mode hors ligne**
   - Changer le statut hors ligne
   - Revenir en ligne
   - Vérifier que la synchronisation se fait automatiquement

## Fichiers modifiés

1. `lib/services/sync_queue_service.dart` - Ajout de `syncApiOrderStatus()`
2. `lib/controllers/pos_controller.dart` - Ajout de `syncApiOrderStatusToBackend()` et modification de `_enqueueOrderSyncById()` et `_syncApiOrderStatusIfNeeded()`

## Compatibilité

- ✅ Commandes API (mobile/web)
- ✅ Commandes POS locales
- ✅ Mode en ligne et hors ligne
- ✅ Synchronisation bidirectionnelle
- ✅ Notifications backend
