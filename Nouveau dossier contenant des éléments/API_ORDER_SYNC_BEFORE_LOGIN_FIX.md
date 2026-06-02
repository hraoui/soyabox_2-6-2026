# API Order Sync Before Login - Fix

## Problem

When a staff user connects with a PIN code (without full login), API orders from the backend were **not being synced** to the local device because:

1. The `SyncController._resolveRestaurantId()` only checked:
   - `PosController.restaurantId` (requires staff to be logged in)
   - `AuthController.currentUser.restaurantId` (requires user authentication)

2. **Before login**, both of these are `null`, so the restaurant ID resolution returned `null`

3. Without a restaurant ID, `_pullIncomingApiOrders()` was **skipped entirely**:
   ```
   ⚠️ [SYNC] No restaurant ID, skipping user pull
   🔇 [SYNC] No API pending orders (api_pending=0)
   ```

4. This meant **API orders could not be received** until after a user logged in, which is incorrect for staff PIN-based authentication where orders can arrive before login.

---

## Solution

### 1. **Added Restaurant Fallback in SyncController** (`sync_controller.dart`)

Updated `_resolveRestaurantId()` to check **3 sources** in order:

```dart
int? _resolveRestaurantId() {
  // 1. Try from PosController (if staff logged in with restaurant context)
  if (Get.isRegistered<PosController>()) {
    final pos = Get.find<PosController>();
    final posRestaurantId = pos.restaurantId;
    final posStaffId = pos.activeStaffId;
    if (posRestaurantId != null && posRestaurantId > 0 && posStaffId != null) {
      return posRestaurantId;
    }
  }

  // 2. Try from AuthController (if user logged in)
  final authRestaurantId = Get.find<AuthController>().currentUser?.restaurantId;
  if (authRestaurantId != null && authRestaurantId > 0) {
    return authRestaurantId;
  }

  // ✅ 3. FALLBACK: Use imported restaurant from RestaurantController
  // This allows API order sync BEFORE user login (e.g., staff connecting with PIN)
  if (Get.isRegistered<RestaurantController>()) {
    final importedRestaurantId = 
        Get.find<RestaurantController>().getImportedRestaurantId();
    if (importedRestaurantId != null && importedRestaurantId > 0) {
      appLogger.d(
        '🍽️ [SYNC] Using imported restaurant ID: $importedRestaurantId',
      );
      return importedRestaurantId;
    }
  }

  appLogger.w('⚠️ [SYNC] No restaurant ID resolved from any source');
  return null;
}
```

**Key Change:** Now falls back to the **imported restaurant** from local database, which is available even before any user logs in.

---

### 2. **Auto-Load Local Restaurants in RestaurantController** (`restaurant_controller.dart`)

Added automatic loading of restaurants from local database on initialization:

```dart
@override
void onInit() {
  super.onInit();
  print('🍽️ [RESTAURANT] RestaurantController initialized (waiting for manual import)');
  
  // ✅ Auto-load restaurants from local database on init
  // This allows getImportedRestaurantId() to work immediately,
  // even before manual import or user login
  _loadLocalRestaurants();
}

/// Load restaurants from local database (not from API)
Future<void> _loadLocalRestaurants() async {
  try {
    final allRestaurants = await DatabaseService.getAllRestaurants();
    _restaurants.assignAll(allRestaurants);
    
    if (_selectedRestaurantId.value == null && allRestaurants.isNotEmpty) {
      _selectedRestaurantId.value = allRestaurants.first.id;
    }
    
    if (allRestaurants.isNotEmpty) {
      appLogger.d(
        '🍽️ [RESTAURANT] Loaded ${allRestaurants.length} restaurant(s) from local DB',
      );
    }
  } catch (e) {
    appLogger.w('⚠️ [RESTAURANT] Failed to load local restaurants: $e');
  }
}
```

**Key Change:** Restaurants are now loaded from local Isar DB immediately, so `getImportedRestaurantId()` can return a valid ID even before the app imports restaurants from the backend.

---

### 3. **Enhanced Logging in API Order Pull** (`sync_controller.dart`)

Added detailed logging to `_pullIncomingApiOrders()` to track sync status:

```dart
Future<ApiOrderSyncResult> _pullIncomingApiOrders() async {
  final restaurantId = _resolveRestaurantId();
  if (restaurantId == null || restaurantId <= 0) {
    appLogger.w('⚠️ [API PULL] No restaurant ID, skipping API order pull');
    return const ApiOrderSyncResult();
  }

  appLogger.d('📡 [API PULL] Pulling API orders for restaurant ID: $restaurantId');
  
  final fallbackStaffId = _resolveFallbackStaffId();
  final result = await ApiOrderPullService.instance.syncApiOrdersForRestaurant(
    restaurantId: restaurantId,
    fallbackStaffId: fallbackStaffId,
  );
  
  appLogger.d(
    '✅ [API PULL] Completed: '
    '${result.apiPendingOrdersCount} pending, '
    '${result.syncedOrdersCount} synced, '
    '${result.errorsCount} errors',
  );
  
  return result;
}
```

---

### 4. **Enhanced Diagnostic Screen** (`check_local_api_orders_screen.dart`)

Added restaurant configuration section to the diagnostic screen:

- Shows if a restaurant is imported locally
- Displays the resolved restaurant ID used for sync
- Shows all restaurant details (name, phone, address, active status)
- Warns if no restaurant is imported (red card)
- Shows success if restaurant is resolved (green card)

---

## Expected Behavior After Fix

### ✅ **Before User Login** (Staff PIN Entry)

1. App starts and loads restaurants from local Isar DB
2. `RestaurantController.getImportedRestaurantId()` returns the imported restaurant ID
3. Background sync runs every 60 seconds
4. `_resolveRestaurantId()` falls back to the imported restaurant ID
5. API orders are pulled from backend and stored locally
6. If pending orders exist, notification sound plays
7. **Staff can see API orders waiting** when they log in with PIN

### Logs You'll See:
```
🍽️ [RESTAURANT] Loaded 1 restaurant(s) from local DB
🍽️ [SYNC] Using imported restaurant ID: 1
📡 [API PULL] Pulling API orders for restaurant ID: 1
✅ [API PULL] Completed: 3 pending, 3 synced, 0 errors
🔔 [NOTIF] Playing new order alarm (3 pending orders)
```

### ✅ **After User Login** (Normal Flow)

Once a user logs in, the resolution priority is:
1. PosController.restaurantId (highest priority)
2. AuthController.currentUser.restaurantId
3. RestaurantController.getImportedRestaurantId() (fallback)

---

## How to Import a Restaurant

If no restaurant exists locally, you need to import one:

### Option 1: Import from Backend (Recommended)
```dart
// In the app, navigate to Import Data screen
// Then click "Import Restaurants" button
// Or call manually:
await Get.find<ImportController>().importRestaurants();
```

### Option 2: Create Locally
```dart
await DatabaseService.createRestaurant(
  Restaurant(
    name: 'My Restaurant',
    address: '123 Main St',
    phone: '+212600000000',
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
);
```

---

## Testing the Fix

### 1. **Verify Restaurant Exists Locally**
```dart
final restaurants = await DatabaseService.getAllRestaurants();
print('🍽️ Local restaurants: ${restaurants.length}');
for (final r in restaurants) {
  print('  - #${r.id}: ${r.name}');
}
```

### 2. **Check Resolved Restaurant ID**
```dart
if (Get.isRegistered<RestaurantController>()) {
  final resolvedId = Get.find<RestaurantController>().getImportedRestaurantId();
  print('✅ Resolved restaurant ID: $resolvedId');
}
```

### 3. **Watch Sync Logs**
After app starts, within 60 seconds you should see:
```
🍽️ [SYNC] Using imported restaurant ID: X
📡 [API PULL] Pulling API orders for restaurant ID: X
✅ [API PULL] Completed: X pending, X synced, 0 errors
```

### 4. **Use Diagnostic Screen**
```dart
Get.to(() => const CheckLocalApiOrdersScreen());
```

This will show:
- ✅ Restaurant configuration section
- ✅ Resolved restaurant details
- ✅ All orders by channel (API, Web, Kiosk, POS)

---

## Files Changed

| File | Change |
|------|--------|
| `lib/controllers/sync_controller.dart` | Added restaurant fallback in `_resolveRestaurantId()` + enhanced logging |
| `lib/controllers/restaurant_controller.dart` | Auto-load local restaurants on init |
| `lib/views/diagnostics/check_local_api_orders_screen.dart` | Added restaurant info section |
| `API_ORDER_SYNC_BEFORE_LOGIN_FIX.md` | This documentation |

---

## Architecture Flow

```
┌─────────────────────────────────────────────────────┐
│                  App Startup                         │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  RestaurantController.onInit()                       │
│  → _loadLocalRestaurants()                           │
│  → Loads from Isar DB                                │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  SyncController.startBackgroundSync()                │
│  → Runs every 60 seconds                             │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  _resolveRestaurantId()                              │
│  1. PosController.restaurantId (if logged in)        │
│  2. AuthController.currentUser.restaurantId          │
│  3. RestaurantController.getImportedRestaurantId() ✅│
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  _pullIncomingApiOrders()                            │
│  → Calls ApiOrderPullService                         │
│  → Fetches orders from backend                       │
│  → Stores locally with channel='api/web/kiosk'       │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  Notification Sound (if pending orders)              │
│  → Plays alarm to alert staff                        │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│  Staff Logs In with PIN                              │
│  → Sees pending API orders waiting                   │
│  → Can process them immediately                      │
└─────────────────────────────────────────────────────┘
```

---

## Benefits

✅ **API orders arrive before login** - Staff can see orders waiting when they connect  
✅ **No dependency on authentication** - Works with PIN-based staff authentication  
✅ **Backward compatible** - Still prioritizes logged-in user's restaurant if available  
✅ **Better logging** - Clear visibility into which restaurant ID is used for sync  
✅ **Diagnostic tools** - Can verify restaurant configuration and orders easily  

---

**Last Updated:** April 6, 2026  
**Status:** ✅ Implemented and Ready for Testing
