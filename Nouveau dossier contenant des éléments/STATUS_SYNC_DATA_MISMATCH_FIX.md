# Status Sync Data Mismatch Fix - Complete Solution

## 📊 Current State Analysis

### Backend Orders (Database Dump)
| ID | source_local_id | synced_from | channel | total_price | created_at | fulfillment_type |
|----|----------------|-------------|---------|-------------|------------|------------------|
| 396 | **NULL** → 10007 | flutter_pos | web | 120.00 | 2026-04-10 15:33:00 | pickup |
| 422 | NULL → 10007 | flutter_pos | web | 60.00 | 2026-04-10 15:33:33 | delivery |
| 423 | NULL → 10007 | flutter_pos | web | 90.00 | 2026-04-10 21:44:31 | pickup |
| 424 | **4** | flutter_pos | pos | 164.00 | 2026-04-10 21:58:25 | on_site |

### Flutter Local Orders
| Local ID | sourceLocalId | channel | total | createdAt | Status |
|----------|--------------|---------|-------|-----------|--------|
| **1** | NULL | web | 120.00 | 2026-04-10 15:33:00 | confirmed |
| **2** | NULL | web | 60.00 | 2026-04-10 15:33:33 | confirmed |
| **3** | NULL | web | 90.00 | 2026-04-10 21:44:31 | confirmed |
| **4** | NULL | pos | 164.00 | 2026-04-10 21:58:25 | confirmed |

### Stale Cache Mapping (WRONG)
```
Flutter Cache: {
  282 → localId: 2,  // ❌ Backend order 282 doesn't exist
  283 → localId: 3,  // ❌ Backend order 283 doesn't exist
  284 → localId: 1,  // ❌ Backend order 284 doesn't exist
}
```

## 🔍 Root Cause

1. **Backend orders have `source_local_id` = 10007** (original ID from old database)
2. **Flutter local IDs are 1, 2, 3** (after database reset)
3. **Cache has stale mappings** to non-existent backend orders (282, 283, 284)
4. **Status sync tries to push to 282, 283, 284** → Returns 404

## ✅ Solution Implemented

### Part 1: Clear Stale Cache on 404 (api_order_pull_service.dart)
**Already implemented** - When 404 is detected, clears the stale cache immediately.

### Part 2: Skip Retries for Cleared Orders (sync_queue_service.dart)
**Already implemented** - Checks if cache was cleared and skips retries.

### Part 3: Fallback Matching Logic (api_order_pull_service.dart)
**Just added** - When `source_local_id` doesn't match, tries heuristic matching by:
- Channel (web/API/pos)
- Created timestamp (within 12 hours)
- Total price
- Customer phone/name

This allows the app to **discover the correct backend orders** (396, 422, 423) even when `source_local_id` is wrong.

## 🔧 Additional Fix Required: Update Backend source_local_id

While the fallback logic will work, the **proper fix** is to update the backend `source_local_id` values to match current Flutter local IDs:

### SQL Migration Script

```sql
-- Update backend orders to match Flutter local IDs
UPDATE orders 
SET source_local_id = CASE id
    WHEN 396 THEN 1  -- Flutter local order #1 (web, 120.00, 15:33:00)
    WHEN 422 THEN 2  -- Flutter local order #2 (web, 60.00, 15:33:33)
    WHEN 423 THEN 3  -- Flutter local order #3 (web, 90.00, 21:44:31)
    WHEN 424 THEN 4  -- Flutter local order #4 (pos, 164.00, 21:58:25)
    ELSE source_local_id
END
WHERE id IN (396, 422, 423, 424);

-- Verify the update
SELECT id, source_local_id, channel, total_price, created_at, fulfillment_type
FROM orders
WHERE id IN (396, 422, 423, 424)
ORDER BY id;
```

### Expected Result After Migration
| ID | source_local_id | channel | total_price | created_at |
|----|----------------|---------|-------------|------------|
| 396 | **1** | web | 120.00 | 2026-04-10 15:33:00 |
| 422 | **2** | web | 60.00 | 2026-04-10 15:33:33 |
| 423 | **3** | web | 90.00 | 2026-04-10 21:44:31 |
| 424 | **4** | pos | 164.00 | 2026-04-10 21:58:25 |

## 📝 Recommended Action Plan

### Option 1: Run SQL Migration (Recommended) ✅
1. Run the SQL migration script above on the backend
2. Clear Flutter app cache (or wait for 404 errors to clear it automatically)
3. Restart the app - status sync will work immediately

### Option 2: Let Fallback Logic Handle It (No DB Changes)
1. Deploy the updated Flutter code
2. The fallback logic will match orders by channel + timestamp + total
3. Cache will be populated with correct backend IDs (396, 422, 423)
4. Status sync will start working after the first successful resolution

## 🧪 Testing

After applying the fix, check logs for:

### Before Fix
```
🔄 [STATUS SYNC] Attempting to push status: confirmed to remote order #282
⚠️ Remote status push failed remote=282 (404)
❌ All status push attempts failed
[... repeats forever ...]
```

### After Fix (With SQL Migration)
```
🔍 [STATUS SYNC] Remote order ID from cache: 396
📤 [STATUS SYNC] Attempting to push status: confirmed to remote order #396
✅ Successfully pushed status confirmed for remote order #396
✅ Successfully sent item: entity=orders, action=status
```

### After Fix (With Fallback Logic Only)
```
⚠️ [FALLBACK MATCH] No source_local_id match for local order #1.
   Trying heuristic match by channel + timestamp + total...
🔗 Resolved remote order by heuristic local=1 -> remote=396
📤 [STATUS SYNC] Attempting to push status: confirmed to remote order #396
✅ Successfully pushed status confirmed for remote order #396
```

## 🔐 Data Integrity Check

To verify the matching is correct, run this query:

```sql
SELECT 
    o.id AS backend_id,
    o.source_local_id,
    o.channel,
    o.total_price,
    o.created_at,
    o.fulfillment_type,
    o.status,
    o.payment_status
FROM orders o
WHERE o.synced_from = 'flutter_pos'
  AND o.created_at >= '2026-04-10 00:00:00'
ORDER BY o.created_at;
```

## 📌 Notes

- The **POS order (#4 → backend #424)** already has correct `source_local_id = 4` ✅
- Only **web orders (#1, #2, #3)** need updating (currently have 10007 instead of 1, 2, 3)
- The fallback logic is a **safety net** - the proper fix is updating `source_local_id`

## 📅 Date
April 10, 2026
