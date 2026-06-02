# API Orders Not Visible in Staff Menu - Fix

## Problem

API/Web orders were successfully synced from backend (notification sound played showing 4 pending orders), but **they were NOT visible in the staff menu** (`pos_staff_orders_screen.dart` or `pos_screen.dart`).

---

## Root Cause

The `loadOrdersToday()` method in `PosController` has a **staff filter** that only shows orders where:

```dart
if (o.staffId == activeStaffId) {
  return true;  // ✅ Show order
}
return false;  // ❌ Hide order
```

### The Issue:

1. **API/Web orders** are created with `staffId = 0` (or backend staff ID that doesn't match)
2. **Logged-in server/staff** has `activeStaffId = 5` (or any other ID)
3. Since `0 != 5`, the order is **filtered out** and not shown in the UI
4. The notification sound plays (orders ARE in database), but they're **invisible** to staff

---

## Solution

Modified the staff filter in `PosController.loadOrdersToday()` to **show API/Web/Kiosk orders to ALL staff**, regardless of staffId match.

### Code Change (`lib/controllers/pos_controller.dart`)

**Before:**
```dart
// Staff: voir UNIQUEMENT ses commandes (POS et distantes assignées)
if (activeStaffId != null) {
  if (isAdminScope) {
    return true;  // Admin sees everything
  }
  // Staff ne voit que SES commandes (staffId correspond)
  if (o.staffId == activeStaffId) {
    return true;  // ✅ Show order
  }
  return false;  // ❌ Hide order
}
```

**After:**
```dart
// Staff: voir UNIQUEMENT ses commandes (POS et distantes assignées)
if (activeStaffId != null) {
  if (isAdminScope) {
    return true;  // Admin sees everything
  }
  
  // ✅ FIX: Les commandes API/Web/Kiosk sont visibles par TOUS les serveurs
  // Ces commandes ne sont pas assignées à un staff spécifique
  final isRemoteOrder = _isRemoteChannel(o.channel);
  if (isRemoteOrder) {
    appLogger.d(
      '  ✅ Order #${o.id} included: remote order (channel=${o.channel}) visible to all staff',
    );
    return true;  // ✅ Show API/Web/Kiosk orders to all staff
  }
  
  // Staff ne voit que SES commandes POS (staffId correspond)
  if (o.staffId == activeStaffId) {
    return true;  // ✅ Show order
  }
  return false;  // ❌ Hide order
}
```

---

## Expected Behavior After Fix

### ✅ **For Staff Users (Non-Admin)**

When a staff member (server/cashier) logs in with PIN:

1. **POS orders**: Only shows orders they created (`staffId == activeStaffId`)
2. **API/Web/Kiosk orders**: Shows **ALL** remote orders, regardless of staffId
   - This makes sense because API orders come from external sources (website, mobile app, kiosk)
   - They're not assigned to a specific staff member
   - Any available staff should be able to see and process them

### ✅ **For Admin Users**

Admins continue to see **ALL orders** (POS + API/Web/Kiosk) from all staff.

---

## Logging

You'll now see these logs in console:

```
✅ Order #123 included: remote order (channel=api) visible to all staff
✅ Order #124 included: remote order (channel=web) visible to all staff
✅ Order #125 included: remote order (channel=kiosk) visible to all staff
```

---

## Testing Steps

1. **Ensure API orders exist locally:**
   - Wait for sync to pull orders from backend (60 seconds)
   - Or manually trigger sync
   - Check logs for: `✅ [API PULL] Completed: X pending`

2. **Login as staff with PIN:**
   - Server enters PIN code
   - Navigate to orders screen

3. **Verify API orders are visible:**
   - Should see orders with `[API]`, `[WEB]`, or `[KIOSK]` labels
   - Should see all pending API orders (not just ones with matching staffId)

4. **Check console logs:**
   ```
   ✅ Order #X included: remote order (channel=api) visible to all staff
   📊 [AFTER SCOPING] X orders
   ```

---

## Channel Types Affected

These channels are now visible to all staff (defined in `_isRemoteChannel()`):

- `api` - API orders from mobile apps
- `web` / `website` / `site` / `online` - Web orders
- `mobile` / `mobile_app` / `app` / `android` / `ios` - Mobile app orders
- `kiosk` / `borne` - Kiosk/self-service orders

---

## Files Changed

| File | Change |
|------|--------|
| `lib/controllers/pos_controller.dart` | Modified staff filter in `loadOrdersToday()` to show remote orders to all staff |
| `API_ORDERS_VISIBILITY_FIX.md` | This documentation |

---

## Related Fixes

This fix complements the previous [API_ORDER_SYNC_BEFORE_LOGIN_FIX](./API_ORDER_SYNC_BEFORE_LOGIN_FIX.md):

1. **Before Login Fix**: Ensures API orders are synced to local DB before staff login
2. **This Fix**: Ensures synced API orders are visible to all staff in the UI

Together, these fixes enable the complete flow:
```
Backend API Orders 
  → Local Sync (before login) 
    → Staff Login with PIN 
      → Orders Visible to All Staff 
        → Staff Can Process Orders
```

---

**Last Updated:** April 6, 2026  
**Status:** ✅ Implemented and Ready for Testing
