import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/models/buying_cart_item.dart';
import 'package:wavezly/models/purchase.dart';
import 'package:wavezly/models/customer.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/services/purchase_service.dart';
import 'package:wavezly/services/customer_service.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/screens/barcode_scanner_screen.dart';
import 'package:wavezly/screens/payment_confirm_screen.dart';

class SelectProductBuyingScreen extends StatefulWidget {
  const SelectProductBuyingScreen({Key? key}) : super(key: key);

  @override
  _SelectProductBuyingScreenState createState() =>
      _SelectProductBuyingScreenState();
}

class _SelectProductBuyingScreenState extends State<SelectProductBuyingScreen> {
  // Services
  final ProductService _productService = ProductService();

  // State
  final Set<String> _selectedProductIds = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Product>? _filteredProducts;
  String _filterType = 'all'; // all, low_stock, out_of_stock, in_stock

  // Colors (matching Home Dashboard theme)
  static const Color primary = ColorPalette.tealAccent;
  static const Color background = ColorPalette.gray100;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderBar(),
            _buildSearchBar(),
            Expanded(
              child: _buildProductList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomCartSheet(),
    );
  }

  // =======================================================================
  // HEADER BAR (Fixed)
  // =======================================================================
  Widget _buildHeaderBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            ColorPalette.offerYellowStart,
            ColorPalette.offerYellowEnd,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    size: 20, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Text(
                'পণ্য নির্বাচন করুন',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.help_outline, size: 22, color: Colors.black87),
                onPressed: () {
                  showTextToast('Help feature coming soon');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 22, color: Colors.black87),
                onPressed: () {
                  showTextToast('More options coming soon');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // SEARCH BAR (Fixed)
  // =======================================================================
  Widget _buildSearchBar() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ColorPalette.slate100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: ColorPalette.slate100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 14, color: ColorPalette.slate800),
                decoration: InputDecoration(
                  hintText: 'পণ্যের নাম দিয়ে খুঁজুন...',
                  hintStyle: TextStyle(fontSize: 14, color: ColorPalette.slate500),
                  prefixIcon: Icon(Icons.search, size: 20, color: ColorPalette.slate400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorPalette.slate100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list, size: 20, color: ColorPalette.slate600),
              onPressed: _showFilterDialog,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 8),
          // QR Scanner button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.qr_code_scanner, size: 20, color: primary),
              onPressed: _handleQrScan,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // PRODUCT LIST (Scrollable)
  // =======================================================================
  Widget _buildProductList() {
    return StreamBuilder<List<Product>>(
      stream: _productService.getAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: ColorPalette.slate400),
                const SizedBox(height: 16),
                Text(
                  'Error loading products',
                  style: TextStyle(fontSize: 14, color: ColorPalette.slate600),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry', style: TextStyle(color: primary)),
                ),
              ],
            ),
          );
        }

        List<Product> products = _filteredProducts ?? snapshot.data ?? [];

        // Apply filter
        products = _applyFilter(products);

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: ColorPalette.slate400),
                const SizedBox(height: 16),
                Text(
                  'কোনো পণ্য পাওয়া যায়নি',
                  style: TextStyle(fontSize: 16, color: ColorPalette.slate600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  // =======================================================================
  // PRODUCT CARD
  // =======================================================================
  Widget _buildProductCard(Product product) {
    final isSelected = _selectedProductIds.contains(product.id);
    final stockColor = _getStockColor(product.quantity ?? 0);
    final salePrice = (product.cost ?? 0) * 1.3; // 30% markup

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.slate50),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
            color: Colors.black.withOpacity(0.05),
          ),
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: -1,
            color: Colors.black.withOpacity(0.03),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleProductSelection(product),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon Tile
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorPalette.teal50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColorPalette.teal100.withOpacity(0.5)),
                  ),
                  child: Icon(
                    _getProductIcon(product.group),
                    color: primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name ?? 'Unknown Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.slate800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildStatColumn(
                            'স্টক',
                            '${product.quantity ?? 0} টি',
                            stockColor,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: ColorPalette.slate100,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          _buildStatColumn(
                            'বিক্রয়',
                            '৳${_formatPrice(salePrice)}',
                            ColorPalette.slate700,
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: ColorPalette.slate100,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          _buildStatColumn(
                            'ক্রয়',
                            '৳${_formatPrice(product.cost ?? 0)}',
                            ColorPalette.slate700,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Selection Icon
                Icon(
                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  color: isSelected ? primary : ColorPalette.slate300,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: ColorPalette.slate500,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // BOTTOM CART SHEET (Fixed)
  // =======================================================================
  Widget _buildBottomCartSheet() {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -8),
            blurRadius: 30,
            color: Colors.black.withOpacity(0.12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'নির্বাচিত পণ্য',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.shopping_cart,
                      size: 24, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedProductIds.length} টি',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Right section - Buy button
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            child: InkWell(
              onTap: _selectedProductIds.isNotEmpty ? _handleBuyPressed : null,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'পণ্য কিনুন',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18, color: primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // HELPER FUNCTIONS
  // =======================================================================

  IconData _getProductIcon(String? group) {
    switch (group?.toLowerCase()) {
      case 'furniture':
        return Icons.table_restaurant;
      case 'electronics':
        return Icons.lightbulb_outline;
      case 'storage':
        return Icons.inventory_2;
      case 'office':
        return Icons.desk;
      default:
        return Icons.inventory_2;
    }
  }

  Color _getStockColor(int quantity) {
    if (quantity < 0) return ColorPalette.danger;
    if (quantity == 0) return ColorPalette.slate400;
    return ColorPalette.teal600;
  }

  String _formatPrice(double price) {
    return NumberFormat('#,##0').format(price);
  }

  List<Product> _applyFilter(List<Product> products) {
    switch (_filterType) {
      case 'low_stock':
        return products.where((p) => (p.quantity ?? 0) < 10).toList();
      case 'out_of_stock':
        return products.where((p) => (p.quantity ?? 0) == 0).toList();
      case 'in_stock':
        return products.where((p) => (p.quantity ?? 0) > 0).toList();
      default:
        return products;
    }
  }

  // =======================================================================
  // EVENT HANDLERS
  // =======================================================================

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.isNotEmpty) {
        final results = await _productService.searchProducts(query);
        setState(() => _filteredProducts = results);
      } else {
        setState(() => _filteredProducts = null);
      }
    });
  }

  void _toggleProductSelection(Product product) {
    setState(() {
      if (_selectedProductIds.contains(product.id)) {
        _selectedProductIds.remove(product.id);
      } else {
        _selectedProductIds.add(product.id!);
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ফিল্টার নির্বাচন করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('সব পণ্য', 'all'),
            _buildFilterOption('স্টক কম (১০ টির কম)', 'low_stock'),
            _buildFilterOption('স্টক শেষ (০ টি)', 'out_of_stock'),
            _buildFilterOption('স্টক আছে', 'in_stock'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    final isSelected = _filterType == value;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: primary,
      ),
      title: Text(label),
      onTap: () {
        setState(() => _filterType = value);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _handleQrScan() async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (product != null && product.id != null) {
      setState(() => _selectedProductIds.add(product.id!));
      showTextToast('${product.name} যোগ করা হয়েছে!');
    }
  }

  Future<void> _handleBuyPressed() async {
    if (_selectedProductIds.isEmpty) {
      showTextToast('অনুগ্রহ করে পণ্য নির্বাচন করুন');
      return;
    }

    final cartItems = await _prepareCartItems();
    if (cartItems.isEmpty) {
      showTextToast('পণ্যের তথ্য লোড করা যায়নি');
      return;
    }

    final totalAmount = cartItems.fold<double>(0.0, (sum, item) => sum + item.totalCost);
    final suppliers = await _fetchSuppliers();

    if (!mounted) return;

    final result = await Navigator.push<PaymentConfirmResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentConfirmScreen(
          totalPayable: totalAmount,
          cartItems: cartItems,
          suppliers: suppliers,
        ),
      ),
    );

    if (result != null && mounted) {
      await _processPurchaseTransaction(cartItems, result, totalAmount);
    }
  }

  Future<List<BuyingCartItem>> _prepareCartItems() async {
    final cartItems = <BuyingCartItem>[];

    try {
      for (final productId in _selectedProductIds) {
        final product = await _productService.getProductById(productId);
        if (product != null && product.id != null) {
          cartItems.add(BuyingCartItem(
            productId: product.id!,
            productName: product.name ?? 'Unknown',
            costPrice: product.cost ?? 0.0,
            quantity: 1,
          ));
        }
      }
    } catch (e) {
      showTextToast('ত্রুটি: পণ্যের তথ্য লোড করা যায়নি');
    }

    return cartItems;
  }

  Future<List<SupplierOption>> _fetchSuppliers() async {
    try {
      final customers = await CustomerService().getCustomers();
      final suppliers = customers
          .where((c) => c.customerType == 'supplier')
          .map((c) => SupplierOption(
                id: c.id ?? '',
                name: c.name ?? '',
                phone: c.phone,
              ))
          .toList();

      suppliers.insert(0, const SupplierOption(id: '', name: 'সরবরাহকারী নেই'));
      return suppliers;
    } catch (e) {
      return [const SupplierOption(id: '', name: 'সরবরাহকারী নেই')];
    }
  }

  Future<void> _processPurchaseTransaction(
    List<BuyingCartItem> cartItems,
    PaymentConfirmResult result,
    double totalAmount,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primary),
          ),
        ),
      );

      final paidAmount = result.method == PaymentMethod.due ? 0.0 : result.cashGiven;
      final dueAmount = totalAmount - paidAmount;
      final changeAmount = result.cashGiven > totalAmount ? result.cashGiven - totalAmount : 0.0;

      String? supplierName;
      if (result.supplierId != null && result.supplierId!.isNotEmpty) {
        try {
          final customers = await CustomerService().getCustomers();
          final supplier = customers.firstWhere(
            (c) => c.id == result.supplierId,
            orElse: () => Customer(name: null),
          );
          supplierName = supplier.name;
        } catch (e) {
          supplierName = null;
        }
      }

      final purchase = Purchase(
        supplierId: result.supplierId?.isEmpty == true ? null : result.supplierId,
        supplierName: supplierName,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        dueAmount: dueAmount,
        cashGiven: result.cashGiven,
        changeAmount: changeAmount,
        paymentMethod: result.method.databaseValue,
        purchaseDate: result.date,
        receiptImagePath: result.receiptImagePath,
        comment: result.comment,
        smsEnabled: result.smsEnabled,
      );

      await PurchaseService().processPurchase(
        purchase: purchase,
        cartItems: cartItems,
      );

      if (mounted) Navigator.pop(context);

      showTextToast('পণ্য ক্রয় সফল হয়েছে!');

      setState(() {
        _selectedProductIds.clear();
        _filteredProducts = null;
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      showTextToast('ত্রুটি: ${e.toString()}');
    }
  }
}
