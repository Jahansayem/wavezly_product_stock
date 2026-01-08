import 'package:warehouse_management/config/supabase_config.dart';
import 'package:warehouse_management/models/sale.dart';
import 'package:warehouse_management/models/sale_item.dart';
import 'package:warehouse_management/models/cart_item.dart';

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

  Future<Sale> getSaleById(String saleId) async {
    final response = await _supabase.from('sales').select().eq('id', saleId).single();
    return Sale.fromMap(response);
  }

  Future<List<SaleItem>> getSaleItems(String saleId) async {
    final response = await _supabase.from('sale_items').select().eq('sale_id', saleId);
    return (response as List).map((item) => SaleItem.fromMap(item)).toList();
  }
}
