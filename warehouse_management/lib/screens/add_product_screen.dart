import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wavezly/utils/color_palette.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum WarrantyUnit { day, month, year }

enum DiscountType { percent, amount }

// ============================================================================
// RESULT MODEL
// ============================================================================

class AddProductResult {
  final String name;
  final double salePrice;
  final int stockQty;
  final double? purchasePrice;
  final String? categoryId;
  final String? subCategoryId;
  final String unit;
  final String? details;
  final bool sellOnline;
  final bool wholesaleEnabled;
  final double? wholesalePrice;
  final int? wholesaleMinQty;
  final bool stockAlertEnabled;
  final int? minStockLevel;
  final bool vatEnabled;
  final double? vatPercent;
  final bool warrantyEnabled;
  final int? warrantyDuration;
  final WarrantyUnit? warrantyUnit;
  final bool discountEnabled;
  final double? discountValue;
  final DiscountType? discountType;
  final List<String> imagePaths;

  AddProductResult({
    required this.name,
    required this.salePrice,
    required this.stockQty,
    this.purchasePrice,
    this.categoryId,
    this.subCategoryId,
    required this.unit,
    this.details,
    required this.sellOnline,
    required this.wholesaleEnabled,
    this.wholesalePrice,
    this.wholesaleMinQty,
    required this.stockAlertEnabled,
    this.minStockLevel,
    required this.vatEnabled,
    this.vatPercent,
    required this.warrantyEnabled,
    this.warrantyDuration,
    this.warrantyUnit,
    required this.discountEnabled,
    this.discountValue,
    this.discountType,
    required this.imagePaths,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'sale_price': salePrice,
        'stock': stockQty,
        'cost': purchasePrice,
        'category_id': categoryId,
        'sub_category_id': subCategoryId,
        'unit': unit,
        'details': details,
        'sell_online': sellOnline,
        'wholesale_enabled': wholesaleEnabled,
        'wholesale_price': wholesalePrice,
        'wholesale_min_qty': wholesaleMinQty,
        'stock_alert_enabled': stockAlertEnabled,
        'min_stock_level': minStockLevel,
        'vat_enabled': vatEnabled,
        'vat_percent': vatPercent,
        'warranty_enabled': warrantyEnabled,
        'warranty_duration': warrantyDuration,
        'warranty_unit': warrantyUnit?.name,
        'discount_enabled': discountEnabled,
        'discount_value': discountValue,
        'discount_type': discountType?.name,
        'images': imagePaths,
      };
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onHelp;
  final VoidCallback? onScanBarcode;
  final String? group; // Pre-selected category/group

  const AddProductScreen({
    Key? key,
    this.onBack,
    this.onHelp,
    this.onScanBarcode,
    this.group,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // Colors
  static const Color primary = ColorPalette.tealAccent;
  static const Color bgLight = ColorPalette.gray100;
  static const Color textDark = ColorPalette.gray900;
  static const Color textMuted = ColorPalette.gray500;
  static const Color borderColor = ColorPalette.gray200;
  static const Color cardBg = Colors.white;
  static const Color toggleBg = ColorPalette.gray50;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // Controllers - Basic Info
  final _nameController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockQtyController = TextEditingController();
  final _purchasePriceController = TextEditingController();

  // Controllers - Advanced Info
  final _detailsController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _wholesaleMinQtyController = TextEditingController();
  final _minStockLevelController = TextEditingController();
  final _vatPercentController = TextEditingController();
  final _warrantyDurationController = TextEditingController();
  final _discountValueController = TextEditingController();

  // Dropdown values
  String? _selectedCategory;
  String? _selectedSubCategory;
  String _selectedUnit = 'ইউনিট';

  // Toggle states
  bool _advancedExpanded = true;
  bool _sellOnline = false;
  bool _wholesaleEnabled = false;
  bool _stockAlertEnabled = false;
  bool _vatEnabled = false;
  bool _warrantyEnabled = false;
  bool _discountEnabled = false;

  // Warranty & Discount dropdowns
  WarrantyUnit _warrantyUnit = WarrantyUnit.day;
  DiscountType _discountType = DiscountType.percent;

  // Images
  final List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill category if group is provided
    if (widget.group != null && widget.group!.isNotEmpty) {
      _selectedCategory = widget.group;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salePriceController.dispose();
    _stockQtyController.dispose();
    _purchasePriceController.dispose();
    _detailsController.dispose();
    _wholesalePriceController.dispose();
    _wholesaleMinQtyController.dispose();
    _minStockLevelController.dispose();
    _vatPercentController.dispose();
    _warrantyDurationController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final result = AddProductResult(
        name: _nameController.text.trim(),
        salePrice: double.tryParse(_salePriceController.text) ?? 0,
        stockQty: int.tryParse(_stockQtyController.text) ?? 0,
        purchasePrice: double.tryParse(_purchasePriceController.text),
        categoryId: _selectedCategory,
        subCategoryId: _selectedSubCategory,
        unit: _selectedUnit,
        details: _detailsController.text.isEmpty ? null : _detailsController.text,
        sellOnline: _sellOnline,
        wholesaleEnabled: _wholesaleEnabled,
        wholesalePrice: _wholesaleEnabled
            ? double.tryParse(_wholesalePriceController.text)
            : null,
        wholesaleMinQty: _wholesaleEnabled
            ? int.tryParse(_wholesaleMinQtyController.text)
            : null,
        stockAlertEnabled: _stockAlertEnabled,
        minStockLevel: _stockAlertEnabled
            ? int.tryParse(_minStockLevelController.text)
            : null,
        vatEnabled: _vatEnabled,
        vatPercent:
            _vatEnabled ? double.tryParse(_vatPercentController.text) : null,
        warrantyEnabled: _warrantyEnabled,
        warrantyDuration: _warrantyEnabled
            ? int.tryParse(_warrantyDurationController.text)
            : null,
        warrantyUnit: _warrantyEnabled ? _warrantyUnit : null,
        discountEnabled: _discountEnabled,
        discountValue: _discountEnabled
            ? double.tryParse(_discountValueController.text)
            : null,
        discountType: _discountEnabled ? _discountType : null,
        imagePaths: _imagePaths,
      );
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBasicInfoCard(),
                          const SizedBox(height: 16),
                          _buildAdvancedInfoCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _buildHeader() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorPalette.offerYellowStart,
            ColorPalette.offerYellowEnd,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: ColorPalette.gray900),
          ),
          const Expanded(
            child: Text(
              'প্রোডাক্ট যুক্ত করুন',
              style: TextStyle(
                color: ColorPalette.gray900,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onHelp ?? () {},
            icon: const Icon(Icons.help_outline, color: ColorPalette.gray900),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BASIC INFO CARD
  // ==========================================================================

  Widget _buildBasicInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabeledTextField(
            label: 'পণ্যের নাম',
            required: true,
            controller: _nameController,
            placeholder: 'পণ্যের নাম লিখুন',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'পণ্যের নাম আবশ্যক';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildLabeledTextField(
            label: 'বিক্রয় মূল্য',
            required: true,
            controller: _salePriceController,
            placeholder: 'বিক্রয় মূল্য লিখুন',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'বিক্রয় মূল্য আবশ্যক';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildLabeledTextField(
            label: 'বর্তমান মজুদ আছে',
            required: false,
            controller: _stockQtyController,
            placeholder: 'স্টকের পরিমাণ লিখুন',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _buildInfoBox(
            'নতুন প্রোডাক্টের ক্ষেত্রে স্টকের পরিমাণ দিন। পূর্বের স্টক থাকলে জিরো পরিমাণ দিয়ে পরবর্তীতে স্টক আপডেট করুন।',
          ),
          const SizedBox(height: 16),
          _buildLabeledTextField(
            label: 'ক্রয়মূল্য',
            required: false,
            controller: _purchasePriceController,
            placeholder: 'ক্রয় মূল্য লিখুন',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          ),
          const SizedBox(height: 16),
          _buildInfoBox(
            'পণ্যের ক্রয়মূল্য না দিলে ব্যবসার লাভ ক্ষতির হিসাব সঠিক ভাবে দেখা যাবে না',
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ADVANCED INFO CARD (ACCORDION)
  // ==========================================================================

  Widget _buildAdvancedInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header button
          InkWell(
            onTap: () => setState(() => _advancedExpanded = !_advancedExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'পণ্যের অ্যাডভান্স তথ্য',
                    style: TextStyle(
                      color: primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Icon(
                    _advancedExpanded ? Icons.expand_less : Icons.expand_more,
                    color: primary,
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _advancedExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdownField(
                          label: 'ক্যাটাগরি',
                          value: _selectedCategory,
                          items: const ['--ক্যাটাগরি--'],
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'সাব ক্যাটাগরি',
                          value: _selectedSubCategory,
                          items: const ['--সাব ক্যাটাগরি--'],
                          onChanged: (v) =>
                              setState(() => _selectedSubCategory = v),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'পণ্যের একক',
                          value: _selectedUnit,
                          items: const ['ইউনিট', 'পিস', 'কেজি', 'লিটার', 'প্যাকেট'],
                          onChanged: (v) =>
                              setState(() => _selectedUnit = v ?? 'ইউনিট'),
                        ),
                        const SizedBox(height: 16),
                        _buildLabeledTextField(
                          label: 'পণ্যের বিস্তারিত',
                          required: false,
                          controller: _detailsController,
                          placeholder: 'পণ্যের বিস্তারিত (না দিলেও হবে)',
                          maxLines: 2,
                          labelColor: textMuted,
                        ),
                        const SizedBox(height: 16),

                        // Toggle: Sell Online
                        _buildToggleBlock(
                          title: 'অনলাইনে বিক্রি করতে চান?',
                          value: _sellOnline,
                          onChanged: (v) => setState(() => _sellOnline = v),
                        ),
                        const SizedBox(height: 12),

                        // Toggle: Wholesale
                        _buildToggleBlock(
                          title: 'পাইকারি বিক্রি করতে চান?',
                          value: _wholesaleEnabled,
                          onChanged: (v) =>
                              setState(() => _wholesaleEnabled = v),
                          expandedContent: _wholesaleEnabled
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: _buildSmallTextField(
                                        label: 'পাইকারি মূল্য',
                                        controller: _wholesalePriceController,
                                        placeholder: 'পাইকারি মূল্য',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSmallTextField(
                                        label: 'ন্যূনতম পরিমাণ',
                                        controller: _wholesaleMinQtyController,
                                        placeholder: 'ন্যূনতম পরিমাণ',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Toggle: Stock Alert
                        _buildToggleBlock(
                          title: 'স্টক কমের এলার্ট?',
                          value: _stockAlertEnabled,
                          onChanged: (v) =>
                              setState(() => _stockAlertEnabled = v),
                          expandedContent: _stockAlertEnabled
                              ? _buildSmallTextField(
                                  label: 'মিনিমাম স্টক লেভেল',
                                  controller: _minStockLevelController,
                                  placeholder: 'মিনিমাম স্টক লেভেল',
                                  keyboardType: TextInputType.number,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Toggle: VAT
                        _buildToggleBlock(
                          title: 'ভ্যাট প্রযোজ্য?',
                          value: _vatEnabled,
                          onChanged: (v) => setState(() => _vatEnabled = v),
                          expandedContent: _vatEnabled
                              ? _buildSmallTextField(
                                  label: 'ভ্যাট %',
                                  controller: _vatPercentController,
                                  placeholder:
                                      '[আপনার দোকানে বিক্রি হওয়া পণ্যের জন্য ভ্যাট শতাংশ (যদি থাকে)]',
                                  keyboardType: TextInputType.number,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Toggle: Warranty
                        _buildToggleBlock(
                          title: 'ওয়ারেন্টি',
                          value: _warrantyEnabled,
                          onChanged: (v) =>
                              setState(() => _warrantyEnabled = v),
                          expandedContent: _warrantyEnabled
                              ? Row(
                                  children: [
                                    Text(
                                      'বিক্রি থেকে শুরু করে',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textMuted,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildMiniTextField(
                                        controller: _warrantyDurationController,
                                        placeholder: 'মেয়াদ',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildPrimaryDropdown(
                                      value: _warrantyUnit,
                                      items: WarrantyUnit.values,
                                      labels: const ['দিন', 'মাস', 'বছর'],
                                      onChanged: (v) =>
                                          setState(() => _warrantyUnit = v!),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Toggle: Discount
                        _buildToggleBlock(
                          title: 'ডিসকাউন্ট',
                          value: _discountEnabled,
                          onChanged: (v) =>
                              setState(() => _discountEnabled = v),
                          expandedContent: _discountEnabled
                              ? Row(
                                  children: [
                                    Text(
                                      'ডিসকাউন্টের পরিমাণ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textMuted,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildMiniTextField(
                                        controller: _discountValueController,
                                        placeholder: 'Discount',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildPrimaryDropdown(
                                      value: _discountType,
                                      items: DiscountType.values,
                                      labels: const ['%', '৳'],
                                      onChanged: (v) =>
                                          setState(() => _discountType = v!),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Product Images
                        _buildImagePickerSection(),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // FOOTER
  // ==========================================================================

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          top: BorderSide(color: borderColor.withOpacity(0.5)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barcode Scan Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: widget.onScanBarcode ?? () {},
                  icon: const Icon(Icons.qr_code_scanner, color: primary),
                  label: const Text(
                    'বারকোড স্ক্যান',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'সেভ করুন',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // HELPER WIDGETS
  // ==========================================================================

  Widget _buildLabeledTextField({
    required String label,
    required bool required,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    Color labelColor = textDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: labelColor,
              fontFamily: 'Nunito',
            ),
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 16,
            color: textDark,
            fontFamily: 'Nunito',
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              fontSize: 16,
              color: textMuted.withOpacity(0.7),
              fontFamily: 'Nunito',
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          cursorColor: primary,
        ),
      ],
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primary.withOpacity(0.4),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: primary,
                fontWeight: FontWeight.w500,
                height: 1.5,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textMuted,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonFormField<String>(
            value: value ?? items.first,
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
            icon: const Icon(Icons.expand_more, color: textMuted),
            dropdownColor: cardBg,
            style: const TextStyle(
              fontSize: 16,
              color: textDark,
              fontFamily: 'Nunito',
            ),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleBlock({
    required String title,
    required bool value,
    required void Function(bool) onChanged,
    Widget? expandedContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: toggleBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textDark,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: primary,
                activeTrackColor: primary.withOpacity(0.5),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFCBD5E1),
              ),
            ],
          ),
          if (expandedContent != null) ...[
            const SizedBox(height: 12),
            expandedContent,
          ],
        ],
      ),
    );
  }

  Widget _buildSmallTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
              : null,
          style: const TextStyle(
            fontSize: 14,
            color: textDark,
            fontFamily: 'Nunito',
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              fontSize: 14,
              color: textMuted.withOpacity(0.7),
              fontFamily: 'Nunito',
            ),
            filled: true,
            fillColor: cardBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
          ),
          cursorColor: primary,
        ),
      ],
    );
  }

  Widget _buildMiniTextField({
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
          : null,
      style: const TextStyle(
        fontSize: 14,
        color: textDark,
        fontFamily: 'Nunito',
      ),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(
          fontSize: 14,
          color: textMuted.withOpacity(0.7),
          fontFamily: 'Nunito',
        ),
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      cursorColor: primary,
    );
  }

  Widget _buildPrimaryDropdown<T>({
    required T value,
    required List<T> items,
    required List<String> labels,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: primary,
          icon: const Icon(Icons.expand_more, color: Colors.white, size: 20),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontFamily: 'Nunito',
          ),
          items: List.generate(
            items.length,
            (i) => DropdownMenuItem(
              value: items[i],
              child: Text(
                labels[i],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'পণ্যের ছবি (সর্বোচ্চ ৫ টি)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textDark,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._imagePaths.map((path) => _buildImageTile(path)),
              if (_imagePaths.length < 5) _buildAddImageTile(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(String path) {
    return GestureDetector(
      onLongPress: () {
        setState(() => _imagePaths.remove(path));
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
          image: DecorationImage(
            image: NetworkImage(path),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildAddImageTile() {
    return GestureDetector(
      onTap: () {
        // TODO: Implement image picker
        // For now, just add a placeholder
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: primary,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: CustomPaint(
          painter: DashedBorderPainter(color: primary),
          child: const Center(
            child: Icon(Icons.add, color: primary, size: 32),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DASHED BORDER PAINTER
// ============================================================================

class DashedBorderPainter extends CustomPainter {
  final Color color;

  DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // The border is already drawn by the Container, this is just for visual effect
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
