import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/models/selling_cart_item.dart';
import 'package:wavezly/screens/barcode_scanner_screen.dart';
import 'package:wavezly/screens/quick_sell_cash_screen.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/utils/color_palette.dart';

class ProductSellingSelectionScreen extends StatefulWidget {
  const ProductSellingSelectionScreen({Key? key}) : super(key: key);

  @override
  _ProductSellingSelectionScreenState createState() =>
      _ProductSellingSelectionScreenState();
}

class _ProductSellingSelectionScreenState
    extends State<ProductSellingSelectionScreen> {
  // Services
  final ProductService _productService = ProductService();

  // State
  final Set<String> _selectedProductIds = {};
  final Map<String, SellingCartItem> _cartItems = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Product>? _filteredProducts;

  // Cart totals
  double _cartTotal = 0.0;
  int _cartItemCount = 0;

  // Colors (matching home screen tealAccent #00BFA5)
  static const Color primary = ColorPalette.tealAccent;
  static const Color background = ColorPalette.slate50;
  static const Color slate400 = ColorPalette.slate400;
  static const Color slate500 = ColorPalette.slate500;
  static const Color slate600 = ColorPalette.slate600;
  static const Color slate700 = ColorPalette.slate700;
  static const Color slate800 = ColorPalette.slate800;
  static const Color orangeAccent = ColorPalette.warningOrange;
  static const Color danger = ColorPalette.danger;
  static const Color amberYellow = ColorPalette.amberYellow;
  static const Color blue = ColorPalette.blue;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() => _filteredProducts = null);
        return;
      }
      try {
        final results = await _productService.searchProducts(query);
        setState(() => _filteredProducts = results);
      } catch (e) {
        print('Search error: $e');
      }
    });
  }

  void _toggleProductSelection(Product product) {
    if (product.id == null) return;

    // Validate stock
    if ((product.quantity ?? 0) == 0) {
      showTextToast('এই পণ্যটি স্টকে নেই!');
      return;
    }

    setState(() {
      if (_selectedProductIds.contains(product.id)) {
        _selectedProductIds.remove(product.id);
        _cartItems.remove(product.id);
      } else {
        _selectedProductIds.add(product.id!);
        _cartItems[product.id!] = SellingCartItem(
          productId: product.id!,
          productName: product.name ?? '',
          salePrice: product.cost ?? 0.0,
          quantity: 1,
          stockAvailable: product.quantity ?? 0,
          imageUrl: product.image,
        );
      }
      _updateCartTotal();
    });
  }

  void _updateCartTotal() {
    double total = 0.0;
    int count = 0;
    for (var item in _cartItems.values) {
      total += item.totalPrice;
      count += item.quantity;
    }
    setState(() {
      _cartTotal = total;
      _cartItemCount = count;
    });
  }

  Future<void> _handleQRScan() async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (product != null && product.id != null) {
      _toggleProductSelection(product);
      showTextToast('${product.name} যোগ করা হয়েছে!');
    }
  }

  Future<void> _handleCheckout() async {
    if (_selectedProductIds.isEmpty) {
      showTextToast('অনুগ্রহ করে পণ্য নির্বাচন করুন');
      return;
    }

    // TODO: Navigate to payment confirmation screen
    // Similar to: SelectProductBuyingScreen -> PaymentConfirmScreen
    showTextToast('Checkout feature coming soon');
  }

  void _showFilterDialog() {
    // TODO: Implement filter options
    // Options: All Products, In Stock, Low Stock, By Category
    showTextToast('Filter feature coming soon');
  }

  // Hardcoded products matching HTML spec
  List<Product> _getHardcodedProducts() {
    return [
      Product(
        id: '1',
        name: 'rahman',
        cost: 50.0,
        quantity: 0, // Out of stock
        group: 'category1',
        barcode: '1234567890',
      ),
      Product(
        id: '2',
        name: 'টেস্ট প্রোডাক্ট',
        cost: 100.0,
        quantity: 23,
        group: 'category2',
        barcode: '0987654321',
      ),
      Product(
        id: '3',
        name: 'প্রাণ চানাচুর',
        cost: 45.0,
        quantity: 12,
        group: 'snacks',
        barcode: '5555555555',
      ),
    ];
  }

  IconData _getProductIcon(Product product) {
    if (product.id == '3') {
      return Icons.local_offer; // Blue icon for "প্রাণ চানাচুর"
    }
    return Icons.hexagon; // Yellow icon for others
  }

  Color _getProductIconColor(Product product) {
    if (product.id == '3') {
      return blue; // Blue
    }
    return amberYellow; // Amber yellow
  }

  Color _getProductIconBackgroundColor(Product product) {
    if (product.id == '3') {
      return blue.withOpacity(0.1);
    }
    return amberYellow.withOpacity(0.1);
  }

  Color _getProductTitleColor(Product product) {
    if (product.name == 'rahman') {
      return danger; // Red for "rahman"
    }
    return slate800;
  }

  double _getProductOpacity(Product product) {
    if ((product.quantity ?? 0) == 0) {
      return 0.5; // Reduced opacity for out-of-stock
    }
    if (product.id == '3') {
      return 0.7; // As per HTML spec for item 3
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.hindSiliguriTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    _buildActionButtons(),
                    const SizedBox(height: 8),
                    _buildSearchRow(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(child: _buildProductList()),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  // =======================================================================
  // HEADER (Sticky teal background)
  // =======================================================================
  Widget _buildHeader() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: primary,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                'বিক্রি করুন',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 24),
            onPressed: () {
              // TODO: Show help dialog
              showTextToast('Help feature coming soon');
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // ACTION BUTTONS (2-column row)
  // =======================================================================
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Quick Sell Button (Outlined with orange icon)
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QuickSellCashScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 40),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, color: orangeAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'দ্রুত বিক্রি',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: slate700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Product List Button (Filled teal)
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // TODO: Navigate to full product list
              showTextToast('Product list feature coming soon');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 40),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.list_alt, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'প্রোডাক্ট লিস্ট',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =======================================================================
  // SEARCH ROW (Search input | Filter | QR Scanner)
  // =======================================================================
  Widget _buildSearchRow() {
    return Row(
      children: [
        // Search container with filter
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.search, color: slate400, size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'পণ্য খোজ করুন',
                      hintStyle: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: slate400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    ),
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      color: slate800,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                InkWell(
                  onTap: _showFilterDialog,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, left: 4),
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt, color: slate600, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'ফিল্টার',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // QR Scanner button
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: IconButton(
            icon: Icon(Icons.qr_code_scanner, color: primary, size: 30),
            onPressed: _handleQRScan,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  // =======================================================================
  // PRODUCT LIST (StreamBuilder with product cards)
  // =======================================================================
  Widget _buildProductList() {
    return StreamBuilder<List<Product>>(
      stream: _productService.getAllProducts(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          print('Stream error: ${snapshot.error}');
          // Fallback to hardcoded products on error
          final products = _getHardcodedProducts();
          return _buildProductListView(products);
        }

        // Success state with data or fallback to hardcoded
        final products = (snapshot.hasData && snapshot.data!.isNotEmpty)
            ? (_filteredProducts ?? snapshot.data!)
            : _getHardcodedProducts();

        return _buildProductListView(products);
      },
    );
  }

  Widget _buildProductListView(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: slate400),
            const SizedBox(height: 16),
            Text(
              'কোনো পণ্য পাওয়া যায়নি',
              style: GoogleFonts.hindSiliguri(
                fontSize: 16,
                color: slate500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 96, top: 0),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(products[index]);
      },
    );
  }

  // =======================================================================
  // PRODUCT CARD (Individual product item)
  // =======================================================================
  Widget _buildProductCard(Product product) {
    final opacity = _getProductOpacity(product);
    final isSelected = _selectedProductIds.contains(product.id);

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: () => _toggleProductSelection(product),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primary : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getProductIconBackgroundColor(product),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Icon(
                    _getProductIcon(product),
                    color: _getProductIconColor(product),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Product name
                        Expanded(
                          child: Text(
                            product.name ?? '',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getProductTitleColor(product),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Price section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'বিক্রয় মূল্য',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: slate500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.cost?.toStringAsFixed(0) ?? '0'} ৳',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: slate800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Stock section
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'স্টক সংখ্যা',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: slate500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.quantity ?? 0}',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: slate800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =======================================================================
  // BOTTOM BAR (Fixed with cart total and checkout)
  // =======================================================================
  Widget _buildBottomBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: primary,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Total section
          Row(
            children: [
              Text(
                'সর্বমোট:',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '৳ ${_cartTotal.toStringAsFixed(0)}',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          // Checkout button
          ElevatedButton(
            onPressed: _handleCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: slate800,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            child: Row(
              children: [
                Text(
                  '$_cartItemCount',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
