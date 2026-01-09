import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/models/product.dart';

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
