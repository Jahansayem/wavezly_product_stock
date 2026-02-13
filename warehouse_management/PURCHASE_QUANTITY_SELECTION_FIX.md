# Purchase Quantity Selection Fix

## Problem
In `select_product_buying_screen.dart`:
- Product selection was binary (selected/not selected)
- `_prepareCartItems()` hardcoded `quantity: 1` for all products
- No way to purchase multiple quantities of same product
- No stock limit validation on selection

## Solution
Replaced binary selection with quantity-based selection:
- Tap to increment quantity (up to stock limit)
- Long-press to decrement quantity
- Show quantity badge on selected products
- Validate stock availability before incrementing
- Display total quantity sum in bottom bar

## Implementation Changes

### 1. State Change - Replaced Selection Set with Quantity Map

**Before:**
```dart
final Set<String> _selectedProductIds = {};
```

**After:**
```dart
final Map<String, int> _selectedProductQuantities = {};
```

**Benefits:**
- Tracks quantity per product instead of just selection
- Single source of truth for product quantities
- Enables multi-quantity purchases

### 2. Tap Logic - Increment with Stock Validation

**Before:**
```dart
void _toggleProductSelection(Product product) {
  setState(() {
    if (_selectedProductIds.contains(product.id)) {
      _selectedProductIds.remove(product.id);
    } else {
      _selectedProductIds.add(product.id!);
    }
  });
}
```

**After:**
```dart
void _incrementProductQuantity(Product product) {
  if (product.id == null) return;

  final currentQty = _selectedProductQuantities[product.id] ?? 0;
  final stockQty = product.quantity ?? 0;

  // Check stock availability
  if (stockQty == 0) {
    showTextToast('স্টক নেই');
    return;
  }

  if (currentQty >= stockQty) {
    showTextToast('সর্বোচ্চ স্টক পৌঁছেছে (${stockQty} টি)');
    return;
  }

  setState(() {
    _selectedProductQuantities[product.id!] = currentQty + 1;
  });
}
```

**Behavior:**
- ✅ Each tap increments quantity by +1
- ✅ Validates stock before incrementing
- ✅ Shows "স্টক নেই" if stock is 0
- ✅ Shows "সর্বোচ্চ স্টক পৌঁছেছে" if quantity equals stock
- ✅ Prevents over-purchasing beyond available stock

### 3. Long-Press - Decrement Quantity

**New Method:**
```dart
void _decrementProductQuantity(Product product) {
  if (product.id == null) return;

  final currentQty = _selectedProductQuantities[product.id] ?? 0;

  if (currentQty <= 1) {
    setState(() {
      _selectedProductQuantities.remove(product.id);
    });
  } else {
    setState(() {
      _selectedProductQuantities[product.id!] = currentQty - 1;
    });
  }
}
```

**Product Card Update:**
```dart
InkWell(
  onTap: () => _incrementProductQuantity(product),
  onLongPress: () => _decrementProductQuantity(product),
  // ...
)
```

**Behavior:**
- ✅ Long-press decrements quantity by 1
- ✅ Removes product from map when quantity reaches 0
- ✅ Provides intuitive way to adjust quantities

### 4. UI Updates - Quantity Badge and Total Sum

**Product Card - Quantity Badge:**
```dart
Stack(
  children: [
    Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: ColorPalette.blue50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.blue100.withOpacity(0.5)),
      ),
      child: Icon(
        _getProductIcon(product.group),
        color: primary,
        size: 32,
      ),
    ),
    if (isSelected)
      Positioned(
        top: -4,
        right: -4,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          constraints: const BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),
          child: Center(
            child: Text(
              '$selectedQty',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
  ],
)
```

**Bottom Bar - Total Quantity Sum:**

**Before:**
```dart
Text(
  '${_selectedProductIds.length} টি',  // Unique product count
  // ...
)
```

**After:**
```dart
Text(
  '${_selectedProductQuantities.values.fold<int>(0, (sum, qty) => sum + qty)} টি',  // Total quantity sum
  // ...
)
```

**Visual Changes:**
- ✅ Circular badge appears on product icon when selected
- ✅ Badge shows current selected quantity
- ✅ Bottom bar shows total quantity across all products (not unique count)
- ✅ Badge has white border for visibility

### 5. Cart Generation - Use Actual Quantities

**Before:**
```dart
Future<List<BuyingCartItem>> _prepareCartItems() async {
  final cartItems = <BuyingCartItem>[];

  try {
    for (final productId in _selectedProductIds) {
      final product = await _productService.getProductById(productId);
      if (product != null && product.id != null) {
        cartItems.add(BuyingCartItem(
          productId: product.id!,
          productName: product.name ?? 'Unknown',
          costPrice: product.cost ?? 0.0,
          quantity: 1,  // ❌ Hardcoded to 1
        ));
      }
    }
  } catch (e) {
    showTextToast('ত্রুটি: পণ্যের তথ্য লোড করা যায়নি');
  }

  return cartItems;
}
```

**After:**
```dart
Future<List<BuyingCartItem>> _prepareCartItems() async {
  final cartItems = <BuyingCartItem>[];

  try {
    for (final entry in _selectedProductQuantities.entries) {
      final productId = entry.key;
      final quantity = entry.value;  // ✅ Actual selected quantity

      final product = await _productService.getProductById(productId);
      if (product != null && product.id != null) {
        cartItems.add(BuyingCartItem(
          productId: product.id!,
          productName: product.name ?? 'Unknown',
          costPrice: product.cost ?? 0.0,
          quantity: quantity.toDouble(),  // ✅ Use actual quantity
        ));
      }
    }
  } catch (e) {
    showTextToast('ত্রুটি: পণ্যের তথ্য লোড করা যায়নি');
  }

  return cartItems;
}
```

**Behavior:**
- ✅ Iterates through map entries (productId → quantity)
- ✅ Creates cart item with actual selected quantity
- ✅ Supports purchasing multiple quantities of same product

### 6. QR Scanner - Increment with Validation

**Before:**
```dart
Future<void> _handleQrScan() async {
  final product = await Navigator.push<Product>(
    context,
    MaterialPageRoute(
      builder: (_) => const BarcodeScannerScreen(),
    ),
  );

  if (product != null && product.id != null) {
    setState(() => _selectedProductIds.add(product.id!));
    showTextToast('${product.name} যোগ করা হয়েছে!');
  }
}
```

**After:**
```dart
Future<void> _handleQrScan() async {
  final product = await Navigator.push<Product>(
    context,
    MaterialPageRoute(
      builder: (_) => const BarcodeScannerScreen(),
    ),
  );

  if (product != null && product.id != null) {
    final currentQty = _selectedProductQuantities[product.id] ?? 0;
    final stockQty = product.quantity ?? 0;

    // Check stock availability
    if (stockQty == 0) {
      showTextToast('${product.name} - স্টক নেই');
      return;
    }

    if (currentQty >= stockQty) {
      showTextToast('${product.name} - সর্বোচ্চ স্টক পৌঁছেছে (${stockQty} টি)');
      return;
    }

    setState(() {
      _selectedProductQuantities[product.id!] = currentQty + 1;
    });
    showTextToast('${product.name} যোগ করা হয়েছে! (${currentQty + 1} টি)');
  }
}
```

**Behavior:**
- ✅ Scanned product increments quantity by +1 (same as tap)
- ✅ Validates stock before incrementing
- ✅ Shows product name with current quantity in toast
- ✅ Consistent with tap behavior

### 7. Purchase Success - Clear Quantities

**Before:**
```dart
setState(() {
  _selectedProductIds.clear();
  _filteredProducts = null;
});
```

**After:**
```dart
setState(() {
  _selectedProductQuantities.clear();
  _filteredProducts = null;
});
```

**Behavior:**
- ✅ Clears quantity map after successful purchase
- ✅ Resets UI to empty state
- ✅ Ready for next purchase

## User Flow Examples

### Example 1: Purchase Multiple Quantities of One Product
```
1. User taps "Rice" product → Qty becomes 1 (badge shows "1")
2. User taps "Rice" again → Qty becomes 2 (badge shows "2")
3. User taps "Rice" again → Qty becomes 3 (badge shows "3")
4. User long-presses "Rice" → Qty becomes 2 (badge shows "2")
5. Bottom bar shows: "2 টি"
6. Click "পণ্য কিনুন" → Cart has 1 item: Rice (qty: 2)
```

### Example 2: Purchase Multiple Products
```
1. User taps "Rice" → Rice qty = 1
2. User taps "Rice" → Rice qty = 2
3. User taps "Oil" → Oil qty = 1
4. User taps "Oil" → Oil qty = 2
5. User taps "Oil" → Oil qty = 3
6. Bottom bar shows: "5 টি" (2 Rice + 3 Oil)
7. Click "পণ্য কিনুন" → Cart has 2 items:
   - Rice (qty: 2)
   - Oil (qty: 3)
```

### Example 3: Stock Limit Validation
```
Product: "Sugar" (stock: 3)

1. User taps "Sugar" → Qty = 1 ✓
2. User taps "Sugar" → Qty = 2 ✓
3. User taps "Sugar" → Qty = 3 ✓
4. User taps "Sugar" → Toast: "সর্বোচ্চ স্টক পৌঁছেছে (3 টি)" ❌
5. Qty remains 3 (cannot exceed stock)
```

### Example 4: QR Scanner Integration
```
1. User scans "Rice" QR code → Rice qty = 1
2. User scans "Rice" QR code again → Rice qty = 2
3. User scans "Oil" QR code → Oil qty = 1
4. Bottom bar shows: "3 টি"
```

### Example 5: Remove Product via Long-Press
```
1. User taps "Rice" → Rice qty = 1
2. User long-presses "Rice" → Rice removed from selection
3. Badge disappears, bottom bar shows: "0 টি"
```

## UI/UX Improvements

### Visual Feedback
- ✅ **Quantity badge** on product icon shows current quantity
- ✅ **Circular badge design** with white border for visibility
- ✅ **Check icon** changes to indicate selection status
- ✅ **Bottom bar** shows total quantity sum (not unique count)

### User Interaction
- ✅ **Tap** = Increment quantity (+1)
- ✅ **Long-press** = Decrement quantity (-1)
- ✅ **Stock validation** prevents over-purchasing
- ✅ **Toast messages** provide clear feedback

### Error Prevention
- ✅ Cannot select products with 0 stock
- ✅ Cannot exceed available stock
- ✅ Clear error messages in Bengali

## Testing Checklist

### Basic Quantity Selection
- [ ] Tap product → quantity increments to 1
- [ ] Tap product again → quantity increments to 2, 3, etc.
- [ ] Long-press product → quantity decrements
- [ ] Long-press when qty = 1 → product removed from selection
- [ ] Quantity badge displays correct number
- [ ] Bottom bar shows total quantity sum

### Stock Limit Validation
- [ ] Cannot select product with 0 stock (toast: "স্টক নেই")
- [ ] Cannot exceed stock limit (toast: "সর্বোচ্চ স্টক পৌঁছেছে")
- [ ] Stock validation works for both tap and QR scan

### Cart Generation
- [ ] Cart item quantities match selected quantities
- [ ] Multiple products with different quantities work correctly
- [ ] Single product with quantity > 1 works correctly

### QR Scanner
- [ ] Scanned product increments quantity by 1
- [ ] Scanning same product multiple times increments quantity
- [ ] Stock validation works for scanned products
- [ ] Toast shows product name and quantity

### Purchase Flow
- [ ] Purchase completes with correct quantities
- [ ] Stock increments apply correctly (from previous fix)
- [ ] Selection map clears after successful purchase
- [ ] Can start new purchase after completion

### Edge Cases
- [ ] Rapidly tapping product doesn't bypass stock limit
- [ ] Long-press on non-selected product does nothing
- [ ] Filtering/searching doesn't affect selection state
- [ ] Navigation away and back preserves selection state

## Benefits

### Functionality
- ✅ **Multi-quantity purchases** - Can buy multiple units of same product
- ✅ **Stock validation** - Prevents over-purchasing
- ✅ **Accurate cart** - Cart items reflect actual selected quantities

### User Experience
- ✅ **Intuitive controls** - Tap to add, long-press to remove
- ✅ **Visual feedback** - Quantity badge shows current selection
- ✅ **Clear messaging** - Bengali error messages
- ✅ **Efficient workflow** - No need to visit separate quantity screen

### Technical
- ✅ **Single source of truth** - Quantity map replaces selection set
- ✅ **Type safety** - Map<String, int> enforces integer quantities
- ✅ **Maintainable** - Clear separation of increment/decrement logic

## Breaking Changes
None. All changes are internal to `select_product_buying_screen.dart`.

## Files Modified
- `lib/screens/select_product_buying_screen.dart` (only file changed)

## Related Fixes
This fix complements the previous stock increment fix:
- Purchase stock increment fix → Updates local cache after purchase
- This fix → Enables purchasing multiple quantities per product

Together, these ensure:
1. Users can purchase multiple quantities
2. Stock updates reflect immediately after purchase
3. UI stays in sync with local cache
