# Sync Queue Service - Améliorations de Gestion d'Erreurs ✅

## Résumé des Modifications

Le fichier `lib/services/sync_queue_service.dart` a été amélioré pour gérer correctement les erreurs de synchronisation et éviter les boucles de retry infinies.

## Modifications Implémentées

### 1. **Gestion des Erreurs 404 (Order Not Found)**

**Problème :** Quand une commande n'existe pas sur le backend (404), le système continuait à réessayer indéfiniment.

**Solution :** 
- Détection du cache vidé (remoteOrderId = null)
- Marquage comme succès pour éviter les retries

```dart
// Ligne ~959-967
if (remoteIdStillInCache == null || remoteIdStillInCache <= 0) {
  appLogger.w(
    '⏭️ [SKIP RETRY] Remote order for local #$localOrderId was cleared from cache (404). '
    'Marking queue item as success to skip retries.',
  );
  return _QueueSendOutcome.success;
}
```

**Résultat :** Les items avec erreurs 404 sont marqués comme succès et retirés de la queue.

---

### 2. **Gestion des Erreurs 401 (Unauthorized)**

**Problème :** Les erreurs 401 (token expiré/invalid) causaient des retries infinies car le token ne se rafraîchit pas automatiquement.

**Solution :**
- Comptage des erreurs 401
- Après 3 tentatives → Déplacement en Dead Letter Queue
- L'utilisateur doit se re-login

#### A. Pour Status Sync (lignes ~970-997)

```dart
// Check if this is a 401 unauthorized error
final lastError = item['last_error']?.toString() ?? '';
if (lastError.contains('unauthorized_401') || lastError.contains('401')) {
  // 401 errors won't recover without re-login
  final retryCount = _recordCountedFailure(
    item,
    reason: 'unauthorized_401',
    error: 'Status sync failed: 401 Unauthorized for local order #$localOrderId',
  );
  
  if (retryCount >= _maxRetryCount) {
    await _moveToDeadLetter(
      item,
      reason: 'max_retries_unauthorized',
      details: 'Status sync failed after $_maxRetryCount attempts due to 401 Unauthorized. '
          'User needs to re-login. local_order=$localOrderId',
    );
    appLogger.d(
      '🚨 Queue item moved to dead letter: status sync for local #$localOrderId '
      'failed after $_maxRetryCount attempts due to 401',
    );
    return _QueueSendOutcome.deadLettered;
  }
  
  appLogger.d(
    '⚠️ Status sync 401 for local #$localOrderId, attempt $retryCount/$_maxRetryCount',
  );
}
```

#### B. Pour General Sync Endpoints (lignes ~1059-1084)

```dart
if (response.statusCode == 401) {
  appLogger.d(
    '❌ Sync unauthorized; token missing/invalid. endpoint=$endpoint',
  );
  
  final retryCount = _recordCountedFailure(
    item,
    reason: 'unauthorized_401',
    error: 'HTTP 401 Unauthorized for endpoint=$endpoint',
  );
  
  if (retryCount >= _maxRetryCount) {
    await _moveToDeadLetter(
      item,
      reason: 'max_retries_unauthorized',
      details: 'HTTP 401 persisted after $_maxRetryCount attempts for endpoint=$endpoint. '
          'User needs to re-login.',
    );
    appLogger.d(
      '🚨 Queue item moved to dead letter after $retryCount 401 errors: entity=$entity action=$action',
    );
    return _QueueSendOutcome.deadLettered;
  }
  
  appLogger.d(
    '⚠️ Sync 401 [$entity/$action] endpoint=$endpoint attempt=$retryCount/$_maxRetryCount',
  );
  return _QueueSendOutcome.retryable;
}
```

---

## Comportement du Système

### Avant les Modifications

```
🔄 Retry infini → 401 → Retry → 401 → Retry → 401 → ... (infini)
```

**Problèmes :**
- Queue remplie d'items en échec
- Consommation de ressources inutile
- Logs pollués
- Aucune indication claire pour l'utilisateur

### Après les Modifications

```
⚠️ Sync 401 attempt 1/3
⚠️ Sync 401 attempt 2/3  
⚠️ Sync 401 attempt 3/3
🚨 Moved to dead letter queue
✅ Item removed from active queue
```

**Avantages :**
- Max 3 tentatives avant arrêt
- Dead letter queue pour analyse
- Logs clairs et structurés
- L'utilisateur sait qu'il doit se re-login

---

## Dead Letter Queue

### Consultation des Items en Échec

```dart
// Obtenir tous les items en dead letter
final failedItems = SyncQueueService.instance.getFailedItems();

// Afficher les détails
for (final item in failedItems) {
  print('Reason: ${item['skip_reason']}');
  print('Details: ${item['dead_letter_details']}');
  print('Failed at: ${item['dead_lettered_at']}');
}
```

### Structure d'un Item Dead Letter

```json
{
  "entity": "orders",
  "action": "status",
  "payload": { "local_id": 123, "status": "confirmed" },
  "retry_count": 3,
  "skip_reason": "max_retries_unauthorized",
  "dead_lettered": true,
  "dead_lettered_at": "2026-04-10T22:34:56.852Z",
  "dead_letter_details": "Status sync failed after 3 attempts due to 401 Unauthorized. User needs to re-login. local_order=123"
}
```

---

## Configuration

### Max Retry Count

Défini dans le fichier (ligne ~28) :

```dart
static const int _maxRetryCount = 3;
```

**Personnalisation :** Modifier cette valeur pour ajuster le nombre de tentatives avant dead letter.

---

## Logs et Monitoring

### Logs d'Erreurs 401

```
⚠️ Sync 401 [orders/status] endpoint=/api/sync/public/orders/status attempt=1/3
⚠️ Sync 401 [orders/status] endpoint=/api/sync/public/orders/status attempt=2/3
⚠️ Sync 401 [orders/status] endpoint=/api/sync/public/orders/status attempt=3/3
🚨 Queue item moved to dead letter after 3 401 errors: entity=orders action=status
```

### Logs d'Erreurs 404

```
🗑️ [CACHE CLEAR] Remote order #123 not found on backend (404). Clearing stale cache mapping.
⏭️ [SKIP RETRY] Remote order for local #123 was cleared from cache (404). Marking queue item as success.
```

---

## Recommendations

### 1. **Monitoring de la Dead Letter Queue**

Implémenter une notification si la dead letter queue contient des items :

```dart
// Dans le dashboard admin
final failedItems = SyncQueueService.instance.getFailedItems();
if (failedItems.isNotEmpty) {
  // Afficher une alerte
  showWarning('${failedItems.length} sync failures in dead letter queue');
}
```

### 2. **Nettoyage Automatique**

Supprimer les anciens items de la dead letter queue après X jours :

```dart
Future<void> cleanOldDeadLetterItems() async {
  final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
  _deadLetterQueue.removeWhere((item) {
    final failedAt = DateTime.tryParse(item['dead_lettered_at'] ?? '');
    return failedAt != null && failedAt.isBefore(cutoffDate);
  });
  await _saveDeadLetterQueue();
}
```

### 3. **Retry Manuel**

Permettre à l'admin de retry manuellement après re-login :

```dart
Future<void> retryDeadLetterItems() async {
  final itemsToRetry = List.from(_deadLetterQueue);
  _deadLetterQueue.clear();
  
  for (final item in itemsToRetry) {
    item['dead_lettered'] = false;
    item['retry_count'] = 0;
    item.remove('skip_reason');
    _queue.add(item);
  }
  
  await _saveDeadLetterQueue();
  await flushQueue();
}
```

---

## Testing

### Tester les Erreurs 401

1. Se connecter avec un token valide
2. Invalider le token côté backend
3. Observer les logs : 3 tentatives puis dead letter
4. Se re-login
5. Les nouveaux items seront syncés correctement

### Tester les Erreurs 404

1. Créer une commande locale
2. Supprimer la commande correspondante sur le backend
3. Tenter la sync
4. Observer : cache cleared + item marqué comme succès

---

## Date
April 10, 2026
