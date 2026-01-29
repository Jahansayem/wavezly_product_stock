import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';

class LinkItem {
  final String text;
  final VoidCallback onTap;

  const LinkItem({
    required this.text,
    required this.onTap,
  });
}

class LinkList extends StatelessWidget {
  final List<LinkItem> links;

  const LinkList({
    super.key,
    required this.links,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: links.map((link) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: GestureDetector(
            onTap: link.onTap,
            child: Text(
              link.text,
              style: const TextStyle(
                fontSize: 12,
                color: ColorPalette.blue600,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
