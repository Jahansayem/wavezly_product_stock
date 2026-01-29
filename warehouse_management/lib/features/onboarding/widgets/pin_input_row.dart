import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/color_palette.dart';

/// 5 separate PIN input boxes with auto-focus, navigation, and paste support
class PinInputRow extends StatefulWidget {
  final Function(String) onChanged;
  final Function(String)? onCompleted;
  final bool hasError;

  const PinInputRow({
    super.key,
    required this.onChanged,
    this.onCompleted,
    this.hasError = false,
  });

  @override
  State<PinInputRow> createState() => _PinInputRowState();
}

class _PinInputRowState extends State<PinInputRow> {
  final List<TextEditingController> _controllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Setup listeners for each field
    for (int i = 0; i < 5; i++) {
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

    // Handle paste operation
    if (value.length > 1) {
      _handlePaste(index, value);
      return;
    }

    // Auto-focus next field if digit entered
    if (value.isNotEmpty && index < 4) {
      _focusNodes[index + 1].requestFocus();
    }

    // Notify parent of change
    final pin = _controllers.map((c) => c.text).join();
    widget.onChanged(pin);

    // Notify completion if all 5 digits entered
    if (pin.length == 5 && widget.onCompleted != null) {
      widget.onCompleted!(pin);
    }
  }

  void _handlePaste(int startIndex, String pastedText) {
    // Filter to only digits
    final digits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');

    // Distribute across fields starting from startIndex
    for (int i = 0; i < digits.length && (startIndex + i) < 5; i++) {
      _controllers[startIndex + i].text = digits[i];
    }

    // Focus last filled field or stay at current if paste didn't fill everything
    final lastIndex = (startIndex + digits.length - 1).clamp(0, 4);
    if (mounted) {
      _focusNodes[lastIndex].requestFocus();
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

  /// Clear all PIN boxes
  void clear() {
    for (var controller in _controllers) {
      controller.clear();
    }
    if (mounted) {
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return Expanded(
          child: index > 0
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildPinBox(index),
                )
              : _buildPinBox(index),
        );
      }),
    );
  }

  Widget _buildPinBox(int index) {
    return AspectRatio(
      aspectRatio: 1.0, // Perfect square
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ColorPalette.gray900,
            fontFamily: 'Hind Siliguri',
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.hasError ? ColorPalette.red500 : ColorPalette.gray300,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.hasError ? ColorPalette.red500 : ColorPalette.gray300,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFFC838), // Updated primary yellow
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
