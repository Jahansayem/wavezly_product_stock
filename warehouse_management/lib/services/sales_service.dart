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

  Future<String> processSale(Sale sale, List<CartItem> cartItems) async {
    final saleNumber = await generateSaleNumber();
    sale.saleNumber = saleNumber;

    final saleItems = cartItems.map((item) => item.toSaleItemJson()).toList();

    final response = await _supabase.rpc('process_sale', params: {
      'p_sale_data': sale.toJson(),
      'p_sale_items': saleItems,
    });

    return response as String;
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
