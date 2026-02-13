import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/models/sale.dart';
import 'package:wavezly/models/sale_item.dart';
import 'package:wavezly/models/cart_item.dart';
import 'package:wavezly/repositories/sales_repository.dart';

/// SalesService - Backward-compatible facade over SalesRepository
/// Maintains existing public API while using offline-first repository internally
class SalesService {
  final SalesRepository _repository = SalesRepository();

  /// Generate sale number (now handled locally by repository)
  Future<String> generateSaleNumber() async {
    // Generate local sale number format: S-YYYYMMDD-XXXXX
    final timestamp = DateTime.now();
    final dateStr = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
    final random = timestamp.millisecondsSinceEpoch % 100000;
    return 'S-$dateStr-${random.toString().padLeft(5, '0')}';
  }

  /// Check which product IDs are missing from server (legacy - no longer needed for offline-first)
  Future<List<String>> findMissingProductIds(List<String> productIds) async {
    // Offline-first: Always return empty (products are local)
    return [];
  }

  /// Validate UUID format
  bool _isValidUUID(String? id) {
    if (id == null || id.isEmpty) return false;
    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidPattern.hasMatch(id);
  }

  /// Process sale - now uses offline-first repository
  Future<String> processSale(Sale sale, List<CartItem> cartItems) async {
    // Validate product IDs (basic format check)
    final productIds = cartItems
        .map((item) => item.product.id)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    for (final id in productIds) {
      if (!_isValidUUID(id)) {
        throw Exception(
          'পণ্যটি সঠিক নয়। আবার চেষ্টা করুন।',
        );
      }
    }

    try {
      return await _repository.processSale(sale, cartItems);
    } catch (e) {
      throw Exception('বিক্রয় প্রক্রিয়া সম্পূর্ণ করা সম্ভব হয়নি: ${e.toString()}');
    }
  }

  /// Process quick cash sale - uses offline-first repository
  Future<String> processQuickCashSale({
    required String userId,
    required double cashReceived,
    String? customerMobile,
    double? profitMargin,
    String? productDetails,
    bool receiptSmsEnabled = true,
    DateTime? saleDate,
    String? photoUrl,
  }) async {
    try {
      return await _repository.processQuickCashSale(
        cashReceived: cashReceived,
        customerMobile: customerMobile,
        profitMargin: profitMargin,
        productDetails: productDetails,
        receiptSmsEnabled: receiptSmsEnabled,
        saleDate: saleDate,
        photoUrl: photoUrl,
      );
    } catch (e) {
      throw Exception('Quick cash sale failed: ${e.toString()}');
    }
  }

  /// Get sale by ID - reads from local database
  Future<Sale> getSaleById(String saleId) async {
    final sale = await _repository.getSaleById(saleId);
    if (sale == null) {
      throw Exception('Sale not found');
    }
    return sale;
  }

  /// Get sale items - returns stream (convert to future for backward compatibility)
  Future<List<SaleItem>> getSaleItems(String saleId) async {
    return await _repository.getSaleItems(saleId).first;
  }

  /// Get all sales - returns stream (convert to future for backward compatibility)
  Future<List<Sale>> getAllSales() async {
    try {
      return await _repository.getAllSales().first;
    } catch (e) {
      throw Exception('বিক্রয় তথ্য লোড করতে সমস্যা হয়েছে: ${e.toString()}');
    }
  }
}
