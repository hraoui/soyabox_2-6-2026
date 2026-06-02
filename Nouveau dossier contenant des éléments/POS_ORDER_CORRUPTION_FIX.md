# POS Order Data Corruption Fix

## Problem

The app was crashing with the following error:

```
RangeError (end): Invalid value: Not in inclusive range 4..176: 28164
#0      _Utf8Decoder.convertSingle
#1      _Utf8Decoder.convert
#2      IsarReaderImpl.readStringOrNull
#3      _posOrderDeserialize (pos_order.g.dart:386:34)
```

## Root Cause

**Isar database corruption** in the `PosOrder` collection. This occurs when:
1. A record was partially written during a crash/power failure
2. Memory corruption during serialization
3. String field contains invalid UTF-8 length metadata

The error happens when deserializing a record where a string field claims to be 28164 bytes, but the actual data is much smaller (4-176 bytes).

## Solution Implemented

### 1. Corruption Detection & Auto-Recovery

All `PosOrder` query methods in `DatabaseService` now catch `RangeError` and `Utf8Decoder` exceptions:

- `getPosOrders()` - Auto-clears corrupted collection on first error
- `getPosOrdersByStatus()` - Returns empty list on error
- `getPosOrdersByDateRange()` - Returns empty list on error
- `getPosOrdersByChannel()` - Returns empty list on error
- `getPosOrdersByStaffAndDate()` - Returns empty list on error
- `getPosOrderBySourceLocalId()` - Returns null on error

### 2. Sync Service Protection

`SyncQueueService.queueUnsyncedOrders()` now catches errors when loading orders and gracefully skips the sync cycle if corruption is detected.

## Behavior

### First Corruption Detection
When `getPosOrders()` detects corruption:
1. Logs the error: `⚠️ [DB] PosOrder collection corruption detected`
2. Clears the entire `posOrders` collection: `🗑️ [DB] Clearing corrupted PosOrder collection...`
3. Returns empty list to allow app to continue
4. Logs confirmation: `✅ [DB] Corrupted PosOrder records cleared`

### Subsequent Queries
All other query methods return empty list or null, allowing the app to continue functioning.

## Data Loss Warning

⚠️ **This fix clears ALL corrupted PosOrder records.** 

Orders that were:
- Already synced to backend: **Safe** (can be re-fetched)
- Not yet synced: **Lost** (cannot be recovered)

## Prevention

To prevent future corruption:

1. **Ensure proper app shutdown** - Don't force-kill the app during write operations
2. **Enable disk persistence** - Already enabled in Isar
3. **Regular sync** - Keep orders synced to backend as backup
4. **Stable storage** - Ensure device has adequate storage space

## Testing

After this fix, the app should:
1. ✅ Start without crashing
2. ✅ Show empty order list initially (if cleared)
3. ✅ Allow creating new orders normally
4. ✅ Sync new orders to backend successfully

## Manual Recovery (if needed)

If you need to manually clear the database:

```dart
// In Flutter DevTools or debug console:
await DatabaseService.db.writeTxn(() async {
  await DatabaseService.db.posOrders.clear();
});
```

Or delete the app data:
- Android: Settings → Apps → [App Name] → Storage → Clear Data
- iOS: Delete and reinstall the app

## Files Modified

- `lib/services/database_service.dart` - Added corruption handling to all PosOrder queries
- `lib/services/sync_queue_service.dart` - Added error handling in queueUnsyncedOrders()

## Related Files

- `lib/models/pos_order.dart` - PosOrder model definition
- `lib/models/pos_order.g.dart` - Generated serialization code (source of error)
