# Product Sync Fix - Testing Guide

## Quick Start

### 1. Build and Run
```bash
cd C:\Users\Jahan\Downloads\wavezly\warehouse_management
flutter clean
flutter pub get
flutter run
```

### 2. Basic Verification Test

**Add a test product and watch console output:**

1. **Login** to the app with existing credentials
2. **Navigate** to ProductListScreen
3. **Tap** "প্রোডাক্ত যুক্ত করুন" (Add Product)
4. **Fill in:**
   - Name: "Test Sync Product"
   - Price: 100
   - Quantity: 10
   - Category: (any)
5. **Tap** "সংরক্ষণ করুন" (Save)

### 3. Expected Console Output

**✅ SUCCESS PATTERN:**
```
🔑 [ProductRepository] _userId getter called: c2e27b87-xxxx-xxxx
➕ [ProductRepository] addProduct() START - userId: c2e27b87-xxxx
💾 [ProductRepository] Inserting to local SQLite
📤 [ProductRepository] Queuing sync operation
🌐 [ProductRepository] Online - triggering immediate sync
☁️ [ProductRepository] BACKUP: Direct Supabase insert
✅ Auth session valid (expires in 3456s)
✅ [ProductRepository] BACKUP sync successful
✅ [ProductRepository] addProduct() COMPLETE
```

**🔄 TOKEN REFRESH PATTERN:**
```
☁️ [ProductRepository] BACKUP: Direct Supabase insert
⚠️ Token expiring soon, refreshing...
✅ Token refreshed successfully
✅ [ProductRepository] BACKUP sync successful
```

**❌ FAILURE PATTERN (with diagnostics):**
```
☁️ [ProductRepository] BACKUP: Direct Supabase insert
❌ [ProductRepository] BACKUP sync FAILED with error:
Error: [detailed error message]
Stack trace: [full stack trace]
✅ Auth session exists: user_id=c2e27b87-xxxx
💡 Possible causes:
  - JWT token expired (check auth.currentSession.expiresAt)
  - Network connectivity issue
  - Supabase RLS policy blocking
  - Missing required fields in data
```

---

## Verification Checklist

### ✅ Test 1: Product Appears Immediately
- [ ] Product appears in ProductListScreen right after save
- [ ] No "কোন পণ্য নেই" (No products) message
- [ ] Product count updates correctly

### ✅ Test 2: Console Shows Success
- [ ] Look for `✅ BACKUP sync successful` message
- [ ] No `❌` error messages appear
- [ ] Auth session validation passes

### ✅ Test 3: Supabase Verification
Use Supabase dashboard or MCP to verify:

```sql
-- Check if product exists
SELECT id, name, user_id, created_at
FROM products
WHERE name = 'Test Sync Product'
ORDER BY created_at DESC;
```

Expected result: Product exists with correct `user_id`

### ✅ Test 4: Sales Integration
- [ ] Navigate to Sales screen
- [ ] Search for "Test Sync Product"
- [ ] Product appears in search results
- [ ] Can add product to cart
- [ ] No "পণ্যটি সার্ভারে sync হয়নি" error when processing sale

---

## Advanced Testing

### Test 5: Multiple Products
Add 5 products in quick succession:
- [ ] All appear in list immediately
- [ ] All sync to Supabase successfully
- [ ] Console shows 5 successful sync messages
- [ ] Supabase has all 5 records

### Test 6: User Isolation (RLS)
1. Login as User A
   - Add "Product A"
   - Verify appears in list
2. Logout
3. Login as User B
   - Add "Product B"
   - Verify ONLY "Product B" appears
   - User A's products should NOT be visible
4. Check Supabase:
   ```sql
   SELECT name, user_id FROM products
   WHERE name IN ('Product A', 'Product B');
   ```
   - [ ] Each product has different `user_id`
   - [ ] RLS properly isolating data

### Test 7: Offline Handling
1. Turn off internet/WiFi
2. Add product "Offline Product"
3. Expected console output:
   ```
   📴 [ProductRepository] Offline - sync will happen when online
   ```
4. Product should still appear in local list
5. Turn internet back on
6. Wait ~30 seconds or manually trigger sync
7. Check Supabase - product should now exist

### Test 8: Expired Token (Optional)
This test requires waiting >1 hour or manipulating token expiration:
1. Let app sit idle for >1 hour (token expires)
2. Add product
3. Expected console output:
   ```
   ❌ JWT token expired, refreshing...
   ✅ Token refreshed successfully
   ✅ BACKUP sync successful
   ```
4. Verify product synced successfully

---

## Troubleshooting

### Issue: Product appears locally but console shows error

**Symptoms:**
- Product in list ✅
- Console shows `❌ BACKUP sync FAILED` ❌

**Check:**
1. Read full error message in console
2. Check auth session status (NULL or valid?)
3. Verify network connectivity
4. Check Supabase dashboard for RLS policy errors

**Common Causes:**
- Expired JWT token (should auto-refresh)
- Network timeout
- Missing required fields in product data
- Supabase service temporarily down

### Issue: Console shows success but product not in Supabase

**Symptoms:**
- Console: `✅ BACKUP sync successful` ✅
- Supabase: No product found ❌

**Check:**
1. Verify querying correct Supabase project
2. Check correct user_id in query
3. Look for `sync_queue` errors in console
4. Manually trigger sync: Pull to refresh or restart app

**Debug Query:**
```sql
-- Get ALL products (ignores RLS)
SELECT id, name, user_id, created_at
FROM products
ORDER BY created_at DESC
LIMIT 20;
```

### Issue: Sales screen still shows "product not synced" error

**Symptoms:**
- Product exists in Supabase ✅
- Sales screen error: "পণ্যটি সার্ভারে sync হয়নি" ❌

**Check:**
1. Verify product ID is valid UUID:
   ```sql
   SELECT id FROM products WHERE name = 'Your Product';
   ```
2. Check `product.id` is not NULL in local database
3. Restart app to refresh product cache

---

## Success Indicators

### ✅ All Good
- Products appear immediately in list
- Console shows `✅ BACKUP sync successful`
- Supabase contains products with correct user_id
- Sales screen can use products without errors
- No `❌` errors in console
- Auth tokens auto-refresh when needed

### ⚠️ Partial Success
- Products appear locally but sync delayed
- Sync queue processing (check `sync_queue` table)
- Network connectivity issues
- Check periodic sync (every 5 minutes)

### ❌ Failure
- Products don't appear in list at all
- Console shows persistent errors
- Auth session NULL
- Supabase connection failed
- Need to investigate root cause using error diagnostics

---

## Quick Diagnostic Commands

### Check Sync Queue Status
```dart
// In debug console or add to UI
final syncStatus = await SyncService().getSyncStatus();
print('Pending: ${syncStatus['pending']}');
print('Failed: ${syncStatus['failed']}');
print('Online: ${syncStatus['is_online']}');
```

### Check Auth Session
```dart
final session = SupabaseConfig.client.auth.currentSession;
print('Session: ${session != null ? "Valid" : "NULL"}');
print('User ID: ${session?.user.id}');
print('Expires at: ${session?.expiresAt}');
```

### Manual Sync Trigger
```dart
await SyncService().syncNow();
```

---

## Expected Timeline

**Immediate (< 1 second):**
- Product appears in ProductListScreen
- Local SQLite save complete

**Quick (1-3 seconds):**
- Backup sync to Supabase complete
- Console shows success message

**Background (5 minutes):**
- Periodic sync processes queue
- Any failed operations retry

---

## Notes

- **Offline-first architecture** means local save always works
- **Sync is dual-path:** Queue + immediate backup
- **Auth tokens** auto-refresh (1 hour expiration)
- **RLS policies** enforce user isolation
- **Error visibility** is now comprehensive with diagnostics

If you see detailed error messages, the fix is working correctly - silent failures are eliminated!
