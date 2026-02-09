import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/color_palette.dart';
import 'product_details_screen.dart';
import 'add_product_screen.dart' show AddProductScreen, AddProductResult;
import 'barcode_scanner_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
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
      final queryLower = _searchQuery.toLowerCase();
      _filteredProducts = _products.where((product) {
        final displayName = product.name ?? '';
        return displayName.toLowerCase().contains(queryLower);
      }).toList();
    }
  }

  void _showProductOptions(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: ColorPalette.tealAccent),
              title: Text('সম্পাদনা করুন', style: GoogleFonts.anekBangla()),
              onTap: () async {
                Navigator.pop(context);

                if (product.id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'পণ্য সম্পাদনা করা যাচ্ছে না',
                        style: GoogleFonts.anekBangla(),
                      ),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsScreen(
                      product: product,
                      docID: product.id!,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
              title: Text('মুছে ফেলুন', style: GoogleFonts.anekBangla()),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('নিশ্চিত করুন', style: GoogleFonts.anekBangla()),
                    content: Text('এই পণ্যটি মুছে ফেলতে চান?', style: GoogleFonts.anekBangla()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('না', style: GoogleFonts.anekBangla()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('হ্যাঁ', style: GoogleFonts.anekBangla()),
                      ),
                    ],
                  ),
                );
                if (confirm == true && product.id != null) {
                  await _productService.deleteProduct(product.id!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _toBengaliNumber(double number) {
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return number.toString().split('').map((char) {
      if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
        return bengaliDigits[int.parse(char)];
      }
      return char;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchRow(),
            _buildProductCount(),
            Expanded(
              child: _buildProductList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFBBF24), // amber-400
            Color(0xFFF59E0B), // amber-500
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'পণ্যের তালিকা',
              style: GoogleFonts.anekBangla(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF111827)),
            onPressed: () {
              print('TODO: Generate PDF');
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF111827)),
            onPressed: () {
              print('TODO: Show help');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'অনুসন্ধান করুন...',
                  hintStyle: GoogleFonts.anekBangla(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list, color: ColorPalette.tealAccent),
              onPressed: () {
                print('TODO: Show filter options');
              },
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: ColorPalette.tealAccent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCount() {
    return StreamBuilder<List<Product>>(
      stream: _productService.getAllProducts(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'মোট পণ্য আছে: ${_toBengaliNumber(count.toDouble())}',
              style: GoogleFonts.anekBangla(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorPalette.tealAccent,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<List<Product>>(
      stream: _productService.getAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
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
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(height: 16),
                Text(
                  'পণ্য লোড করতে ত্রুটি হয়েছে',
                  style: GoogleFonts.anekBangla(
                    fontSize: 16,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 16),
                Text(
                  'কোন পণ্য নেই',
                  style: GoogleFonts.anekBangla(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'নতুন পণ্য যুক্ত করতে + বাটনে ক্লিক করুন',
                  style: GoogleFonts.anekBangla(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        }

        _products = products;
        _filterProducts();

        if (_filteredProducts.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 64,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 16),
                Text(
                  'কোন পণ্য পাওয়া যায়নি',
                  style: GoogleFonts.anekBangla(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'অন্য শব্দ দিয়ে খুঁজে দেখুন',
                  style: GoogleFonts.anekBangla(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) => _ProductTile(
            product: _filteredProducts[index],
            onTap: () {
              // TODO: Navigate to ProductDetailsScreen with all required parameters
              _showProductOptions(context, _filteredProducts[index]);
            },
            onMoreTap: () => _showProductOptions(context, _filteredProducts[index]),
          ),
        );
      },
    );
  }

  Widget _buildFAB() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: ColorPalette.tealAccent,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ColorPalette.tealAccent.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            );

            if (result != null && result is AddProductResult) {
              await _handleAddProductResult(result);
            }
          },
          borderRadius: BorderRadius.circular(28),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'প্রোডাক্ত যুক্ত করুন',
                style: GoogleFonts.anekBangla(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddProductResult(AddProductResult result) async {
    try {
      // Map AddProductResult to Product model
      final product = Product(
        name: result.name,
        cost: result.purchasePrice ?? 0,
        quantity: result.stockQty,
        group: result.categoryId,
        description: result.details,
        stockAlertEnabled: result.stockAlertEnabled,
        minStockLevel: result.minStockLevel,
      );

      // Persist to database
      await _productService.addProduct(product);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'পণ্য সফলভাবে যুক্ত হয়েছে',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: ColorPalette.tealAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'পণ্য যুক্ত করতে ব্যর্থ হয়েছে',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.onMoreTap,
  });

  bool _shouldPriceBeRed(Product product) {
    if ((product.quantity ?? 0) < 10) return true;
    if (product.expiryDate != null) {
      final daysUntilExpiry = product.expiryDate!.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 7) return true;
    }
    return false;
  }

  String _toBengaliNumber(double number) {
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return number.toString().split('').map((char) {
      if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
        return bengaliDigits[int.parse(char)];
      }
      return char;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = product.name ?? '';
    final isPriceRed = _shouldPriceBeRed(product);
    final priceColor = isPriceRed ? const Color(0xFFEF4444) : ColorPalette.tealAccent;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                color: const Color(0xFFF0FDFA),
                child: product.image != null && product.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.image!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorPalette.tealAccent,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          color: Color(0xFF94A3B8),
                        ),
                      )
                    : const Icon(
                        Icons.image,
                        color: Color(0xFF94A3B8),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.anekBangla(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_toBengaliNumber(product.cost ?? 0)} ৳',
                    style: GoogleFonts.anekBangla(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: priceColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
              onPressed: onMoreTap,
            ),
          ],
        ),
      ),
    );
  }
}
