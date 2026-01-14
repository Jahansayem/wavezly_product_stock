import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/models/purchase.dart';
import 'package:wavezly/models/purchase_item.dart';
import 'package:wavezly/models/buying_cart_item.dart';

class PurchaseService {
  final _supabase = SupabaseConfig.client;

  Future<String> generatePurchaseNumber() async {
    final response = await _supabase.rpc('generate_purchase_number');
    return response as String;
  }

  Future<String> processPurchase({
    required Purchase purchase,
    required List<BuyingCartItem> cartItems,
  }) async {
    try {
      final purchaseNumber = await generatePurchaseNumber();
      purchase.purchaseNumber = purchaseNumber;

      final purchaseItemsJson = cartItems
          .map((item) => {
                'product_id': item.productId,
                'product_name': item.productName,
                'cost_price': item.costPrice,
                'quantity': item.quantity,
                'total_cost': item.totalCost,
              })
          .toList();

      final response = await _supabase.rpc('process_purchase', params: {
        'p_purchase_data': purchase.toMap(),
        'p_purchase_items': purchaseItemsJson,
      });

      return response as String;
    } catch (e) {
      throw Exception('Failed to process purchase: $e');
    }
  }

  Future<Purchase> getPurchaseById(String purchaseId) async {
    final response = await _supabase
        .from('purchases')
        .select()
        .eq('id', purchaseId)
        .single();
    return Purchase.fromMap(response);
  }

  Future<List<PurchaseItem>> getPurchaseItems(String purchaseId) async {
    final response = await _supabase
        .from('purchase_items')
        .select()
        .eq('purchase_id', purchaseId)
        .order('created_at');
    return (response as List)
        .map((item) => PurchaseItem.fromMap(item))
        .toList();
  }

  Future<List<Purchase>> getAllPurchases() async {
    final response = await _supabase
        .from('purchases')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((item) => Purchase.fromMap(item)).toList();
  }

  Future<List<Purchase>> getPurchasesBySupplier(String supplierId) async {
    final response = await _supabase
        .from('purchases')
        .select()
        .eq('supplier_id', supplierId)
        .order('created_at', ascending: false);
    return (response as List).map((item) => Purchase.fromMap(item)).toList();
  }
}
