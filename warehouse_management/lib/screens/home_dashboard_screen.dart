import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wavezly/services/dashboard_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/screens/sales_screen.dart';
import 'package:wavezly/screens/sales_book_screen.dart';
import 'package:wavezly/screens/customers_page.dart';
import 'package:wavezly/screens/settings_page.dart';
import 'package:wavezly/screens/reports_page.dart';
import 'package:wavezly/screens/inventory_screen_wrapper.dart';
import 'package:wavezly/screens/product_list_screen.dart';
import 'package:wavezly/screens/purchase_book_screen.dart';
import 'package:wavezly/screens/stock_book_screen_v2.dart';
import 'package:wavezly/screens/expense_management_screen_v3.dart';
import 'package:wavezly/screens/cashbox_screen_v2.dart';
import 'package:wavezly/screens/user_list_screen_v1.dart';
import 'package:wavezly/screens/select_product_buying_screen.dart';
import 'package:wavezly/screens/notifications_screen.dart';
import 'package:wavezly/services/local_notification_cache_service.dart';
import 'package:wavezly/widgets/gradient_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================================
// Stitch Design Colors - #26A69A primary, Yellow offer banner
// ============================================================================

class HomeDashboardScreen extends StatefulWidget {
  final Function(int)? onNavTap;
  final int? refreshToken;
  final DashboardSummary? initialSummary;
  final String? initialShopName;

  const HomeDashboardScreen({
    Key? key,
    this.onNavTap,
    this.refreshToken,
    this.initialSummary,
    this.initialShopName,
  }) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  DashboardSummary? _summary;
  bool _isLoading = false; // Start with false - we use local-first approach
  bool _isDayView = true;
  String? _shopName;
  int _badgeRefreshToken = 0; // Token to trigger badge refresh

  @override
  void initState() {
    super.initState();

    // Initialize shop name from initial value or preloaded summary
    _shopName = widget.initialShopName ?? widget.initialSummary?.shopName;

    // Priority 1: If preloaded summary exists, use it immediately
    if (widget.initialSummary != null) {
      _summary = widget.initialSummary;
      // Background refresh to get latest data (silent)
      _loadDashboardData(silent: true);
    } else {
      // Priority 2: Try to load from persistent cache for instant render
      _loadFromCacheThenRefresh();
    }
  }

  /// Load from persistent cache first (instant), then refresh from DB/remote.
  /// Always silent - no loading indicator on first paint (local-first approach).
  Future<void> _loadFromCacheThenRefresh() async {
    try {
      // Try persistent cache first
      final cachedSummary = await _dashboardService.getCachedSummary();
      if (cachedSummary != null && mounted) {
        setState(() {
          _summary = cachedSummary;
          if (cachedSummary.shopName != null) {
            _shopName = cachedSummary.shopName;
          }
        });
      }
      // Always do background refresh (silent) - getSummary is offline-first anyway
      _loadDashboardData(silent: true);
    } catch (e) {
      print('Cache load error: $e');
      // Fallback: still do silent load since service is offline-first
      _loadDashboardData(silent: true);
    }
  }

  @override
  void didUpdateWidget(HomeDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload dashboard data when refresh token changes (silent refresh, no loader)
    if (widget.refreshToken != oldWidget.refreshToken) {
      _loadDashboardData(silent: true);
    }
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      // getSummary now uses offline-first approach (returns local immediately)
      final summary = await _dashboardService.getSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
          // Update shop name if available in summary
          if (summary.shopName != null) {
            _shopName = summary.shopName;
          }
        });
      }
    } catch (e) {
      print('Dashboard load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatBengaliNumber(double number) {
    final bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    final intValue = number.abs().toInt();
    final formatted = intValue.toString().split('').map((d) {
      final digit = int.tryParse(d);
      return digit != null ? bengaliDigits[digit] : d;
    }).join('');
    return number < 0 ? '-$formatted' : formatted;
  }

  Future<void> _launchWhatsApp() async {
    final phoneNumber = '8801707346634'; // Bangladesh number
    final whatsappUrl = Uri.parse('https://wa.me/$phoneNumber');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Show error if WhatsApp cannot be opened
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'WhatsApp খুলতে পারছে না। অনুগ্রহ করে নিশ্চিত করুন WhatsApp ইন্সটল করা আছে।',
                style: GoogleFonts.anekBangla(),
              ),
              backgroundColor: ColorPalette.red500,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'একটি সমস্যা হয়েছে: $e',
              style: GoogleFonts.anekBangla(),
            ),
            backgroundColor: ColorPalette.red500,
          ),
        );
      }
    }
  }

  Widget _buildAppBarTitle({String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _shopName ?? 'হালখাতা ম্যানেজার',
          style: GoogleFonts.anekBangla(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.anekBangla(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
          ),
        ],
      ],
    );
  }

  Stream<int> _getUnreadCountStream() {
    final cacheService = LocalNotificationCacheService();
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      try {
        return await cacheService.getUnreadCount();
      } catch (e) {
        return 0;
      }
    }).asyncMap((future) => future);
  }

  List<Widget> _buildAppBarActions() {
    return [
      // Chat icon (WhatsApp style)
      IconButton(
        icon: const Icon(Icons.chat, color: Colors.black87),
        onPressed: _launchWhatsApp,
      ),
      // Notifications with unread count badge
      StreamBuilder<int>(
        key: ValueKey(_badgeRefreshToken), // Force rebuild when token changes
        stream: _getUnreadCountStream(),
        initialData: 0,
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;

          return Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black87),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                  // Refresh badge count after returning
                  if (mounted) {
                    setState(() {
                      _badgeRefreshToken++; // Trigger badge refresh
                    });
                  }
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      // Settings icon
      IconButton(
        icon: const Icon(Icons.settings, color: Colors.black87),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsPage()),
        ),
      ),
      const SizedBox(width: 8), // Right padding
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.gray100, // Stitch: #F3F4F6
      appBar: GradientAppBar(
        title: _buildAppBarTitle(
          subtitle: _summary?.lastBackupTime ?? 'Last sync: Not configured',
        ),
        actions: _buildAppBarActions(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Summary card (no overlap)
              _SummaryCard(
                summary: _summary,
                isLoading: _isLoading,
                isDayView: _isDayView,
                onToggleView: (isDay) {
                  setState(() => _isDayView = isDay);
                },
                formatNumber: _formatBengaliNumber,
              ),
              const SizedBox(height: 16),
              // Yellow Offer banner (Stitch design)
              _OfferBanner(onTap: () {}),
              const SizedBox(height: 16),
              // Section: খাতা সমূহ
              _SectionCard(
                title: 'খাতা সমূহ',
                items: [
                  _GridItemData(
                              icon: Icons.menu_book,
                              label: 'কেনা খাতা',
                              bgColor: ColorPalette.orange100,
                              iconColor: ColorPalette.orange600,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const PurchaseBookScreen())),
                            ),
                            _GridItemData(
                              icon: Icons.receipt_long,
                              label: 'বেচা খাতা',
                              bgColor: ColorPalette.blue100,
                              iconColor: ColorPalette.blue600,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const SalesBookScreen())),
                            ),
                            _GridItemData(
                              icon: Icons.pending_actions,
                              label: 'বাকির খাতা',
                              bgColor: ColorPalette.red100,
                              iconColor: ColorPalette.red600,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const CustomersPage())),
                            ),
                            _GridItemData(
                              icon: Icons.payments,
                              label: 'খরচের খাতা',
                              bgColor: ColorPalette.teal100,
                              iconColor: ColorPalette.teal600,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ExpenseManagementScreenV3())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Section: আপনার ব্যবসার জন্য
                        _SectionCard(
                          title: 'আপনার ব্যবসার জন্য',
                          items: [
                            _GridItemData(
                              icon: Icons.groups,
                              label: 'যোগাযোগ',
                              bgColor: ColorPalette.indigo100,
                              iconColor: ColorPalette.indigo600,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const CustomersPage())),
                            ),
                            _GridItemData(
                              icon: Icons.inventory_2,
                              label: 'প্রোডাক্ট লিস্ট',
                              bgColor: ColorPalette.amber100,
                              iconColor: ColorPalette.amber600,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ProductListScreen())),
                            ),
                            _GridItemData(
                              icon: Icons.warehouse,
                              label: 'স্টকের হিসাব',
                              bgColor: ColorPalette.lime100,
                              iconColor: ColorPalette.lime600,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const StockBookScreenV2())),
                            ),
                            _GridItemData(
                              icon: Icons.analytics,
                              label: 'ব্যবসার রিপোর্ট',
                              bgColor: ColorPalette.sky100,
                              iconColor: ColorPalette.sky600,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ReportsPage())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Section: অন্যান্য (8 items)
                        _SectionCard(
                          title: 'অন্যান্য',
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 24,
                          items: [
                            _GridItemData(
                              icon: Icons.point_of_sale,
                              label: 'ক্যাশবক্স',
                              bgColor: ColorPalette.emerald50,
                              iconColor: ColorPalette.emerald600,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const CashboxScreenV2())),
                            ),
                            _GridItemData(
                              icon: Icons.admin_panel_settings,
                              label: 'অ্যাপ অ্যাক্সেস',
                              bgColor: ColorPalette.purple100,
                              iconColor: ColorPalette.purple600,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const UserListScreenV1())),
                            ),
                            _GridItemData(
                              icon: Icons.campaign,
                              label: 'মার্কেটিং',
                              bgColor: ColorPalette.rose100,
                              iconColor: ColorPalette.rose600,
                              onTap: () {},
                            ),
                            _GridItemData(
                              icon: Icons.smartphone,
                              label: 'টপ আপ',
                              bgColor: ColorPalette.violet100,
                              iconColor: ColorPalette.violet600,
                              onTap: () {},
                            ),
                            _GridItemData(
                              icon: Icons.verified,
                              label: 'ওয়ারেন্টি',
                              bgColor: ColorPalette.fuchsia100,
                              iconColor: ColorPalette.fuchsia600,
                              onTap: () {},
                            ),
                            _GridItemData(
                              icon: Icons.event_busy,
                              label: 'মেয়াদোত্তীর্ণ',
                              bgColor: ColorPalette.red100,
                              iconColor: ColorPalette.red600,
                              onTap: () {},
                            ),
                            _GridItemData(
                              icon: Icons.print,
                              label: 'প্রিন্টার',
                              bgColor: ColorPalette.cyan100,
                              iconColor: ColorPalette.cyan600,
                              onTap: () {},
                            ),
                            _GridItemData(
                              icon: Icons.account_balance_wallet,
                              label: 'পুঁজি',
                              bgColor: ColorPalette.yellow100,
                              iconColor: ColorPalette.yellow600,
                              onTap: () {},
                            ),
                          ],
                        ),
              const SizedBox(height: 16),
              // Support card
              _SupportCard(onLiveChatTap: _launchWhatsApp),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        onPurchaseTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SelectProductBuyingScreen()),
          );
        },
        onHomeTap: () {
          if (widget.onNavTap != null) widget.onNavTap!(1);
        },
        onSellTap: () {
          if (widget.onNavTap != null) widget.onNavTap!(2);
        },
        currentIndex: 1,
      ),
    );
  }
}

// ============================================================================
// SUMMARY CARD WIDGET
// ============================================================================

class _SummaryCard extends StatelessWidget {
  final DashboardSummary? summary;
  final bool isLoading;
  final bool isDayView;
  final Function(bool) onToggleView;
  final String Function(double) formatNumber;

  const _SummaryCard({
    this.summary,
    required this.isLoading,
    required this.isDayView,
    required this.onToggleView,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Row 1: Balance, Today's Sales, Toggle
          IntrinsicHeight(
            child: Row(
              children: [
                // Balance
                Expanded(
                  child: _SummaryItem(
                    label: 'ব্যালেন্স',
                    value: isLoading ? '...' : '${formatNumber(summary?.balance ?? 0)} ৳',
                    valueColor: ColorPalette.red500,
                    isLarge: true,
                  ),
                ),
                _VerticalDivider(),
                // Today's Sales
                Expanded(
                  child: _SummaryItem(
                    label: isDayView ? 'আজকের বিক্রি' : 'এই মাসের বিক্রি',
                    value: isLoading
                        ? '...'
                        : '${formatNumber(isDayView ? (summary?.todaySales ?? 0) : (summary?.monthSales ?? 0))} ৳',
                    valueColor: ColorPalette.tealAccent,
                    isLarge: true,
                  ),
                ),
                _VerticalDivider(),
                // Toggle
                Expanded(
                  child: Center(
                    child: _SegmentedToggle(
                      isDayView: isDayView,
                      onToggle: onToggleView,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: ColorPalette.gray100),
          const SizedBox(height: 16),
          // Row 2: Expenses, Dues, Stock
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: isDayView ? 'আজকের ব্যয়' : 'এই মাসের ব্যয়',
                    value: isLoading
                        ? '...'
                        : '${formatNumber(isDayView ? (summary?.todayExpenses ?? 0) : (summary?.monthExpenses ?? 0))} ৳',
                    valueColor: ColorPalette.red500,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _SummaryItem(
                    label: 'বাকি দিয়েছি',
                    value: isLoading ? '...' : '${formatNumber(summary?.duesGiven ?? 0)} ৳',
                    valueColor: ColorPalette.red500,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _SummaryItem(
                    label: 'স্টক সংখ্যা',
                    value: isLoading ? '...' : formatNumber((summary?.stockCount ?? 0).toDouble()),
                    valueColor: ColorPalette.green500,
                    isLarge: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isLarge;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.anekBangla(
            fontSize: 12,
            color: ColorPalette.slate500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.anekBangla(
            fontSize: isLarge ? 18 : 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: ColorPalette.gray100,
      margin: EdgeInsets.zero,
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  final bool isDayView;
  final Function(bool) onToggle;

  const _SegmentedToggle({
    required this.isDayView,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorPalette.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'দিন',
            isActive: isDayView,
            onTap: () => onToggle(true),
          ),
          _ToggleButton(
            label: 'মাস',
            isActive: !isDayView,
            onTap: () => onToggle(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? ColorPalette.tealAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.anekBangla(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            color: isActive ? Colors.white : ColorPalette.slate500,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// OFFER BANNER WIDGET - YELLOW GRADIENT (Stitch Design)
// ============================================================================

class _OfferBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const _OfferBanner({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [
              ColorPalette.offerYellowStart, // #FBBF24
              ColorPalette.offerYellowEnd,   // #F59E0B
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative celebration icon watermark
            Positioned(
              top: 0,
              right: 0,
              child: Opacity(
                opacity: 0.2,
                child: Icon(
                  Icons.celebration,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OFFER',
                                style: GoogleFonts.anekBangla(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'নতুন বছর উপলক্ষে',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.anekBangla(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '২০২৫৳',
                              style: GoogleFonts.anekBangla(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'ছাড়ে লাইফটাইম প্যাক',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.anekBangla(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Opacity(
                          opacity: 0.8,
                          child: Text(
                            'সাথে থাকছে নিশ্চিত উপহার',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.anekBangla(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // CTA Button - White
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      'ট্যাপ করুন',
                      style: GoogleFonts.anekBangla(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION CARD WIDGET
// ============================================================================

class _GridItemData {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  _GridItemData({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  });
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<_GridItemData> items;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const _SectionCard({
    required this.title,
    required this.items,
    this.crossAxisCount = 4,
    this.mainAxisSpacing = 16.0,
    this.crossAxisSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ColorPalette.gray50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: ColorPalette.gray100),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.anekBangla(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorPalette.gray700,
              ),
            ),
          ),
          // Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: 0.85,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _GridItem(
                  icon: item.icon,
                  label: item.label,
                  bgColor: item.bgColor,
                  iconColor: item.iconColor,
                  onTap: item.onTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _GridItem({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.anekBangla(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: ColorPalette.gray600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SUPPORT CARD WIDGET
// ============================================================================

class _SupportCard extends StatelessWidget {
  final VoidCallback? onLiveChatTap;

  const _SupportCard({this.onLiveChatTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5), // emerald-100
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent,
              color: ColorPalette.emerald600,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'যেকোনো প্রয়োজনে',
                  style: GoogleFonts.anekBangla(
                    fontSize: 12,
                    color: ColorPalette.slate500,
                  ),
                ),
                Text(
                  'এক্সপার্টের কাছ থেকে সহায়তা নিন',
                  style: GoogleFonts.anekBangla(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.gray800,
                  ),
                ),
              ],
            ),
          ),
          // Button
          ElevatedButton(
            onPressed: onLiveChatTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.navBlue, // Blue to match reference design
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 1,
            ),
            child: Text(
              'লাইভ চ্যাট',
              style: GoogleFonts.anekBangla(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOTTOM NAVIGATION BAR WIDGET
// ============================================================================

class _BottomNavBar extends StatelessWidget {
  final VoidCallback? onPurchaseTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onSellTap;
  final int currentIndex;

  const _BottomNavBar({
    this.onPurchaseTap,
    this.onHomeTap,
    this.onSellTap,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: ColorPalette.gray200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  // Left: Purchase (কেনা)
                  Expanded(
                    child: _NavItem(
                      icon: Icons.add_shopping_cart,
                      label: 'কেনা',
                      color: ColorPalette.navOrange, // #F97316
                      isActive: currentIndex == 0,
                      onTap: onPurchaseTap,
                    ),
                  ),
                  // Center: Home with floating button
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Floating circle button
                        Positioned(
                          top: -40,
                          child: GestureDetector(
                            onTap: onHomeTap,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                                border: Border.all(
                                  color: ColorPalette.gray100,
                                  width: 1,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ColorPalette.tealAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.home,
                                  size: 28,
                                  color: ColorPalette.tealAccent, // Stitch: #26A69A
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Label below
                        Positioned(
                          bottom: 8,
                          child: Text(
                            'হোম',
                            style: GoogleFonts.anekBangla(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: ColorPalette.tealAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right: Sell (বেচা)
                  Expanded(
                    child: _NavItem(
                      icon: Icons.sell,
                      label: 'বেচা',
                      color: ColorPalette.navBlue, // #3B82F6
                      isActive: currentIndex == 2,
                      onTap: onSellTap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.anekBangla(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
