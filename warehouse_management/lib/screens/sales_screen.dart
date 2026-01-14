import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/models/selling_cart_item.dart';
import 'package:wavezly/screens/barcode_scanner_screen.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/utils/color_palette.dart';

/// Unified Sales Screen with tab-based view switching
/// Contains Quick Sell and Product List views with state preservation
class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  // Tab state (0 = Quick Sell, 1 = Product List)
  int _selectedTab = 0;

  // Colors
  static const Color primary = ColorPalette.tealAccent;
  static const Color background = ColorPalette.slate50;

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
  // Cash calculator state
  String _cashAmount = '৫০'; // Default "50" in Bengali

  // Form controllers
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _profitController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  // Toggle state
  bool _receiptSmsEnabled = true; // Default ON

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
    // TODO: Implement safe expression evaluation
    return expression;
  }

  Future<void> _handleSubmit() async {
    try {
      final double amount = _parseBengaliNumber(_cashAmount);

      if (amount <= 0) {
        showTextToast('অনুগ্রহ করে ক্যাশ পরিমাণ লিখুন');
        return;
      }

      // TODO: Implement sale creation
      showTextToast('বিক্রয় সফল হয়েছে!');
      Navigator.pop(context);
    } catch (e) {
      showTextToast('ত্রুটি: ${e.toString()}');
    }
  }

  double _parseBengaliNumber(String bengaliNumber) {
    const bengaliDigits = '০১২৩৪৫৬৭৮৯';
    const englishDigits = '0123456789';

    String result = bengaliNumber;
    for (int i = 0; i < bengaliDigits.length; i++) {
      result = result.replaceAll(bengaliDigits[i], englishDigits[i]);
    }

    return double.tryParse(result) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 0),
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
                onTap: () {
                  showTextToast('Date picker coming soon');
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
                        '১৪ জানুয়ারী',
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
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.person_add, color: primary),
                  onPressed: () {
                    showTextToast('Add customer feature coming soon');
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
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
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
              Transform.scale(
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

class _ProductListViewState extends State<_ProductListView> {
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

    showTextToast('Checkout feature coming soon');
  }

  void _showFilterDialog() {
    showTextToast('Filter feature coming soon');
  }

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

  IconData _getProductIcon(Product product) {
    if (product.id == '3') {
      return Icons.local_offer;
    }
    return Icons.hexagon;
  }

  Color _getProductIconColor(Product product) {
    if (product.id == '3') {
      return blue;
    }
    return amberYellow;
  }

  Color _getProductIconBackgroundColor(Product product) {
    if (product.id == '3') {
      return blue.withOpacity(0.1);
    }
    return amberYellow.withOpacity(0.1);
  }

  Color _getProductTitleColor(Product product) {
    if (product.name == 'rahman') {
      return danger;
    }
    return slate800;
  }

  double _getProductOpacity(Product product) {
    if ((product.quantity ?? 0) == 0) {
      return 0.5;
    }
    if (product.id == '3') {
      return 0.7;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildSearchRow(),
        ),
        Expanded(child: _buildProductList()),
        _buildBottomBar(),
      ],
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
                      hintStyle: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: slate400,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
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
                            style: GoogleFonts.hindSiliguri(
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
