import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/models/sale.dart';
import 'package:wavezly/models/sale_item.dart';
import 'package:wavezly/models/cart_item.dart';

class SalesService {
  final _supabase = SupabaseConfig.client;

  Future<String> generateSaleNumber() async {
    final response = await _supabase.rpc('generate_sale_number');
    return response as String;
  }

  /// Check which product IDs are missing from server
  Future<List<String>> findMissingProductIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    try {
      final response = await _supabase
          .from('products')
          .select('id')
          .inFilter('id', productIds);

      final existingIds = (response as List)
          .map((row) => row['id'] as String)
          .toSet();

      return productIds.where((id) => !existingIds.contains(id)).toList();
    } catch (e) {
      // If query fails, assume all missing to be safe
      return productIds;
    }
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

  Future<String> processSale(Sale sale, List<CartItem> cartItems) async {
    // Collect and validate product IDs
    final productIds = cartItems
        .map((item) => item.product.id)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    // Validate UUID format
    for (final id in productIds) {
      if (!_isValidUUID(id)) {
        throw Exception(
          'পণ্যটি সার্ভারে sync হয়নি। Sync করে আবার চেষ্টা করুন।',
        );
      }
    }

    // Check if products exist on server
    final missingIds = await findMissingProductIds(productIds);
    if (missingIds.isNotEmpty) {
      throw Exception(
        'কিছু পণ্য সার্ভারে sync হয়নি। Sync করে আবার চেষ্টা করুন।',
      );
    }

    try {
      final saleNumber = await generateSaleNumber();
      sale.saleNumber = saleNumber;

      final saleItems = cartItems.map((item) => item.toSaleItemJson()).toList();

      final response = await _supabase.rpc('process_sale', params: {
        'p_sale_data': sale.toJson(),
        'p_sale_items': saleItems,
      });

      return response as String;
    } on PostgrestException catch (e) {
      // Map database errors to user-friendly messages
      if (e.message.contains('foreign key') ||
          e.message.contains('product_id') ||
          e.message.contains('uuid')) {
        throw Exception(
          'কিছু পণ্য সার্ভারে sync হয়নি। Sync করে আবার চেষ্টা করুন।',
        );
      }
      rethrow;
    }
  }

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
      final response = await _supabase.rpc('create_quick_cash_sale', params: {
        'p_user_id': userId,
        'p_customer_mobile': customerMobile,
        'p_cash_received': cashReceived,
        'p_profit_margin': profitMargin ?? 0.0,
        'p_product_details': productDetails,
        'p_receipt_sms_enabled': receiptSmsEnabled,
        'p_sale_date': saleDate?.toIso8601String().split('T')[0],
        'p_photo_url': photoUrl,
      });

      return response as String;
    } catch (e) {
      throw Exception('Quick cash sale failed: ${e.toString()}');
    }
  }

  Future<Sale> getSaleById(String saleId) async {
    final response = await _supabase.from('sales').select().eq('id', saleId).single();
    return Sale.fromMap(response);
  }

  Future<List<SaleItem>> getSaleItems(String saleId) async {
    final response = await _supabase.from('sale_items').select().eq('sale_id', saleId);
    return (response as List).map((item) => SaleItem.fromMap(item)).toList();
  }
}
