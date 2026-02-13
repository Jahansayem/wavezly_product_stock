import 'package:wavezly/models/purchase.dart';
import 'package:wavezly/models/purchase_item.dart';
import 'package:wavezly/models/buying_cart_item.dart';
import 'package:wavezly/repositories/purchase_repository.dart';

/// PurchaseService - Backward-compatible facade over PurchaseRepository
/// Maintains existing public API while using offline-first repository internally
class PurchaseService {
  final PurchaseRepository _repository = PurchaseRepository();

  /// Generate purchase number (now handled locally by repository)
  Future<String> generatePurchaseNumber() async {
    // Generate local purchase number format: P-YYYYMMDD-XXXXX
    final timestamp = DateTime.now();
    final dateStr = '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}';
    final random = timestamp.millisecondsSinceEpoch % 100000;
    return 'P-$dateStr-${random.toString().padLeft(5, '0')}';
  }

  /// Process purchase - now uses offline-first repository
  Future<String> processPurchase({
    required Purchase purchase,
    required List<BuyingCartItem> cartItems,
  }) async {
    try {
      return await _repository.processPurchase(
        purchase: purchase,
        cartItems: cartItems,
      );
    } catch (e) {
      throw Exception('Failed to process purchase: $e');
    }
  }

  /// Get purchase by ID - reads from local database
  Future<Purchase> getPurchaseById(String purchaseId) async {
    final purchase = await _repository.getPurchaseById(purchaseId);
    if (purchase == null) {
      throw Exception('Purchase not found');
    }
    return purchase;
  }

  /// Get purchase items - returns stream (convert to future for backward compatibility)
  Future<List<PurchaseItem>> getPurchaseItems(String purchaseId) async {
    return await _repository.getPurchaseItems(purchaseId).first;
  }

  /// Get all purchases - returns stream (convert to future for backward compatibility)
  Future<List<Purchase>> getAllPurchases() async {
    return await _repository.getAllPurchases().first;
  }

  /// Get purchases by supplier - reads from local database
  Future<List<Purchase>> getPurchasesBySupplier(String supplierId) async {
    return await _repository.getPurchasesBySupplier(supplierId);
  }
}
