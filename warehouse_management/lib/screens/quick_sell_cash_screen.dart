import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/screens/product_selling_selection_screen.dart';
import 'package:wavezly/utils/color_palette.dart';

class QuickSellCashScreen extends StatefulWidget {
  const QuickSellCashScreen({Key? key}) : super(key: key);

  @override
  _QuickSellCashScreenState createState() => _QuickSellCashScreenState();
}

class _QuickSellCashScreenState extends State<QuickSellCashScreen> {
  // Cash calculator state
  String _cashAmount = '৫০'; // Default "50" in Bengali

  // Form controllers
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _profitController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  // Toggle state
  bool _receiptSmsEnabled = true; // Default ON

  // Tab state (0 = Quick Sell, 1 = Product List)
  int _selectedTab = 0;

  // Colors (matching home screen tealAccent #00BFA5)
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
          // Optional: Evaluate expression
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
    // For MVP: Just return as-is
    return expression;
  }

  Future<void> _handleSubmit() async {
    try {
      // Parse cash amount (convert Bengali numerals if needed)
      final double amount = _parseBengaliNumber(_cashAmount);

      // Validate
      if (amount <= 0) {
        showTextToast('অনুগ্রহ করে ক্যাশ পরিমাণ লিখুন');
        return;
      }

      // TODO: Implement sale creation
      // final String mobile = _mobileController.text.trim();
      // final double profit = double.tryParse(_profitController.text) ?? 0;
      // final String details = _detailsController.text.trim();
      // Create sale using SalesService or Supabase function

      showTextToast('বিক্রয় সফল হয়েছে!');
      Navigator.pop(context);
    } catch (e) {
      showTextToast('ত্রুটি: ${e.toString()}');
    }
  }

  double _parseBengaliNumber(String bengaliNumber) {
    // Convert Bengali numerals to English
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
    return Scaffold(
      backgroundColor: ColorPalette.slate50,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 0),
              child: Column(
                children: [
                  _buildTabButtons(),
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
        ],
      ),
      bottomNavigationBar: _buildFooter(),
    );
  }

  // =======================================================================
  // HEADER (Fixed 56px teal header)
  // =======================================================================
  Widget _buildHeader() {
    return Container(
      height: 56,
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
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'বিক্রি করুন',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansBengali(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.015,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              // TODO: Show help dialog
              showTextToast('Help feature coming soon');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.help_outline, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // TAB BUTTONS (Segmented control)
  // =======================================================================
  Widget _buildTabButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Quick Sell (Active)
          Expanded(
            child: Material(
              color: primary,
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
                      const Icon(Icons.shopping_cart,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'দ্রুত বিক্রি',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Product List (Inactive)
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              elevation: 0,
              child: InkWell(
                onTap: () {
                  // Navigate to Product List screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductSellingSelectionScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 44,
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
                      const Icon(Icons.list_alt, color: ColorPalette.gray700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'প্রোডাক্ট লিস্ট',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.gray700,
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

  // =======================================================================
  // ACTION ROW (Date/Photo/Add)
  // =======================================================================
  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        children: [
          // Date Button
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                  // TODO: Show date picker
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
          // Photo Button
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                // TODO: Pick image
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
          // Add Button
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                // TODO: Add action
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

  // =======================================================================
  // CASH DISPLAY (Big number display)
  // =======================================================================
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

  // =======================================================================
  // CALCULATOR KEYPAD (4x5 grid)
  // =======================================================================
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
    // Determine button style based on key type
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

  // =======================================================================
  // MOBILE INPUT (Flag + phone + add person)
  // =======================================================================
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
                // Flag + Country Code Prefix
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
                      // Bangladesh Flag (circle with red center)
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF006A4E), // Green
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF42A41), // Red
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
                // Input Field
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
                // Add Person Button
                IconButton(
                  icon: Icon(Icons.person_add, color: primary),
                  onPressed: () {
                    // TODO: Add customer to database
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

  // =======================================================================
  // PROFIT INPUT (Simple number field)
  // =======================================================================
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

  // =======================================================================
  // DETAILS INPUT (Textarea)
  // =======================================================================
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

  // =======================================================================
  // INFO BANNER (Subscription banner)
  // =======================================================================
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

  // =======================================================================
  // FOOTER (Submit button + SMS toggle)
  // =======================================================================
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Submit Button
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
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'সাবমিট',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // SMS Toggle
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'রিসিট এসএমএস পাঠান',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.gray600,
                ),
              ),
              const SizedBox(height: 4),
              Switch(
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
            ],
          ),
        ],
      ),
    );
  }
}
