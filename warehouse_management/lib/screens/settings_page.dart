import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:wavezly/features/auth/screens/login_screen.dart';
import 'package:wavezly/functions/confirm_dialog.dart';
import 'package:wavezly/models/user_profile.dart';
import 'package:wavezly/screens/cash_counter_screen.dart';
import 'package:wavezly/services/auth_service.dart';
import 'package:wavezly/services/user_service.dart';
import 'package:wavezly/utils/color_palette.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  UserProfile? _currentUser;
  bool _isProfileLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _userService.getCurrentUserProfile();
      if (!mounted) return;
      setState(() {
        _currentUser = profile;
        _isProfileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProfileLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ColorPalette.mandy,
          content: Text(
            'প্রোফাইল তথ্য লোড করা যায়নি।',
            style: _bodyStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  String get _displayName {
    final name = _currentUser?.name.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'হালখাতা ব্যবহারকারী';
  }

  String get _displayRole {
    final role = _currentUser?.role.trim().toUpperCase();
    if (role == 'OWNER') {
      return 'OWNER';
    }
    if (role == 'STAFF') {
      return 'STAFF';
    }
    return 'USER';
  }

  String get _displayPhone {
    final phone = _currentUser?.phone?.trim();
    if (phone != null && phone.isNotEmpty) {
      return phone;
    }
    return 'ফোন নম্বর যোগ করা হয়নি';
  }

  String get _avatarText {
    final name = _displayName.trim();
    if (name.isEmpty) {
      return 'হ';
    }
    return name.characters.first.toUpperCase();
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColorPalette.nileBlue,
        content: Text(
          '$label শীঘ্রই যুক্ত হবে।',
          style: _bodyStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _openCashCounter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (screenContext) => CashCounterScreen(
          onBack: () => Navigator.of(screenContext).pop(),
          onRefresh: () {
            ScaffoldMessenger.of(screenContext).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'ক্যাশ কাউন্টার হিসাব লাইভ আপডেট হয়।',
                  style: _bodyStyle(fontWeight: FontWeight.w600),
                ),
              ),
            );
          },
          onHistory: () {
            ScaffoldMessenger.of(screenContext).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'ক্যাশ কাউন্টার হিস্ট্রি পরে যোগ হবে।',
                  style: _bodyStyle(fontWeight: FontWeight.w600),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    showConfirmDialog(
      context,
      'আপনি কি লগআউট করতে চান?',
      'না',
      'হ্যাঁ',
      () => Navigator.of(context).pop(),
      () async {
        Navigator.of(context).pop();

        if (!mounted) return;

        setState(() => _isLoggingOut = true);

        try {
          await _authService.signOut().timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              throw TimeoutException('Logout request timed out');
            },
          );

          if (!mounted) return;

          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } on TimeoutException {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: ColorPalette.mandy,
              content: Text(
                'লগআউট সময় শেষ হয়েছে। আবার চেষ্টা করুন।',
                style: _bodyStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: ColorPalette.mandy,
              content: Text(
                'লগআউট করা যায়নি। আবার চেষ্টা করুন।',
                style: _bodyStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        } finally {
          if (mounted) {
            setState(() => _isLoggingOut = false);
          }
        }
      },
    );
  }

  List<_SettingsAction> get _appSettings => [
        _SettingsAction(
          label: 'হিসাবী অ্যাপ সেটিংস',
          icon: Icons.phone_android_rounded,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon('অ্যাপ সেটিংস'),
          trailing: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ColorPalette.gray500,
          ),
        ),
        _SettingsAction(
          label: 'ক্যাশ কাউন্টার',
          icon: Icons.calculate_rounded,
          iconColor: ColorPalette.emerald600,
          onTap: _openCashCounter,
        ),
        _SettingsAction(
          label: 'সাবস্ক্রিপশন',
          icon: Icons.workspace_premium_rounded,
          iconColor: ColorPalette.warningAmber,
          onTap: () => _showComingSoon('সাবস্ক্রিপশন'),
        ),
        _SettingsAction(
          label: 'হিসাবী ওয়েব অ্যাপ',
          icon: Icons.language_rounded,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon('ওয়েব অ্যাপ'),
          trailing: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ColorPalette.gray500,
          ),
        ),
        _SettingsAction(
          label: 'অ্যাপ ট্রেনিং',
          icon: Icons.play_circle_outline_rounded,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon('অ্যাপ ট্রেনিং'),
        ),
        const _SettingsAction(
          label: 'ভাষা',
          icon: Icons.translate_rounded,
          iconColor: ColorPalette.blue600,
          trailingText: 'বাংলা',
        ),
        const _SettingsAction(
          label: 'কারেন্সি',
          icon: Icons.currency_exchange_rounded,
          iconColor: ColorPalette.blue600,
          trailingText: 'BDT | ৳',
        ),
        _SettingsAction(
          label: 'বিজনেস কার্ড',
          icon: Icons.badge_outlined,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon('বিজনেস কার্ড'),
        ),
        _SettingsAction(
          label: 'শর্টকাট এড করুন',
          icon: Icons.add_box_outlined,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon('শর্টকাট'),
        ),
      ];

  List<_SettingsAction> get _otherSettings => [
        _SettingsAction(
          label: 'ফিচার অনুরোধ',
          icon: Icons.lightbulb_outline_rounded,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon('ফিচার অনুরোধ'),
        ),
        _SettingsAction(
          label: 'হিসাবী গ্রোথ পার্টনার',
          icon: Icons.groups_2_outlined,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon('গ্রোথ পার্টনার'),
        ),
        _SettingsAction(
          label: 'ফেসবুক কমিউনিটি',
          icon: Icons.facebook_rounded,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon('ফেসবুক কমিউনিটি'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFC107),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'সেটিংস',
              style: _headingStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(),
                  const SizedBox(height: 16),
                  _buildSectionDivider(),
                  const SizedBox(height: 16),
                  _buildProfileStatusCard(),
                  const SizedBox(height: 14),
                  _buildSubscriptionCard(),
                  const SizedBox(height: 14),
                  _buildSwitchShopButton(),
                  const SizedBox(height: 20),
                  _buildSettingsGroup('অ্যাপ সেটিংস', _appSettings),
                  const SizedBox(height: 20),
                  _buildSettingsGroup('অন্যান্য', _otherSettings),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoggingOut ? null : _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF04438),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFF04438),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'লগ আউট',
                        style: _bodyStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoggingOut)
          ColoredBox(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'লগআউট হচ্ছে...',
                    style: _bodyStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileSection() {
    final infoColor =
        _isProfileLoading ? ColorPalette.gray400 : ColorPalette.gray600;

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: ColorPalette.gray200, width: 2),
          ),
          alignment: Alignment.center,
          child: _isProfileLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : Text(
                  _avatarText,
                  style: _headingStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.gray700,
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _headingStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.gray800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _displayRole,
                style: _bodyStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.gray500,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _displayPhone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _bodyStyle(color: infoColor),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: () => _showComingSoon('প্রোফাইল এডিট'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: ColorPalette.blue600),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'এডিট করুন',
            style: _bodyStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ColorPalette.blue600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      height: 4,
      width: double.infinity,
      color: Colors.white,
    );
  }

  Widget _buildProfileStatusCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'প্রোফাইল স্ট্যাটাস:',
                style: _bodyStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '0%',
              style: _bodyStyle(
                fontWeight: FontWeight.w800,
                color: ColorPalette.red600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(
            value: 0,
            minHeight: 6,
            backgroundColor: ColorPalette.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.red500),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ফ্রি বিজনেস কার্ড পেতে প্রোফাইল তথ্য ১০০% সম্পূর্ণ করুন',
          style: _bodyStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorPalette.blue600,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFFBEB),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: ColorPalette.warningAmber,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'সাবস্ক্রিপশন',
                  style: _bodyStyle(fontSize: 12, color: ColorPalette.gray500),
                ),
                const SizedBox(height: 2),
                Text(
                  'তথ্য শীঘ্রই যুক্ত হবে',
                  style: _headingStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.gray800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI ক্রেডিট, SMS এবং প্যাকেজ তথ্য এখানে দেখানো হবে।',
                  style: _bodyStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchShopButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showComingSoon('দোকান পরিবর্তন'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'দোকান পরিবর্তন করুন',
          style: _bodyStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<_SettingsAction> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: _bodyStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ColorPalette.gray500,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Divider(
                thickness: 1,
                height: 1,
                color: ColorPalette.gray300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...actions.map(_buildSettingsTile),
      ],
    );
  }

  Widget _buildSettingsTile(_SettingsAction action) {
    final enabled = action.onTap != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ColorPalette.gray200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: action.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    action.icon,
                    size: 18,
                    color: action.iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action.label,
                    style: _bodyStyle(
                      fontWeight: FontWeight.w700,
                      color:
                          enabled ? ColorPalette.gray700 : ColorPalette.gray600,
                    ),
                  ),
                ),
                if (action.trailingText != null)
                  Text(
                    action.trailingText!,
                    style: _bodyStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.gray400,
                    ),
                  )
                else
                  action.trailing ??
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: ColorPalette.gray400,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsAction {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? trailingText;
  final Widget? trailing;

  const _SettingsAction({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.trailingText,
    this.trailing,
  });
}

TextStyle _headingStyle({
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
}) {
  return GoogleFonts.hindSiliguri(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: 1.1,
  );
}

TextStyle _bodyStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w500,
  Color color = ColorPalette.gray700,
  double? letterSpacing,
}) {
  return GoogleFonts.hindSiliguri(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: 1.2,
  );
}
