import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/models/buying_cart_item.dart';
import 'package:wavezly/models/cart_item.dart';
import 'package:wavezly/models/customer.dart';
import 'package:wavezly/models/fast_sale_scan_result.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/models/sale.dart';
import 'package:wavezly/models/selling_cart_item.dart';
import 'package:wavezly/screens/barcode_scanner_screen.dart';
import 'package:wavezly/screens/purchase_cart_screen.dart';
import 'package:wavezly/services/auth_service.dart';
import 'package:wavezly/services/customer_service.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/services/sales_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/utils/date_formatter.dart';
import 'package:wavezly/utils/number_formatter.dart';

/// Unified Sales Screen with tab-based view switching
/// Contains Quick Sell and Product List views with state preservation
class SalesScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onSaleCompleted;
  final int salesSessionToken;

  const SalesScreen({
    Key? key,
    this.onBackPressed,
    this.onSaleCompleted,
    required this.salesSessionToken,
  }) : super(key: key);

  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // Tab state (0 = Quick Sell, 1 = Product List)
  int _selectedTab = 0;

  // Colors
  static const Color primary = ColorPalette.tealAccent;
  static const Color background = ColorPalette.slate50;

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      // Context: Pushed as route (e.g., from HomeDashboardScreen)
      Navigator.pop(context);
    } else if (widget.onBackPressed != null) {
      // Context: In tab - switch to Home tab
      widget.onBackPressed!();
    } else {
      // Fallback: maintain compatibility
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.anekBanglaTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: background,
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                _buildHeader(),
                _buildTabButtons(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _QuickSellView(
                        onTabChange: (index) =>
                            setState(() => _selectedTab = index),
                        onSaleCompleted: widget.onSaleCompleted,
                        salesSessionToken: widget.salesSessionToken,
                      ),
                      _ProductListView(
                        onTabChange: (index) =>
                            setState(() => _selectedTab = index),
                        onSaleCompleted: widget.onSaleCompleted,
                        salesSessionToken: widget.salesSessionToken,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =======================================================================
  // HEADER (Shared between both tabs)
  // =======================================================================
  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      height: 64 + topPadding,
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
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: ColorPalette.gray900, size: 24),
                onPressed: _handleBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text(
                'বিক্রি করুন',
                style: GoogleFonts.anekBangla(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.gray900,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.help_outline,
                color: ColorPalette.gray900, size: 24),
            onPressed: () {
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
  // TAB BUTTONS (Shared between both tabs)
  // =======================================================================
  Widget _buildTabButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Quick Sell Tab
          Expanded(
            child: Material(
              color: _selectedTab == 0 ? primary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              elevation: 0,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTab = 0;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: _selectedTab == 0
                        ? null
                        : Border.all(color: ColorPalette.gray300),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: _selectedTab == 0
                            ? Colors.white
                            : ColorPalette.gray700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'দ্রুত বিক্রি',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedTab == 0
                              ? Colors.white
                              : ColorPalette.gray700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product List Tab
          Expanded(
            child: Material(
              color: _selectedTab == 1 ? primary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              elevation: 0,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTab = 1;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: _selectedTab == 1
                        ? null
                        : Border.all(color: ColorPalette.gray300),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_alt,
                        color: _selectedTab == 1
                            ? Colors.white
                            : ColorPalette.gray700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'প্রোডাক্ট লিস্ট',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedTab == 1
                              ? Colors.white
                              : ColorPalette.gray700,
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
    );
  }
}

// ===========================================================================
// QUICK SELL VIEW (Tab 0)
// ===========================================================================
class _QuickSellView extends StatefulWidget {
  final Function(int) onTabChange;
  final VoidCallback? onSaleCompleted;
  final int salesSessionToken;

  const _QuickSellView({
    Key? key,
    required this.onTabChange,
    this.onSaleCompleted,
    required this.salesSessionToken,
  }) : super(key: key);

  @override
  _QuickSellViewState createState() => _QuickSellViewState();
}

class _QuickSellViewState extends State<_QuickSellView> {
  // Services
  final SalesService _salesService = SalesService();
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();

  // Cash calculator state
  String _cashAmount = ''; // Start empty instead of hardcoded "50"

  // Form controllers
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _profitController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  // Toggle state
  bool _receiptSmsEnabled = true; // Default ON

  // Dynamic state
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  String? _customerName;
  String? _customerId;
  final Map<String, FastSaleScanItem> _scannedItems =
      {}; // Scanned items from multi-scan session

  // Colors
  static const Color primary = ColorPalette.tealAccent;

  @override
  void dispose() {
    _mobileController.dispose();
    _profitController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_QuickSellView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset Quick Sell state when session token changes (user re-enters Sales tab)
    if (oldWidget.salesSessionToken != widget.salesSessionToken) {
      setState(() {
        _cashAmount = '';
        _mobileController.clear();
        _profitController.clear();
        _detailsController.clear();
        _receiptSmsEnabled = true;
        _selectedDate = DateTime.now();
        _customerName = null;
        _customerId = null;
        _scannedItems.clear();
      });
    }
  }

  void _onKeypadTap(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _cashAmount = '';
          break;
        case '⌫': // Backspace
          if (_cashAmount.isNotEmpty) {
            _cashAmount = _cashAmount.substring(0, _cashAmount.length - 1);
          }
          break;
        case '=':
          _cashAmount = _evaluateExpression(_cashAmount);
          break;
        case '+':
        case '-':
        case '×':
        case '÷':
        case '(':
        case ')':
        case '.':
          _cashAmount += key;
          break;
        default: // Numbers 0-9
          _cashAmount += key;
      }
    });
  }

  String _evaluateExpression(String expression) {
    if (expression.isEmpty) return '';

    try {
      // Replace display operators with math operators
      String englishExpression =
          expression.replaceAll('×', '*').replaceAll('÷', '/');

      // Parse and evaluate
      Parser parser = Parser();
      Expression exp = parser.parse(englishExpression);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);

      // Return result as English number
      return result.toStringAsFixed(2);
    } catch (e) {
      // Invalid expression, return original
      return expression;
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    try {
      setState(() => _isSubmitting = true);

      // Get current user ID
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        showTextToast('ব্যবহারকারী লগইন করা নেই');
        setState(() => _isSubmitting = false);
        return;
      }

      // Parse and validate cash amount
      final double amount = double.tryParse(_cashAmount) ?? 0.0;

      if (amount <= 0) {
        showTextToast('অনুগ্রহ করে ক্যাশ পরিমাণ লিখুন');
        setState(() => _isSubmitting = false);
        return;
      }

      // Validate date - cannot be in the future
      if (_selectedDate.isAfter(DateTime.now())) {
        showTextToast('ভবিষ্যতের তারিখ নির্বাচন করা যাবে না');
        setState(() => _isSubmitting = false);
        return;
      }

      // Validate mobile number if provided
      final mobile = _mobileController.text.trim();
      if (mobile.isNotEmpty && mobile.length != 11) {
        showTextToast('সঠিক মোবাইল নম্বর লিখুন (১১ ডিজিট)');
        setState(() => _isSubmitting = false);
        return;
      }

      // Parse profit margin (optional)
      final double profit =
          double.tryParse(_profitController.text.trim()) ?? 0.0;

      // Get product details (optional)
      String? productDetailsText;
      final List<String> detailParts = [];

      // Include selected fast-sale items if any
      if (_scannedItems.isNotEmpty) {
        detailParts.add('যোগ করা পণ্য:');
        for (final item in _scannedItems.values) {
          final productName = item.product.name ?? 'পণ্য';
          final productId = item.product.id ?? '';
          final qty = NumberFormatter.formatIntToBengali(item.quantity);
          final price =
              NumberFormatter.formatCurrency(item.product.salePrice ?? 0.0);
          final subtotal = NumberFormatter.formatCurrency(item.subtotal);
          detailParts.add(
              '  - $productName (ID: $productId) x$qty @ $price = $subtotal');
        }
      }

      // Include manual details
      final manualDetails = _detailsController.text.trim();
      if (manualDetails.isNotEmpty) {
        detailParts.add(manualDetails);
      }

      productDetailsText =
          detailParts.isNotEmpty ? detailParts.join('\n') : null;

      // Process quick cash sale using new service method
      await _salesService.processQuickCashSale(
        userId: userId,
        cashReceived: amount,
        customerMobile: mobile.isNotEmpty ? mobile : null,
        profitMargin: profit,
        productDetails: productDetailsText,
        receiptSmsEnabled: _receiptSmsEnabled,
        saleDate: _selectedDate,
        photoUrl: null,
      );

      // Success feedback
      showTextToast('বিক্রয় সফল হয়েছে!');

      // Trigger dashboard refresh callback
      widget.onSaleCompleted?.call();

      if (mounted) {
        // Do not pop here. In tab context this can pop the root route and
        // show a blank screen after successful quick sale.
        setState(() {
          _cashAmount = '';
          _mobileController.clear();
          _profitController.clear();
          _detailsController.clear();
          _receiptSmsEnabled = true;
          _selectedDate = DateTime.now();
          _customerName = null;
          _customerId = null;
          _scannedItems.clear();
        });
      }
    } catch (e) {
      String errorMessage = 'ত্রুটি: ';

      if (e.toString().contains('authentication')) {
        errorMessage += 'লগইন সমস্যা, পুনরায় লগইন করুন';
      } else if (e.toString().contains('network')) {
        errorMessage += 'ইন্টারনেট সংযোগ চেক করুন';
      } else {
        errorMessage += e.toString();
      }

      showTextToast(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleCustomerLookup() async {
    final phone = _mobileController.text.trim();
    if (phone.isEmpty || phone.length < 11) return;

    try {
      final customers = await _customerService.searchCustomers(phone);
      if (customers.isNotEmpty) {
        setState(() {
          _customerName = customers.first.name;
          _customerId = customers.first.id;
        });
        showTextToast('কাস্টমার পাওয়া গেছে: ${customers.first.name}');
      } else {
        setState(() {
          _customerName = null;
          _customerId = null;
        });
      }
    } catch (e) {
      print('Customer lookup error: $e');
    }
  }

  Future<String?> _showCreateCustomerDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('কাস্টমার নাম লিখুন', style: GoogleFonts.notoSansBengali()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'নাম'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বাতিল', style: GoogleFonts.notoSansBengali()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('যোগ করুন', style: GoogleFonts.notoSansBengali()),
          ),
        ],
      ),
    );
  }

  void _mergeFastSaleItems(Map<String, FastSaleScanItem> items) {
    for (final entry in items.entries) {
      final productId = entry.key;
      final item = entry.value;

      if (_scannedItems.containsKey(productId)) {
        _scannedItems[productId]!.quantity += item.quantity;
      } else {
        _scannedItems[productId] = FastSaleScanItem(
          product: item.product,
          quantity: item.quantity,
        );
      }
    }
  }

  Future<void> _handleProductPicker() async {
    final result = await showDialog<FastSaleScanResult>(
      context: context,
      builder: (context) =>
          _ProductPickerDialog(productService: _productService),
    );

    if (result != null && result.hasItems) {
      setState(() {
        _mergeFastSaleItems(result.items);
      });

      showTextToast(
          '${NumberFormatter.formatIntToBengali(result.totalItems)} টি পণ্য যোগ করা হয়েছে');
    }
  }

  Future<void> _handleProductBarcodeScanner() async {
    final result = await Navigator.push<FastSaleScanResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(
          mode: BarcodeScannerMode.fastSaleSession,
        ),
      ),
    );

    if (result != null && result.hasItems) {
      setState(() {
        _mergeFastSaleItems(result.items);
      });

      final itemCount = result.totalItems;
      showTextToast(
          '${NumberFormatter.formatIntToBengali(itemCount)} টি পণ্য স্ক্যান সম্পন্ন');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                _buildActionRow(),
                const SizedBox(height: 8),
                _buildProductSelectionRow(),
                if (_scannedItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildScannedItemsList(),
                ],
                _buildCashDisplay(),
                _buildCalculatorKeypad(),
                _buildMobileInput(),
                _buildProfitInput(),
                _buildDetailsInput(),
                _buildInfoBanner(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(Duration(days: 365)),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(primary: primary),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ColorPalette.gray300),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today,
                          color: ColorPalette.gray600, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.toBengaliDate(_selectedDate),
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ColorPalette.gray900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                showTextToast('Photo picker coming soon');
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ColorPalette.gray300),
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
                    const Icon(Icons.photo_camera,
                        color: ColorPalette.gray600, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'ছবি',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ColorPalette.gray900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                showTextToast('Add feature coming soon');
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorPalette.gray300),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.add, color: ColorPalette.gray600, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelectionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        children: [
          // Product selector button (left/middle)
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _handleProductPicker,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _scannedItems.isNotEmpty
                          ? primary
                          : ColorPalette.gray300,
                      width: _scannedItems.isNotEmpty ? 2 : 1,
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
                      Icon(
                        _scannedItems.isEmpty
                            ? Icons.add_circle_outline
                            : Icons.playlist_add,
                        color: _scannedItems.isEmpty
                            ? ColorPalette.gray600
                            : primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _scannedItems.isEmpty
                              ? 'পণ্য যোগ করুন'
                              : 'আরও পণ্য যোগ করুন',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 14,
                            fontWeight: _scannedItems.isEmpty
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: _scannedItems.isEmpty
                                ? ColorPalette.gray700
                                : ColorPalette.gray900,
                          ),
                        ),
                      ),
                      if (_scannedItems.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${NumberFormatter.formatIntToBengali(_scannedItems.length)} পণ্য',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Barcode scanner icon (right)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _handleProductBarcodeScanner,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ColorPalette.gray300),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedItemsList() {
    final totalItems = _scannedItems.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final totalAmount = _scannedItems.values.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary, width: 2),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'যোগ করা পণ্য',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.gray900,
                ),
              ),
              Text(
                '${NumberFormatter.formatIntToBengali(totalItems)} টি পণ্য • ${NumberFormatter.formatCurrency(totalAmount)}',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 12,
                  color: ColorPalette.gray600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: ColorPalette.gray200),
          const SizedBox(height: 8),

          // Items list
          ...List.generate(_scannedItems.length, (index) {
            final item = _scannedItems.values.elementAt(index);
            final productId = _scannedItems.keys.elementAt(index);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name ?? 'পণ্য',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ColorPalette.gray900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${NumberFormatter.formatCurrency(item.product.salePrice ?? 0.0)} × ${NumberFormatter.formatIntToBengali(item.quantity)}',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 11,
                            color: ColorPalette.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    NumberFormatter.formatCurrency(item.subtotal),
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _scannedItems.remove(productId);
                      });
                    },
                    child: const Icon(
                      Icons.remove_circle_outline,
                      size: 18,
                      color: ColorPalette.mandy,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCashDisplay() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ক্যাশ পেয়েছেন',
            style: GoogleFonts.notoSansBengali(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorPalette.gray600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorPalette.gray300),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _cashAmount.isEmpty ? '0' : _cashAmount,
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.gray800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorKeypad() {
    final keys = [
      ['C', '(', ')', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['.', '0', '⌫', '='],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.8,
        ),
        itemCount: 20,
        itemBuilder: (context, index) {
          final row = index ~/ 4;
          final col = index % 4;
          final key = keys[row][col];
          return _buildKeyButton(key);
        },
      ),
    );
  }

  Widget _buildKeyButton(String key) {
    Color backgroundColor;
    Color textColor;
    bool isOperator = ['C', '(', ')', '÷', '×', '-', '+', '⌫'].contains(key);
    bool isEquals = key == '=';
    bool isNumber = RegExp(r'^[0-9.]$').hasMatch(key);

    if (isEquals) {
      backgroundColor = ColorPalette.teal100;
      textColor = ColorPalette.teal700;
    } else if (isOperator) {
      backgroundColor = ColorPalette.gray200;
      textColor = ColorPalette.gray700;
    } else {
      backgroundColor = ColorPalette.gray100;
      textColor = ColorPalette.gray800;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _onKeypadTap(key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: isNumber
                ? [
                    BoxShadow(
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: key == '⌫'
                ? Icon(Icons.backspace_outlined, size: 20, color: textColor)
                : Text(
                    key,
                    style: GoogleFonts.manrope(
                      fontSize: isEquals ? 20 : 18,
                      fontWeight: isOperator || isEquals
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'কাস্টমার মোবাইল',
            style: GoogleFonts.notoSansBengali(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorPalette.gray600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorPalette.gray300),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: ColorPalette.gray50,
                    border: Border(
                      right: BorderSide(color: ColorPalette.gray200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF006A4E),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF42A41),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+88',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ColorPalette.gray700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.expand_more,
                          size: 16, color: ColorPalette.gray400),
                    ],
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'মোবাইল নম্বর লিখুন',
                      hintStyle: GoogleFonts.notoSansBengali(
                        fontSize: 14,
                        color: ColorPalette.gray400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: ColorPalette.gray900,
                    ),
                    onChanged: (value) {
                      if (value.length == 11) {
                        _handleCustomerLookup();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.person_add, color: primary),
                  onPressed: () async {
                    final phone = _mobileController.text.trim();
                    if (phone.isEmpty || phone.length != 11) {
                      showTextToast('সঠিক মোবাইল নম্বর লিখুন');
                      return;
                    }

                    // Create customer dialog
                    final name = await _showCreateCustomerDialog();
                    if (name != null && name.isNotEmpty) {
                      try {
                        final customer = Customer(name: name, phone: phone);
                        final createdCustomer =
                            await _customerService.createCustomer(customer);
                        setState(() {
                          _customerName = createdCustomer.name;
                          _customerId = createdCustomer.id;
                        });
                        showTextToast('কাস্টমার যোগ হয়েছে!');
                      } catch (e) {
                        showTextToast('ত্রুটি: ${e.toString()}');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'লাভ',
            style: GoogleFonts.notoSansBengali(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorPalette.gray600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorPalette.gray300),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: TextField(
              controller: _profitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: GoogleFonts.manrope(
                  fontSize: 14,
                  color: ColorPalette.gray400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: ColorPalette.gray900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'পণ্য সম্পর্কে বিস্তারিত',
            style: GoogleFonts.notoSansBengali(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorPalette.gray600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorPalette.gray300),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: TextField(
              controller: _detailsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'বিস্তারিত লিখুন...',
                hintStyle: GoogleFonts.notoSansBengali(
                  fontSize: 14,
                  color: ColorPalette.gray400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: GoogleFonts.notoSansBengali(
                fontSize: 14,
                color: ColorPalette.gray900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColorPalette.teal50,
          border: Border.all(color: ColorPalette.teal100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.teal700,
                  ),
                  children: [
                    const TextSpan(text: 'সাবস্ক্রিপশন কিনতে '),
                    TextSpan(
                      text: 'এখানে ক্লিক করুন →',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primary,
                        decoration: TextDecoration.none,
                      ),
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

  Widget _buildFooter() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: ColorPalette.gray200)),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -4),
            blurRadius: 6,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'সাবমিট',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'রিসিট এসএমএস পাঠান',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.gray600,
                ),
              ),
              SizedBox(
                height: 32,
                child: Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _receiptSmsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _receiptSmsEnabled = value;
                      });
                    },
                    activeColor: primary,
                    activeTrackColor: primary.withOpacity(0.5),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: ColorPalette.gray200,
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

// ===========================================================================
// PRODUCT LIST VIEW (Tab 1)
// ===========================================================================
class _ProductListView extends StatefulWidget {
  final Function(int) onTabChange;
  final VoidCallback? onSaleCompleted;
  final int salesSessionToken;

  const _ProductListView({
    Key? key,
    required this.onTabChange,
    this.onSaleCompleted,
    required this.salesSessionToken,
  }) : super(key: key);

  @override
  _ProductListViewState createState() => _ProductListViewState();
}

class _ProductListViewState extends State<_ProductListView>
    with TickerProviderStateMixin {
  // Services
  final ProductService _productService = ProductService();
  final SalesService _salesService = SalesService();

  // State
  final Set<String> _selectedProductIds = {};
  final Map<String, SellingCartItem> _cartItems = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isProcessing = false;

  // Stable stream initialized once
  late final Stream<List<Product>> _productsStream;

  // Recent usage map for sorting (product_id -> last sale timestamp)
  Map<String, DateTime> _recentUsageMap = {};

  // Cart totals
  double _cartTotal = 0.0;
  int _cartItemCount = 0;

  // Animation controllers and state
  late AnimationController _flyingAnimationController;
  late AnimationController _badgePulseController;
  late Animation<double> _flyingOpacity;
  late Animation<double> _badgeScale;

  bool _showFlyingIcon = false;
  Offset _flyingIconStart = Offset.zero;
  Offset _flyingIconEnd = Offset.zero;
  final GlobalKey _cartButtonKey = GlobalKey();
  final GlobalKey _cartBadgeKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();

  // Colors
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

    // Initialize stable product stream once - LOCAL ONLY (no sync trigger)
    _productsStream = _productService.getAllProductsLocalOnly();

    // Load recent usage map for sorting
    _loadRecentUsageMap();

    // Initialize animation controllers
    _flyingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _badgePulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Setup animations
    _flyingOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _flyingAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _badgeScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _badgePulseController,
        curve: Curves.elasticOut,
      ),
    );

    // Listen to animation completion
    _flyingAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFlyingIcon = false;
        });
        _flyingAnimationController.reset();
      }
    });

    _badgePulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _badgePulseController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _flyingAnimationController.dispose();
    _badgePulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ProductListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset Product List cart state when session token changes (user re-enters Sales tab)
    if (oldWidget.salesSessionToken != widget.salesSessionToken) {
      setState(() {
        // Clear cart items and selections
        _selectedProductIds.clear();
        _cartItems.clear();
        // Reset totals
        _cartTotal = 0.0;
        _cartItemCount = 0;
        // Clear search
        _searchController.clear();
        // Reset processing flag
        _isProcessing = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Trigger rebuild to apply filter on live stream data
      if (mounted) setState(() {});
    });
  }

  // Load recent usage map for sorting products by recently sold
  Future<void> _loadRecentUsageMap() async {
    try {
      final usageMap = await _productService.getProductRecentUsageMap();
      if (mounted) {
        setState(() {
          _recentUsageMap = usageMap;
        });
      }
    } catch (e) {
      print('Error loading recent usage map: $e');
      // Continue with empty map (no sorting by recent usage)
    }
  }

  // Sort products by recent usage: recently sold first, then never-sold, tie-breaker: name ASC
  List<Product> _sortProductsByRecentUsage(List<Product> products) {
    final sorted = List<Product>.from(products);

    sorted.sort((a, b) {
      final aId = a.id;
      final bId = b.id;

      // Get last usage timestamps
      final aLastUsed = (aId != null) ? _recentUsageMap[aId] : null;
      final bLastUsed = (bId != null) ? _recentUsageMap[bId] : null;

      // Both have usage history -> sort by timestamp DESC (most recent first)
      if (aLastUsed != null && bLastUsed != null) {
        final timeComparison = bLastUsed.compareTo(aLastUsed); // DESC
        if (timeComparison != 0) return timeComparison;
        // Tie-breaker: name ASC
        return (a.name ?? '').compareTo(b.name ?? '');
      }

      // Only A has usage -> A comes first
      if (aLastUsed != null) return -1;

      // Only B has usage -> B comes first
      if (bLastUsed != null) return 1;

      // Neither has usage -> sort by name ASC
      return (a.name ?? '').compareTo(b.name ?? '');
    });

    return sorted;
  }

  void _toggleProductSelection(Product product, {GlobalKey? productIconKey}) {
    if (product.id == null) return;

    // Oversell support: Allow selling even when stock is 0 or negative
    setState(() {
      if (_selectedProductIds.contains(product.id)) {
        // Already in cart → increment quantity (no stock limit check)
        final currentItem = _cartItems[product.id]!;
        _cartItems[product.id!] = currentItem.copyWith(
          quantity: currentItem.quantity + 1,
        );
      } else {
        // Not in cart → add with quantity=1
        _selectedProductIds.add(product.id!);
        _cartItems[product.id!] = SellingCartItem(
          productId: product.id!,
          productName: product.name ?? '',
          salePrice: product.salePrice ?? 0.0,
          quantity: 1,
          stockAvailable: product.quantity ?? 0,
          imageUrl: product.image,
        );
      }
      _updateCartTotal();
    });

    // Trigger flying animation on every add/increment
    if (productIconKey != null) {
      _triggerFlyingAnimation(productIconKey);
    }
  }

  void _triggerFlyingAnimation(GlobalKey productIconKey) {
    try {
      // Get Stack's render box for coordinate conversion
      final RenderBox? stackBox =
          _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (stackBox == null) return;

      // Get product icon position
      final RenderBox? productBox =
          productIconKey.currentContext?.findRenderObject() as RenderBox?;
      if (productBox == null) return;

      // Get cart button position
      final RenderBox? cartButtonBox =
          _cartButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (cartButtonBox == null) return;

      // Get global positions (screen coordinates)
      final Offset productGlobal = productBox.localToGlobal(Offset.zero);
      final Offset cartButtonGlobal = cartButtonBox.localToGlobal(Offset.zero);

      // Convert to Stack-local coordinates (for Positioned widget)
      final Offset productLocal = stackBox.globalToLocal(productGlobal);
      final Offset cartButtonLocal = stackBox.globalToLocal(cartButtonGlobal);

      // Calculate centers
      final Offset productCenter = Offset(
        productLocal.dx + productBox.size.width / 2,
        productLocal.dy + productBox.size.height / 2,
      );

      final Offset cartBadgeCenter = Offset(
        cartButtonLocal.dx + 15, // Target the count number on left of button
        cartButtonLocal.dy + cartButtonBox.size.height / 2,
      );

      print('🎯 Animation Debug (Stack-local):');
      print(
          '   Product: global=$productGlobal, local=$productLocal, center=$productCenter');
      print(
          '   Cart: global=$cartButtonGlobal, local=$cartButtonLocal, target=$cartBadgeCenter');

      setState(() {
        _flyingIconStart = productCenter;
        _flyingIconEnd = cartBadgeCenter;
        _showFlyingIcon = true;
      });

      // Start animations
      _flyingAnimationController.forward(from: 0);
      _badgePulseController.forward(from: 0);
    } catch (e) {
      print('Animation error: $e');
    }
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
      // Add product to cart
      _toggleProductSelection(product);

      // Set search field to scanned barcode to filter list
      if (product.barcode != null && product.barcode!.isNotEmpty) {
        _searchController.text = product.barcode!;
        // _onSearchChanged will trigger automatically via listener
      }

      showTextToast('${product.name} যোগ করা হয়েছে!');
    }
  }

  Future<void> _handleCheckout() async {
    if (_selectedProductIds.isEmpty) {
      showTextToast('অনুগ্রহ করে পণ্য নির্বাচন করুন');
      return;
    }

    if (_isProcessing) return;

    // Map SellingCartItem to BuyingCartItem for PurchaseCartScreen
    final buyingItems = _cartItems.values.map((sellingItem) {
      return BuyingCartItem(
        productId: sellingItem.productId,
        productName: sellingItem.productName,
        costPrice: sellingItem.salePrice,
        quantity: sellingItem.quantity,
        imageUrl: sellingItem.imageUrl,
      );
    }).toList();

    // Navigate to PurchaseCartScreen first
    final result = await Navigator.push<PurchaseCartCheckoutResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseCartScreen(
          initialItems: buyingItems,
        ),
      ),
    );

    if (result == null) return; // User cancelled

    setState(() => _isProcessing = true);

    try {
      // Use returned items and checkout data from PurchaseCartScreen
      final checkoutData = result.checkout;
      final finalItems = result.items;
      final finalTotal = result.totalAmount;

      // Get sale items from returned cart items
      final saleItems =
          finalItems.map((item) => item.toSaleItemJson()).toList();

      // Create Sale object with final total from cart screen
      final sale = Sale(
        totalAmount: finalTotal,
        subtotal: finalTotal,
        taxAmount: 0.0,
        customerName: checkoutData.customerName,
        paymentMethod: checkoutData.paymentMethod,
        createdAt: checkoutData.saleDate,
      );

      // Process sale with final items
      final saleId = await _salesService.processSale(
          sale,
          finalItems.map((item) {
            return CartItem(
              product: Product(
                id: item.productId,
                name: item.productName,
                salePrice: item.salePrice,
              ),
              quantity: item.quantity,
            );
          }).toList());

      // Apply local stock deductions immediately using final items
      // Build deduction map: productId -> total quantity sold
      final Map<String, int> deductions = {};
      for (final item in finalItems) {
        deductions[item.productId] =
            (deductions[item.productId] ?? 0) + item.quantity;
      }

      try {
        await _productService.applyLocalStockDeductions(deductions);
        print('✅ Local stock updated for ${deductions.length} products');
      } catch (e) {
        // Don't fail sale if local update fails (sale already completed server-side)
        print('⚠️ Local stock update failed (non-critical): $e');
      }

      // Clear cart on success
      setState(() {
        _selectedProductIds.clear();
        _cartItems.clear();
        _updateCartTotal();
        _isProcessing = false;
      });

      // Reload recent usage map to reflect new sale (products just sold will appear at top)
      await _loadRecentUsageMap();

      showTextToast('বিক্রয় সফল হয়েছে!');

      // Trigger dashboard refresh callback
      widget.onSaleCompleted?.call();
    } catch (e) {
      setState(() => _isProcessing = false);

      final errorMsg = e.toString();

      // Check for product sync error
      if (errorMsg.contains('sync হয়নি') ||
          errorMsg.contains('foreign key') ||
          errorMsg.contains('uuid') ||
          errorMsg.contains('product_id')) {
        showTextToast(
            'কিছু পণ্য সার্ভারে sync হয়নি। Sync করে আবার চেষ্টা করুন।');
      } else {
        showTextToast('ত্রুটি: ${e.toString()}');
      }
    }
  }

  void _showFilterDialog() {
    showTextToast('Filter feature coming soon');
  }

  // Uniform product icon
  IconData _getProductIcon(Product product) {
    return Icons.inventory_2;
  }

  // Uniform product icon color
  Color _getProductIconColor(Product product) {
    return primary;
  }

  // Uniform product icon background
  Color _getProductIconBackgroundColor(Product product) {
    return primary.withOpacity(0.1);
  }

  // Product title color (always normal color)
  Color _getProductTitleColor(Product product) {
    return slate800;
  }

  // Product opacity (always full opacity)
  double _getProductOpacity(Product product) {
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _stackKey,
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildSearchRow(),
            ),
            Expanded(child: _buildProductList()),
            _buildBottomBar(),
          ],
        ),
        // Flying icon animation overlay
        if (_showFlyingIcon) _buildFlyingIcon(),
      ],
    );
  }

  Widget _buildFlyingIcon() {
    return AnimatedBuilder(
      animation: _flyingAnimationController,
      builder: (context, child) {
        // Calculate current position using linear interpolation
        final double t = _flyingAnimationController.value;
        final Offset currentPosition = Offset.lerp(
          _flyingIconStart,
          _flyingIconEnd,
          t,
        )!;

        return Positioned(
          left: currentPosition.dx - 18, // Center the 36px icon
          top: currentPosition.dy - 18,
          child: Opacity(
            opacity: _flyingOpacity.value,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Icon(
                  Icons.inventory_2,
                  color: primary,
                  size: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
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
                      hintStyle: GoogleFonts.anekBangla(
                        fontSize: 14,
                        color: slate400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 10),
                    ),
                    style: GoogleFonts.anekBangla(
                      fontSize: 14,
                      color: slate800,
                    ),
                  ),
                ),
                // Clear button (X) - only visible when search text is not empty
                if (_searchController.text.isNotEmpty)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                      });
                      FocusScope.of(context).unfocus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.clear,
                        color: slate500,
                        size: 18,
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
                          style: GoogleFonts.anekBangla(
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

  Widget _buildProductList() {
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          );
        }

        if (snapshot.hasError) {
          print('Stream error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: slate400),
                const SizedBox(height: 16),
                Text(
                  'পণ্য লোড করতে ত্রুটি',
                  style: GoogleFonts.anekBangla(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: slate500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ইন্টারনেট সংযোগ চেক করুন',
                  style: GoogleFonts.anekBangla(
                    fontSize: 14,
                    color: slate400,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildProductListView(<Product>[]);
        }

        // Apply search filter synchronously on live stream data
        final allProducts = snapshot.data!;
        final query = _searchController.text.trim().toLowerCase();

        // Apply search filter
        final filteredProducts = query.isEmpty
            ? allProducts
            : allProducts.where((product) {
                final name = (product.name ?? '').toLowerCase();
                final barcode = (product.barcode ?? '').toLowerCase();
                final description = (product.description ?? '').toLowerCase();
                return name.contains(query) ||
                    barcode.contains(query) ||
                    description.contains(query);
              }).toList();

        // Apply sorting by recent usage
        final sortedProducts = _sortProductsByRecentUsage(filteredProducts);

        return _buildProductListView(sortedProducts);
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
              style: GoogleFonts.anekBangla(
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

  Widget _buildProductCard(Product product) {
    final opacity = _getProductOpacity(product);
    final isSelected = _selectedProductIds.contains(product.id);
    final GlobalKey productIconKey = GlobalKey();

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: () =>
            _toggleProductSelection(product, productIconKey: productIconKey),
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
              Container(
                key: productIconKey,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name ?? '',
                            style: GoogleFonts.anekBangla(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getProductTitleColor(product),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'বিক্রয় মূল্য',
                              style: GoogleFonts.anekBangla(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: slate500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              NumberFormatter.formatCurrencyInt(
                                  product.salePrice ?? 0.0),
                              style: GoogleFonts.anekBangla(
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
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'স্টক সংখ্যা',
                              style: GoogleFonts.anekBangla(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: slate500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              NumberFormatter.formatIntToBengali(
                                  product.quantity ?? 0),
                              style: GoogleFonts.anekBangla(
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
          Row(
            children: [
              Text(
                'সর্বমোট:',
                style: GoogleFonts.anekBangla(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                NumberFormatter.formatCurrencyInt(_cartTotal),
                style: GoogleFonts.anekBangla(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          ElevatedButton(
            key: _cartButtonKey,
            onPressed: _isProcessing ? null : _handleCheckout,
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
            child: _isProcessing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(slate800),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        key: _cartBadgeKey,
                        child: AnimatedBuilder(
                          animation: _badgeScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _badgeScale.value,
                              child: child,
                            );
                          },
                          child: Text(
                            NumberFormatter.formatIntToBengali(_cartItemCount),
                            style: GoogleFonts.anekBangla(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

// ===========================================================================
// PRODUCT PICKER DIALOG (for Fast Sale)
// ===========================================================================
class _ProductPickerDialog extends StatefulWidget {
  final ProductService productService;

  const _ProductPickerDialog({
    Key? key,
    required this.productService,
  }) : super(key: key);

  @override
  _ProductPickerDialogState createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<_ProductPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<Product>> _productsStream;
  final Map<String, FastSaleScanItem> _selectedItems = {};
  static const Color primary = ColorPalette.tealAccent;

  @override
  void initState() {
    super.initState();
    // Use local-only stream to avoid triggering sync
    _productsStream = widget.productService.getAllProductsLocalOnly();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addProduct(Product product) {
    final productId = product.id;
    if (productId == null || productId.isEmpty) {
      return;
    }

    setState(() {
      if (_selectedItems.containsKey(productId)) {
        _selectedItems[productId]!.increment();
      } else {
        _selectedItems[productId] = FastSaleScanItem(product: product);
      }
    });
  }

  void _changeQuantity(Product product, int delta) {
    final productId = product.id;
    if (productId == null || productId.isEmpty) {
      return;
    }

    setState(() {
      final selected = _selectedItems[productId];
      if (selected == null) {
        if (delta > 0) {
          _selectedItems[productId] = FastSaleScanItem(product: product);
        }
        return;
      }

      selected.quantity += delta;
      if (selected.quantity <= 0) {
        _selectedItems.remove(productId);
      }
    });
  }

  FastSaleScanResult _buildResult() {
    final items = <String, FastSaleScanItem>{};
    for (final entry in _selectedItems.entries) {
      items[entry.key] = FastSaleScanItem(
        product: entry.value.product,
        quantity: entry.value.quantity,
      );
    }
    return FastSaleScanResult(items: items);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedItems.values.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'পণ্য নির্বাচন করুন',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.gray900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: ColorPalette.gray700),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Search bar
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: ColorPalette.gray300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.search,
                        color: ColorPalette.gray400, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'পণ্য খুঁজুন',
                        hintStyle: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          color: ColorPalette.gray400,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 14,
                        color: ColorPalette.gray900,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Product list
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _productsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorPalette.tealAccent,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text(
                        'পণ্য লোড করতে সমস্যা হয়েছে',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          color: ColorPalette.gray500,
                        ),
                      ),
                    );
                  }

                  final allProducts = snapshot.data!;
                  final query = _searchController.text.trim().toLowerCase();

                  final filteredProducts = query.isEmpty
                      ? allProducts
                      : allProducts.where((product) {
                          final name = (product.name ?? '').toLowerCase();
                          final barcode = (product.barcode ?? '').toLowerCase();
                          return name.contains(query) ||
                              barcode.contains(query);
                        }).toList();

                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Text(
                        'কোনো পণ্য পাওয়া যায়নি',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          color: ColorPalette.gray500,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final selectedQty =
                          _selectedItems[product.id]?.quantity ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: selectedQty > 0
                                ? primary
                                : ColorPalette.gray200,
                            width: selectedQty > 0 ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _addProduct(product),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      ColorPalette.tealAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.inventory_2,
                                    color: ColorPalette.tealAccent,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _addProduct(product),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name ?? '',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: ColorPalette.gray900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'স্টক: ${NumberFormatter.formatIntToBengali(product.quantity ?? 0)}',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 12,
                                            color: ColorPalette.gray600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          NumberFormatter.formatCurrencyInt(
                                              product.salePrice ?? 0.0),
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: ColorPalette.gray700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            selectedQty == 0
                                ? OutlinedButton(
                                    onPressed: () => _addProduct(product),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primary,
                                      side: const BorderSide(color: primary),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    child: Text(
                                      'যোগ',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: primary),
                                      borderRadius: BorderRadius.circular(999),
                                      color: ColorPalette.teal50,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              _changeQuantity(product, -1),
                                          icon: const Icon(
                                            Icons.remove,
                                            size: 16,
                                          ),
                                          color: primary,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        Text(
                                          NumberFormatter.formatIntToBengali(
                                              selectedQty),
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: primary,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _changeQuantity(product, 1),
                                          icon: const Icon(
                                            Icons.add,
                                            size: 16,
                                          ),
                                          color: primary,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCount == 0
                        ? 'একাধিক পণ্য যোগ করতে তালিকা থেকে বেছে নিন'
                        : '${NumberFormatter.formatIntToBengali(selectedCount)} টি পণ্য প্রস্তুত',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      color: ColorPalette.gray600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: selectedCount == 0
                      ? null
                      : () => Navigator.pop(context, _buildResult()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'যোগ করুন',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
