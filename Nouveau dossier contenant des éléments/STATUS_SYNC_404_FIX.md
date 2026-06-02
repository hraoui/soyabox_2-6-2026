# Status Sync 404 Fix - Clear Stale Remote Order Cache

## Problem

The synchronization status was failing repeatedly for web/API channel orders because the Flutter app had **stale remote order ID mappings** in its cache. When attempting to push status updates to the backend, the API returned **404 errors** (order not found), but the cache was never cleared, causing infinite retry loops.

### Error Log
```
⚠️ Remote status push failed remote=282 status=confirmed last_code=404 
last_path=/api/orders/282/update-status 
last_body={"message": "No query results for model [App\\Models\\Order] 282"}
```

### Root Cause
- Local orders (IDs 1, 2, 3) had cached mappings to remote orders (282, 283, 284)
- These remote orders were **deleted or never existed** on the backend
- The cache kept trying to sync to non-existent remote orders
- Every retry failed with 404, wasting resources and cluttering logs

## Solution

### 1. Clear Stale Cache on 404 (api_order_pull_service.dart)
When a 404 error is detected during status push, immediately clear the stale cache entry:

```dart
if (response.statusCode == 404) {
  appLogger.w(
    '🗑️ [CACHE CLEAR] Remote order #$remoteOrderId not found on backend (404). '
    'Clearing stale cache mapping for local order #$localOrderId.',
  );
  _remoteState.remove(remoteOrderId);
  _remoteLocalOrderIds.remove(localOrderId);
  _saveState(); // Persist immediately
}
```

**Changes:**
- File: `lib/services/api_order_pull_service.dart`
- Line: ~1996-2005
- Added cache clearing logic inside the 404 handling block

### 2. Skip Retries for Cleared Cache (sync_queue_service.dart)
After a status sync failure, check if the remote order ID was cleared from cache. If yes, mark the queue item as **success** (skip retries):

```dart
if (!ok) {
  // Check if remote order ID was cleared (404 = doesn't exist)
  final remoteIdStillInCache = await ApiOrderPullService.instance
      .remoteOrderIdForLocalId(localOrderId);
  if (remoteIdStillInCache == null || remoteIdStillInCache <= 0) {
    appLogger.w(
      '⏭️ [SKIP RETRY] Remote order for local #$localOrderId was cleared (404). '
      'Skipping retries.',
    );
    return _QueueSendOutcome.success; // Skip, don't retry
  }
  item['last_error'] = 'remote_status_sync_failed';
  return _QueueSendOutcome.retryable;
}
```

**Changes:**
- File: `lib/services/sync_queue_service.dart`
- Line: ~953-971
- Added cache validation check before marking as retryable

## Expected Behavior After Fix

### Before Fix
```
🔄 [STATUS SYNC] Attempting to push status: confirmed to remote order #282
⚠️ Remote status push failed remote=282 status=confirmed (404)
❌ [STATUS SYNC] All status push attempts failed
❌ Failed to send item: entity=orders, action=status
[... repeats every minute forever ...]
```

### After Fix
```
🔄 [STATUS SYNC] Attempting to push status: confirmed to remote order #282
⚠️ Remote status push failed remote=282 status=confirmed (404)
🗑️ [CACHE CLEAR] Remote order #282 not found on backend (404). 
   Clearing stale cache mapping for local order #2.
❌ [STATUS SYNC] All status push attempts failed
⏭️ [SKIP RETRY] Remote order for local #2 was cleared from cache (404). 
   Marking queue item as success to skip retries.
✅ Successfully sent item: entity=orders, action=status
[... item removed from queue, no more retries ...]
```

## Technical Details

### Cache Structure
The `_remoteState` map stores:
```dart
Map<int, _RemoteOrderSyncState> _remoteState = {
  282: _RemoteOrderSyncState(localId: 2, ...),
  283: _RemoteOrderSyncState(localId: 3, ...),
  284: _RemoteOrderSyncState(localId: 1, ...),
};
```

When 404 is detected:
1. `_remoteState.remove(282)` - Remove the mapping
2. `_remoteLocalOrderIds.remove(2)` - Remove local ID tracking
3. `_saveState()` - Persist to `api_orders_sync_state.json`

### Queue Outcome Logic
- `_QueueSendOutcome.success` - Item removed from queue (won't retry)
- `_QueueSendOutcome.retryable` - Item kept in queue (will retry)
- `_QueueSendOutcome.deadLettered` - Item moved to dead letter queue

**For 404 errors:** Return `success` to skip retries (order doesn't exist on backend)

## Testing

To verify the fix works:

1. **Check logs** for "🗑️ [CACHE CLEAR]" messages
2. **Verify** "⏭️ [SKIP RETRY]" appears after cache is cleared
3. **Confirm** queue items are marked as success, not retryable
4. **Monitor** that the same orders don't retry indefinitely

## Related Files
- `lib/services/api_order_pull_service.dart` - Status sync logic
- `lib/services/sync_queue_service.dart` - Queue management
- `API_ORDER_STATUS_SYNC_FIX.md` - Original status sync implementation

## Date
April 10, 2026
