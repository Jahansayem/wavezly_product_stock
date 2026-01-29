import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/features/auth/widgets/helpline_button.dart';
import 'package:wavezly/features/auth/widgets/primary_button.dart';
import 'package:wavezly/features/onboarding/models/business_info_model.dart';
import 'package:wavezly/features/onboarding/models/pin_setup_model.dart';
import 'package:wavezly/features/onboarding/screens/business_type_screen.dart';
import 'package:wavezly/features/onboarding/widgets/info_banner.dart';
import 'package:wavezly/features/onboarding/widgets/pin_input_row.dart';
import 'package:wavezly/features/onboarding/widgets/progress_header.dart';
import 'package:wavezly/utils/color_palette.dart';

class PinSetupScreen extends StatefulWidget {
  final BusinessInfoModel businessInfo;

  const PinSetupScreen({
    super.key,
    required this.businessInfo,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  // PIN values
  String _createPin = '';
  String _confirmPin = '';

  // Error state
  bool _hasError = false;
  String? _errorMessage;

  // Validation
  bool get _isFormValid {
    return _createPin.length == 5 &&
        _confirmPin.length == 5 &&
        _createPin == _confirmPin;
  }

  bool get _showError {
    // Show error if confirm PIN is complete but doesn't match
    return _confirmPin.length == 5 && _createPin != _confirmPin;
  }

  void _handleCreatePinChange(String pin) {
    setState(() {
      _createPin = pin;
      _hasError = false;
      _errorMessage = null;
    });
  }

  void _handleConfirmPinChange(String pin) {
    setState(() {
      _confirmPin = pin;

      // Check for mismatch
      if (pin.length == 5 && _createPin != pin) {
        _hasError = true;
        _errorMessage = 'পিন মিলছে না, আবার চেষ্টা করুন';
      } else {
        _hasError = false;
        _errorMessage = null;
      }
    });
  }

  Future<void> _handleSubmit() async {
    final pinModel = PinSetupModel(
      pin: _createPin,
      createdAt: DateTime.now(),
    );

    // Navigate to Step 3: Business Type Selection
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessTypeScreen(
            businessInfo: widget.businessInfo,
            pinModel: pinModel,
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
                                    currentStep: 2,
                                    totalSteps: 3,
                                  ),
                                  const SizedBox(height: 24),
                                  // Title
                                  Text(
                                    'পিন তৈরি করুন',
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
                                    // Info banner
                                    const InfoBanner(
                                      text:
                                          'তথ্য সুরক্ষার জন্য একটি ৫ ডিজিটের পিন সেট করুন',
                                      icon: Icons.lock,
                                    ),
                                    const SizedBox(height: 28),
                                    // Section 1: Create PIN
                                    const Text(
                                      '৫-ডিজিট পিন',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Hind Siliguri',
                                        color: ColorPalette.gray500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    PinInputRow(
                                      onChanged: _handleCreatePinChange,
                                      hasError: false,
                                    ),
                                    const SizedBox(height: 28),
                                    // Section 2: Confirm PIN
                                    const Text(
                                      'পিন নিশ্চিত করুন',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Hind Siliguri',
                                        color: ColorPalette.gray500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    PinInputRow(
                                      onChanged: _handleConfirmPinChange,
                                      hasError: _hasError,
                                    ),
                                    // Error message
                                    if (_showError)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _errorMessage ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Hind Siliguri',
                                            color: ColorPalette.red500,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    // Helper text
                                    if (!_showError)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 8),
                                        child: Text(
                                          'পিন মনে রাখুন, পরবর্তীতে লগ-ইন করতে প্রয়োজন হবে।',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Hind Siliguri',
                                            color: ColorPalette.gray500,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
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
                                  text: 'পরবর্তী',
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
          color: const Color(0xFFFDC800), // Primary yellow from design
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
