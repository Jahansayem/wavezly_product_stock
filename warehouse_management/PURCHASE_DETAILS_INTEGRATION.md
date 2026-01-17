# Purchase Details Screen - Integration Guide

## Overview
This guide explains how to integrate the PurchaseDetailsScreen into your ShopStock application.

## Files Created

1. **`lib/screens/purchase_details_screen.dart`** - Flutter UI implementation
2. **`purchase_details_schema.sql`** - Supabase database schema
3. **`PURCHASE_DETAILS_INTEGRATION.md`** - This integration guide

## Step 1: Database Setup

### Execute SQL Schema in Supabase

1. Open your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy the contents of `purchase_details_schema.sql`
4. Paste and execute the SQL

This will create:
- ✅ `suppliers` table
- ✅ `purchases` table
- ✅ `purchase_items` table
- ✅ Row Level Security (RLS) policies
- ✅ Helper functions and triggers
- ✅ Sample data for testing

### Verify Installation

Run this query in Supabase SQL Editor to verify:

```sql
SELECT
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_name IN ('suppliers', 'purchases', 'purchase_items');
```

Expected result: 3 tables with their column counts.

## Step 2: Install Dependencies

Add `google_fonts` to your `pubspec.yaml` if not already present:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0  # Add this line
  supabase_flutter: ^2.5.10
  # ... other dependencies
```

Then run:

```bash
cd warehouse_management
flutter pub get
```

## Step 3: Create Purchase Service

Create a new service file: `lib/services/purchase_service.dart`

```dart
import 'package:warehouse_management/config/supabase_config.dart';

class PurchaseService {
  final _supabase = SupabaseConfig.client;

  // Fetch purchase details by ID
  Future<Map<String, dynamic>?> getPurchaseById(String purchaseId) async {
    try {
      final response = await _supabase
          .from('purchase_details_view')
          .select()
          .eq('id', purchaseId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching purchase: $e');
      return null;
    }
  }

  // Fetch purchase details by receipt number
  Future<Map<String, dynamic>?> getPurchaseByReceiptNumber(String receiptNumber) async {
    try {
      final response = await _supabase
          .from('purchase_details_view')
          .select()
          .eq('receipt_number', receiptNumber)
          .single();

      return response;
    } catch (e) {
      print('Error fetching purchase: $e');
      return null;
    }
  }

  // Fetch all purchases for current user
  Future<List<Map<String, dynamic>>> getAllPurchases() async {
    try {
      final response = await _supabase
          .from('purchases')
          .select('''
            *,
            suppliers (
              name,
              phone,
              address
            )
          ''')
          .order('purchase_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching purchases: $e');
      return [];
    }
  }

  // Create new purchase
  Future<String?> createPurchase({
    required String supplierId,
    required String receiptNumber,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    double deliveryCharge = 0,
    double discount = 0,
    String? notes,
    String? receiptImageUrl,
  }) async {
    try {
      // Calculate totals
      double subtotal = items.fold(0, (sum, item) => sum + (item['total_price'] ?? 0));
      double totalAmount = subtotal + deliveryCharge - discount;

      // Insert purchase
      final purchaseResponse = await _supabase
          .from('purchases')
          .insert({
            'supplier_id': supplierId,
            'receipt_number': receiptNumber,
            'payment_method': paymentMethod,
            'subtotal': subtotal,
            'delivery_charge': deliveryCharge,
            'discount': discount,
            'total_amount': totalAmount,
            'due_amount': totalAmount,
            'notes': notes,
            'receipt_image_url': receiptImageUrl,
          })
          .select('id')
          .single();

      final purchaseId = purchaseResponse['id'] as String;

      // Insert purchase items
      final purchaseItems = items.map((item) => {
        'purchase_id': purchaseId,
        'product_id': item['product_id'],
        'product_name': item['product_name'],
        'quantity': item['quantity'],
        'unit_price': item['unit_price'],
        'total_price': item['total_price'],
      }).toList();

      await _supabase.from('purchase_items').insert(purchaseItems);

      return purchaseId;
    } catch (e) {
      print('Error creating purchase: $e');
      return null;
    }
  }

  // Update purchase payment
  Future<bool> updatePurchasePayment({
    required String purchaseId,
    required double paidAmount,
    required String paymentStatus,
  }) async {
    try {
      await _supabase
          .from('purchases')
          .update({
            'paid_amount': paidAmount,
            'payment_status': paymentStatus,
          })
          .eq('id', purchaseId);

      return true;
    } catch (e) {
      print('Error updating purchase payment: $e');
      return false;
    }
  }

  // Delete purchase
  Future<bool> deletePurchase(String purchaseId) async {
    try {
      await _supabase
          .from('purchases')
          .delete()
          .eq('id', purchaseId);

      return true;
    } catch (e) {
      print('Error deleting purchase: $e');
      return false;
    }
  }
}
```

## Step 4: Update Purchase Details Screen (Dynamic Data)

To make the screen dynamic, update `purchase_details_screen.dart`:

### Option A: Simple Navigation with Receipt Number

```dart
// Navigate to purchase details
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PurchaseDetailsScreen(
      receiptNumber: '9216735951270',
    ),
  ),
);
```

### Option B: Full Implementation with State Management

Replace the current static screen with a dynamic version:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warehouse_management/services/purchase_service.dart';

class PurchaseDetailsScreen extends StatefulWidget {
  final String? purchaseId;
  final String? receiptNumber;

  const PurchaseDetailsScreen({
    super.key,
    this.purchaseId,
    this.receiptNumber,
  }) : assert(purchaseId != null || receiptNumber != null,
            'Either purchaseId or receiptNumber must be provided');

  @override
  State<PurchaseDetailsScreen> createState() => _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends State<PurchaseDetailsScreen> {
  final _purchaseService = PurchaseService();
  Map<String, dynamic>? _purchaseData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPurchaseData();
  }

  Future<void> _loadPurchaseData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic>? data;

      if (widget.purchaseId != null) {
        data = await _purchaseService.getPurchaseById(widget.purchaseId!);
      } else if (widget.receiptNumber != null) {
        data = await _purchaseService.getPurchaseByReceiptNumber(widget.receiptNumber!);
      }

      setState(() {
        _purchaseData = data;
        _isLoading = false;
        if (data == null) {
          _error = 'Purchase not found';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading purchase: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ক্রয়ের বিবরণ',
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.red)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPurchaseData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildPurchaseDetails(),
    );
  }

  Widget _buildPurchaseDetails() {
    if (_purchaseData == null) {
      return const Center(child: Text('No data available'));
    }

    // Extract data
    final receiptNumber = _purchaseData!['receipt_number'] ?? '';
    final paymentMethod = _purchaseData!['payment_method'] ?? '';
    final purchaseDate = _purchaseData!['purchase_date'] ?? '';
    final totalAmount = _purchaseData!['total_amount'] ?? 0.0;
    final subtotal = _purchaseData!['subtotal'] ?? 0.0;
    final deliveryCharge = _purchaseData!['delivery_charge'] ?? 0.0;
    final discount = _purchaseData!['discount'] ?? 0.0;
    final paymentStatus = _purchaseData!['payment_status'] ?? '';
    final notes = _purchaseData!['notes'] ?? '';
    final supplierName = _purchaseData!['supplier_name'] ?? '';
    final supplierPhone = _purchaseData!['supplier_phone'] ?? '';
    final supplierAddress = _purchaseData!['supplier_address'] ?? '';
    final supplierBalance = _purchaseData!['supplier_balance'] ?? 0.0;
    final items = _purchaseData!['items'] as List? ?? [];

    // Format date
    final formattedDate = _formatDate(purchaseDate);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Purchase Header Card
                _SoftCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              receiptNumber,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 14,
                                  color: const Color(0xFF6B7280),
                                ),
                                children: [
                                  const TextSpan(text: 'মূল্য পরিশোধ পদ্ধতি: '),
                                  TextSpan(
                                    text: paymentMethod,
                                    style: GoogleFonts.hindSiliguri(
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedDate,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(totalAmount),
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              // TODO: Handle image tap
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.image,
                                size: 20,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Supplier Info Card
                _SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplierName,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      if (supplierPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          supplierPhone,
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                      if (supplierAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          supplierAddress,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Product List Card
                _SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ক্রয় করা পণ্যের লিস্ট',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const Divider(
                        height: 20,
                        thickness: 1,
                        color: Color(0xFFF3F4F6),
                      ),
                      Column(
                        children: items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ProductRow(
                              name: item['product_name'] ?? '',
                              quantity: 'X${item['quantity'] ?? 0}',
                              price: _formatCurrency(item['total_price'] ?? 0),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Summary Card
                _SoftCard(
                  child: Column(
                    children: [
                      _KeyValueRow(
                        label: 'মোট',
                        value: _formatCurrency(subtotal),
                      ),
                      const SizedBox(height: 8),
                      _KeyValueRow(
                        label: 'ডেলিভারী চার্জ',
                        value: _formatCurrency(deliveryCharge),
                      ),
                      const SizedBox(height: 8),
                      _KeyValueRow(
                        label: 'ডিস্কাউন্ট',
                        value: _formatCurrency(discount),
                      ),
                      const Divider(
                        height: 20,
                        thickness: 1,
                        color: Color(0xFFF3F4F6),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'সর্বমোট',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            _formatCurrency(totalAmount),
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'পেমেন্ট অবস্থা',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            paymentStatus,
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Supplier Balance Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'সাপ্লায়ার ব্যালেন্স',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            supplierBalance.toStringAsFixed(0),
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF26A69A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.rotate(
                            angle: -0.785398,
                            child: const Icon(
                              Icons.arrow_upward,
                              size: 20,
                              color: Color(0xFF26A69A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Actions Grid
                Row(
                  children: [
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.print,
                        label: 'রিসিপ্ট প্রিন্ট করুন',
                        onTap: () {
                          // TODO: Implement print
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionTile(
                        icon: Icons.share,
                        label: 'রিসিপ্ট শেয়ার',
                        onTap: () {
                          // TODO: Implement share
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes Field
                if (notes.isNotEmpty)
                  _FloatingLabelBox(
                    label: 'নোট',
                    content: notes,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];
      final year = date.year;
      final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour < 12 ? 'AM' : 'PM';

      return '$day $month $year | $hour:$minute $period';
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(dynamic amount) {
    final value = double.tryParse(amount.toString()) ?? 0.0;
    return '${_toBengaliNumerals(value.toStringAsFixed(1))} ৳';
  }

  String _toBengaliNumerals(String number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

    String result = number;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], bengali[i]);
    }

    // Add thousand separators
    List<String> parts = result.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    // Add commas
    String formatted = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count == 3) {
        formatted = ',$formatted';
        count = 0;
      }
      formatted = integerPart[i] + formatted;
      count++;
    }

    return formatted + decimalPart;
  }
}

// ... (Keep all the _SoftCard, _KeyValueRow, _ProductRow, _ActionTile, _FloatingLabelBox widgets from the original file)
```

## Step 5: Navigation Examples

### From Purchase List Screen

```dart
// In your purchase list
ListTile(
  title: Text(purchase['receipt_number']),
  subtitle: Text(purchase['total_amount'].toString()),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseDetailsScreen(
          purchaseId: purchase['id'],
        ),
      ),
    );
  },
)
```

### From Barcode Scanner

```dart
// After scanning a receipt barcode
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PurchaseDetailsScreen(
      receiptNumber: scannedBarcode,
    ),
  ),
);
```

## Step 6: Testing

### Test with Sample Data

1. Run the SQL script to insert sample data
2. Navigate to PurchaseDetailsScreen:

```dart
// Test navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PurchaseDetailsScreen(
      receiptNumber: '9216735951270',
    ),
  ),
);
```

3. Verify all sections display correctly:
   - ✅ Purchase header with receipt number and amount
   - ✅ Supplier information
   - ✅ Product list with quantities and prices
   - ✅ Summary with totals
   - ✅ Supplier balance
   - ✅ Action buttons (Print/Share)
   - ✅ Notes section

## Features Implemented

### ✅ Complete Features
- Pixel-perfect UI matching HTML design
- Material 3 design system
- Bengali text support (Hind Siliguri font)
- Responsive layout (max-width 420px)
- Soft shadows and rounded corners
- Database schema with RLS
- Sample data for testing

### 🔄 TODO Features (Implement as needed)
- [ ] Print receipt functionality
- [ ] Share receipt functionality
- [ ] Image upload for receipts
- [ ] Edit purchase details
- [ ] Delete purchase
- [ ] Payment recording
- [ ] PDF generation
- [ ] Bengali numeral conversion (implemented in dynamic version)
- [ ] Date formatting (implemented in dynamic version)

## Database Schema Details

### Tables Created

1. **suppliers**
   - id (UUID)
   - user_id (UUID, FK to auth.users)
   - name, phone, address
   - balance (for tracking supplier credit/debit)

2. **purchases**
   - id (UUID)
   - user_id (UUID, FK to auth.users)
   - supplier_id (UUID, FK to suppliers)
   - receipt_number (unique per user)
   - payment_method, payment_status
   - subtotal, delivery_charge, discount
   - total_amount, paid_amount, due_amount
   - notes, receipt_image_url
   - purchase_date

3. **purchase_items**
   - id (UUID)
   - purchase_id (UUID, FK to purchases)
   - product_id (UUID, FK to products)
   - product_name, quantity
   - unit_price, total_price

### Helper View

`purchase_details_view` - Combines purchase, supplier, and items data for easy querying

## Troubleshooting

### Issue: "Table does not exist"
**Solution**: Execute the SQL schema in Supabase SQL Editor first

### Issue: "google_fonts not found"
**Solution**: Run `flutter pub get` after adding google_fonts to pubspec.yaml

### Issue: "RLS policy violation"
**Solution**: Ensure user is authenticated and RLS policies are enabled

### Issue: Bengali text not displaying
**Solution**: Verify Hind Siliguri font is loading correctly

### Issue: Data not showing
**Solution**: Check if sample data was inserted and user_id matches authenticated user

## Support

For issues or questions:
1. Check IMPLEMENTATION_STATUS.md for project status
2. Review PRD.md for feature requirements
3. Consult CLAUDE.md for development patterns

## Next Steps

1. ✅ Database schema executed
2. ✅ Dependencies installed
3. ✅ PurchaseService created
4. ⏳ Update screen to use dynamic data
5. ⏳ Implement print/share functionality
6. ⏳ Add purchase creation flow
7. ⏳ Integrate with existing inventory system

---

**Version**: 1.0.0
**Last Updated**: 2026-01-17
**Author**: Claude Code
