# API Orders Missing Buttons (Confirm & Assign Livreur) - Fix

## Problem

API/Web orders were visible in the staff menu, but **action buttons were missing**:
- ❌ No "Confirmer" button
- ❌ No "Assigner livreur" button  
- ❌ No "Payer" button
- ❌ No action buttons at all

---

## Root Cause

The `canAccessOrder()` method in `PosController` was blocking API orders:

```dart
bool canAccessOrder(PosOrder order) {
  if (_activeStaff == null) return false;
  if (isAdminEditor) return true;
  // Staff ne voit que ses commandes
  return order.staffId == _activeStaff!.id;  // ❌ BLOCKS API ORDERS
}
```

### The Issue:

1. **API/Web orders** have `staffId = 0` (or backend staff ID)
2. **Logged-in staff** has `activeStaff.id = 5` (or any other ID)
3. `canAccessOrder()` returns `false` because `0 != 5`
4. UI uses `isOwner = pos.canAccessOrder(order)` to show buttons
5. Since `isOwner = false`, **ALL buttons are hidden**:

```dart
// In pos_staff_orders_screen.dart
if (order.paymentStatus != 'paid' && isOwner && ...)  // ❌ isOwner = false
  _actionButtonCompact(label: 'Confirmer', ...)  // ❌ NOT SHOWN

if (order.fulfillmentType == 'delivery' && isOwner)  // ❌ isOwner = false
  _actionButtonCompact(label: 'Assigner livreur', ...)  // ❌ NOT SHOWN
```

---

## Solution

Modified `canAccessOrder()` in `PosController` to **allow all staff to access API/Web/Kiosk orders**:

### Code Change (`lib/controllers/pos_controller.dart`)

**Before:**
```dart
bool canAccessOrder(PosOrder order) {
  if (_activeStaff == null) return false;
  if (isAdminEditor) return true;
  // Staff ne voit que ses commandes
  return order.staffId == _activeStaff!.id;
}
```

**After:**
```dart
bool canAccessOrder(PosOrder order) {
  if (_activeStaff == null) return false;
  if (isAdminEditor) return true;
  
  // ✅ FIX: Les commandes API/Web/Kiosk sont accessibles par TOUS les staffs
  // Ces commandes viennent de sources externes et ne sont pas assignées à un staff spécifique
  if (_isRemoteChannel(order.channel)) {
    return true;
  }
  
  // Staff ne voit que ses commandes POS (staffId correspond)
  return order.staffId == _activeStaff!.id;
}
```

---

## What This Fixes

Now that `canAccessOrder()` returns `true` for API/Web/Kiosk orders:

### ✅ **"Confirmer" Button**
```dart
if (order.paymentStatus != 'paid' &&
    isOwner &&  // ✅ NOW TRUE FOR API ORDERS
    (order.channel == 'pos' || 
     ['web', 'api', 'mobile'].contains(order.channel)) &&
    order.status == 'pending')
  _actionButtonCompact(
    icon: Icons.play_arrow,
    label: 'Confirmer',
    onTap: () => pos.updateOrderStatus(order, 'confirmed'),
  )
```

**Result:** Staff can now confirm API orders (changes status from `pending` → `confirmed`)

---

### ✅ **"Assigner livreur" Button**
```dart
if (order.fulfillmentType == 'delivery' && isOwner)  // ✅ NOW TRUE FOR API ORDERS
  _actionButtonCompact(
    icon: Icons.person_add_outlined,
    label: order.deliveryLivreurId != null ? 'Changer livreur' : 'Assigner livreur',
    onTap: () => _showAssignLivreurDialog(pos, order),
  )
```

**Result:** Staff can now assign a livreur to API delivery orders

---

### ✅ **"Payer" Button**
```dart
if (order.paymentStatus != 'paid' &&
    isOwner &&  // ✅ NOW TRUE FOR API ORDERS
    order.status != 'delivered' &&
    ((order.channel == 'pos' && ...) ||
     (['web', 'api', 'mobile'].contains(order.channel) && ...)))
  _actionButton(
    icon: Icons.payment_outlined,
    label: 'Payer',
    onTap: () => _showSimplePaymentDialog(pos, order),
  )
```

**Result:** Staff can now process payment for API orders

---

### ✅ **"Éditer" Button**
```dart
if (canEditOrder && order.paymentStatus != 'paid' && isOwner)  // ✅ NOW TRUE
  _actionButton(
    icon: Icons.edit_note_outlined,
    label: 'Éditer',
    onTap: () => _openOrderEditor(pos, order),
  )
```

**Result:** Staff can now edit API orders

---

## Complete Flow After All Fixes

With the three fixes combined:

```
1. Backend has API orders
       ↓
2. [FIX 1] Sync pulls orders to local DB (before login)
   → API_ORDER_SYNC_BEFORE_LOGIN_FIX.md
       ↓
3. [FIX 2] Orders visible in staff menu (staff filter)
   → API_ORDERS_VISIBILITY_FIX.md
       ↓
4. [FIX 3] Buttons visible and functional (access control)
   → THIS FIX
       ↓
5. Staff can:
   ✅ See "Confirmer" button → Change status to confirmed
   ✅ See "Assigner livreur" button → Assign delivery driver
   ✅ See "Payer" button → Process payment
   ✅ See "Éditer" button → Modify order
```

---

## Testing Steps

1. **Ensure API orders exist locally:**
   - Wait for background sync (60 seconds)
   - Check logs for: `✅ [API PULL] Completed: X pending`

2. **Login as staff with PIN:**
   - Server enters PIN code
   - Navigate to orders screen

3. **Verify buttons are visible:**
   - Select an API order (should have `[API]` label)
   - Should see:
     - ✅ "Confirmer" button (if status = pending)
     - ✅ "Assigner livreur" button (if fulfillment = delivery)
     - ✅ "Payer" button (if not paid)
     - ✅ "Éditer" button

4. **Test button functionality:**
   - Click "Confirmer" → Status should change to `confirmed`
   - Click "Assigner livreur" → Dialog should open to select livreur
   - Click "Payer" → Payment dialog should open

5. **Check console logs:**
   ```
   ✅ Order #X included: remote order (channel=api) visible to all staff
   ✅ canAccessOrder: remote order (channel=api) accessible to all staff
   ```

---

## Access Control Rules (After Fix)

| Order Channel | Who Can Access | Who Can Edit | Who Can Pay |
|---------------|----------------|--------------|-------------|
| **POS** | Creator staff only | Creator staff only | Creator staff only |
| **API** | **All staff** ✅ | **All staff** ✅ | **All staff** ✅ |
| **Web** | **All staff** ✅ | **All staff** ✅ | **All staff** ✅ |
| **Kiosk** | **All staff** ✅ | **All staff** ✅ | **All staff** ✅ |
| **Mobile** | **All staff** ✅ | **All staff** ✅ | **All staff** ✅ |
| **Admin** | All admins | All admins | All admins |

---

## Files Changed

| File | Change |
|------|--------|
| `lib/controllers/pos_controller.dart` | Modified `canAccessOrder()` to allow remote channel access for all staff |
| `API_ORDERS_BUTTONS_FIX.md` | This documentation |

---

## Related Fixes

This fix is part of a series:

1. **[API_ORDER_SYNC_BEFORE_LOGIN_FIX.md](./API_ORDER_SYNC_BEFORE_LOGIN_FIX.md)**
   - Ensures API orders are synced before staff login
   - Fixes restaurant ID resolution

2. **[API_ORDERS_VISIBILITY_FIX.md](./API_ORDERS_VISIBILITY_FIX.md)**
   - Ensures API orders appear in staff order list
   - Fixes staff filter in `loadOrdersToday()`

3. **[API_ORDERS_BUTTONS_FIX.md](./API_ORDERS_BUTTONS_FIX.md)** (THIS FIX)
   - Ensures action buttons are visible for API orders
   - Fixes access control in `canAccessOrder()`

---

**Last Updated:** April 6, 2026  
**Status:** ✅ Implemented and Ready for Testing
