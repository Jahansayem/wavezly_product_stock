import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onQRTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.onQRTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 93,
      decoration: const BoxDecoration(
        color: ColorPalette.white,
        border: Border(
          top: BorderSide(width: 1, color: ColorPalette.geyser),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "Home", 0),
              _buildNavItem(Icons.inventory_2_outlined, "Stock", 1),
              const SizedBox(width: 56),
              _buildNavItem(Icons.people_outline, "Customers", 3),
              _buildNavItem(Icons.settings_outlined, "Settings", 4),
            ],
          ),
          Positioned(
            top: -28,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ColorPalette.pacificBlue,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: ColorPalette.pacificBlue.withOpacity(0.3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: ColorPalette.white,
                  size: 28,
                ),
                onPressed: onQRTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? ColorPalette.pacificBlue
                  : ColorPalette.nileBlue.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontFamily: "Nunito",
                color: isActive
                    ? ColorPalette.pacificBlue
                    : ColorPalette.nileBlue.withOpacity(0.6),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
