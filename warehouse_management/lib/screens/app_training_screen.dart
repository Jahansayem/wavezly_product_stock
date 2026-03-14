import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/utils/color_palette.dart';

class AppTrainingScreen extends StatefulWidget {
  const AppTrainingScreen({super.key});

  @override
  State<AppTrainingScreen> createState() => _AppTrainingScreenState();
}

class _AppTrainingScreenState extends State<AppTrainingScreen> {
  static const List<String> _filters = [
    'সব',
    'বেসিক',
    'অ্যাডভান্সড',
    'নতুন ফিচার',
  ];

  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = _filters.first;
  String _searchQuery = '';

  List<_TrainingItem> get _visibleItems {
    final query = _searchQuery.trim();
    return _trainingItems.where((item) {
      final matchesFilter =
          _selectedFilter == 'সব' || item.category == _selectedFilter;
      final matchesSearch = query.isEmpty ||
          item.title.contains(query) ||
          item.subtitle.contains(query);
      return matchesFilter && matchesSearch;
    }).toList(growable: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUnavailableMessage([String? label]) {
    final message = label == null
        ? 'এই ট্রেনিংটি শীঘ্রই চালু হবে।'
        : '$label শীঘ্রই চালু হবে।';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColorPalette.nileBlue,
        content: Text(
          message,
          style: _bodyStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final spacing = width < 360 ? 10.0 : 12.0;
    final cardAspectRatio = width < 360 ? 0.70 : 0.74;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TrainingHeader(onHelpPressed: _showUnavailableMessage),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: _buildSearchField(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 42,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isSelected = filter == _selectedFilter;
                          return _TrainingFilterChip(
                            label: filter,
                            isSelected: isSelected,
                            onTap: () {
                              if (isSelected) return;
                              setState(() => _selectedFilter = filter);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  if (_visibleItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, spacing + 8),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = _visibleItems[index];
                            return _TrainingCard(
                              item: item,
                              onTap: () => _showUnavailableMessage(item.title),
                            );
                          },
                          childCount: _visibleItems.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: cardAspectRatio,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _TrainingBottomNav(),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: _bodyStyle(
          fontSize: 15,
          color: ColorPalette.gray800,
        ),
        decoration: InputDecoration(
          hintText: 'ট্রেনিং ভিডিও খুঁজুন',
          hintStyle: _bodyStyle(
            fontSize: 15,
            color: ColorPalette.gray400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ColorPalette.gray500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ColorPalette.gray500,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: ColorPalette.yellow50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: ColorPalette.orange600,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'কোনো ট্রেনিং পাওয়া যায়নি',
            style: _bodyStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ColorPalette.gray800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'অন্য শব্দ দিয়ে খুঁজে দেখুন বা অন্য ক্যাটাগরি বেছে নিন।',
            style: _bodyStyle(
              color: ColorPalette.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TrainingHeader extends StatelessWidget {
  const _TrainingHeader({required this.onHelpPressed});

  final VoidCallback onHelpPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFACC15),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: ColorPalette.gray900,
            ),
          ),
          Expanded(
            child: Text(
              'অ্যাপ ট্রেনিং',
              style: _bodyStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ColorPalette.gray900,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onHelpPressed,
              icon: const Icon(
                Icons.help_outline_rounded,
                color: ColorPalette.gray900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingFilterChip extends StatelessWidget {
  const _TrainingFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEC5B13) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFFEC5B13) : ColorPalette.gray200,
            ),
          ),
          child: Text(
            label,
            style: _bodyStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : ColorPalette.gray600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({
    required this.item,
    required this.onTap,
  });

  final _TrainingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(item.imageAsset, fit: BoxFit.cover),
                      Container(color: Colors.black.withValues(alpha: 0.22)),
                      Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEC5B13),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.duration,
                            style: _bodyStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _bodyStyle(
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          color: ColorPalette.gray800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _bodyStyle(
                          fontSize: 12,
                          color: ColorPalette.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingBottomNav extends StatelessWidget {
  const _TrainingBottomNav();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: ColorPalette.gray200)),
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Expanded(
              child: _TrainingNavItem(
                icon: Icons.home_rounded,
                label: 'হোম',
              ),
            ),
            Expanded(
              child: _TrainingNavItem(
                icon: Icons.receipt_long_rounded,
                label: 'লেনদেন',
              ),
            ),
            Expanded(
              child: _TrainingNavItem(
                icon: Icons.school_rounded,
                label: 'ট্রেনিং',
                isActive: true,
              ),
            ),
            Expanded(
              child: _TrainingNavItem(
                icon: Icons.menu_rounded,
                label: 'মেনু',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingNavItem extends StatelessWidget {
  const _TrainingNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFFEC5B13) : ColorPalette.gray400;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 3),
        Text(
          label,
          style: _bodyStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TrainingItem {
  const _TrainingItem({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.category,
    required this.imageAsset,
  });

  final String title;
  final String subtitle;
  final String duration;
  final String category;
  final String imageAsset;
}

const List<_TrainingItem> _trainingItems = [
  _TrainingItem(
    title: 'কীভাবে নতুন হিসাব শুরু করবেন',
    subtitle: 'মডিউল ১ • ৫৬টি ভিউ',
    duration: '১০:১৫',
    category: 'বেসিক',
    imageAsset: 'assets/app_training/training_start.png',
  ),
  _TrainingItem(
    title: 'কাস্টমার ও বাকি যোগ করার নিয়ম',
    subtitle: 'মডিউল ২ • ৮২টি ভিউ',
    duration: '০৫:৩০',
    category: 'বেসিক',
    imageAsset: 'assets/app_training/customer_due.png',
  ),
  _TrainingItem(
    title: 'প্রতিদিনের রিপোর্ট দেখার উপায়',
    subtitle: 'মডিউল ৩ • ৪৪টি ভিউ',
    duration: '০৮:৪৫',
    category: 'বেসিক',
    imageAsset: 'assets/app_training/daily_report.png',
  ),
  _TrainingItem(
    title: 'বাকি আদায়ে এসএমএস পাঠানো',
    subtitle: 'মডিউল ৪ • ১২০টি ভিউ',
    duration: '০৪:২০',
    category: 'নতুন ফিচার',
    imageAsset: 'assets/app_training/sms_due.png',
  ),
  _TrainingItem(
    title: 'স্টক ম্যানেজমেন্ট অ্যাডভান্সড টিপস',
    subtitle: 'মডিউল ৫ • ৩০টি ভিউ',
    duration: '১২:০০',
    category: 'অ্যাডভান্সড',
    imageAsset: 'assets/app_training/advanced_stock.png',
  ),
  _TrainingItem(
    title: 'কিউআর কোড পেমেন্ট সেটআপ',
    subtitle: 'মডিউল ৬ • ৯৫টি ভিউ',
    duration: '০৭:১৫',
    category: 'নতুন ফিচার',
    imageAsset: 'assets/app_training/qr_setup.png',
  ),
];

TextStyle _bodyStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w500,
  double? height,
  Color color = ColorPalette.gray700,
}) {
  return GoogleFonts.hindSiliguri(
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color,
  );
}
