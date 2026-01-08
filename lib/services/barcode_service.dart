import 'package:warehouse_management/config/supabase_config.dart';
import 'package:warehouse_management/models/product.dart';

class BarcodeService {
  Future<Product?> findProductByBarcode(String barcode) async {
    final response = await SupabaseConfig.client
        .from('products')
        .select()
        .eq('barcode', barcode)
        .eq('user_id', SupabaseConfig.client.auth.currentUser!.id)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromMap(response);
  }
}
