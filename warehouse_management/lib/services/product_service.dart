import 'dart:io';
import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductService {
  final ProductRepository _repository = ProductRepository();

  // Delegate to repository
  Stream<List<Product>> getAllProducts() => _repository.getAllProducts();

  Future<List<Product>> getProducts() async {
    return await getAllProducts().first;
  }

  Stream<List<Product>> getProductsByGroup(String group) =>
      _repository.getProductsByGroup(group);

  Future<void> addProduct(Product product, {File? imageFile}) =>
      _repository.addProduct(product, imageFile: imageFile);

  Future<void> updateProduct(String id, Product product, {File? newImageFile}) =>
      _repository.updateProduct(id, product, newImageFile: newImageFile);

  Future<void> updateProductQuantity(String id, int newQuantity) =>
      _repository.updateProductQuantity(id, newQuantity);

  Future<void> deleteProduct(String id) => _repository.deleteProduct(id);

  Future<void> deleteProductImage(String productId, String imageUrl) =>
      _repository.deleteProductImage(productId, imageUrl);

  Future<Product?> getProductById(String id) => _repository.getProductById(id);

  Future<List<Product>> searchProducts(String query) =>
      _repository.searchProducts(query);

  Future<List<Product>> searchProductsInGroup(String query, String group) =>
      _repository.searchProductsInGroup(query, group);

  List<Product> sortProducts(List<Product> products, String sortBy) {
    switch (sortBy) {
      case 'name_asc':
        products.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        break;
      case 'quantity_asc':
        products.sort((a, b) => (a.quantity ?? 0).compareTo(b.quantity ?? 0));
        break;
      case 'quantity_desc':
        products.sort((a, b) => (b.quantity ?? 0).compareTo(a.quantity ?? 0));
        break;
      case 'expiry_asc':
        products.sort((a, b) {
          if (a.expiryDate == null && b.expiryDate == null) return 0;
          if (a.expiryDate == null) return 1;
          if (b.expiryDate == null) return -1;
          return a.expiryDate!.compareTo(b.expiryDate!);
        });
        break;
    }
    return products;
  }

  // Product groups management
  Future<List<String>> getProductGroups() => _repository.getProductGroups();

  Stream<List<String>> getProductGroupsStream() =>
      _repository.getProductGroupsStream();

  Future<void> addProductGroup(String groupName) =>
      _repository.addProductGroup(groupName);

  Future<void> deleteProductGroup(String groupName) =>
      _repository.deleteProductGroup(groupName);

  // Locations management
  Future<List<String>> getLocations() => _repository.getLocations();

  /// Apply local stock deductions after sale completion
  /// Updates local cache immediately without queuing sync
  Future<void> applyLocalStockDeductions(Map<String, int> deductions) =>
      _repository.applyLocalStockDeductions(deductions);

  /// Apply local stock increments after purchase completion
  /// Updates local cache immediately without queuing sync
  Future<void> applyLocalStockIncrements(Map<String, int> increments) =>
      _repository.applyLocalStockIncrements(increments);
}
