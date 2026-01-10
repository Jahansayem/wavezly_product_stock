import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/models/product.dart';

enum ProductBadge { none, lowStock, expired }

class ProductItem {
  final String title;
  final String category;
  final String sku;
  final String imageUrl;
  final int stock;
  final double value;
  final ProductBadge badge;

  ProductItem({
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
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildFilterChips(),
                _buildTableHeader(),
                Expanded(child: _buildProductList()),
              ],
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomNav(context),
              ),
            ),
          ],
        ),
      ),
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
            _FilterChip(label: 'All Items', isActive: true),
            const SizedBox(width: 8),
            _FilterChip(label: 'Low Stock', isActive: false),
            const SizedBox(width: 8),
            _FilterChip(label: 'Expired', isActive: false),
            const SizedBox(width: 8),
            _FilterChip(label: 'Pharmacy', isActive: false),
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
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.tealAccent),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: ColorPalette.danger),
                const SizedBox(height: 16),
                Text(
                  'Error loading products',
                  style: TextStyle(color: ColorPalette.slate700),
                ),
              ],
            ),
          );
        }

        // Empty state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
        final productItems = products.map((p) => ProductItem.fromProduct(p)).toList();

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: productItems.length,
          itemBuilder: (context, index) {
            return _ProductRow(
              product: productItems[index],
              onTap: () => widget.onProductTap(productItems[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _slate100)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.dashboard_outlined,
                label: 'Dash',
                isActive: false,
                index: 0,
                onTap: widget.onTabSelected,
              ),
              _BottomNavItem(
                icon: Icons.inventory_2,
                label: 'Stock',
                isActive: true,
                hasNotification: true,
                index: 1,
                onTap: widget.onTabSelected,
              ),
              _BottomNavItem(
                icon: Icons.qr_code_scanner_outlined,
                label: 'Scan',
                isActive: false,
                index: 2,
                onTap: widget.onTabSelected,
              ),
              _BottomNavItem(
                icon: Icons.group_outlined,
                label: 'CRM',
                isActive: false,
                index: 3,
                onTap: widget.onTabSelected,
              ),
              _BottomNavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                isActive: false,
                index: 4,
                onTap: widget.onTabSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _FilterChip({
    required this.label,
    required this.isActive,
  });

  static const Color _primary = ColorPalette.tealAccent;
  static const Color _slate50 = ColorPalette.slate50;
  static const Color _slate200 = ColorPalette.slate200;
  static const Color _slate500 = ColorPalette.slate500;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                '\$${product.value.toStringAsFixed(2)}',
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

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool hasNotification;
  final int index;
  final Function(int) onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.hasNotification = false,
    required this.index,
    required this.onTap,
  });

  static const Color _primary = ColorPalette.tealAccent;
  static const Color _slate400 = ColorPalette.slate400;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: SizedBox(
          height: double.infinity,
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isActive ? _primary : _slate400,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isActive ? _primary : _slate400,
                    ),
                  ),
                ],
              ),
              if (hasNotification)
                Positioned(
                  top: 8,
                  right: MediaQuery.of(context).size.width / 10 - 12,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
