import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wavezly/app/app_theme.dart';

/// Combined phone input field with Bangladesh flag prefix
///
/// CRITICAL: Combined input with left prefix + right field
/// Structure:
/// - Outer container with single border
/// - Left prefix: Bangladesh flag circle + "+88" + dropdown icon + divider
/// - Right field: TextField with no border (handled by outer container)
/// - Focus state: Yellow border (1px ring)
class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _isFocused ? AppTheme.primaryYellow : AppTheme.borderGray,
          width: _isFocused ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.softShadow,
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Left prefix section (flag, +88, dropdown)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: AppTheme.spacingInput,
            ),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: AppTheme.borderGray,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bangladesh flag circle
                _buildBangladeshFlag(),
                const SizedBox(width: 8),
                // Country code
                Text(
                  '+88',
                  style: AppTheme.bodyRegular.copyWith(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                // Dropdown icon
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),

          // Right input section
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.phone,
              style: AppTheme.bodyRegular.copyWith(
                fontSize: 15,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11), // 01XXXXXXXXX
              ],
              decoration: InputDecoration(
                hintText: 'মোবাইল নং',
                hintStyle: AppTheme.bodyRegular.copyWith(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: AppTheme.spacingInput,
                ),
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Bangladesh flag as circular icon
  /// Green background with red center dot
  Widget _buildBangladeshFlag() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF006A4E), // Bangladesh green
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFFF42A41), // Bangladesh red
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
