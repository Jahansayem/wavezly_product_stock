import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wavezly/app/app_theme.dart';

/// 6 separate OTP input boxes with auto-focus and navigation
class OtpFieldsRow extends StatefulWidget {
  final Function(String) onChanged;
  final Function(String)? onCompleted;

  const OtpFieldsRow({
    super.key,
    required this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpFieldsRow> createState() => _OtpFieldsRowState();
}

class _OtpFieldsRowState extends State<OtpFieldsRow> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Setup listeners for each field
    for (int i = 0; i < 6; i++) {
      _controllers[i].addListener(() => _onFieldChanged(i));
    }

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _onFieldChanged(int index) {
    final value = _controllers[index].text;

    // Ensure only 1 digit
    if (value.length > 1) {
      _controllers[index].text = value[value.length - 1];
      _controllers[index].selection =
          TextSelection.fromPosition(const TextPosition(offset: 1));
    }

    // Auto-focus next field if digit entered
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Notify parent of change
    final otp = _controllers.map((c) => c.text).join();
    widget.onChanged(otp);

    // Notify completion if all 6 digits entered
    if (otp.length == 6 && widget.onCompleted != null) {
      widget.onCompleted!(otp);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    // Handle backspace on empty field
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        // Move to previous field and clear it
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  /// Clear all OTP boxes
  void clear() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return _buildOtpBox(index);
      }),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) => _onKeyEvent(index, event),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(
                color: Color(0xFFFDE047), // yellow-300
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(
                color: Color(0xFFFDE047), // yellow-300
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(
                color: AppTheme.primaryYellow,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
