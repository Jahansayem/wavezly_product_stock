import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../utils/number_formatter.dart';

class StockBookScreenV2 extends StatefulWidget {
  const StockBookScreenV2({super.key});

  @override
  State<StockBookScreenV2> createState() => _StockBookScreenV2State();
}

class _StockBookScreenV2State extends State<StockBookScreenV2> {
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  String _searchQuery = '';
  bool _isDarkMode = false;

  // Helper methods
  int _calculateTotalQuantity(List<Product> products) {
    return products.fold<int>(0, (sum, p) => sum + (p.quantity ?? 0));
  }

  double _calculateTotalValue(List<Product> products) {
    return products.fold<double>(
      0,
      (sum, p) => sum + ((p.quantity ?? 0) * (p.cost ?? 0.0))
    );
  }

  String _formatBengaliNumber(double number) {
    return NumberFormatter.formatToBengali(number);
  }

  String _formatPrice(double price) {
    return '${NumberFormatter.formatToBengali(price, decimals: 1)} ৳';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateSearchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchQuery() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ColorPalette.tealAccent;
    final bgLight = ColorPalette.gray100;
    final bgDark = ColorPalette.slate900;
    final backgroundColor = _isDarkMode ? bgDark : bgLight;
    final cardColor = _isDarkMode ? ColorPalette.slate800 : ColorPalette.white;
    final textColor = _isDarkMode ? ColorPalette.slate100 : ColorPalette.slate900;
    final mutedColor = _isDarkMode ? ColorPalette.slate400 : ColorPalette.slate600;
    final borderColor = _isDarkMode ? ColorPalette.slate700 : ColorPalette.slate200;

    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.anekBanglaTextTheme(),
        scaffoldBackgroundColor: backgroundColor,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            Column(
              children: [
                // App Bar
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
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
                  padding: const EdgeInsets.only(
                    top: 40,
                    left: 16,
                    right: 16,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      // Back button and title
                      Expanded(
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                // TODO: Back navigation
                                Navigator.of(context).maybePop();
                              },
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black87,
                                size: 24,
                              ),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'স্টকের হিসাব',
                              style: GoogleFonts.anekBangla(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // History button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: InkWell(
                          onTap: () {
                            // TODO: Navigate to history
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.history,
                                color: Colors.black87,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'স্টকের ইতিহাস',
                                style: GoogleFonts.anekBangla(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // More button
                      IconButton(
                        onPressed: () {
                          // TODO: Show more options
                        },
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.black87,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Scrollable content with StreamBuilder
                Expanded(
                  child: StreamBuilder<List<Product>>(
                    stream: _productService.getAllProducts(),
                    builder: (context, snapshot) {
                      // Loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        );
                      }

                      // Error state
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(
                                'ত্রুটি: ${snapshot.error}',
                                style: GoogleFonts.anekBangla(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Get products and calculate totals
                      final allProducts = snapshot.data ?? [];
                      final filteredProducts = _searchQuery.isEmpty
                          ? allProducts
                          : allProducts.where((p) =>
                              p.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false
                            ).toList();

                      final totalQty = _calculateTotalQuantity(filteredProducts);
                      final totalValue = _calculateTotalValue(filteredProducts);

                      // Empty state
                      if (filteredProducts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: mutedColor),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty ? 'কোনো পণ্য নেই' : 'কোনো পণ্য পাওয়া যায়নি',
                                style: GoogleFonts.anekBangla(
                                  fontSize: 16,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Build content with dynamic data
                      return ScrollConfiguration(
                        behavior: _NoGlowScrollBehavior(),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          children: [
                            // Summary cards
                            Row(
                              children: [
                                Expanded(
                                  child: SummaryCard(
                                    label: 'মোট মজুদ',
                                    value: _formatBengaliNumber(totalQty.toDouble()),
                                    primaryColor: primaryColor,
                                    cardColor: cardColor,
                                    mutedColor: mutedColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SummaryCard(
                                    label: 'মজুদ মূল্য',
                                    value: _formatPrice(totalValue),
                                    primaryColor: primaryColor,
                                    cardColor: cardColor,
                                    mutedColor: mutedColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Search and filter
                            Row(
                              children: [
                                // Search field
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      border: Border.all(color: borderColor),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      style: GoogleFonts.anekBangla(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'পণ্য খোঁজ করুন',
                                        hintStyle: GoogleFonts.anekBangla(
                                          fontSize: 14,
                                          color: mutedColor,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search,
                                          color: mutedColor,
                                          size: 20,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Filter button
                                Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      // TODO: Show filter options
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.filter_alt,
                                            size: 20,
                                            color: textColor.withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'ফিল্টার',
                                            style: GoogleFonts.anekBangla(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: textColor.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Product list
                            ...filteredProducts.map((product) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ProductStockTile(
                                    product: product,
                                    primaryColor: primaryColor,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedColor: mutedColor,
                                    borderColor: borderColor,
                                  ),
                                )),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Bottom action bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomActionBar(
                primaryColor: primaryColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ),
            // Floating theme toggle button
            Positioned(
              right: 16,
              bottom: 96,
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _toggleTheme,
                  icon: Icon(
                    Icons.dark_mode,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget: Summary Card
class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color primaryColor;
  final Color cardColor;
  final Color mutedColor;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.primaryColor,
    required this.cardColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          bottom: BorderSide(
            color: primaryColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.anekBangla(
              fontSize: 12,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.anekBangla(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Helper widget: Product Stock Tile
class ProductStockTile extends StatelessWidget {
  final Product product;
  final Color primaryColor;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;

  const ProductStockTile({
    super.key,
    required this.product,
    required this.primaryColor,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () {
          // TODO: Handle item tap
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? 'Unknown',
                    style: GoogleFonts.anekBangla(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'স্টক সংখ্যা ${NumberFormatter.formatIntToBengali(product.quantity ?? 0)}',
                    style: GoogleFonts.anekBangla(
                      fontSize: 12,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              '${NumberFormatter.formatToBengali(product.cost ?? 0, decimals: 1)} ৳',
              style: GoogleFonts.anekBangla(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget: Bottom Action Bar
class BottomActionBar extends StatelessWidget {
  final Color primaryColor;
  final Color cardColor;
  final Color borderColor;

  const BottomActionBar({
    super.key,
    required this.primaryColor,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Update button (outline)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // TODO: Update stock quantity
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'পণ্য সংখ্যা আপডেট করুন',
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Add product button (filled)
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Add new product
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 4,
                shadowColor: primaryColor.withOpacity(0.3),
              ),
              child: Text(
                'প্রোডাক্ট যুক্ত করুন',
                style: GoogleFonts.anekBangla(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// No glow scroll behavior
class _NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
