import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';

class TermsCheckboxRow extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool> onChanged;

  const TermsCheckboxRow({
    super.key,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: checked
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.black,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'আমি শর্তাবলী পড়েছি ও গ্রহণ করেছি',
              style: TextStyle(
                fontSize: 14,
                color: ColorPalette.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
