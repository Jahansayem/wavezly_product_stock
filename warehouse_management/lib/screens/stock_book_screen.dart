import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class StockBookScreen extends StatefulWidget {
  const StockBookScreen({Key? key}) : super(key: key);

  @override
  State<StockBookScreen> createState() => _StockBookScreenState();
}

class _StockBookScreenState extends State<StockBookScreen> {
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
        final displayName = product.nameBn ?? product.name ?? '';
        return displayName.toLowerCase().contains(queryLower);
      }).toList();
    }
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

  int _calculateTotalQuantity(List<Product> products) {
    return products.fold<int>(0, (sum, p) => sum + (p.quantity ?? 0));
  }

  double _calculateTotalValue(List<Product> products) {
    return products.fold<double>(
      0,
      (sum, p) => sum + ((p.quantity ?? 0) * (p.cost ?? 0.0))
    );
  }

  IconData _getIconData(String? iconName) {
    const iconMap = {
      'inventory_2': Icons.inventory_2,
      'water_drop': Icons.water_drop,
      'grape': Icons.apps, // Use closest Material icon
      'apple': Icons.apple,
      'spa': Icons.spa,
      'fastfood': Icons.fastfood,
      'medication': Icons.medication,
    };
    return iconMap[iconName] ?? Icons.inventory_2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: StreamBuilder<List<Product>>(
        stream: _productService.getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D9488)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                  const SizedBox(height: 16),
                  Text('Error loading stock data',
                    style: GoogleFonts.anekBangla(fontSize: 16)),
                ],
              ),
            );
          }

          final products = snapshot.data ?? [];
          _products = products;
          _filterProducts();

          final totalQty = _calculateTotalQuantity(products);
          final totalValue = _calculateTotalValue(products);

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  Text('কোনো পণ্য নেই',
                    style: GoogleFonts.anekBangla(
                      fontSize: 18,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSummaryCards(totalQty, totalValue),
                          const SizedBox(height: 16),
                          _buildSearchRow(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _StockTile(
                          product: _filteredProducts[index],
                          toBengaliNumber: _toBengaliNumber,
                          getIconData: _getIconData,
                        ),
                        childCount: _filteredProducts.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 128), // Bottom padding for action bar
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomActionBar(),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: const Color(0xFF111827),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      flexibleSpace: Container(
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
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'স্টকের হিসাব',
        style: GoogleFonts.anekBangla(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.history, size: 18, color: Color(0xFF111827)),
              const SizedBox(width: 6),
              Text(
                'স্টকের ইতিহাস',
                style: GoogleFonts.anekBangla(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF111827)),
          onPressed: () {
            print('TODO: More options');
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCards(int totalQty, double totalValue) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'মোট মজুদ',
            value: _toBengaliNumber(totalQty.toDouble()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'মজুদ মূল্য',
            value: '${_toBengaliNumber(totalValue)} ৳',
          ),
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.anekBangla(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'পণ্য খোঁজ করুন',
                hintStyle: GoogleFonts.anekBangla(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: InkWell(
            onTap: () {
              print('TODO: Filter options');
            },
            child: Row(
              children: [
                const Icon(Icons.filter_alt, color: Color(0xFF64748B), size: 20),
                const SizedBox(width: 6),
                Text(
                  'ফিল্টার',
                  style: GoogleFonts.anekBangla(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                print('TODO: Update product quantity');
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF0D9488), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('পণ্য সংখ্যা আপডেট করুন',
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D9488),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                print('TODO: Add new product');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xFF0D9488),
                elevation: 4,
                shadowColor: const Color(0xFF0D9488).withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('প্রোডাক্ট যুক্ত করুন',
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF0D9488), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(label,
            style: GoogleFonts.anekBangla(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(value,
            style: GoogleFonts.anekBangla(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D9488),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final Product product;
  final String Function(double) toBengaliNumber;
  final IconData Function(String?) getIconData;

  const _StockTile({
    required this.product,
    required this.toBengaliNumber,
    required this.getIconData,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = product.nameBn ?? product.name ?? '';
    final stockCount = product.quantity ?? 0;
    final totalPrice = stockCount * (product.cost ?? 0.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
          // Icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              getIconData(product.iconName),
              color: const Color(0xFF0D9488),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                  style: GoogleFonts.anekBangla(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text('স্টক সংখ্যা ${toBengaliNumber(stockCount.toDouble())}',
                  style: GoogleFonts.anekBangla(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Price
          Text('${toBengaliNumber(totalPrice)} ৳',
            style: GoogleFonts.anekBangla(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D9488),
            ),
          ),
        ],
      ),
    );
  }
}
