import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StockBookScreenV2 extends StatefulWidget {
  const StockBookScreenV2({super.key});

  @override
  State<StockBookScreenV2> createState() => _StockBookScreenV2State();
}

class _StockBookScreenV2State extends State<StockBookScreenV2> {
  final TextEditingController _searchController = TextEditingController();
  List<StockItem> _filteredItems = [];
  bool _isDarkMode = false;

  final List<StockItem> _allItems = [
    StockItem(
      name: 'Kinley 2L',
      stock: 12,
      price: '৩১২ ৳',
      icon: Icons.inventory_2,
    ),
    StockItem(
      name: 'kinley 500mili',
      stock: 24,
      price: '২৮৮ ৳',
      icon: Icons.water_drop,
    ),
    StockItem(
      name: 'আঙ্গুর',
      stock: 43,
      price: '১১,০২৪.৪ ৳',
      icon: Icons.eco, // Using eco as closest to grape
    ),
    StockItem(
      name: 'আপেল',
      stock: 11,
      price: '১,৩৯৯.২ ৳',
      icon: Icons.apple,
    ),
    StockItem(
      name: 'আম',
      stock: 14,
      price: '৪,০৯৮.৮ ৳',
      icon: Icons.spa,
    ),
    StockItem(
      name: 'বিস্কুট (প্যাকেট)',
      stock: 56,
      price: '১,১২০ ৳',
      icon: Icons.fastfood,
    ),
    StockItem(
      name: 'প্যারাসিটামল ৫০০মিগ্রা',
      stock: 200,
      price: '৪০০ ৳',
      icon: Icons.medication,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems
            .where((item) => item.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0D9488);
    final bgLight = const Color(0xFFF8FAFC);
    final bgDark = const Color(0xFF0F172A);
    final backgroundColor = _isDarkMode ? bgDark : bgLight;
    final cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = _isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final mutedColor = _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.hindSiliguriTextTheme(),
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
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
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
                                color: Colors.white,
                                size: 24,
                              ),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'স্টকের হিসাব',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // History button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
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
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'স্টকের ইতিহাস',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
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
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: ScrollConfiguration(
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
                                value: '১,৪২৪',
                                primaryColor: primaryColor,
                                cardColor: cardColor,
                                mutedColor: mutedColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SummaryCard(
                                label: 'মজুদ মূল্য',
                                value: '১,৭৮,৩৪৪.৭ ৳',
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
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'পণ্য খোঁজ করুন',
                                    hintStyle: GoogleFonts.hindSiliguri(
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
                                        style: GoogleFonts.hindSiliguri(
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
                        // Stock list
                        ..._filteredItems.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: StockTile(
                                item: item,
                                primaryColor: primaryColor,
                                cardColor: cardColor,
                                textColor: textColor,
                                mutedColor: mutedColor,
                                borderColor: borderColor,
                              ),
                            )),
                      ],
                    ),
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
            style: GoogleFonts.hindSiliguri(
              fontSize: 12,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.hindSiliguri(
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

// Helper widget: Stock Tile
class StockTile extends StatelessWidget {
  final StockItem item;
  final Color primaryColor;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;
  final Color borderColor;

  const StockTile({
    super.key,
    required this.item,
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
                item.icon,
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
                    item.name,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'স্টক সংখ্যা ${_convertToBengaliNumber(item.stock)}',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              item.price,
              style: GoogleFonts.hindSiliguri(
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

  String _convertToBengaliNumber(int number) {
    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return number
        .toString()
        .split('')
        .map((digit) => bengaliDigits[int.parse(digit)])
        .join('');
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
                style: GoogleFonts.hindSiliguri(
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
                style: GoogleFonts.hindSiliguri(
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

// Data model
class StockItem {
  final String name;
  final int stock;
  final String price;
  final IconData icon;

  StockItem({
    required this.name,
    required this.stock,
    required this.price,
    required this.icon,
  });
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
