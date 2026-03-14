import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/models/product.dart';
import 'package:wavezly/screens/barcode_scanner_screen.dart';
import 'package:wavezly/screens/product_details_screen.dart';
import 'package:wavezly/services/product_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/utils/number_formatter.dart';

enum ExpiryFilterTab { expiringSoon, expired }

class ExpiryHandlingScreen extends StatefulWidget {
  const ExpiryHandlingScreen({super.key});

  @override
  State<ExpiryHandlingScreen> createState() => _ExpiryHandlingScreenState();
}

class _ExpiryHandlingScreenState extends State<ExpiryHandlingScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  ExpiryFilterTab _selectedTab = ExpiryFilterTab.expiringSoon;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<Product?>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    final query = (result.barcode?.isNotEmpty ?? false)
        ? result.barcode!
        : (result.name ?? '');

    setState(() {
      _searchController.text = query;
      _searchQuery = query.trim().toLowerCase();
    });
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  List<Product> _filterProducts(List<Product> products) {
    final today = _startOfToday();
    final query = _searchQuery;

    final filtered = products.where((product) {
      final expiryDate = product.expiryDate;
      if (expiryDate == null) {
        return false;
      }

      final expiryDay = DateTime(
        expiryDate.year,
        expiryDate.month,
        expiryDate.day,
      );
      final daysUntilExpiry = expiryDay.difference(today).inDays;

      final matchesTab = _selectedTab == ExpiryFilterTab.expiringSoon
          ? daysUntilExpiry >= 0 && daysUntilExpiry <= 7
          : daysUntilExpiry < 0;

      if (!matchesTab) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final name = (product.name ?? '').toLowerCase();
      final barcode = (product.barcode ?? '').toLowerCase();
      return name.contains(query) || barcode.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aDate = a.expiryDate ?? DateTime(9999);
      final bDate = b.expiryDate ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });

    return filtered;
  }

  String _formatExpiryDate(DateTime? date) {
    if (date == null) {
      return 'তারিখ নেই';
    }

    final months = <int, String>{
      1: 'জানুয়ারি',
      2: 'ফেব্রুয়ারি',
      3: 'মার্চ',
      4: 'এপ্রিল',
      5: 'মে',
      6: 'জুন',
      7: 'জুলাই',
      8: 'আগস্ট',
      9: 'সেপ্টেম্বর',
      10: 'অক্টোবর',
      11: 'নভেম্বর',
      12: 'ডিসেম্বর',
    };

    return '${NumberFormatter.formatIntToBengali(date.day)} ${months[date.month]}, ${NumberFormatter.formatIntToBengali(date.year)}';
  }

  String _buildDayBadge(DateTime expiryDate) {
    final days = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    ).difference(_startOfToday()).inDays;

    if (days < 0) {
      return 'মেয়াদ শেষ';
    }
    if (days == 0) {
      return 'আজ শেষ';
    }
    if (days == 1) {
      return '১ দিন বাকি';
    }
    return '${NumberFormatter.formatIntToBengali(days)} দিন বাকি';
  }

  Future<void> _openProduct(Product product) async {
    final productId = product.id;
    if (productId == null || productId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'পণ্যের বিস্তারিত দেখা যাচ্ছে না',
            style: GoogleFonts.anekBangla(),
          ),
          backgroundColor: ColorPalette.danger,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          product: product,
          docID: productId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.slate50,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildTabs(),
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _productService.getAllProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !(snapshot.hasData && snapshot.data!.isNotEmpty)) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ColorPalette.warningAmber,
                      ),
                    );
                  }

                  final products = _filterProducts(snapshot.data ?? const []);

                  if (products.isEmpty) {
                    return _EmptyState(
                      isSearching: _searchQuery.isNotEmpty,
                      isExpiredTab: _selectedTab == ExpiryFilterTab.expired,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ExpiryProductCard(
                        product: product,
                        isExpiredTab: _selectedTab == ExpiryFilterTab.expired,
                        dayBadge: _buildDayBadge(product.expiryDate!),
                        expiryLabel: _formatExpiryDate(product.expiryDate),
                        onManage: () => _openProduct(product),
                        onUpdateStock: () => _openProduct(product),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFB300),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A111827),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: ColorPalette.gray900,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'মেয়াদ উত্তীর্ণ পেইজ',
              style: GoogleFonts.anekBangla(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ColorPalette.gray900,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'এখানে শিগগিরই আরও সহায়তা যোগ করা হবে',
                    style: GoogleFonts.anekBangla(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.help_outline),
            color: ColorPalette.gray900,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim().toLowerCase();
          });
        },
        style: GoogleFonts.anekBangla(
          fontSize: 14,
          color: ColorPalette.gray900,
        ),
        decoration: InputDecoration(
          hintText: 'পণ্য খুঁজুন (নাম বা বারকোড)',
          hintStyle: GoogleFonts.anekBangla(
            fontSize: 14,
            color: ColorPalette.gray400,
          ),
          filled: true,
          fillColor: ColorPalette.gray100,
          prefixIcon: const Icon(Icons.search, color: ColorPalette.gray400),
          suffixIcon: IconButton(
            onPressed: _scanBarcode,
            icon: const Icon(
              Icons.qr_code_scanner,
              color: ColorPalette.warningAmber,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final isExpiringSoon = _selectedTab == ExpiryFilterTab.expiringSoon;

    return ColoredBox(
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'মেয়াদ প্রায় শেষ',
              isActive: isExpiringSoon,
              onTap: () {
                setState(() {
                  _selectedTab = ExpiryFilterTab.expiringSoon;
                });
              },
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'মেয়াদোত্তীর্ণ',
              isActive: !isExpiringSoon,
              onTap: () {
                setState(() {
                  _selectedTab = ExpiryFilterTab.expired;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFFFFB300) : ColorPalette.gray200,
              width: isActive ? 3 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.anekBangla(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isActive ? ColorPalette.gray900 : ColorPalette.gray400,
          ),
        ),
      ),
    );
  }
}

class _ExpiryProductCard extends StatelessWidget {
  final Product product;
  final bool isExpiredTab;
  final String dayBadge;
  final String expiryLabel;
  final VoidCallback onManage;
  final VoidCallback onUpdateStock;

  const _ExpiryProductCard({
    required this.product,
    required this.isExpiredTab,
    required this.dayBadge,
    required this.expiryLabel,
    required this.onManage,
    required this.onUpdateStock,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isExpiredTab ? Colors.white : const Color(0xFFFFF7ED);
    final borderColor =
        isExpiredTab ? ColorPalette.gray200 : const Color(0xFFFED7AA);
    final statusColor =
        isExpiredTab ? ColorPalette.red600 : ColorPalette.warningAmber;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductImage(imageUrl: product.image),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name ?? 'নামবিহীন পণ্য',
                            style: GoogleFonts.anekBangla(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ColorPalette.gray900,
                            ),
                          ),
                        ),
                        if (!isExpiredTab) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              dayBadge,
                              style: GoogleFonts.anekBangla(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: ColorPalette.red600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          isExpiredTab ? Icons.event_busy : Icons.event,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'মেয়াদ শেষ হবে: $expiryLabel',
                            style: GoogleFonts.anekBangla(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: ColorPalette.gray500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'বর্তমান স্টক: ${NumberFormatter.formatIntToBengali(product.quantity ?? 0)} পিস',
                          style: GoogleFonts.anekBangla(
                            fontSize: 12,
                            color: ColorPalette.gray500,
                          ),
                        ),
                      ],
                    ),
                    if (product.barcode?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 6),
                      Text(
                        'বারকোড: ${NumberFormatter.englishToBengali(product.barcode!)}',
                        style: GoogleFonts.anekBangla(
                          fontSize: 11,
                          color: ColorPalette.gray400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onUpdateStock,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB45309),
                    backgroundColor: const Color(0xFFFFF7ED),
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'স্টক আপডেট',
                    style: GoogleFonts.anekBangla(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onManage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: ColorPalette.gray900,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'ম্যানেজ',
                    style: GoogleFonts.anekBangla(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          placeholder: (_, __) => _imageFallback(showLoader: true),
          errorWidget: (_, __, ___) => _imageFallback(),
        ),
      );
    }

    return _imageFallback();
  }

  Widget _imageFallback({bool showLoader = false}) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: ColorPalette.gray100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: showLoader
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColorPalette.warningAmber,
                ),
              )
            : const Icon(
                Icons.inventory_2,
                color: ColorPalette.gray400,
                size: 30,
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final bool isExpiredTab;

  const _EmptyState({
    required this.isSearching,
    required this.isExpiredTab,
  });

  @override
  Widget build(BuildContext context) {
    final title = isSearching
        ? 'কোনো পণ্য পাওয়া যায়নি'
        : isExpiredTab
            ? 'মেয়াদোত্তীর্ণ পণ্য নেই'
            : 'মেয়াদ প্রায় শেষ পণ্য নেই';
    final subtitle = isSearching
        ? 'অন্য নাম বা বারকোড দিয়ে খুঁজে দেখুন'
        : isExpiredTab
            ? 'এখনো কোনো পণ্যের মেয়াদ শেষ হয়নি'
            : 'এই মুহূর্তে ঝুঁকিপূর্ণ কোনো পণ্য নেই';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 68,
              color: ColorPalette.gray300,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.anekBangla(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ColorPalette.gray700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.anekBangla(
                fontSize: 13,
                color: ColorPalette.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
