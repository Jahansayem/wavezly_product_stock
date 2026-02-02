import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/functions/toast.dart';
import 'package:wavezly/models/customer.dart';
import 'package:wavezly/models/selling_cart_item.dart';
import 'package:wavezly/services/customer_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/utils/date_formatter.dart';

class SellingCheckoutResult {
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final DateTime saleDate;
  final String paymentMethod;
  final String? notes;

  const SellingCheckoutResult({
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.saleDate,
    required this.paymentMethod,
    this.notes,
  });
}

class SellingCheckoutScreen extends StatefulWidget {
  final List<SellingCartItem> cartItems;
  final double totalAmount;

  const SellingCheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<SellingCheckoutScreen> createState() => _SellingCheckoutScreenState();
}

class _SellingCheckoutScreenState extends State<SellingCheckoutScreen> {
  // Services
  final CustomerService _customerService = CustomerService();

  // State
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = 'cash';
  String? _customerId;
  String? _customerName;
  bool _isSearching = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.slate50,
      appBar: AppBar(
        title: Text('চেকআউট', style: GoogleFonts.notoSansBengali(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        )),
        backgroundColor: ColorPalette.tealAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCartSummary(),
                  SizedBox(height: 16),
                  _buildCustomerInput(),
                  SizedBox(height: 16),
                  _buildDatePicker(),
                  SizedBox(height: 16),
                  _buildPaymentMethod(),
                  SizedBox(height: 16),
                  _buildNotesInput(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorPalette.gray300),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 2,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'পণ্য সারসংক্ষেপ',
            style: GoogleFonts.notoSansBengali(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorPalette.gray900,
            ),
          ),
          SizedBox(height: 12),
          ...widget.cartItems.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.productName} × ${item.quantity}',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 14,
                      color: ColorPalette.gray700,
                    ),
                  ),
                ),
                Text(
                  '৳ ${item.totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.anekBangla(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.gray900,
                  ),
                ),
              ],
            ),
          )),
          Divider(height: 24, thickness: 1, color: ColorPalette.gray300),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'মোট',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.gray900,
                ),
              ),
              Text(
                '৳ ${widget.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.anekBangla(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.tealAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'কাস্টমার (ঐচ্ছিক)',
          style: GoogleFonts.notoSansBengali(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorPalette.gray700,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorPalette.gray300),
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'মোবাইল নম্বর',
              hintStyle: GoogleFonts.notoSansBengali(
                fontSize: 14,
                color: ColorPalette.gray400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: _isSearching
                  ? Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.tealAccent),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.search, color: ColorPalette.gray600),
                      onPressed: _searchCustomer,
                    ),
            ),
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: ColorPalette.gray900,
            ),
            onChanged: (value) {
              if (value.length == 11) _searchCustomer();
            },
          ),
        ),
        if (_customerName != null) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorPalette.teal50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorPalette.tealAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: ColorPalette.tealAccent, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'কাস্টমার: $_customerName',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 14,
                      color: ColorPalette.gray900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _searchCustomer() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 11) return;

    setState(() => _isSearching = true);

    try {
      final customers = await _customerService.searchCustomers(phone);
      setState(() {
        if (customers.isNotEmpty) {
          _customerId = customers.first.id;
          _customerName = customers.first.name;
        } else {
          _customerId = null;
          _customerName = null;
        }
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      print('Customer search error: $e');
    }
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(Duration(days: 365)),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: ColorPalette.tealAccent),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorPalette.gray300),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'তারিখ',
              style: GoogleFonts.notoSansBengali(
                fontSize: 14,
                color: ColorPalette.gray700,
              ),
            ),
            Row(
              children: [
                Text(
                  DateFormatter.toBengaliDate(_selectedDate),
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.gray900,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 18, color: ColorPalette.gray600),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'পেমেন্ট পদ্ধতি',
          style: GoogleFonts.notoSansBengali(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorPalette.gray700,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPaymentOption('cash', 'নগদ', Icons.payments),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildPaymentOption('due', 'বাকি', Icons.event_busy),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.tealAccent : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ColorPalette.tealAccent : ColorPalette.gray300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: ColorPalette.tealAccent.withOpacity(0.3),
                  ),
                ]
              : [
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : ColorPalette.gray600,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.notoSansBengali(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : ColorPalette.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'নোট (ঐচ্ছিক)',
          style: GoogleFonts.notoSansBengali(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorPalette.gray700,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorPalette.gray300),
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'নোট লিখুন...',
              hintStyle: GoogleFonts.notoSansBengali(
                fontSize: 14,
                color: ColorPalette.gray400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
            style: GoogleFonts.notoSansBengali(
              fontSize: 14,
              color: ColorPalette.gray900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPalette.tealAccent,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
          ),
          child: Text(
            'নিশ্চিত করুন',
            style: GoogleFonts.notoSansBengali(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _handleConfirm() {
    // Validate date
    if (_selectedDate.isAfter(DateTime.now())) {
      showTextToast('ভবিষ্যতের তারিখ নির্বাচন করা যাবে না');
      return;
    }

    // Optionally recommend customer for 'due' payment
    if (_paymentMethod == 'due' && _customerId == null && _phoneController.text.trim().isEmpty) {
      // Just a warning, not enforced
      showTextToast('বাকি বিক্রয়ের জন্য কাস্টমার যোগ করা ভালো');
    }

    final result = SellingCheckoutResult(
      customerId: _customerId,
      customerName: _customerName,
      customerPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      saleDate: _selectedDate,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    Navigator.pop(context, result);
  }
}
