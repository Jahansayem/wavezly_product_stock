import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/models/customer.dart';
import 'package:wavezly/models/cart_item.dart';
import 'package:wavezly/models/sale.dart';
import 'package:wavezly/models/sale_item.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/services/customer_service.dart';
import 'package:wavezly/services/sales_service.dart';
import 'package:wavezly/screens/sales_completed_screen.dart';
import 'package:wavezly/screens/main_navigation.dart';
import 'package:intl/intl.dart';

class LogNewSaleScreen extends StatefulWidget {
  final List<CartItem> initialCartItems;
  final List<Customer> availableCustomers;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final VoidCallback? onScanBarcode;
  final VoidCallback? onClearAll;
  final VoidCallback? onAddCustomItem;
  final VoidCallback? onPrint;
  final VoidCallback? onCharge;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<Customer>? onCustomerChanged;
  final ValueChanged<CartItem>? onQtyIncrement;
  final ValueChanged<CartItem>? onQtyDecrement;

  const LogNewSaleScreen({
    super.key,
    this.initialCartItems = const [],
    this.availableCustomers = const [],
    this.onBack,
    this.onMore,
    this.onScanBarcode,
    this.onClearAll,
    this.onAddCustomItem,
    this.onPrint,
    this.onCharge,
    this.onSearchChanged,
    this.onCustomerChanged,
    this.onQtyIncrement,
    this.onQtyDecrement,
  });

  @override
  State<LogNewSaleScreen> createState() => _LogNewSaleScreenState();
}

class _LogNewSaleScreenState extends State<LogNewSaleScreen> {
  late List<CartItem> _cartItems;
  late List<Customer> _customers;
  late Customer _selectedCustomer;
  final TextEditingController _searchController = TextEditingController();

  // Service instances
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();
  final SalesService _salesService = SalesService();

  // Product state
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  bool _isLoadingProducts = false;
  bool _isLoadingCustomers = false;
  bool _isProcessingSale = false;
  StreamSubscription<List<Product>>? _productSubscription;

  @override
  void initState() {
    super.initState();
    // Start with empty cart (no seed data)
    _cartItems = List.from(widget.initialCartItems);

    // Initialize customers with walk-in option
    _customers = [Customer(id: 'walk-in', name: 'Walk-in Customer')];
    _selectedCustomer = _customers.first;

    // Load real data from services
    _loadCustomers();
    _loadProducts();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);

    try {
      final customers = await _customerService.getCustomers();
      setState(() {
        _customers = [
          Customer(id: 'walk-in', name: 'Walk-in Customer'), // Keep walk-in option
          ...customers,
        ];
        _selectedCustomer = _customers.first; // Default to walk-in
        _isLoadingCustomers = false;
      });
    } catch (e) {
      print('Error loading customers: $e');
      // Fallback to walk-in only
      setState(() {
        _customers = [Customer(id: 'walk-in', name: 'Walk-in Customer')];
        _selectedCustomer = _customers.first;
        _isLoadingCustomers = false;
      });
    }
  }

  void _loadProducts() {
    setState(() => _isLoadingProducts = true);

    _productSubscription = _productService.getAllProducts().listen(
      (products) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products; // Show all initially
          _isLoadingProducts = false;
        });
      },
      onError: (error) {
        print('Error loading products: $error');
        setState(() => _isLoadingProducts = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load products: $error'),
              backgroundColor: ColorPalette.mandy,
            ),
          );
        }
      },
    );
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();

      if (_searchQuery.isEmpty) {
        // Show all products when search is cleared
        _filteredProducts = _allProducts;
      } else {
        // Filter products by name or barcode
        _filteredProducts = _allProducts.where((product) {
          final name = product.name?.toLowerCase() ?? '';
          final barcode = product.barcode?.toLowerCase() ?? '';
          return name.contains(_searchQuery) || barcode.contains(_searchQuery);
        }).toList();
      }
    });

    // Call parent callback if provided
    widget.onSearchChanged?.call(query);
  }

  void _addProductToCart(Product product) {
    setState(() {
      // Check if product already in cart
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (existingIndex >= 0) {
        // Increment quantity
        _cartItems[existingIndex].quantity++;
      } else {
        // Add new item
        _cartItems.add(CartItem(
          product: product,
          quantity: 1,
        ));
      }
    });

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          duration: const Duration(seconds: 1),
          backgroundColor: ColorPalette.tealAccent,
        ),
      );
    }
  }

  Future<String?> _showPaymentMethodSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorPalette.timberGreen,
              ),
            ),
            const SizedBox(height: 20),
            _buildPaymentOption(
              'cash',
              'Cash',
              Icons.payments,
              'Customer pays now',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'due',
              'Due',
              Icons.schedule,
              'Customer pays later',
              isDark,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon,
    String subtitle,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : ColorPalette.slate200,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorPalette.tealAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: ColorPalette.tealAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.timberGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: ColorPalette.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: ColorPalette.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeSale() async {
    // Validation: Check cart is not empty
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add items to cart before completing sale'),
          backgroundColor: ColorPalette.mandy,
        ),
      );
      return;
    }

    // Show payment method selection
    final paymentMethod = await _showPaymentMethodSheet();
    if (paymentMethod == null) return; // User cancelled

    setState(() => _isProcessingSale = true);

    try {
      // Create Sale object
      final sale = Sale(
        totalAmount: _subtotal,
        taxAmount: 0.0, // Add tax calculation if needed
        subtotal: _subtotal,
        customerName: _selectedCustomer.name,
        paymentMethod: paymentMethod,
      );

      // Process sale (saves to database)
      final saleId = await _salesService.processSale(sale, _cartItems);

      // Fetch the saved sale with generated data
      final savedSale = await _salesService.getSaleById(saleId);
      final saleItems = await _salesService.getSaleItems(saleId);

      setState(() => _isProcessingSale = false);

      // Navigate to success screen
      if (mounted) {
        final dateFormatter = DateFormat('MMM dd, h:mm a');
        final dateText = savedSale.createdAt != null
            ? dateFormatter.format(savedSale.createdAt!)
            : 'Just now';
        final currencyFormatter = NumberFormat.currency(symbol: '৳', decimalDigits: 2);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SalesCompletedScreen(
              onClose: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (route) => false,
                );
              },
              onGeneratePdf: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF generation coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              onNewSale: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LogNewSaleScreen()),
                  (route) => false,
                );
              },
              title: 'Sales Completed',
              dateText: dateText,
              totalAmount: currencyFormatter.format(savedSale.totalAmount ?? 0),
              paymentMethod: savedSale.paymentMethod?.toUpperCase() ?? 'CASH',
              customerName: savedSale.customerName ?? 'Walk-in Customer',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessingSale = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing sale: $e'),
            backgroundColor: ColorPalette.mandy,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _productSubscription?.cancel();
    super.dispose();
  }

  void _incrementQuantity(CartItem item) {
    setState(() {
      item.quantity++;
    });
    widget.onQtyIncrement?.call(item);
  }

  void _decrementQuantity(CartItem item) {
    if (item.quantity > 1) {
      setState(() {
        item.quantity--;
      });
      widget.onQtyDecrement?.call(item);
    }
  }

  void _clearAll() {
    setState(() {
      _cartItems.clear();
    });
    widget.onClearAll?.call();
  }

  double get _subtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  int get _totalItems =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF101a22) : Colors.white;
    final surfaceColor =
        isDark ? const Color(0xFF1E293B) : ColorPalette.slate50;
    final borderColor =
        isDark ? const Color(0xFF334155) : ColorPalette.slate100;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main Content
          Column(
            children: [
              // Header
              _buildHeader(context),

              // Top Controls Section
              _buildTopControls(context, surfaceColor, borderColor),

              // Main Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cart Header
                      _buildCartHeader(),

                      // Cart Items
                      _buildCartItems(context, borderColor),

                      // Add Custom Item Button
                      _buildAddCustomItemButton(context),

                      // Browse Products Section
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Browse Products',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.timberGreen,
                          ),
                        ),
                      ),

                      // Product Grid
                      _buildProductGrid(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fixed Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFooter(context, borderColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      color: const Color(0xFF00BFA5),
      child: Row(
        children: [
          // Left cluster: back button + title
          Expanded(
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onBack,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const Text(
                  'Log New Sale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Right: more button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onMore,
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls(
      BuildContext context, Color surfaceColor, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      color: surfaceColor,
      child: Column(
        children: [
          // Search & Barcode Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _handleSearch,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(
                        color: ColorPalette.slate400,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(
                          Icons.search,
                          color: ColorPalette.slate400,
                          size: 20,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onScanBarcode,
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.qr_code_2,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Customer Dropdown
          _buildCustomerDropdown(context, isDark, borderColor),
        ],
      ),
    );
  }

  Widget _buildCustomerDropdown(
      BuildContext context, bool isDark, Color borderColor) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.person,
              color: const Color(0xFF00BFA5),
              size: 18,
            ),
          ),
          Expanded(
            child: DropdownButton<Customer>(
              value: _selectedCustomer,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: _customers.map((customer) {
                return DropdownMenuItem<Customer>(
                  value: customer,
                  child: Text(
                    customer.name ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (customer) {
                if (customer != null) {
                  setState(() {
                    _selectedCustomer = customer;
                  });
                  widget.onCustomerChanged?.call(customer);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.expand_more,
              color: ColorPalette.slate400,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CART (${_cartItems.length} ITEMS)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: ColorPalette.slate400,
            ),
          ),
          GestureDetector(
            onTap: _clearAll,
            child: Text(
              'Clear All',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _cartItems.isEmpty ? Colors.grey : ColorPalette.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(BuildContext context, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_cartItems.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : ColorPalette.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : ColorPalette.slate100,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: ColorPalette.slate500.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cart is empty',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorPalette.slate500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Search or browse products below to add items',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: ColorPalette.slate500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(
        _cartItems.length,
        (index) {
          final item = _cartItems[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Product Image
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDark
                            ? const Color(0xFF334155)
                            : ColorPalette.slate100,
                        image: item.product.image != null
                            ? DecorationImage(
                                image: NetworkImage(item.product.image!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.product.name ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1a2e35),
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                          Text(
                            '${(item.product.cost ?? 0).toStringAsFixed(2)}৳ ea',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: ColorPalette.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Quantity Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : ColorPalette.slate100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF475569)
                              : ColorPalette.slate200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Minus Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _decrementQuantity(item),
                              customBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),

                          // Quantity Text
                          SizedBox(
                            width: 24,
                            child: Text(
                              item.quantity.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          // Plus Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _incrementQuantity(item),
                              customBorder: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BFA5),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Price
                    SizedBox(
                      width: 56,
                      child: Text(
                        '${item.subtotal.toStringAsFixed(2)}৳',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF2dd4bf)
                              : const Color(0xFF00897b),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index < _cartItems.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF475569)
                        : ColorPalette.slate50,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddCustomItemButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onAddCustomItem,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark
                    ? const Color(0xFF475569)
                    : ColorPalette.slate200,
                width: 2,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle,
                    size: 20,
                    color: ColorPalette.slate400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ADD CUSTOM ITEM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: ColorPalette.slate400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoadingProducts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(
            color: ColorPalette.tealAccent,
          ),
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: ColorPalette.slate500.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isEmpty
                    ? 'No products available'
                    : 'No products found for "$_searchQuery"',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: ColorPalette.slate500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _addProductToCart(product),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : ColorPalette.slate100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: ColorPalette.slate50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: product.image != null && product.image!.isNotEmpty
                    ? Image.network(
                        product.image!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.inventory_2,
                          size: 48,
                          color: ColorPalette.slate500,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2,
                        size: 48,
                        color: ColorPalette.slate500,
                      ),
              ),
            ),
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name ?? 'Unknown Product',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.timberGreen,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.cost?.toStringAsFixed(2) ?? '0.00'}৳',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.tealAccent,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ColorPalette.tealAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: ColorPalette.tealAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: -3,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Line: Tax, Units, Total
          Row(
            children: [
              // Tax Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : ColorPalette.slate100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'TAX INCL.',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: ColorPalette.slate500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_totalItems units total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ColorPalette.slate400,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Total:',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ColorPalette.slate500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_subtotal.toStringAsFixed(2)}৳',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1a2e35),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom Buttons
          Row(
            children: [
              // Print Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPrint,
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : ColorPalette.slate100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.print,
                      size: 20,
                      color: isDark
                          ? Colors.white70
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Sales Complete Button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isProcessingSale ? null : _completeSale,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: _isProcessingSale
                            ? ColorPalette.slate400
                            : const Color(0xFF00BFA5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: !_isProcessingSale
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFF00BFA5).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isProcessingSale)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          else
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 22,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            _isProcessingSale
                                ? 'Processing...'
                                : 'Sales Complete',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Nunito',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
