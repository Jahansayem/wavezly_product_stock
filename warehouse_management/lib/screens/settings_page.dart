import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wavezly/config/database_config.dart';
import 'package:wavezly/features/auth/screens/login_screen.dart';
import 'package:wavezly/functions/confirm_dialog.dart';
import 'package:wavezly/localization/app_locale_controller.dart';
import 'package:wavezly/localization/app_strings.dart';
import 'package:wavezly/models/user_profile.dart';
import 'package:wavezly/screens/app_training_screen.dart';
import 'package:wavezly/screens/cash_counter_screen.dart';
import 'package:wavezly/screens/profile_edit_screen.dart';
import 'package:wavezly/services/auth_service.dart';
import 'package:wavezly/services/dashboard_service.dart';
import 'package:wavezly/services/user_service.dart';
import 'package:wavezly/sync/sync_service.dart';
import 'package:wavezly/utils/color_palette.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const String _appLockEnabledKey = 'app_lock_enabled';

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final SyncService _syncService = SyncService();
  final DashboardService _dashboardService = DashboardService();

  UserProfile? _currentUser;
  bool _isProfileLoading = true;
  bool _isLoggingOut = false;
  bool _isHalkhataSettingsExpanded = false;
  bool _isAppLockEnabled = false;
  bool _isBackingUp = false;

  AppStrings get _strings => AppStrings.of(context);
  AppLocaleController get _localeController => AppLocaleController.instance;

  Future<void> _showLanguageSelector() async {
    final strings = _strings;
    final selectedCode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final currentCode = _localeController.languageCode;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.languageSheetTitle,
                  style: _headingStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.gray800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.languageSheetSubtitle,
                  style: _bodyStyle(color: ColorPalette.gray500),
                ),
                const SizedBox(height: 16),
                _buildLanguageOption(
                  context: context,
                  languageCode: 'bn',
                  label: strings.bangla,
                  isSelected: currentCode == 'bn',
                ),
                const SizedBox(height: 12),
                _buildLanguageOption(
                  context: context,
                  languageCode: 'en',
                  label: strings.english,
                  isSelected: currentCode == 'en',
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedCode == null ||
        selectedCode == _localeController.languageCode) {
      return;
    }

    await _localeController.setLanguageCode(selectedCode);
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String languageCode,
    required String label,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(languageCode),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? ColorPalette.blue600 : ColorPalette.gray200,
              width: isSelected ? 1.5 : 1,
            ),
            color: isSelected
                ? ColorPalette.blue600.withValues(alpha: 0.06)
                : Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                Icons.translate_rounded,
                color: isSelected ? ColorPalette.blue600 : ColorPalette.gray500,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: _bodyStyle(
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.gray800,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: ColorPalette.blue600,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_SettingsAction> get _localizedAppSettings => [
        _SettingsAction(
          label: _strings.halkhataAppSettings,
          icon: Icons.phone_android_rounded,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon(_strings.appSettings),
          trailing: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ColorPalette.gray500,
          ),
        ),
        _SettingsAction(
          label: _strings.cashCounter,
          icon: Icons.calculate_rounded,
          iconColor: ColorPalette.emerald600,
          onTap: _openCashCounter,
        ),
        _SettingsAction(
          label: _strings.subscription,
          icon: Icons.workspace_premium_rounded,
          iconColor: ColorPalette.warningAmber,
          onTap: () => _showComingSoon(_strings.subscription),
        ),
        _SettingsAction(
          label: _strings.webApp,
          icon: Icons.language_rounded,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon(_strings.webApp),
          trailing: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ColorPalette.gray500,
          ),
        ),
        _SettingsAction(
          label: _strings.appTraining,
          icon: Icons.play_circle_outline_rounded,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon(_strings.appTraining),
        ),
        _SettingsAction(
          label: _strings.language,
          icon: Icons.translate_rounded,
          iconColor: ColorPalette.blue600,
          onTap: _showLanguageSelector,
          trailingText:
              _strings.currentLanguageLabel(_localeController.languageCode),
        ),
        _SettingsAction(
          label: _strings.currency,
          icon: Icons.currency_exchange_rounded,
          iconColor: ColorPalette.blue600,
          trailingText: 'BDT | ৳',
        ),
        _SettingsAction(
          label: _strings.businessCard,
          icon: Icons.badge_outlined,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon(_strings.businessCard),
        ),
        _SettingsAction(
          label: _strings.addShortcut,
          icon: Icons.add_box_outlined,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon(_strings.addShortcut),
        ),
      ];

  List<_SettingsAction> get _localizedHalkhataAppSettingsMenu => [
        _SettingsAction(
          label: _strings.bkashNagadQr,
          icon: Icons.qr_code_2_rounded,
          iconColor: ColorPalette.gray700,
          onTap: () => _showComingSoon(_strings.bkashNagadQr),
          isNested: true,
        ),
        _SettingsAction(
          label: _strings.customCategory,
          icon: Icons.grid_view_rounded,
          iconColor: ColorPalette.gray700,
          onTap: () => _showComingSoon(_strings.customCategory),
          isNested: true,
        ),
        _SettingsAction(
          label: _strings.decimalPoint,
          icon: Icons.tag_rounded,
          iconColor: ColorPalette.gray700,
          onTap: () => _showComingSoon(_strings.decimalPoint),
          isNested: true,
        ),
        _SettingsAction(
          label: _strings.dataBackup,
          icon: Icons.cloud_upload_rounded,
          iconColor: ColorPalette.gray700,
          onTap: _handleLocalizedDataBackup,
          trailing: _isBackingUp
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          isNested: true,
        ),
        _SettingsAction(
          label: _strings.recycleBin,
          icon: Icons.delete_outline_rounded,
          iconColor: ColorPalette.gray700,
          onTap: () => _showComingSoon(_strings.recycleBin),
          isNested: true,
        ),
        _SettingsAction(
          label: _strings.appLock,
          icon: Icons.lock_outline_rounded,
          iconColor: ColorPalette.gray700,
          onTap: () => _handleLocalizedAppLockToggle(!_isAppLockEnabled),
          trailing: Switch.adaptive(
            value: _isAppLockEnabled,
            activeThumbColor: ColorPalette.blue600,
            onChanged: _handleLocalizedAppLockToggle,
          ),
          isNested: true,
          hideDefaultTrailing: true,
        ),
        _SettingsAction(
          label: _strings.dataDownload,
          subtitle: _strings.dataDownloadSubtitle,
          icon: Icons.file_download_outlined,
          iconColor: ColorPalette.gray700,
          onTap: () => _showComingSoon(_strings.dataDownload),
          isNested: true,
        ),
        _SettingsAction(
          label: _strings.appReset,
          subtitle: _strings.appResetSubtitle,
          icon: Icons.restart_alt_rounded,
          iconColor: ColorPalette.red600,
          onTap: _showLocalizedAppResetConfirmation,
          isNested: true,
          isDestructive: true,
        ),
      ];

  List<_SettingsAction> get _localizedOtherSettings => [
        _SettingsAction(
          label: _strings.featureRequest,
          icon: Icons.lightbulb_outline_rounded,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon(_strings.featureRequest),
        ),
        _SettingsAction(
          label: _strings.growthPartner,
          icon: Icons.groups_2_outlined,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon(_strings.growthPartner),
        ),
        _SettingsAction(
          label: _strings.facebookCommunity,
          icon: Icons.facebook_rounded,
          iconColor: ColorPalette.blue600,
          onTap: () => _showComingSoon(_strings.facebookCommunity),
        ),
      ];

  Future<void> _handleLocalizedAppLockToggle(bool enabled) async {
    final previousValue = _isAppLockEnabled;
    setState(() => _isAppLockEnabled = enabled);

    try {
      await _writeAppSetting(_appLockEnabledKey, enabled ? '1' : '0');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ColorPalette.nileBlue,
          content: Text(
            enabled
                ? _strings.appLockEnabledMessage
                : _strings.appLockDisabledMessage,
            style: _bodyStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAppLockEnabled = previousValue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ColorPalette.mandy,
          content: Text(
            _strings.appLockSaveFailed,
            style: _bodyStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _handleLocalizedDataBackup() async {
    if (_isBackingUp) return;

    final status = await _syncService.getSyncStatus();
    if ((status['is_syncing'] as bool? ?? false) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _strings.backupInProgress,
            style: _bodyStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    setState(() => _isBackingUp = true);
    final result = await _syncService.backupAllData();
    if (!mounted) return;
    setState(() => _isBackingUp = false);

    if (!result.success) {
      final message = result.error == 'Device is offline'
          ? _strings.backupOffline
          : _strings.backupFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ColorPalette.mandy,
          content: Text(
            message,
            style: _bodyStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }

    await _dashboardService.saveLastBackupTime(DateTime.now());
    if (!mounted) return;

    final message = result.syncedCount > 0
        ? _strings.backupSuccessCount(result.syncedCount)
        : _strings.backupSuccessNoChanges;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColorPalette.emerald600,
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

  void _showLocalizedAppResetConfirmation() {
    showConfirmDialog(
      context,
      _strings.resetConfirmation,
      _strings.no,
      _strings.reset,
      () => Navigator.of(context).pop(),
      () async {
        Navigator.of(context).pop();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: ColorPalette.red600,
            content: Text(
              _strings.appResetNotAvailable,
              style: _bodyStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLocalizedLogout() async {
    showConfirmDialog(
      context,
      _strings.logoutConfirmation,
      _strings.no,
      _strings.yes,
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
                _strings.logoutTimeout,
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
                _strings.logoutFailed,
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

  Widget _buildLocalizedProfileSection() {
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
              : _avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _avatarUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, _) => _buildAvatarFallback(),
                        errorWidget: (context, _, __) => _buildAvatarFallback(),
                      ),
                    )
                  : _buildAvatarFallback(),
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
          onPressed: _openProfileEdit,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: ColorPalette.blue600),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            _strings.edit,
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

  Widget _buildLocalizedProfileStatusCard() {
    final completion = _profileCompletion;
    final percentLabel = '${(completion * 100).round()}%';
    final progressColor =
        completion >= 1 ? ColorPalette.emerald600 : ColorPalette.red500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _strings.profileStatus,
                style: _bodyStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              percentLabel,
              style: _bodyStyle(
                fontWeight: FontWeight.w800,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: completion,
            minHeight: 6,
            backgroundColor: ColorPalette.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _strings.completeProfileForCard,
          style: _bodyStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorPalette.blue600,
          ),
        ),
      ],
    );
  }

  Widget _buildLocalizedSubscriptionCard() {
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
                  _strings.subscription,
                  style: _bodyStyle(fontSize: 12, color: ColorPalette.gray500),
                ),
                const SizedBox(height: 2),
                Text(
                  _strings.subscriptionPending,
                  style: _headingStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.gray800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _strings.subscriptionDetail,
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

  Widget _buildLocalizedSwitchShopButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showComingSoon(_strings.switchShop),
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
          _strings.switchShop,
          style: _bodyStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAppPreferences();
  }

  Future<String?> _readAppSetting(String key) async {
    final db = DatabaseConfig.database;
    final result = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> _writeAppSetting(String key, String value) async {
    final db = DatabaseConfig.database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _loadAppPreferences() async {
    try {
      final enabled = await _readAppSetting(_appLockEnabledKey);
      if (!mounted) return;
      setState(() => _isAppLockEnabled = enabled == '1');
    } catch (_) {
      // Keep the default values if preferences cannot be loaded.
    }
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
    return _strings.userFallbackName;
  }

  String get _displayRole {
    final role = _currentUser?.role.trim().toUpperCase();
    if (role == 'OWNER') return 'OWNER';
    if (role == 'STAFF') return 'STAFF';
    return 'USER';
  }

  String get _displayPhone {
    final phone = _currentUser?.phone?.trim();
    if (phone != null && phone.isNotEmpty) {
      return phone;
    }
    return 'ফোন নম্বর যোগ করা হয়নি';
  }

  String get _avatarText {
    final name = _displayName.trim();
    if (name.isEmpty) {
      return 'হ';
    }
    return name.characters.first.toUpperCase();
  }

  String? get _avatarUrl {
    final avatarUrl = _currentUser?.avatarUrl?.trim();
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }
    return avatarUrl;
  }

  double get _profileCompletion {
    final profile = _currentUser;
    if (profile == null) return 0;

    final completedFields = <bool>[
      profile.name.trim().isNotEmpty,
      profile.phone?.trim().isNotEmpty ?? false,
      profile.address?.trim().isNotEmpty ?? false,
      profile.email?.trim().isNotEmpty ?? false,
      profile.birthday != null,
      profile.gender?.trim().isNotEmpty ?? false,
      profile.avatarUrl?.trim().isNotEmpty ?? false,
    ].where((filled) => filled).length;

    return completedFields / 7;
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColorPalette.nileBlue,
        content: Text(
          _strings.comingSoon(label),
          style: _bodyStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _openProfileEdit() async {
    final profile = _currentUser;
    if (_isProfileLoading || profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ColorPalette.mandy,
          content: Text(
            'প্রোফাইল তথ্য এখনো প্রস্তুত নয়।',
            style: _bodyStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(initialProfile: profile),
      ),
    );

    if (updated == true && mounted) {
      await _loadProfile();
    }
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

  Future<void> _openAppTraining() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppTrainingScreen()),
    );
  }

  void _toggleHalkhataSettings() {
    setState(() {
      _isHalkhataSettingsExpanded = !_isHalkhataSettingsExpanded;
    });
  }

  Future<void> _handleAppLockToggle(bool enabled) async {
    final previousValue = _isAppLockEnabled;
    setState(() => _isAppLockEnabled = enabled);

    try {
      await _writeAppSetting(_appLockEnabledKey, enabled ? '1' : '0');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ColorPalette.nileBlue,
          content: Text(
            enabled ? 'অ্যাপ লক চালু করা হয়েছে।' : 'অ্যাপ লক বন্ধ করা হয়েছে।',
            style: _bodyStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAppLockEnabled = previousValue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ColorPalette.mandy,
          content: Text(
            'অ্যাপ লক সেটিংস সংরক্ষণ করা যায়নি।',
            style: _bodyStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _handleDataBackup() async {
    if (_isBackingUp) return;

    final status = await _syncService.getSyncStatus();
    if ((status['is_syncing'] as bool? ?? false) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'ডাটা ব্যাকআপ চলছে। অনুগ্রহ করে অপেক্ষা করুন।',
            style: _bodyStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    setState(() => _isBackingUp = true);
    final result = await _syncService.backupAllData();
    if (!mounted) return;
    setState(() => _isBackingUp = false);

    if (!result.success) {
      final message = result.error == 'Device is offline'
          ? 'ইন্টারনেট সংযোগ ছাড়া ব্যাকআপ করা যাবে না।'
          : 'ডাটা ব্যাকআপ সম্পন্ন করা যায়নি।';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ColorPalette.mandy,
          content: Text(
            message,
            style: _bodyStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }

    await _dashboardService.saveLastBackupTime(DateTime.now());
    if (!mounted) return;

    final message = result.syncedCount > 0
        ? 'ডাটা ব্যাকআপ সম্পন্ন হয়েছে। ${result.syncedCount} টি রেকর্ড সিঙ্ক হয়েছে।'
        : 'ডাটা ব্যাকআপ সম্পন্ন হয়েছে। নতুন কোনো পরিবর্তন ছিল না।';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColorPalette.emerald600,
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

  void _showAppResetConfirmation() {
    showConfirmDialog(
      context,
      'অ্যাপ রিসেট করলে আপনার সকল লোকাল ডাটা মুছে যেতে পারে। আপনি কি নিশ্চিত?',
      'না',
      'রিসেট',
      () => Navigator.of(context).pop(),
      () async {
        Navigator.of(context).pop();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: ColorPalette.red600,
            content: Text(
              'অ্যাপ রিসেট এখনো চালু হয়নি। পরে যুক্ত করা হবে।',
              style: _bodyStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
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
                'লগআউট সময় শেষ হয়েেছে। আবার চেষ্টা করুন।',
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

  List<_SettingsAction> get _halkhataAppSettingsMenu => [
        _SettingsAction(
          label: 'বিকাশ/নগদ কিউ আর',
          icon: Icons.qr_code_2_rounded,
          iconColor: ColorPalette.gray700,
          onTap: () => _showComingSoon('বিকাশ/নগদ কিউ আর'),
          isNested: true,
        ),
        _SettingsAction(
          label: 'কাস্টম ক্যাটাগরি',
          icon: Icons.grid_view_rounded,
          iconColor: ColorPalette.gray700,
          onTap: () => _showComingSoon('কাস্টম ক্যাটাগরি'),
          isNested: true,
        ),
        _SettingsAction(
          label: 'দশমিক পয়েন্ট',
          icon: Icons.tag_rounded,
          iconColor: ColorPalette.gray700,
          onTap: () => _showComingSoon('দশমিক পয়েন্ট'),
          isNested: true,
        ),
        _SettingsAction(
          label: 'ডাটা ব্যাকআপ',
          icon: Icons.cloud_upload_rounded,
          iconColor: ColorPalette.gray700,
          onTap: _handleDataBackup,
          trailing: _isBackingUp
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          isNested: true,
        ),
        _SettingsAction(
          label: 'রিসাইকেল বিন',
          icon: Icons.delete_outline_rounded,
          iconColor: ColorPalette.gray700,
          onTap: () => _showComingSoon('রিসাইকেল বিন'),
          isNested: true,
        ),
        _SettingsAction(
          label: 'অ্যাপ লক',
          icon: Icons.lock_outline_rounded,
          iconColor: ColorPalette.gray700,
          onTap: () => _handleAppLockToggle(!_isAppLockEnabled),
          trailing: Switch.adaptive(
            value: _isAppLockEnabled,
            activeThumbColor: ColorPalette.blue600,
            onChanged: _handleAppLockToggle,
          ),
          isNested: true,
          hideDefaultTrailing: true,
        ),
        _SettingsAction(
          label: 'ডাটা ডাউনলোড',
          subtitle: 'অ্যাপের সকল তথ্য ডাউনলোড',
          icon: Icons.file_download_outlined,
          iconColor: ColorPalette.gray700,
          onTap: () => _showComingSoon('ডাটা ডাউনলোড'),
          isNested: true,
        ),
        _SettingsAction(
          label: 'অ্যাপ রিসেট',
          subtitle: 'রিসেট করলে অ্যাপের সকল তথ্য মুছে যাবে',
          icon: Icons.restart_alt_rounded,
          iconColor: ColorPalette.red600,
          onTap: _showAppResetConfirmation,
          isNested: true,
          isDestructive: true,
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
              _strings.settingsTitle,
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
                  _buildLocalizedProfileSection(),
                  const SizedBox(height: 16),
                  _buildSectionDivider(),
                  const SizedBox(height: 16),
                  _buildLocalizedProfileStatusCard(),
                  const SizedBox(height: 14),
                  _buildLocalizedSubscriptionCard(),
                  const SizedBox(height: 14),
                  _buildLocalizedSwitchShopButton(),
                  const SizedBox(height: 20),
                  _buildSettingsGroup(
                    _strings.appSettingsSection,
                    _localizedAppSettings,
                  ),
                  const SizedBox(height: 20),
                  _buildSettingsGroup(
                    _strings.otherSection,
                    _localizedOtherSettings,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoggingOut ? null : _handleLocalizedLogout,
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
                        _strings.logout,
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
                    _strings.loggingOut,
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
              : _avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _avatarUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, _) => _buildAvatarFallback(),
                        errorWidget: (context, _, __) => _buildAvatarFallback(),
                      ),
                    )
                  : _buildAvatarFallback(),
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
          onPressed: _openProfileEdit,
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

  Widget _buildAvatarFallback() {
    return Text(
      _avatarText,
      style: _headingStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: ColorPalette.gray700,
      ),
    );
  }

  Widget _buildProfileStatusCard() {
    final completion = _profileCompletion;
    final percentLabel = '${(completion * 100).round()}%';
    final progressColor =
        completion >= 1 ? ColorPalette.emerald600 : ColorPalette.red500;

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
              percentLabel,
              style: _bodyStyle(
                fontWeight: FontWeight.w800,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: completion,
            minHeight: 6,
            backgroundColor: ColorPalette.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
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
    final tiles = <Widget>[];
    for (final action in actions) {
      tiles.add(_buildSettingsTile(action));
      if (_isHalkhataSettingsTrigger(action) && _isHalkhataSettingsExpanded) {
        tiles.add(_buildNestedSettingsMenu());
      }
    }

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
        ...tiles,
      ],
    );
  }

  bool _isHalkhataSettingsTrigger(_SettingsAction action) {
    return action.icon == Icons.phone_android_rounded;
  }

  Widget _buildNestedSettingsMenu() {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 2, bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorPalette.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: _localizedHalkhataAppSettingsMenu
            .map(_buildSettingsTile)
            .toList(growable: false),
      ),
    );
  }

  Widget _buildSettingsTile(_SettingsAction action) {
    final enabled = action.onTap != null;
    final isExpandableTrigger = _isHalkhataSettingsTrigger(action);
    final effectiveOnTap = isExpandableTrigger
        ? _toggleHalkhataSettings
        : action.icon == Icons.play_circle_outline_rounded
            ? _openAppTraining
            : action.onTap;
    final tilePadding = action.isNested
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 14);
    final tileBottomPadding = action.isNested ? 8.0 : 10.0;
    final iconBackground = action.isDestructive
        ? ColorPalette.red100
        : action.iconColor.withValues(alpha: 0.12);
    final labelColor = action.isDestructive
        ? ColorPalette.red600
        : enabled
            ? ColorPalette.gray700
            : ColorPalette.gray600;
    final subtitleColor =
        action.isDestructive ? ColorPalette.red500 : ColorPalette.gray500;

    Widget trailingWidget;
    if (isExpandableTrigger) {
      trailingWidget = AnimatedRotation(
        turns: _isHalkhataSettingsExpanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 180),
        child: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: ColorPalette.gray500,
        ),
      );
    } else if (action.trailingText != null) {
      trailingWidget = Text(
        action.trailingText!,
        style: _bodyStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ColorPalette.gray400,
        ),
      );
    } else if (action.trailing != null) {
      trailingWidget = action.trailing!;
    } else if (action.hideDefaultTrailing) {
      trailingWidget = const SizedBox.shrink();
    } else {
      trailingWidget = Icon(
        Icons.arrow_forward_ios_rounded,
        size: action.isNested ? 16 : 14,
        color:
            action.isDestructive ? ColorPalette.red500 : ColorPalette.gray400,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: tileBottomPadding),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: effectiveOnTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: tilePadding,
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
                    color: iconBackground,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.label,
                        style: _bodyStyle(
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                        ),
                      ),
                      if (action.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          action.subtitle!,
                          style: _bodyStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action.trailing != null && action.hideDefaultTrailing)
                  const SizedBox(width: 8),
                trailingWidget,
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
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? trailingText;
  final Widget? trailing;
  final bool isNested;
  final bool isDestructive;
  final bool hideDefaultTrailing;

  const _SettingsAction({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.subtitle,
    this.onTap,
    this.trailingText,
    this.trailing,
    this.isNested = false,
    this.isDestructive = false,
    this.hideDefaultTrailing = false,
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
