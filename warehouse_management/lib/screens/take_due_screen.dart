import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

enum DueTxnType { take, give }

class DueTransactionResult {
  final DueTxnType type;
  final double amount;
  final String note;
  final DateTime date;
  final bool smsEnabled;
  final String? attachmentPath;

  const DueTransactionResult({
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
    required this.smsEnabled,
    this.attachmentPath,
  });
}

class TakeDueScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final double currentDue;

  const TakeDueScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.currentDue,
  });

  @override
  State<TakeDueScreen> createState() => _TakeDueScreenState();
}

class _TakeDueScreenState extends State<TakeDueScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _smsEnabled = false;
  double _enteredAmount = 0.0;
  String? _attachmentPath;

  static const Color _primaryTeal = Color(0xFF0D9488);
  static const Color _bgLight = Color(0xFFF9FAFB);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _inputBorder = Color(0xFFE2E8F0);
  static const Color _redWarning = Color(0xFFEF4444);
  static const Color _gray100 = Color(0xFFF3F4F6);
  static const Color _gray500 = Color(0xFF6B7280);
  static const Color _gray600 = Color(0xFF4B5563);
  static const Color _gray700 = Color(0xFF374151);
  static const Color _teal50 = Color(0xFFF0FDFA);
  static const Color _teal100 = Color(0xFFCCFBF1);
  static const Color _teal600 = Color(0xFF0D9488);

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateAmount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateAmount() {
    final text = _amountController.text;
    setState(() {
      _enteredAmount = double.tryParse(text) ?? 0.0;
    });
  }

  String _formatBanglaAmount(double amount) {
    final formatter = NumberFormat('#,##,##0', 'en_US');
    String formatted = formatter.format(amount);
    
    // Convert to Bangla numerals
    const englishToBangla = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
    };
    
    String banglaFormatted = formatted;
    englishToBangla.forEach((english, bangla) {
      banglaFormatted = banglaFormatted.replaceAll(english, bangla);
    });
    
    return banglaFormatted;
  }

  String _formatDateBangla(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${date.day} ${months[date.month - 1]}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryTeal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onPickImage() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker feature coming soon')),
    );
  }

  void _onSubmit() {
    if (_enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে একটি বৈধ পরিমাণ প্রবেশ করান'),
          backgroundColor: _redWarning,
        ),
      );
      return;
    }

    final result = DueTransactionResult(
      type: DueTxnType.take,  // This is TAKE screen - customer pays you back
      amount: _enteredAmount,
      note: _noteController.text.trim(),
      date: _selectedDate,
      smsEnabled: _smsEnabled,
      attachmentPath: _attachmentPath,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Container(
              height: 56,
              decoration: const BoxDecoration(
                color: _primaryTeal,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'নতুন বাকি',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      // Top Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          border: Border.all(color: _teal100, width: 1),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          'মোট পাবোঃ ${_formatBanglaAmount(_enteredAmount)} ৳',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _primaryTeal,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Red Warning Text
                      Text(
                        'মোট পাবোঃ ${_formatBanglaAmount(_enteredAmount)} ৳',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _redWarning,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Form Fields
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Amount Input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 6),
                                child: Text(
                                  'টাকার পরিমাণ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _gray600,
                                  ),
                                ),
                              ),
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _cardBg,
                                  border: Border.all(color: _teal100, width: 1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                  ],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: _gray700,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '০',
                                    hintStyle: TextStyle(
                                      color: Color(0xFFD1D5DB),
                                      fontSize: 20,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Note Input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 6),
                                child: Text(
                                  'নোট',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _gray600,
                                  ),
                                ),
                              ),
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _cardBg,
                                  border: Border.all(color: _teal100, width: 1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: _noteController,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: _gray700,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'নোট',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Photo + Date Row
                          Row(
                            children: [
                              // Photo Button
                              GestureDetector(
                                onTap: _onPickImage,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: _cardBg,
                                    border: Border.all(color: _teal100, width: 1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate,
                                    color: _teal600,
                                    size: 24,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Date Field
                              Expanded(
                                child: GestureDetector(
                                  onTap: _selectDate,
                                  child: Container(
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: _cardBg,
                                      border: Border.all(color: _teal100, width: 1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDateBangla(_selectedDate),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: _gray700,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_month,
                                          color: _primaryTeal,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // SMS Toggle
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _gray100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.textsms,
                                      color: _gray500,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'এস এম এস: (30)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: _gray700,
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _smsEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _smsEnabled = value;
                                    });
                                  },
                                  activeColor: _primaryTeal,
                                  activeTrackColor: _primaryTeal.withOpacity(0.3),
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: Color(0xFFD1D5DB),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
      
      // Fixed Bottom Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            top: BorderSide(color: Color(0xFFF3F4F6), width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: _primaryTeal.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'আপডেট',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}