import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/product.dart';

class ProductService {
  final _supabase = SupabaseConfig.client;

  Stream<List<Product>> getAllProducts() {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((data) => data.map((item) => Product.fromMap(item)).toList());
  }

  Stream<List<Product>> getProductsByGroup(String group) {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('product_group', group)
        .order('name')
        .map((data) => data.map((item) => Product.fromMap(item)).toList());
  }

  Future<void> addProduct(Product product) async {
    final data = product.toMap();
    data['user_id'] = _supabase.auth.currentUser!.id;
    await _supabase.from('products').insert(data);
  }

  Future<void> updateProduct(String id, Product product) async {
    await _supabase.from('products').update(product.toMap()).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }

  Future<List<Product>> searchProducts(String query) async {
    final response = await _supabase
        .from('products')
        .select()
        .ilike('name', '%$query%')
        .order('name');

    return (response as List).map((item) => Product.fromMap(item)).toList();
  }

  Future<List<Product>> searchProductsInGroup(String query, String group) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('product_group', group)
        .ilike('name', '%$query%')
        .order('name');

    return (response as List).map((item) => Product.fromMap(item)).toList();
  }

  // Product groups management
  Future<List<String>> getProductGroups() async {
    final response = await _supabase
        .from('product_groups')
        .select('name')
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('name');

    return (response as List).map((item) => item['name'] as String).toList();
  }

  Stream<List<String>> getProductGroupsStream() {
    return _supabase
        .from('product_groups')
        .stream(primaryKey: ['id'])
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('name')
        .map((data) => data.map((item) => item['name'] as String).toList());
  }

  Future<void> addProductGroup(String groupName) async {
    await _supabase.from('product_groups').insert({
      'name': groupName,
      'user_id': _supabase.auth.currentUser!.id,
    });
  }

  Future<void> deleteProductGroup(String groupName) async {
    await _supabase
        .from('product_groups')
        .delete()
        .eq('name', groupName)
        .eq('user_id', _supabase.auth.currentUser!.id);
  }

  // Locations management
  Future<List<String>> getLocations() async {
    final response = await _supabase
        .from('locations')
        .select('name')
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('name');

    return (response as List).map((item) => item['name'] as String).toList();
  }
}
