import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/features/auth/widgets/helpline_button.dart';
import 'package:wavezly/features/auth/widgets/primary_button.dart';
import 'package:wavezly/features/onboarding/models/business_info_model.dart';
import 'package:wavezly/features/onboarding/screens/pin_setup_screen.dart';
import 'package:wavezly/features/onboarding/widgets/age_selector.dart';
import 'package:wavezly/features/onboarding/widgets/labeled_text_field.dart';
import 'package:wavezly/features/onboarding/widgets/link_list.dart';
import 'package:wavezly/features/onboarding/widgets/progress_header.dart';
import 'package:wavezly/features/onboarding/widgets/referral_toggle_field.dart';
import 'package:wavezly/features/onboarding/widgets/terms_checkbox_row.dart';
import 'package:wavezly/utils/color_palette.dart';

class BusinessInfoScreen extends StatefulWidget {
  final String phoneNumber;

  const BusinessInfoScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  // Controllers
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();

  // Form state
  AgeGroup? _selectedAgeGroup;
  bool _referralEnabled = false;
  bool _termsAccepted = true; // Default checked

  // Validation
  bool get _isFormValid {
    return _shopNameController.text.trim().isNotEmpty &&
        _selectedAgeGroup != null &&
        _termsAccepted;
  }

  @override
  void initState() {
    super.initState();
    _shopNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final businessInfo = BusinessInfoModel(
      shopName: _shopNameController.text.trim(),
      ageGroup: _selectedAgeGroup!,
      referralCode:
          _referralEnabled ? _referralCodeController.text.trim() : null,
      termsAccepted: _termsAccepted,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinSetupScreen(
            businessInfo: businessInfo,
          ),
        ),
      );
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

  void _handleTermsLink(String linkType) {
    Fluttertoast.showToast(
      msg: '$linkType খোলা হচ্ছে...',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = AppTheme.isTablet(constraints.maxWidth);

            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  color: isTablet ? AppTheme.backgroundGray : Colors.white,
                ),
                child: Center(
                  child: Container(
                    constraints: isTablet
                        ? const BoxConstraints(maxWidth: 420)
                        : null,
                    decoration: isTablet
                        ? BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(48),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 40,
                                spreadRadius: 0,
                              ),
                            ],
                          )
                        : null,
                    child: Stack(
                      children: [
                        // Main scrollable content
                        Column(
                          children: [
                            // Header section
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Back button + Helpline
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildBackButton(),
                                      HelplineButton(
                                        onTap: _handleHelpline,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Progress header
                                  const ProgressHeader(
                                    currentStep: 1,
                                    totalSteps: 3,
                                  ),
                                  const SizedBox(height: 24),
                                  // Title
                                  Text(
                                    'ব্যবসার তথ্য দিন',
                                    style: AppTheme.titleBold,
                                  ),
                                ],
                              ),
                            ),
                            // Form section
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.only(
                                  left: 24,
                                  right: 24,
                                  bottom: MediaQuery.of(context)
                                          .viewInsets
                                          .bottom +
                                      20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Shop name field
                                    LabeledTextField(
                                      label: 'দোকানের নাম',
                                      placeholder: 'আপনার দোকানের নাম লিখুন',
                                      controller: _shopNameController,
                                      isRequired: true,
                                      enabled: true,
                                    ),
                                    const SizedBox(height: 28),
                                    // Age group label
                                    const Text(
                                      'বয়স',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: ColorPalette.gray500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Age selector
                                    AgeSelector(
                                      selectedAge: _selectedAgeGroup,
                                      onAgeSelected: (age) {
                                        setState(() {
                                          _selectedAgeGroup = age;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 28),
                                    // Referral toggle field
                                    ReferralToggleField(
                                      enabled: _referralEnabled,
                                      controller: _referralCodeController,
                                      onToggle: (value) {
                                        setState(() {
                                          _referralEnabled = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 28),
                                    // Terms checkbox
                                    TermsCheckboxRow(
                                      checked: _termsAccepted,
                                      onChanged: (value) {
                                        setState(() {
                                          _termsAccepted = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    // T&C links
                                    LinkList(
                                      links: [
                                        LinkItem(
                                          text: 'ব্যবহারের শর্তাবলী',
                                          onTap: () =>
                                              _handleTermsLink('ব্যবহারের শর্তাবলী'),
                                        ),
                                        LinkItem(
                                          text: 'গোপনীয়তা নীতি',
                                          onTap: () =>
                                              _handleTermsLink('গোপনীয়তা নীতি'),
                                        ),
                                        LinkItem(
                                          text: 'রিফান্ড নীতি',
                                          onTap: () =>
                                              _handleTermsLink('রিফান্ড নীতি'),
                                        ),
                                      ],
                                    ),
                                    // Extra spacing for CTA overlay
                                    const SizedBox(height: 120),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Bottom CTA overlay
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white,
                                ],
                                stops: const [0.0, 0.3],
                              ),
                            ),
                            child: Column(
                              children: [
                                PrimaryButton(
                                  text: 'এগিয়ে যান',
                                  enabled: _isFormValid,
                                  onPressed: _isFormValid ? _handleSubmit : null,
                                ),
                                const SizedBox(height: 24),
                                // Home indicator bar
                                Container(
                                  width: 100,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: ColorPalette.gray300,
                                    borderRadius: BorderRadius.circular(9999),
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _handleBack,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFFCF33),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 20,
          ),
        ),
      ),
    );
  }
}
