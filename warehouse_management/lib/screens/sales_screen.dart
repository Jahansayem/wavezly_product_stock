import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/models/cart_item.dart';
import 'package:wavezly/models/customer.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/models/sale.dart';
import 'package:wavezly/models/selling_cart_item.dart';
import 'package:wavezly/screens/barcode_scanner_screen.dart';
import 'package:wavezly/screens/selling_checkout_screen.dart';
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

  const SalesScreen({Key? key, this.onBackPressed}) : super(key: key);

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
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabButtons(),
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _QuickSellView(
                      onTabChange: (index) => setState(() => _selectedTab = index),
                    ),
                    _ProductListView(
                      onTabChange: (index) => setState(() => _selectedTab = index),
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
  // HEADER (Shared between both tabs)
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
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 24),
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

  const _QuickSellView({Key? key, required this.onTabChange}) : super(key: key);

  @override
  _QuickSellViewState createState() => _QuickSellViewState();
}

class _QuickSellViewState extends State<_QuickSellView> {
  // Services
  final SalesService _salesService = SalesService();
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();

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

  // Colors
  static const Color primary = ColorPalette.tealAccent;

  @override
  void dispose() {
    _mobileController.dispose();
    _profitController.dispose();
    _detailsController.dispose();
    super.dispose();
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
      // Convert Bengali to English for evaluation
      String englishExpression = NumberFormatter.bengaliToEnglish(expression);

      // Replace display operators with math operators
      englishExpression = englishExpression
          .replaceAll('×', '*')
          .replaceAll('÷', '/');

      // Parse and evaluate
      Parser parser = Parser();
      Expression exp = parser.parse(englishExpression);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);

      // Convert back to Bengali
      return NumberFormatter.formatToBengali(result, decimals: 2);
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
      final String englishAmount = NumberFormatter.bengaliToEnglish(_cashAmount);
      final double amount = double.tryParse(englishAmount) ?? 0.0;

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
      final String englishProfit = NumberFormatter.bengaliToEnglish(
        _profitController.text.trim()
      );
      final double profit = double.tryParse(englishProfit) ?? 0.0;

      // Get product details (optional)
      final String details = _detailsController.text.trim();

      // Process quick cash sale using new service method
      final saleId = await _salesService.processQuickCashSale(
        userId: userId,
        cashReceived: amount,
        customerMobile: mobile.isNotEmpty ? mobile : null,
        profitMargin: profit,
        productDetails: details.isNotEmpty ? details : null,
        receiptSmsEnabled: _receiptSmsEnabled,
        saleDate: _selectedDate,
        photoUrl: null,
      );

      // Success feedback
      showTextToast('বিক্রয় সফল হয়েছে!');

      if (mounted) {
        Navigator.pop(context, saleId);
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

  double _parseBengaliNumber(String bengaliNumber) {
    return NumberFormatter.parseBengaliNumber(bengaliNumber);
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
                    const Icon(Icons.photo_camera, color: ColorPalette.gray600, size: 18),
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
                _cashAmount.isEmpty ? '০' : _cashAmount,
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
                      fontWeight:
                          isOperator || isEquals ? FontWeight.bold : FontWeight.w500,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      Icon(Icons.expand_more, size: 16, color: ColorPalette.gray400),
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
                        final createdCustomer = await _customerService.createCustomer(customer);
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

  const _ProductListView({Key? key, required this.onTabChange})
      : super(key: key);

  @override
  _ProductListViewState createState() => _ProductListViewState();
}

class _ProductListViewState extends State<_ProductListView> with TickerProviderStateMixin {
  // Services
  final ProductService _productService = ProductService();
  final SalesService _salesService = SalesService();

  // State
  final Set<String> _selectedProductIds = {};
  final Map<String, SellingCartItem> _cartItems = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Product>? _filteredProducts;
  bool _isProcessing = false;

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

  void _toggleProductSelection(Product product, {GlobalKey? productIconKey}) {
    if (product.id == null) return;

    if ((product.quantity ?? 0) == 0) {
      showTextToast('এই পণ্যটি স্টকে নেই!');
      return;
    }

    setState(() {
      if (_selectedProductIds.contains(product.id)) {
        // Already in cart → increment quantity (if stock allows)
        final currentItem = _cartItems[product.id]!;
        if (currentItem.quantity < currentItem.stockAvailable) {
          _cartItems[product.id!] = currentItem.copyWith(
            quantity: currentItem.quantity + 1,
          );
        } else {
          showTextToast('স্টক সীমায় পৌঁছেছে!');
          return;
        }
      } else {
        // Not in cart → add with quantity=1
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

    // Trigger flying animation on every add/increment
    if (productIconKey != null) {
      _triggerFlyingAnimation(productIconKey);
    }
  }

  void _triggerFlyingAnimation(GlobalKey productIconKey) {
    try {
      // Get Stack's render box for coordinate conversion
      final RenderBox? stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (stackBox == null) return;

      // Get product icon position
      final RenderBox? productBox = productIconKey.currentContext?.findRenderObject() as RenderBox?;
      if (productBox == null) return;

      // Get cart button position
      final RenderBox? cartButtonBox = _cartButtonKey.currentContext?.findRenderObject() as RenderBox?;
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
      print('   Product: global=$productGlobal, local=$productLocal, center=$productCenter');
      print('   Cart: global=$cartButtonGlobal, local=$cartButtonLocal, target=$cartBadgeCenter');

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
      _toggleProductSelection(product);
      showTextToast('${product.name} যোগ করা হয়েছে!');
    }
  }

  Future<void> _handleCheckout() async {
    if (_selectedProductIds.isEmpty) {
      showTextToast('অনুগ্রহ করে পণ্য নির্বাচন করুন');
      return;
    }

    if (_isProcessing) return;

    // Navigate to checkout screen
    final result = await Navigator.push<SellingCheckoutResult>(
      context,
      MaterialPageRoute(
        builder: (_) => SellingCheckoutScreen(
          cartItems: _cartItems.values.toList(),
          totalAmount: _cartTotal,
        ),
      ),
    );

    if (result == null) return; // User cancelled

    setState(() => _isProcessing = true);

    try {
      // Get sale items from cart (already has toSaleItemJson)
      final saleItems = _cartItems.values
          .map((item) => item.toSaleItemJson())
          .toList();

      // Create Sale object
      final sale = Sale(
        totalAmount: _cartTotal,
        subtotal: _cartTotal,
        taxAmount: 0.0,
        customerName: result.customerName,
        paymentMethod: result.paymentMethod,
        createdAt: result.saleDate,
      );

      // Process sale
      final saleId = await _salesService.processSale(sale, _cartItems.values.map((item) {
        return CartItem(
          product: Product(
            id: item.productId,
            name: item.productName,
            cost: item.salePrice,
          ),
          quantity: item.quantity,
        );
      }).toList());

      // Clear cart on success
      setState(() {
        _selectedProductIds.clear();
        _cartItems.clear();
        _updateCartTotal();
        _isProcessing = false;
      });

      showTextToast('বিক্রয় সফল হয়েছে!');
    } catch (e) {
      setState(() => _isProcessing = false);

      // Check for insufficient stock error
      if (e.toString().contains('Insufficient stock')) {
        showTextToast('স্টক অপর্যাপ্ত! পণ্যের স্টক চেক করুন');
      } else {
        showTextToast('ত্রুটি: ${e.toString()}');
      }
    }
  }

  void _showFilterDialog() {
    showTextToast('Filter feature coming soon');
  }

  // Fallback products for offline mode or service errors
  List<Product> _getHardcodedProducts() {
    return [
      Product(
        id: '1',
        name: 'rahman',
        cost: 50.0,
        quantity: 0,
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

  // Product title color (only special case: out of stock)
  Color _getProductTitleColor(Product product) {
    return (product.quantity ?? 0) == 0
        ? ColorPalette.gray400
        : slate800;
  }

  // Product opacity (out of stock indicator)
  double _getProductOpacity(Product product) {
    return (product.quantity ?? 0) == 0 ? 0.5 : 1.0;
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    ),
                    style: GoogleFonts.anekBangla(
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
      stream: _productService.getAllProducts(),
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
          final products = _getHardcodedProducts();
          return _buildProductListView(products);
        }

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
        onTap: () => _toggleProductSelection(product, productIconKey: productIconKey),
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
                              '${product.cost?.toStringAsFixed(0) ?? '0'} ৳',
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
                              '${product.quantity ?? 0}',
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
                '৳ ${_cartTotal.toStringAsFixed(0)}',
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
                            '$_cartItemCount',
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
