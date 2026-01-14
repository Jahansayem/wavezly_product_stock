import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/screens/select_product_buying_screen.dart';

enum ProductBadge { none, lowStock, expired }

enum ProductFilter { all, lowStock, expired }

class ProductItem {
  final String id;
  final String title;
  final String category;
  final String sku;
  final String imageUrl;
  final int stock;
  final double value;
  final ProductBadge badge;

  ProductItem({
    required this.id,
    required this.title,
    required this.category,
    required this.sku,
    required this.imageUrl,
    required this.stock,
    required this.value,
    this.badge = ProductBadge.none,
  });

  factory ProductItem.fromProduct(Product product) {
    return ProductItem(
      id: product.id ?? '',
      title: product.name ?? 'Unknown Product',
      category: product.group ?? 'UNCATEGORIZED',
      sku: product.barcode ?? '',
      imageUrl: product.image ?? '',
      stock: product.quantity ?? 0,
      value: product.cost ?? 0.0,
      badge: _calculateBadge(product),
    );
  }

  static ProductBadge _calculateBadge(Product product) {
    // Check expiry date
    if (product.expiryDate != null) {
      final daysUntilExpiry = product.expiryDate!.difference(DateTime.now()).inDays;
      if (daysUntilExpiry < 0 || daysUntilExpiry <= 7) {
        return ProductBadge.expired;
      }
    }

    // Check low stock
    if ((product.quantity ?? 0) < 10) {
      return ProductBadge.lowStock;
    }

    return ProductBadge.none;
  }

  Color get stockColor {
    if (badge == ProductBadge.lowStock) return ColorPalette.warningAmber;
    if (badge == ProductBadge.expired) return ColorPalette.slate500;
    return ColorPalette.tealAccent;
  }
}

class InventoryScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onMore;
  final VoidCallback onAddNewProduct;
  final Function(int) onTabSelected;
  final Function(ProductItem) onProductTap;

  const InventoryScreen({
    Key? key,
    required this.onBack,
    required this.onSearch,
    required this.onMore,
    required this.onAddNewProduct,
    required this.onTabSelected,
    required this.onProductTap,
  }) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ProductService _productService = ProductService();
  ProductFilter _selectedFilter = ProductFilter.all;

  static const Color _primary = ColorPalette.tealAccent;
  static const Color _secondary = ColorPalette.warningAmber;
  static const Color _danger = ColorPalette.danger;
  static const Color _background = Colors.white;
  static const Color _slate50 = ColorPalette.slate50;
  static const Color _slate100 = ColorPalette.slate100;
  static const Color _slate200 = ColorPalette.slate200;
  static const Color _slate400 = ColorPalette.slate400;
  static const Color _slate500 = ColorPalette.slate500;
  static const Color _slate700 = ColorPalette.slate700;
  static const Color _slate800 = ColorPalette.slate800;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            _buildTableHeader(),
            Expanded(child: _buildProductList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventory_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SelectProductBuyingScreen(),
            ),
          );
        },
        backgroundColor: _primary,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
        label: const Text(
          'স্টক যোগ করুন',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 24, color: Colors.white),
                    onPressed: widget.onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Inventory',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.search, size: 22, color: Colors.white.withOpacity(0.9)),
                    onPressed: widget.onSearch,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.more_vert, size: 22, color: Colors.white.withOpacity(0.9)),
                    onPressed: widget.onMore,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: widget.onAddNewProduct,
              icon: const Icon(Icons.add_circle, size: 18),
              label: const Text(
                'ADD NEW PRODUCT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _slate200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _FilterChip(
              label: 'All Items',
              isActive: _selectedFilter == ProductFilter.all,
              onTap: () => setState(() => _selectedFilter = ProductFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Low Stock',
              isActive: _selectedFilter == ProductFilter.lowStock,
              onTap: () => setState(() => _selectedFilter = ProductFilter.lowStock),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Expired',
              isActive: _selectedFilter == ProductFilter.expired,
              onTap: () => setState(() => _selectedFilter = ProductFilter.expired),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _slate100.withOpacity(0.5),
        border: const Border(bottom: BorderSide(color: _slate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 32),
                Text(
                  'PRODUCT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _slate400,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  'STOCK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _slate400,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: Text(
                  'VALUE',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _slate400,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<List<Product>>(
      stream: _productService.getAllProducts(),
      builder: (context, snapshot) {
        print('📺 StreamBuilder rebuild - ConnectionState: ${snapshot.connectionState}');

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ StreamBuilder WAITING...');
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.tealAccent),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          print('❌ StreamBuilder ERROR: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: ColorPalette.danger),
                const SizedBox(height: 16),
                Text(
                  'Error loading products',
                  style: TextStyle(color: ColorPalette.slate700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '${snapshot.error}',
                    style: TextStyle(color: ColorPalette.danger, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Force rebuild to retry
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Empty state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('⚠️ StreamBuilder NO DATA (hasData: ${snapshot.hasData}, isEmpty: ${snapshot.data?.isEmpty})');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_outlined, size: 64, color: ColorPalette.slate400),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(color: ColorPalette.slate700),
                ),
              ],
            ),
          );
        }

        // Success state - convert and display
        final products = snapshot.data!;
        print('✅ StreamBuilder DATA: ${products.length} products');
        final productItems = products.map((p) => ProductItem.fromProduct(p)).toList();

        // Filter products based on selected filter
        final filteredProducts = _filterProducts(productItems);

        // Show empty state if no products match filter
        if (filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: 64, color: ColorPalette.slate400),
                const SizedBox(height: 16),
                Text(
                  'No products match this filter',
                  style: TextStyle(color: ColorPalette.slate700),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            return _ProductRow(
              product: filteredProducts[index],
              onTap: () => widget.onProductTap(filteredProducts[index]),
            );
          },
        );
      },
    );
  }

  List<ProductItem> _filterProducts(List<ProductItem> products) {
    switch (_selectedFilter) {
      case ProductFilter.all:
        return products;
      case ProductFilter.lowStock:
        return products.where((p) => p.badge == ProductBadge.lowStock).toList();
      case ProductFilter.expired:
        return products.where((p) => p.badge == ProductBadge.expired).toList();
    }
  }

}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  static const Color _primary = ColorPalette.tealAccent;
  static const Color _slate50 = ColorPalette.slate50;
  static const Color _slate200 = ColorPalette.slate200;
  static const Color _slate500 = ColorPalette.slate500;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? _primary.withOpacity(0.1) : _slate50,
          borderRadius: BorderRadius.circular(6),
          border: isActive ? null : Border.all(color: _slate200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? _primary : _slate500,
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final ProductItem product;
  final VoidCallback onTap;

  const _ProductRow({
    required this.product,
    required this.onTap,
  });

  static const Color _slate100 = ColorPalette.slate100;
  static const Color _slate400 = ColorPalette.slate400;
  static const Color _slate700 = ColorPalette.slate700;
  static const Color _slate800 = ColorPalette.slate800;
  static const Color _secondary = ColorPalette.warningAmber;
  static const Color _danger = ColorPalette.danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _slate100)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _slate100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _slate100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: _slate100,
                      child: const Icon(Icons.image, size: 24, color: _slate400),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _slate800,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (product.badge != ProductBadge.none) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: product.badge == ProductBadge.lowStock
                                ? _secondary
                                : _danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.badge == ProductBadge.expired
                        ? 'EXP. TOMORROW'
                        : '${product.category} • #${product.sku}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: product.badge == ProductBadge.expired
                          ? _danger
                          : _slate400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${product.stock}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: product.stockColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: Text(
                '${product.value.toStringAsFixed(2)}৳',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _slate700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

