# Check Local API/Web Orders Diagnostic

## Overview
This guide shows you how to check if API/Web orders from the backend have been received and stored locally in the Isar database.

## Method 1: Quick Check via Flutter DevTools (Recommended)

Run the diagnostic screen in your app by adding this route temporarily:

```dart
// Add to your main app routes or run it directly
Get.to(() => const CheckLocalApiOrdersScreen());
```

The diagnostic screen will show:
- ✅ Summary of all orders by channel (API, Web, Kiosk, POS)
- ✅ Detailed view of API/Web orders received from backend
- ✅ Recent orders list with channel identification

## Method 2: Console Logs (If App is Running)

If your app is currently running, look for these log messages in the console:

```
📡 [API PULL] Syncing API orders for restaurant X
✅ [API PULL] Found X orders from backend
📦 [LOCAL DB] Stored/updated order #X (channel: api/web)
```

Or when loading orders:
```
📊 [LOAD ORDERS] Total BDD: X, restId=X, staffId=X, role=X
```

## Method 3: Direct Database Query (Standalone Script)

Run this standalone Dart script to check the local database:

```bash
# From project root directory
flutter run -d macos --target=lib/tools/check_local_api_orders.dart
```

This will output:
- Total orders in database
- Breakdown by channel (API, Web, Kiosk, POS)
- Details of each API/Web order
- Recent order activity

## Method 4: Check Sync State Files

The sync system maintains state files in the app documents directory:

```bash
# On macOS, check app documents directory:
ls ~/Library/Containers/com.yourapp.data/Documents/

# Look for these files:
api_orders_sync_state.json  # Tracks remote API orders sync state
orders_sync_state.json      # Tracks local->backend sync state
sync_queue.json             # Pending sync queue
```

## Key Indicators

### ✅ API/Web Orders ARE Present Locally
Look for orders with:
- `channel` = "api" or "web" or "kiosk"
- `isFromApi` = true
- `sourceLocalId` = remote order ID from backend

### ❌ No API/Web Orders Found
Possible causes:
1. **Sync not running** - Check if `SyncController` is initialized
2. **No orders on backend** - Verify orders exist on backend via API
3. **Auth issue** - Check if user has valid token
4. **Network issue** - Check connectivity logs

## Quick Diagnostic Commands

### Check Sync Controller Status
Add this debug code temporarily in your app:

```dart
// Debug: Check local API orders count
final apiOrders = await DatabaseService.getPosOrdersByChannel('api');
final webOrders = await DatabaseService.getPosOrdersByChannel('web');
print('📡 API orders locally: ${apiOrders.length}');
print('🌐 Web orders locally: ${webOrders.length}');

for (final order in apiOrders) {
  print('  Order #${order.id} - Status: ${order.status} - Total: ${order.totalPrice}');
}
```

### Force Manual Sync
You can trigger a manual sync from the app:

```dart
// Trigger sync controller manually
await SyncController.instance.startSyncAfterLogin();

// Or force API order pull specifically
await SyncController.instance._pullIncomingApiOrders();
```

## Expected Behavior

When backend→local sync is working correctly:

1. **Every 60 seconds**, `SyncController` runs `_backgroundSyncTick()`
2. It calls `ApiOrderPullService.syncApiOrdersForRestaurant()`
3. Backend orders are fetched and stored locally with:
   - `channel = 'api'` or `'web'` or `'kiosk'`
   - `isFromApi = true`
   - `sourceLocalId = backend_order_id`
4. If pending API orders are found, a notification sound plays
5. Orders appear in the POS screen with `[API]` tag

## Troubleshooting

### No API Orders Found Locally

1. **Check backend has orders:**
   ```bash
   curl -X GET "https://your-api.com/api/orders?restaurant_id=X" \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

2. **Check sync is running:**
   Look for logs: `🔄 [SYNC TICK] Starting sync cycle...`

3. **Check auth token:**
   ```dart
   final auth = Get.find<AuthController>();
   print('Token: ${auth.currentUser?.token}');
   print('Restaurant: ${auth.currentUser?.restaurantId}');
   ```

4. **Force refresh sync:**
   ```dart
   await SyncController.instance.clearApiOrderRemoteState();
   await Future.delayed(Duration(seconds: 2));
   await SyncController.instance.startSyncAfterLogin();
   ```

### Orders Found but Not Showing in UI

Check the filtering in `loadOrdersToday()`:
- Orders must match current `restaurantId`
- Orders must be within the business day time range
- Check if status filtering is applied

## Related Files

- `/lib/services/api_order_pull_service.dart` - Pulls API orders from backend
- `/lib/services/sync_queue_service.dart` - Manages sync queue
- `/lib/controllers/sync_controller.dart` - Orchestrates sync every 60s
- `/lib/services/database_service.dart` - Isar database operations
- `/lib/models/pos_order.dart` - Order model with channel field
- `/lib/views/diagnostics/check_local_api_orders_screen.dart` - Diagnostic UI

## Next Steps

After confirming local orders exist:

1. **View them in POS screen** - They should appear with [API] tag
2. **Process them** - Change status from pending → paid
3. **Sync status back** - Status updates sync back to backend automatically
4. **Monitor sync logs** - Ensure bidirectional sync is working

---

**Last Updated:** April 6, 2026
