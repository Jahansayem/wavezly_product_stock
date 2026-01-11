import 'package:flutter/material.dart';
import 'package:wavezly/screens/inventory_screen.dart';
import 'package:wavezly/screens/new_product_page.dart';
import 'package:wavezly/screens/product_details_page.dart';
import 'package:wavezly/screens/global_search_page.dart';

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

  void _handleProductTap(BuildContext context, ProductItem product) {
    // Navigate to product details
    // Note: ProductDetailsPage may need modification to accept ProductItem
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tapped: ${product.title}')),
    );

    // TODO: Implement proper navigation to ProductDetailsPage
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => ProductDetailsPage(product: product),
    //   ),
    // );
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
