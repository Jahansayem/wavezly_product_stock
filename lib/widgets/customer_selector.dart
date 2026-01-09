import 'package:flutter/material.dart';
import 'package:wavezly/utils/color_palette.dart';

class CustomerSelector extends StatelessWidget {
  final String customerName;
  final Function(String) onCustomerChanged;

  const CustomerSelector({
    super.key,
    required this.customerName,
    required this.onCustomerChanged,
  });

  void _showCustomerBottomSheet(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: ColorPalette.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Customer',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.timberGreen,
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  onCustomerChanged('Walk-in Customer');
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: customerName == 'Walk-in Customer'
                        ? ColorPalette.pacificBlue.withOpacity(0.1)
                        : ColorPalette.aquaHaze,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: ColorPalette.pacificBlue,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Walk-in Customer',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          color: ColorPalette.timberGreen,
                        ),
                      ),
                      const Spacer(),
                      if (customerName == 'Walk-in Customer')
                        Icon(
                          Icons.check_circle,
                          color: ColorPalette.pacificBlue,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Or enter custom name',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: ColorPalette.nileBlue,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Customer name',
                  filled: true,
                  fillColor: ColorPalette.aquaHaze,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  color: ColorPalette.timberGreen,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      onCustomerChanged(nameController.text.trim());
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.pacificBlue,
                    foregroundColor: ColorPalette.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCustomerBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ColorPalette.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorPalette.pacificBlue.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              color: ColorPalette.pacificBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              customerName,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: ColorPalette.timberGreen,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: ColorPalette.nileBlue,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
