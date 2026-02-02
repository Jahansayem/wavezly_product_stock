import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/models/expense_category.dart';
import 'package:wavezly/services/expense_service.dart';
import 'package:wavezly/utils/color_palette.dart';

/// Category Creation Screen - Create custom expense category
class CategoryCreationScreen extends StatefulWidget {
  const CategoryCreationScreen({Key? key}) : super(key: key);

  @override
  State<CategoryCreationScreen> createState() => _CategoryCreationScreenState();
}

class _CategoryCreationScreenState extends State<CategoryCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameBengaliController = TextEditingController();
  final TextEditingController _descriptionBengaliController = TextEditingController();
  final ExpenseService _expenseService = ExpenseService();

  String _selectedIcon = 'category';
  String _selectedIconColor = 'blue600';
  String _selectedBgColor = 'blue100';
  bool _isSaving = false;

  final List<Map<String, String>> _colorPairs = [
    {'icon': 'blue600', 'bg': 'blue100', 'name': 'নীল'},
    {'icon': 'orange600', 'bg': 'orange100', 'name': 'কমলা'},
    {'icon': 'purple600', 'bg': 'purple100', 'name': 'বেগুনি'},
    {'icon': 'emerald600', 'bg': 'emerald100', 'name': 'সবুজ'},
    {'icon': 'red600', 'bg': 'red100', 'name': 'লাল'},
    {'icon': 'teal600', 'bg': 'teal100', 'name': 'টিল'},
    {'icon': 'indigo600', 'bg': 'indigo100', 'name': 'ইন্ডিগো'},
    {'icon': 'amber600', 'bg': 'amber100', 'name': 'অ্যাম্বার'},
  ];

  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'category', 'icon': Icons.category, 'label': 'সাধারণ'},
    {'name': 'shopping_cart', 'icon': Icons.shopping_cart, 'label': 'কেনাকাটা'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'খাবার'},
    {'name': 'local_gas_station', 'icon': Icons.local_gas_station, 'label': 'জ্বালানি'},
    {'name': 'build', 'icon': Icons.build, 'label': 'মেরামত'},
    {'name': 'medical_services', 'icon': Icons.medical_services, 'label': 'চিকিৎসা'},
    {'name': 'school', 'icon': Icons.school, 'label': 'শিক্ষা'},
    {'name': 'phone', 'icon': Icons.phone, 'label': 'ফোন'},
    {'name': 'wifi', 'icon': Icons.wifi, 'label': 'ইন্টারনেট'},
    {'name': 'electric_bolt', 'icon': Icons.electric_bolt, 'label': 'বিদ্যুৎ'},
    {'name': 'water_drop', 'icon': Icons.water_drop, 'label': 'পানি'},
    {'name': 'celebration', 'icon': Icons.celebration, 'label': 'উৎসব'},
  ];

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final category = ExpenseCategory(
        name: _nameBengaliController.text.trim(),
        nameBengali: _nameBengaliController.text.trim(),
        descriptionBengali: _descriptionBengaliController.text.trim().isEmpty
            ? null
            : _descriptionBengaliController.text.trim(),
        iconName: _selectedIcon,
        iconColor: _selectedIconColor,
        bgColor: _selectedBgColor,
      );

      await _expenseService.createCategory(category);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'নতুন খাত সফলভাবে তৈরি হয়েছে',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: ColorPalette.green600,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'সংরক্ষণ করতে সমস্যা হয়েছে: $e',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: ColorPalette.red500,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'blue600':
        return ColorPalette.blue600;
      case 'blue100':
        return ColorPalette.blue100;
      case 'orange600':
        return ColorPalette.orange600;
      case 'orange100':
        return ColorPalette.orange100;
      case 'purple600':
        return ColorPalette.purple600;
      case 'purple100':
        return ColorPalette.purple100;
      case 'emerald600':
        return ColorPalette.emerald600;
      case 'emerald100':
        return ColorPalette.emerald100;
      case 'red600':
        return ColorPalette.red600;
      case 'red100':
        return ColorPalette.red100;
      case 'teal600':
        return ColorPalette.teal600;
      case 'teal100':
        return ColorPalette.teal100;
      case 'indigo600':
        return ColorPalette.indigo600;
      case 'indigo100':
        return ColorPalette.indigo100;
      case 'amber600':
        return ColorPalette.amber600;
      case 'amber100':
        return ColorPalette.amber100;
      default:
        return ColorPalette.blue600;
    }
  }

  IconData _getIconFromName(String iconName) {
    final icon = _iconOptions.firstWhere(
      (i) => i['name'] == iconName,
      orElse: () => _iconOptions[0],
    );
    return icon['icon'] as IconData;
  }

  @override
  void dispose() {
    _nameBengaliController.dispose();
    _descriptionBengaliController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.gray100,
      appBar: AppBar(
        backgroundColor: ColorPalette.expensePrimary,
        elevation: 2,
        title: Text(
          'নতুন খাত তৈরি করুন',
          style: GoogleFonts.anekBangla(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorPalette.gray200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getColorFromName(_selectedBgColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getIconFromName(_selectedIcon),
                        color: _getColorFromName(_selectedIconColor),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameBengaliController.text.isEmpty
                                ? 'খাতের নাম'
                                : _nameBengaliController.text,
                            style: GoogleFonts.anekBangla(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_descriptionBengaliController.text.isNotEmpty)
                            Text(
                              _descriptionBengaliController.text,
                              style: GoogleFonts.anekBangla(
                                fontSize: 12,
                                color: ColorPalette.gray500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              Text(
                'খাতের নাম *',
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.gray700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameBengaliController,
                style: GoogleFonts.anekBangla(fontSize: 16),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'যেমন: অফিস খরচ',
                  hintStyle: GoogleFonts.anekBangla(color: ColorPalette.gray400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ColorPalette.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ColorPalette.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ColorPalette.expensePrimary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'খাতের নাম লিখুন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description field
              Text(
                'বিবরণ (ঐচ্ছিক)',
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.gray700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionBengaliController,
                maxLines: 2,
                style: GoogleFonts.anekBangla(fontSize: 16),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'খাতের বিস্তারিত...',
                  hintStyle: GoogleFonts.anekBangla(color: ColorPalette.gray400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ColorPalette.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ColorPalette.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ColorPalette.expensePrimary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon picker
              Text(
                'আইকন নির্বাচন করুন',
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.gray700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorPalette.gray200),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconOptions.map((iconOption) {
                    final isSelected = _selectedIcon == iconOption['name'];
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = iconOption['name'] as String),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getColorFromName(_selectedBgColor)
                              : ColorPalette.gray50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? _getColorFromName(_selectedIconColor)
                                : ColorPalette.gray200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          iconOption['icon'] as IconData,
                          color: isSelected
                              ? _getColorFromName(_selectedIconColor)
                              : ColorPalette.gray600,
                          size: 24,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Color picker
              Text(
                'রং নির্বাচন করুন',
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.gray700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorPalette.gray200),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorPairs.map((pair) {
                    final isSelected = _selectedIconColor == pair['icon'];
                    return InkWell(
                      onTap: () => setState(() {
                        _selectedIconColor = pair['icon']!;
                        _selectedBgColor = pair['bg']!;
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getColorFromName(pair['bg']!),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? _getColorFromName(pair['icon']!)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getColorFromName(pair['icon']!),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pair['name']!,
                              style: GoogleFonts.anekBangla(
                                fontSize: 10,
                                color: _getColorFromName(pair['icon']!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.expensePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'সংরক্ষণ করুন',
                        style: GoogleFonts.anekBangla(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
