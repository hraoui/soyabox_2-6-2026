# Server Commission Tracking Implementation

## Overview
This document describes the implementation of server commission tracking and delivery order accounting across all admin views.

## Commission Rules

### ✅ Server Commission (Comptabilité Serveur):
- **Type: À EMPORTER (PICKUP)** from **Web/API channels only**
- Attributed to: **Server who confirms the order**
- Excludes: ALL delivery orders, POS orders

### ✅ Livreur Commission (Comptabilité Livreur):
- **Type: LIVRAISON (DELIVERY)** from **ALL channels** (POS, API, Web)
- Attributed to: **Livreur assigned to delivery**
- Excludes: From server accounting completely

## Implementation Details

### 1. Admin Accounting Screen (`lib/views/admin_accounting_screen.dart`)

#### Server Attribution Logic:
- **Filters applied:**
  1. ❌ EXCLUDE all delivery orders (any channel) → handled in delivery accounting
  2. ❌ EXCLUDE POS orders → not concerned here
  3. ✅ ONLY include: Web/API + Pickup orders

- **Attribution rule:**
  - When server confirms a pending Web/API pickup order:
    - `staffId` is assigned to the confirming server
    - Order appears in server's commission report

#### Overall Stats (Top Dashboard):
- **CA Total**: ALL orders (POS + Web/API, all fulfillment types)
- **CA POS**: All POS channel orders
- **CA Web/API**: All Web/API channel orders
- **Breakdown by type**: Onsite, Pickup, Delivery (counts + revenue)

### 2. Financial Admin Dashboard (`lib/views/financial_admin_dashboard.dart`)

#### Tab 1 - "Vue globale" (Global Overview):
- Total revenue card (all paid orders)
- Revenue breakdown: POS vs Web/API
- Order count breakdown: POS vs Web/API
- **📊 Delivery stats**: Delivery count + delivery revenue (NEW)

#### Tab 2 - "Serveurs" (Server Performance):
- **ONLY counts Web/API Pickup orders** (consistent with admin accounting)
- Excludes: Delivery orders, POS orders
- Shows per-server: order count, revenue, payment breakdown

#### Tab 3 - "Livreurs" (Delivery Stats):
- Uses `OrderDelivery` table for accuracy
- Filters deliveries by `assignedAt` date
- Excludes cancelled orders
- Shows per-livreur: delivery count, completed deliveries, revenue

#### Tab 4 - "Commandes" (Orders List):
- Full order list with filter bar
- Shows all orders for selected date

#### Server Stats Logic:
- Only tracks Web/API pickup orders
- Separates revenue by payment method (TPE, Cash, En Compte)
- Delivery orders tracked separately in livreur stats (not server stats)

## How Server Commission Works

### For Web/API Channel Orders (PICKUP - À Emporter):
1. Order arrives from backend (API/Web/Mobile/Kiosk):
   - `channel` = 'api', 'web', or 'kiosk'
   - `fulfillmentType` = 'pickup'
   - `staffId` = 0 (initially unassigned)

2. Server confirms the order:
   - `staffId` is assigned to confirming server's ID
   - Server gets commission credit for this order

3. Order appears in:
   - ✅ Server commission accounting (admin accounting screen)
   - ✅ Server stats in financial dashboard (Tab 2)

### For Delivery Orders (ALL CHANNELS):
1. Order has `fulfillmentType` = 'delivery'
2. Order has `deliveryLivreurId` assigned
3. Order appears in:
   - ✅ Delivery accounting (livreur commission) - both screens
   - ❌ NOT in server accounting (excluded from both screens)

## Data Flow

```
Web/API Pickup Order:
Order arrives from backend → staffId = 0, channel = 'api/web/kiosk'
→ Server confirms order → staffId = server.id
→ Order saved locally → Synced to backend
→ ✅ Server gets commission credit (both accounting screens)

Delivery Order (Any Channel):
Order arrives → deliveryLivreurId assigned
→ ✅ Livreur gets delivery credit (delivery accounting)
→ ❌ NOT in server accounting (excluded)
```

## Views Consistency

| View | Server Commission | Delivery Accounting | Notes |
|------|-------------------|---------------------|-------|
| **Admin Accounting** | ✅ Web/API Pickup only | ❌ Excluded (separate screen) | Correct |
| **Financial Dashboard - Serveurs Tab** | ✅ Web/API Pickup only | ❌ Excluded | Correct (fixed) |
| **Financial Dashboard - Livreurs Tab** | N/A | ✅ Uses OrderDelivery table | Correct |
| **Admin Delivery Accounting** | N/A | ✅ Uses OrderDelivery table | Correct (separate screen) |

## Files Modified

1. `/lib/views/admin_accounting_screen.dart`
   - Filters: Exclude delivery orders, exclude POS, only include Web/API pickup
   - Shows server commission for Web/API pickup orders only
   - Overall stats include ALL orders (correct for business metrics)

2. `/lib/views/financial_admin_dashboard.dart`
   - Tab 1: Added delivery stats section (count + revenue)
   - Tab 2: Fixed to only count Web/API pickup orders (exclude delivery and POS)
   - Tab 3: Uses OrderDelivery table for accurate delivery stats
   - All tabs now consistent with commission rules

## Key Points

✅ **Web/API Pickup Orders**: Server who confirms gets credit  
✅ **Delivery Orders (All Channels)**: Livreur gets credit, NOT server  
✅ **POS Orders**: Not included in server accounting (handled separately)  
✅ **All Views**: Now consistent with commission logic  

## Backward Compatibility

- All changes use existing fields (`staffId`, `deliveryLivreurId`, `channel`, `fulfillmentType`)
- No database schema changes required
- Existing orders work correctly with current logic
- Financial dashboard now properly reflects commission rules
