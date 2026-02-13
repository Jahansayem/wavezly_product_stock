import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import '../widgets/product_quantity_card.dart';
import '../widgets/search_filter_bar.dart';

/// Screen for bulk updating product quantities with search and filter
/// Follows offline-first architecture with local state tracking
class UpdateProductQuantityScreen extends StatefulWidget {
  const UpdateProductQuantityScreen({super.key});

  @override
  State<UpdateProductQuantityScreen> createState() =>
      _UpdateProductQuantityScreenState();
}

class _UpdateProductQuantityScreenState
    extends State<UpdateProductQuantityScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Track quantity changes as deltas (productId → +/- delta)
  final Map<String, int> _quantityChanges = {};

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text.trim();
        _filterProducts();
      });
    });
  }

  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredProducts = _products.where((product) {
        final name = product.name?.toLowerCase() ?? '';
        final group = product.group?.toLowerCase() ?? '';
        return name.contains(query) || group.contains(query);
      }).toList();
    }
  }

  void _updateQuantity(String productId, int delta) {
    setState(() {
      _quantityChanges[productId] = (_quantityChanges[productId] ?? 0) + delta;
    });
  }

  int _getCurrentQuantity(Product product) {
    final base = product.quantity ?? 0;
    final delta = _quantityChanges[product.id] ?? 0;
    return max(0, base + delta); // Never negative
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ফিল্টার', style: GoogleFonts.anekBangla()),
        content: Text(
          'ফিল্টার ফিচার শীঘ্রই আসছে',
          style: GoogleFonts.anekBangla(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ঠিক আছে', style: GoogleFonts.anekBangla()),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuantityChanges() async {
    if (_quantityChanges.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      for (final entry in _quantityChanges.entries) {
        final productId = entry.key;
        final delta = entry.value;
        final product = _products.firstWhere((p) => p.id == productId);
        final newQuantity = max(0, (product.quantity ?? 0) + delta);
        await _productService.updateProductQuantity(productId, newQuantity);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'পণ্যের সংখ্যা আপডেট হয়েছে',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: ColorPalette.tealAccent,
          ),
        );
        Navigator.pop(context, _quantityChanges);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'আপডেট করতে ব্যর্থ: $e',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: ColorPalette.danger,
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: ColorPalette.gray100,
        body: Column(
          children: [
            _buildHeader(),
            SearchFilterBar(
              searchController: _searchController,
              onFilterTap: _showFilterDialog,
            ),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _productService.getAllProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ColorPalette.tealAccent,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: ColorPalette.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ত্রুটি ঘটেছে',
                            style: GoogleFonts.anekBangla(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.gray900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: GoogleFonts.anekBangla(
                              fontSize: 14,
                              color: ColorPalette.gray500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final products = snapshot.data ?? [];

                  // Update local products list and filter
                  if (_products != products) {
                    _products = products;
                    _filterProducts();
                  }

                  if (_filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty
                                ? Icons.inventory_2_outlined
                                : Icons.search_off,
                            size: 64,
                            color: ColorPalette.slate400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'কোন পণ্য নেই'
                                : 'কোন পণ্য পাওয়া যায়নি',
                            style: GoogleFonts.anekBangla(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: ColorPalette.slate600,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'অন্য শব্দ দিয়ে খুঁজে দেখুন',
                              style: GoogleFonts.anekBangla(
                                fontSize: 14,
                                color: ColorPalette.slate500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ProductQuantityCard(
                        product: product,
                        currentQuantity: _getCurrentQuantity(product),
                        onQuantityChange: (delta) {
                          _updateQuantity(product.id!, delta);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomButton(),
      ),
    );
  }

  Widget _buildHeader() {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      height: topInset + 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorPalette.offerYellowStart,
            ColorPalette.offerYellowEnd,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.only(top: topInset, left: 16, right: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'পণ্য সংখ্যা আপডেট করুন',
              style: GoogleFonts.anekBangla(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: ColorPalette.white,
        border: Border(
          top: BorderSide(color: ColorPalette.gray200),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveQuantityChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPalette.tealAccent,
            foregroundColor: ColorPalette.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            elevation: 0,
            shadowColor: ColorPalette.tealAccent.withOpacity(0.3),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ColorPalette.white,
                  ),
                )
              : Text(
                  'সম্পন্ন করুন',
                  style: GoogleFonts.anekBangla(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
