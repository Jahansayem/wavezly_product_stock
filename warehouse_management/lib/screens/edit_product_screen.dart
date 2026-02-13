import 'package:flutter/material.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/widgets/product_form_body.dart';
import 'package:google_fonts/google_fonts.dart';

/// Edit Product Screen - Uses shared ProductFormBody component
class EditProductScreen extends StatefulWidget {
  final Product product;
  final String docID;

  const EditProductScreen({
    Key? key,
    required this.product,
    required this.docID,
  }) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final ProductService _productService = ProductService();
  bool _isSaving = false;

  Future<void> _handleUpdate(ProductFormResult result) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Map ProductFormResult to Product model for update
      final updatedProduct = Product(
        id: widget.docID,
        name: result.name,
        cost: result.purchasePrice ?? result.salePrice,
        quantity: result.stockQty,
        group: result.categoryId,
        description: result.details,
        stockAlertEnabled: result.stockAlertEnabled,
        minStockLevel: result.minStockLevel,
        image: result.imagePaths.isNotEmpty ? result.imagePaths.first : null,
      );

      // Update in database
      await _productService.updateProduct(widget.docID, updatedProduct);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'পণ্য সফলভাবে আপডেট হয়েছে',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: ColorPalette.tealAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Return to previous screen with success result
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'পণ্য আপডেট করতে ব্যর্থ হয়েছে',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.gray100,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isSaving
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ColorPalette.tealAccent,
                      ),
                    )
                  : ProductFormBody(
                      mode: ProductFormMode.edit,
                      initialProduct: widget.product,
                      onSubmit: _handleUpdate,
                    ),
            ),
          ],
        ),
      ),
    );
  }

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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: ColorPalette.gray900),
          ),
          const Expanded(
            child: Text(
              'পণ্য সম্পাদনা করুন',
              style: TextStyle(
                color: ColorPalette.gray900,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // Show help dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('সাহায্য', style: GoogleFonts.anekBangla()),
                  content: Text(
                    'পণ্যের তথ্য পরিবর্তন করুন এবং "আপডেট করুন" বাটনে ক্লিক করুন।',
                    style: GoogleFonts.anekBangla(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('বুঝেছি', style: GoogleFonts.anekBangla()),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.help_outline, color: ColorPalette.gray900),
          ),
        ],
      ),
    );
  }
}
