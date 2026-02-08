# Testing Guide: Product List & Sync Fix

## Changes Made

### 1. Added Comprehensive Debug Logging
**Files Modified:**
- `lib/repositories/product_repository.dart`
- `lib/database/dao/product_dao.dart`

**Logging Added:**
- 🔑 User ID tracking at every critical point
- 💾 SQLite insert/query operations
- 📤 Sync queue operations
- ☁️ Direct Supabase sync
- ✅ Success/failure confirmations

### 2. Fixed user_id Consistency
**File:** `lib/repositories/product_repository.dart`

**Change:** Capture `userId` once at the beginning of each method to ensure consistency throughout the operation. This prevents issues where auth session might change mid-operation.

**Before:**
```dart
Future<void> addProduct(Product product) async {
  await _productDao.insertProduct(product, _userId);  // Gets user_id here
  // ... other operations
  await _syncService.queueOperation(data: {'user_id': _userId});  // Might get different user_id here!
}
```

**After:**
```dart
Future<void> addProduct(Product product) async {
  final userId = _userId;  // Capture once at start
  await _productDao.insertProduct(product, userId);
  // ... other operations
  await _syncService.queueOperation(data: {'user_id': userId});  // Same user_id guaranteed
}
```

### 3. Implemented Direct Supabase Backup Sync
**File:** `lib/repositories/product_repository.dart`

**New Method:** `_directSupabaseInsert()`

**Behavior:**
1. Product is saved to local SQLite (fast, always works)
2. Operation is queued for background sync (existing behavior)
3. **NEW:** If online, also do immediate direct Supabase insert as backup
4. If backup sync fails, error is logged but not thrown (local save already succeeded)

**Why:** This ensures products reach Supabase immediately even if sync queue has issues. It's a safety net to guarantee data reaches the server.

### 4. Verified RLS Policies
**Supabase products table RLS policies:**
- ✅ INSERT: `user_id = auth.uid() OR user_id = current_effective_owner()`
- ✅ SELECT: `user_id = auth.uid() OR user_id = current_effective_owner()`
- ✅ UPDATE: `user_id = auth.uid() OR user_id = current_effective_owner()`
- ✅ DELETE: `user_id = auth.uid() OR user_id = current_effective_owner()`

**Result:** Policies are correctly configured and will allow authenticated users to insert their products.

## Testing Instructions

### Prerequisites
1. Ensure you have at least one test user account
2. Clear existing data if needed (fresh test)
3. Enable console logging to see debug output

### Test Case 1: Add Product and Verify Immediate Appearance ✅

**Steps:**
1. Login as existing user (note the user email/ID)
2. Navigate to ProductListScreen
3. Note current product count (should show "কোন পণ্য নেই" if empty)
4. Tap "প্রোডাক্ত যুক্ত করুন" (Add Product) button
5. Fill in product details:
   - Name: "Test Product 1"
   - Price: 100
   - Quantity: 10
   - Category: "Test Category"
6. Tap "সংরক্ষণ করুন" (Save)

**Expected Results:**
- ✅ Success toast appears
- ✅ ProductListScreen immediately shows "Test Product 1"
- ✅ Product count updates in header
- ✅ No "কোন পণ্য নেই" message

**Debug Logs to Check:**
```
🔑 [ProductRepository] _userId getter called: <user-uuid>
➕ [ProductRepository] addProduct() START - userId: <user-uuid>, productId: <product-uuid>, name: Test Product 1
💾 [ProductRepository] Inserting to local SQLite with userId: <user-uuid>
💾 [ProductDao] insertProduct START - userId: <user-uuid>, productId: <product-uuid>, name: Test Product 1
💾 [ProductDao] Inserting into SQLite table: products
✅ [ProductDao] Insert successful for product <product-uuid>
📢 [ProductDao] Notifying stream listeners
✅ [ProductDao] insertProduct COMPLETE
📤 [ProductRepository] Queuing sync operation for product <product-uuid>
🌐 [ProductRepository] Online - triggering immediate sync
☁️ [ProductRepository] BACKUP: Direct Supabase insert
✅ [ProductRepository] BACKUP sync successful
✅ [ProductRepository] addProduct() COMPLETE for product <product-uuid>
🔄 [ProductDao] _refreshProducts called for userId: <user-uuid>
📊 [ProductDao] Querying products from database...
✅ [ProductDao] Query successful: 1 products found
✅ [ProductDao] Products added to stream
```

**Verify in Supabase:**
```sql
SELECT id, name, user_id, created_at
FROM products
WHERE name = 'Test Product 1';
```
- ✅ Should return 1 row with correct user_id

---

### Test Case 2: Multiple Products from Same User ✅

**Steps:**
1. Repeat Test Case 1 three times with different product names:
   - "Test Product 2"
   - "Test Product 3"
   - "Test Product 4"

**Expected Results:**
- ✅ All 3 products appear in ProductListScreen
- ✅ Products are sorted alphabetically by name
- ✅ Header shows correct count (e.g., "৪টি পণ্য")

**Verify in Supabase:**
```sql
SELECT COUNT(*) as count
FROM products
WHERE user_id = '<user-uuid>';
```
- ✅ Should return count = 4 (including Test Product 1)

---

### Test Case 3: Products Isolated by User (RLS Working) ✅

**Steps:**
1. Login as User A (test@example.com)
2. Add product "Product A"
3. Note User A's ID from logs
4. Logout
5. Login as User B (test2@example.com)
6. Add product "Product B"
7. Verify User B only sees "Product B", NOT "Product A"

**Expected Results:**
- ✅ User A sees only "Product A"
- ✅ User B sees only "Product B"
- ✅ RLS properly isolating user data

**Verify in Supabase:**
```sql
SELECT user_id, name
FROM products
WHERE name IN ('Product A', 'Product B');
```
- ✅ Should show 2 rows with different user_ids

---

### Test Case 4: Offline → Online Sync 🔄

**Steps:**
1. Turn off internet/WiFi
2. Add product "Offline Product"
3. Verify product appears in local list
4. Turn on internet/WiFi
5. Wait 5 seconds (or trigger manual sync if available)

**Expected Results:**
- ✅ Product appears immediately in local list (offline)
- ✅ After going online, product syncs to Supabase

**Debug Logs to Check (Offline):**
```
📴 [ProductRepository] Offline - sync will happen when online
```

**Debug Logs to Check (Online):**
```
🌐 [ProductRepository] Online - triggering immediate sync
☁️ [ProductRepository] BACKUP: Direct Supabase insert
✅ [ProductRepository] BACKUP sync successful
```

**Verify in Supabase:**
```sql
SELECT name, user_id, created_at
FROM products
WHERE name = 'Offline Product';
```
- ✅ Should exist after going online

---

### Test Case 5: Sale Screen Integration ✅

**Steps:**
1. Add at least 2 products
2. Navigate to Sale Screen
3. Try to select products for sale

**Expected Results:**
- ✅ Products appear in sale screen
- ✅ No "products not synced" error
- ✅ Can successfully create sales

---

## Troubleshooting

### Issue: Products Don't Appear in List

**Debug Steps:**
1. Check console logs for user_id consistency
2. Look for these specific logs:
   ```
   🔑 [ProductRepository] _userId getter called: <user-uuid>
   📖 [ProductRepository] getAllProducts() called with userId: <user-uuid>
   🔍 [ProductDao] _queryProducts executing for userId: <user-uuid>
   ✅ [ProductDao] Query successful: X products found
   ```

3. If user_id is different between insert and query:
   - **Cause:** Auth session changed between operations
   - **Solution:** Already fixed by capturing userId once at start

4. If query returns 0 products but insert succeeded:
   - Check SQLite directly:
   ```sql
   SELECT id, name, user_id FROM products;
   ```
   - Verify user_id matches auth.currentUser.id

### Issue: Products Don't Sync to Supabase

**Debug Steps:**
1. Check for backup sync logs:
   ```
   ☁️ [ProductRepository] BACKUP: Direct Supabase insert
   ✅ [ProductRepository] BACKUP sync successful
   ```

2. If backup sync fails:
   ```
   ⚠️ [ProductRepository] BACKUP sync failed (non-critical): <error>
   ```
   - Product is still saved locally
   - Background sync queue will retry

3. Check Supabase directly:
   ```sql
   SELECT COUNT(*) FROM products;
   ```

4. Check sync queue:
   ```sql
   SELECT * FROM sync_queue WHERE table_name = 'products' AND status = 'pending';
   ```

### Issue: "No authenticated user" Error

**Debug Steps:**
1. Look for this log:
   ```
   ❌ ERROR: No authenticated user in ProductRepository
   ```

2. **Cause:** User logged out or session expired
3. **Solution:** Re-login

### Issue: RLS Policy Blocking Insert

**Debug Steps:**
1. Check Supabase logs for policy violations
2. Verify user_id in insert matches auth.uid():
   ```sql
   SELECT auth.uid();  -- Should match user_id in product data
   ```

## Success Criteria Checklist

After running all tests, verify:

- [ ] Products added via AddProductScreen appear IMMEDIATELY in ProductListScreen
- [ ] Supabase products table contains products (run: `SELECT COUNT(*) FROM products;`)
- [ ] Each product has correct user_id matching authenticated user
- [ ] Products properly isolated by user (RLS working correctly)
- [ ] No "কোন পণ্য নেই" message when products exist
- [ ] Sale screen can use products without errors
- [ ] Same product count shown in both list header and actual list
- [ ] Debug logs confirm consistent user_id throughout flow
- [ ] Offline mode works (products saved locally, sync when online)

## Rollback Plan

If issues occur, rollback by:
1. Reverting changes to `lib/repositories/product_repository.dart`
2. Reverting changes to `lib/database/dao/product_dao.dart`
3. Running: `flutter clean && flutter pub get`

## Next Steps After Testing

1. ✅ Verify all test cases pass
2. Remove or reduce debug logging (optional - keep for production monitoring)
3. Monitor sync success rate in production
4. Consider adding sync status indicator in UI
5. Implement conflict resolution for offline edits (future enhancement)

## Database Queries for Verification

### Check Total Products
```sql
SELECT COUNT(*) as total_products,
       COUNT(DISTINCT user_id) as unique_users
FROM products;
```

### Check Products by User
```sql
SELECT user_id,
       COUNT(*) as product_count,
       array_agg(name) as product_names
FROM products
GROUP BY user_id;
```

### Check Recent Products
```sql
SELECT id, name, user_id, created_at, updated_at
FROM products
ORDER BY created_at DESC
LIMIT 10;
```

### Check Sync Status
```sql
SELECT id, name, is_synced, last_synced_at
FROM products
WHERE is_synced = 0;
```

### Verify RLS Policies
```sql
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'products'
ORDER BY cmd;
```
