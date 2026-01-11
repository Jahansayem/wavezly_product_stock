import 'package:flutter/material.dart';
import 'package:wavezly/screens/inventory_screen.dart';
import 'package:wavezly/screens/new_product_page.dart';
import 'package:wavezly/screens/product_details_page.dart';
import 'package:wavezly/screens/product_details_screen.dart';
import 'package:wavezly/screens/global_search_page.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/models/product.dart';

class InventoryScreenWrapper extends StatelessWidget {
  final Function(int) onTabSelected;

  const InventoryScreenWrapper({
    Key? key,
    required this.onTabSelected,
  }) : super(key: key);

  void _handleBack(BuildContext context) {
    // Navigate to home tab (index 0)
    onTabSelected(0);
  }

  void _handleSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GlobalSearchPage()),
    );
  }

  void _handleMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement export functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_alt),
              title: const Text('Advanced Filters'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement advanced filters
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings tab
                onTabSelected(3);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddNewProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NewProductPage()),
    );
  }

  void _handleProductTap(BuildContext context, ProductItem productItem) async {
    // Fetch full product data from ProductService
    final productService = ProductService();
    final fullProduct = await productService.getProductById(productItem.id);

    if (fullProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found')),
      );
      return;
    }

    // Navigate to ProductDetailsScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(
          productName: fullProduct.name ?? 'Unknown Product',
          salePriceText: '${_calculateSalePrice(fullProduct).toStringAsFixed(0)} ৳',
          costPriceText: '${fullProduct.cost?.toStringAsFixed(0) ?? '0'} ৳',
          profitText: '${_calculateProfit(fullProduct).toStringAsFixed(0)} ৳',
          stockText: '${fullProduct.quantity ?? 0}',
          stockValueText: '${_calculateStockValue(fullProduct).toStringAsFixed(0)} ৳',
          discountText: 'Not set',
          subCatText: fullProduct.group ?? 'Not set',
          vatText: '0%',
          warrantyText: 'Not set',
          lowStockText: _getLowStockStatus(fullProduct),
          descriptionText: fullProduct.description ?? 'No description provided for this item.',
          imageUrl: fullProduct.image,
          onBack: () => Navigator.of(context).pop(),
          onHelp: () => _showHelpDialog(context),
          onEdit: () => _handleEdit(context, fullProduct),
          onDelete: () => _handleDelete(context, fullProduct),
          onUpdateStock: () => _handleUpdateStock(context, fullProduct),
          onShare: () => _handleShare(context, fullProduct),
          onHistory: () => _handleHistory(context, fullProduct),
        ),
      ),
    );
  }

  // Helper calculation methods
  double _calculateSalePrice(Product product) {
    // Assume 20% markup if no separate sale price
    return (product.cost ?? 0) * 1.2;
  }

  double _calculateProfit(Product product) {
    return _calculateSalePrice(product) - (product.cost ?? 0);
  }

  double _calculateStockValue(Product product) {
    return (product.cost ?? 0) * (product.quantity ?? 0);
  }

  String _getLowStockStatus(Product product) {
    final qty = product.quantity ?? 0;
    if (qty < 10) return 'Low Stock Alert';
    return 'Healthy Stock';
  }

  // Callback implementations
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Details Help'),
        content: const Text('View complete product information, update stock, edit details, or delete product.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _handleEdit(BuildContext context, Product product) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          product: product,
          docID: product.id,
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && product.id != null) {
      final productService = ProductService();
      await productService.deleteProduct(product.id!);
      Navigator.of(context).pop(); // Return to inventory
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
    }
  }

  void _handleUpdateStock(BuildContext context, Product product) async {
    final controller = TextEditingController(
      text: product.quantity?.toString() ?? '0',
    );

    final newQty = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final qty = int.tryParse(controller.text);
              Navigator.of(context).pop(qty);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (newQty != null && product.id != null) {
      product.quantity = newQty;
      final productService = ProductService();
      await productService.updateProduct(product.id!, product);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock updated successfully')),
      );
      Navigator.of(context).pop(); // Refresh inventory
    }
  }

  void _handleShare(BuildContext context, Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  void _handleHistory(BuildContext context, Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // InventoryScreen with all its content including its own bottom nav
        InventoryScreen(
          onBack: () => _handleBack(context),
          onSearch: () => _handleSearch(context),
          onMore: () => _handleMore(context),
          onAddNewProduct: () => _handleAddNewProduct(context),
          onTabSelected: onTabSelected,
          onProductTap: (product) => _handleProductTap(context, product),
        ),
        // White overlay to hide InventoryScreen's bottom nav
        // This allows MainNavigation's bottom nav to show instead
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80,
          child: Container(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
