# Purchase Stock Update Fix

## Problem
After successful purchase:
- Purchase RPC succeeds on server (stock updated in Supabase)
- Local SQLite cache retains old quantity
- Stock হিসাব screen reads from local cache → shows stale data
- User must wait for periodic sync (5 minutes) to see updated stock

## Root Cause
Purchase flow updates server stock via RPC but doesn't update local cache immediately. The offline-first architecture reads from local cache, causing stock values to appear unchanged until next sync.

## Solution
Apply local stock increments immediately after purchase succeeds, mirroring the pattern used for sales (which applies local stock deductions).

## Implementation

### 1. ProductDao - Added `applyLocalStockIncrements()`
**File:** `lib/database/dao/product_dao.dart`

```dart
/// Apply local stock increments after purchase completion
/// Does NOT queue for sync - server already has correct stock
/// Updates local cache to match server state immediately
Future<void> applyLocalStockIncrements(
  String userId,
  Map<String, int> increments,
) async {
  if (increments.isEmpty) return;

  try {
    await _db.transaction((txn) async {
      for (final entry in increments.entries) {
        final productId = entry.key;
        final purchasedQty = entry.value;

        // Update quantity: COALESCE(quantity, 0) + purchasedQty
        // Keep is_synced unchanged (do not queue sync)
        await txn.rawUpdate(
          '''
          UPDATE $tableName
          SET quantity = COALESCE(quantity, 0) + ?,
              updated_at = ?
          WHERE id = ? AND user_id = ?
          ''',
          [
            purchasedQty,
            DateTime.now().toIso8601String(),
            productId,
            userId,
          ],
        );
      }
    });

    // Notify stream listeners to refresh UI
    await notifyProductsChanged(userId);
    print('✅ [ProductDao] Local stock increments applied for ${increments.length} products');
  } catch (e) {
    print('❌ [ProductDao] Error applying local stock increments: $e');
    rethrow;
  }
}
```

**Key Points:**
- Atomic transaction for multiple products
- `COALESCE(quantity, 0) + qty` handles null quantities
- `is_synced` unchanged → does NOT queue for sync (server already updated)
- `notifyProductsChanged()` triggers stream refresh → UI updates immediately

### 2. ProductRepository - Added wrapper method
**File:** `lib/repositories/product_repository.dart`

```dart
/// Apply local stock increments after purchase completion
/// Local-only operation - does not queue for sync
/// Used to immediately update local cache after server purchase
Future<void> applyLocalStockIncrements(Map<String, int> increments) async {
  final userId = _userId;
  await _productDao.applyLocalStockIncrements(userId, increments);
}
```

### 3. ProductService - Added service method
**File:** `lib/services/product_service.dart`

```dart
/// Apply local stock increments after purchase completion
/// Updates local cache immediately without queuing sync
Future<void> applyLocalStockIncrements(Map<String, int> increments) =>
    _repository.applyLocalStockIncrements(increments);
```

### 4. SelectProductBuyingScreen - Call after purchase success
**File:** `lib/screens/select_product_buying_screen.dart`

**Before:**
```dart
await PurchaseService().processPurchase(
  purchase: purchase,
  cartItems: cartItems,
);

if (mounted) Navigator.pop(context);
showTextToast('পণ্য ক্রয় সফল হয়েছে!');
```

**After:**
```dart
await PurchaseService().processPurchase(
  purchase: purchase,
  cartItems: cartItems,
);

// Apply local stock increments immediately (server already updated via RPC)
try {
  final increments = <String, int>{};
  for (final item in cartItems) {
    final productId = item.productId;
    final qty = item.quantity?.toInt() ?? 0;
    if (productId != null && qty > 0) {
      increments[productId] = (increments[productId] ?? 0) + qty;
    }
  }
  if (increments.isNotEmpty) {
    await _productService.applyLocalStockIncrements(increments);
    print('✅ Local stock increments applied: $increments');
  }
} catch (e) {
  // Log warning but don't fail purchase flow
  print('⚠️ Failed to apply local stock increments: $e');
}

if (mounted) Navigator.pop(context);
showTextToast('পণ্য ক্রয় সফল হয়েছে!');
```

**Key Points:**
- Builds `increments` map: `productId → total purchased qty`
- Handles multiple items of same product (aggregates quantities)
- Wrapped in try-catch → purchase success not affected by cache update failures
- Logs success/failure for debugging

## Flow Diagram

### Before Fix
```
Purchase Screen
  ↓
PurchaseService.processPurchase()
  ↓
Supabase RPC (update_stock_after_purchase)
  ↓ Server stock updated
  ↓
Success ✓
  ↓
User navigates to Stock হিসাব
  ↓
ProductService.getAllProducts()
  ↓
Local SQLite cache
  ↓
❌ OLD quantity shown (stale data)
  ↓
Wait 5 minutes for periodic sync...
  ↓
✓ Updated quantity shown
```

### After Fix
```
Purchase Screen
  ↓
PurchaseService.processPurchase()
  ↓
Supabase RPC (update_stock_after_purchase)
  ↓ Server stock updated
  ↓
Success ✓
  ↓
applyLocalStockIncrements()
  ↓
Local SQLite cache updated
  ↓
notifyProductsChanged()
  ↓
Product streams refresh
  ↓
User navigates to Stock হিসাব
  ↓
✓ UPDATED quantity shown immediately
```

## Benefits

### User Experience
- ✅ **Instant stock updates** - Stock হিসাব shows correct quantities immediately after purchase
- ✅ **No wait for sync** - No 5-minute delay to see updated stock
- ✅ **Consistent behavior** - Matches sales flow (which already updates local cache)

### Technical
- ✅ **Atomic transactions** - Multiple products updated atomically in SQLite
- ✅ **Resilient** - Purchase success not affected by cache update failures
- ✅ **No duplicate syncs** - Doesn't queue for sync (server already has correct data)
- ✅ **Stream refresh** - Triggers automatic UI refresh via reactive streams

### Performance
- ✅ **No additional network calls** - Pure local cache update
- ✅ **Fast** - SQLite transaction completes in milliseconds
- ✅ **Efficient** - Aggregates quantities before updating (one update per product)

## Testing Checklist

### Basic Flow
- [ ] Purchase single product → verify stock increases in Stock হিসাব
- [ ] Purchase multiple different products → verify all stocks increase
- [ ] Purchase multiple items of same product → verify quantity aggregates correctly

### Edge Cases
- [ ] Purchase with null product_id → should skip (not crash)
- [ ] Purchase with 0 quantity → should skip (not crash)
- [ ] Local cache update fails → purchase should still succeed (check logs)

### UI Verification
- [ ] Stock হিসাব screen shows updated quantities immediately (no page refresh needed)
- [ ] Product streams refresh automatically after purchase
- [ ] No duplicate stock updates (check product quantities match expected values)

### Sync Verification
- [ ] Local cache matches server after purchase
- [ ] Periodic sync doesn't create duplicate increments
- [ ] Manual sync doesn't corrupt stock values

## Comparison with Sales Flow

| Aspect | Sales (Stock Deductions) | Purchases (Stock Increments) |
|--------|-------------------------|------------------------------|
| **Server Update** | RPC: `process_sale_with_stock` | RPC: `update_stock_after_purchase` |
| **Local Update** | `applyLocalStockDeductions()` | `applyLocalStockIncrements()` |
| **Operation** | `quantity = MAX(quantity - qty, 0)` | `quantity = quantity + qty` |
| **Timing** | After sale success | After purchase success |
| **Sync Queue** | No (server already updated) | No (server already updated) |
| **Stream Refresh** | Yes (`notifyProductsChanged`) | Yes (`notifyProductsChanged`) |

Both flows follow the same pattern:
1. Update server via RPC
2. Update local cache immediately
3. Don't queue for sync (would duplicate server changes)
4. Trigger stream refresh for UI update

## Files Changed

### New Methods Added
- `lib/database/dao/product_dao.dart` - `applyLocalStockIncrements()`
- `lib/repositories/product_repository.dart` - `applyLocalStockIncrements()`
- `lib/services/product_service.dart` - `applyLocalStockIncrements()`

### Modified Logic
- `lib/screens/select_product_buying_screen.dart` - Call increment method after purchase success

### No Schema Changes
- Uses existing `products` table
- No new columns or tables required

## Conclusion

This fix ensures stock quantities update immediately after purchase, providing consistent behavior with sales and eliminating the 5-minute wait for periodic sync. The implementation follows the existing offline-first architecture patterns and maintains data integrity.
