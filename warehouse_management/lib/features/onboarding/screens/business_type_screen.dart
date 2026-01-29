import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/features/auth/widgets/helpline_button.dart';
import 'package:wavezly/features/auth/widgets/primary_button.dart';
import 'package:wavezly/features/onboarding/models/business_info_model.dart';
import 'package:wavezly/features/onboarding/models/business_type_model.dart';
import 'package:wavezly/features/onboarding/models/pin_setup_model.dart';
import 'package:wavezly/features/onboarding/widgets/business_type_tile.dart';
import 'package:wavezly/features/onboarding/widgets/info_banner.dart';
import 'package:wavezly/features/onboarding/widgets/progress_header.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/screens/main_navigation.dart';
import 'package:wavezly/utils/security_helpers.dart';

/// Business Type Selection Screen (Step 3/3)
///
/// Allows users to select their business category from 8 predefined options
/// in a 2-column grid layout.
class BusinessTypeScreen extends StatefulWidget {
  final BusinessInfoModel businessInfo;
  final PinSetupModel pinModel;

  const BusinessTypeScreen({
    super.key,
    required this.businessInfo,
    required this.pinModel,
  });

  @override
  State<BusinessTypeScreen> createState() => _BusinessTypeScreenState();
}

class _BusinessTypeScreenState extends State<BusinessTypeScreen> {
  BusinessType? _selectedType;
  bool _isSubmitting = false;

  // Validation
  bool get _isFormValid => _selectedType != null;

  void _handleTypeSelection(BusinessType type) {
    setState(() {
      _selectedType = type;
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedType == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    // Get current user (declare outside try block for error handling access)
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      setState(() => _isSubmitting = false);
      Fluttertoast.showToast(
        msg: 'ব্যবহারকারী প্রমাণীকৃত নয়',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      // Show loading toast
      Fluttertoast.showToast(
        msg: 'সংরক্ষণ করা হচ্ছে...',
        toastLength: Toast.LENGTH_SHORT,
      );

      // 1. Save business profile (Step 1 data)
      // Delete existing record (if any) then insert fresh
      await SupabaseConfig.client
          .from('user_business_profiles')
          .delete()
          .eq('user_id', user.id);
      await SupabaseConfig.client.from('user_business_profiles').insert({
        'user_id': user.id,
        'shop_name': widget.businessInfo.shopName,
        'age_group': widget.businessInfo.ageGroup.label,
        'referral_code': widget.businessInfo.referralCode?.isEmpty ?? true
            ? null
            : widget.businessInfo.referralCode,
        'terms_accepted': widget.businessInfo.termsAccepted,
        'onboarding_completed_at': DateTime.now().toIso8601String(),
      });

      // 2. Save PIN (Step 2 data) - HASHED!
      final hashedPin = SecurityHelpers.hashPin(widget.pinModel.pin);
      // Delete existing record (if any) then insert fresh
      await SupabaseConfig.client
          .from('user_security')
          .delete()
          .eq('user_id', user.id);
      await SupabaseConfig.client.from('user_security').insert({
        'user_id': user.id,
        'pin_hash': hashedPin,
        'pin_created_at': widget.pinModel.createdAt.toIso8601String(),
      });

      // 3. Update profile with business type (Step 3 data)
      await SupabaseConfig.client.from('profiles').update({
        'business_type': _selectedType!.name,
        'business_type_label': _selectedType!.label,
        'business_type_selected_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Success! Show toast and navigate to main app
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'স্বাগতম! আপনার অ্যাকাউন্ট তৈরি হয়েছে',
          toastLength: Toast.LENGTH_LONG,
        );

        // Navigate to main app (replace entire navigation stack)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    } on PostgrestException catch (e) {
      debugPrint('Supabase error: ${e.message}');
      debugPrint('Error code: ${e.code}');

      if (e.message.contains('duplicate key')) {
        // User might have already completed onboarding
        // Check if profile is complete
        try {
          final profile = await SupabaseConfig.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single();

          if (profile['business_type'] != null) {
            // Already complete - just navigate
            debugPrint('User already completed onboarding, navigating to main');
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigation()),
                (route) => false,
              );
            }
            return;
          }
        } catch (profileError) {
          debugPrint('Error checking profile: $profileError');
        }
      }

      // Show error to user
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'ডেটাবেস ত্রুটি: ${e.message}',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      debugPrint('General error: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'অপ্রত্যাশিত ত্রুটি ঘটেছে',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  void _handleHelpline() {
    Fluttertoast.showToast(
      msg: 'হেল্পলাইন: ০১৭১২-৩৪৫৬৭৮',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button + Helpline button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBackButton(),
                            HelplineButton(onTap: _handleHelpline),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Progress header (3/3)
                        const ProgressHeader(
                          currentStep: 3,
                          totalSteps: 3,
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'আপনার কিসের ব্যবসা?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Hind Siliguri',
                            color: isDark
                                ? Colors.white
                                : ColorPalette.gray900,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Info banner
                        InfoBanner(
                          text: 'আমরা আপনার ব্যবসার ধরন অনুযায়ী হিসাব নিকাশ কাস্টমাইজ করে দিব, যাতে আপনার ব্যবসা আরও ভালোভাবে পরিচালনা করতে পারেন',
                          icon: Icons.info_outline,
                          backgroundColor: const Color(0xFFFFF8D6),
                          borderColor: ColorPalette.yellow100,
                          backgroundColorDark: const Color(0xFF423E2A),
                          borderColorDark:
                              const Color(0xFF713F12).withOpacity(0.3),
                          iconColor: ColorPalette.yellow600,
                          textColor: const Color(0xFF92400E),
                          textColorDark: ColorPalette.gray200,
                        ),
                        const SizedBox(height: 24),

                        // Business type grid
                        _buildBusinessTypeGrid(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Fixed bottom CTA
            _buildBottomCTA(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: _handleBack,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFC72C), // primary yellow
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBusinessTypeGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true, // Important for nested scroll
      physics: const NeverScrollableScrollPhysics(), // Let parent handle scroll
      childAspectRatio: 160 / 112, // width / height approximation
      children: BusinessType.values.map((type) {
        return BusinessTypeTile(
          type: type,
          isSelected: _selectedType == type,
          onTap: () => _handleTypeSelection(type),
        );
      }).toList(),
    );
  }

  Widget _buildBottomCTA(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? ColorPalette.gray800 : ColorPalette.gray200,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: PrimaryButton(
            text: 'এগিয়ে যান',
            enabled: _isFormValid && !_isSubmitting,
            onPressed: _isFormValid && !_isSubmitting ? _handleSubmit : null,
          ),
        ),
      ),
    );
  }
}
