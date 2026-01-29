import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/features/auth/widgets/helpline_button.dart';
import 'package:wavezly/features/auth/widgets/primary_button.dart';
import 'package:wavezly/features/onboarding/widgets/pin_input_row.dart';
import 'package:wavezly/screens/main_navigation.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/utils/security_helpers.dart';

/// PIN Verification Screen for Existing Users
///
/// Displayed after OTP verification for users who have completed onboarding.
/// Verifies user-entered PIN against stored hash in user_security table.
///
/// Features:
/// - 5-digit PIN entry using PinInputRow widget
/// - SHA-256 hash verification via SecurityHelpers
/// - Max 5 attempts before forced logout
/// - Error messages in Bengali
/// - Helpline support button
class PinVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const PinVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;
  int _attemptCount = 0;
  static const maxAttempts = 5;
  bool _hasError = false;

  bool get _isFormValid => _pin.length == 5;

  void _handlePinChange(String pin) {
    setState(() {
      _pin = pin;
      _hasError = false;
      _errorMessage = null;
    });
  }

  void _handlePinComplete(String pin) {
    // Auto-submit when PIN is complete
    if (pin.length == 5) {
      _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Get current user
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get stored PIN hash from user_security table
      final response = await SupabaseConfig.client
          .from('user_security')
          .select('pin_hash')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // PIN not set (edge case - shouldn't happen for completed onboarding)
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'পিন সেটআপ সম্পূর্ণ হয়নি। পুনরায় সাইন ইন করুন';
        });

        // Logout and return to login after delay
        await Future.delayed(const Duration(seconds: 2));
        await _logoutAndReturnToLogin();
        return;
      }

      final storedHash = response['pin_hash'] as String;

      // Verify PIN using SecurityHelpers
      if (SecurityHelpers.verifyPin(_pin, storedHash)) {
        // Success - navigate to main app
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
            (route) => false,
          );
        }
      } else {
        // Failed verification
        _attemptCount++;

        if (_attemptCount >= maxAttempts) {
          // Max attempts reached - logout and return to login
          Fluttertoast.showToast(
            msg: 'অনেকবার ভুল পিন। আবার লগইন করুন',
            toastLength: Toast.LENGTH_LONG,
            backgroundColor: ColorPalette.red500,
            textColor: Colors.white,
          );

          await Future.delayed(const Duration(seconds: 1));
          await _logoutAndReturnToLogin();
        } else {
          // Show error, allow retry
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage =
                'ভুল পিন। আবার চেষ্টা করুন (${maxAttempts - _attemptCount} বার বাকি)';
            _pin = ''; // Clear PIN for retry
          });
        }
      }
    } catch (e) {
      debugPrint('PIN verification error: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'পিন যাচাই করতে সমস্যা হয়েছে। আবার চেষ্টা করুন';
      });
    }
  }

  Future<void> _logoutAndReturnToLogin() async {
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _handleBack() {
    // Return to login screen
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _handleHelpline() {
    Fluttertoast.showToast(
      msg: 'হেল্পলাইন: ০১৭১২-৩৪৫৬৭৮',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  void _handleForgotPin() {
    // TODO: Implement forgot PIN flow
    Fluttertoast.showToast(
      msg: 'পিন রিসেট ফিচার শীঘ্রই আসছে',
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = AppTheme.isTablet(constraints.maxWidth);

            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  color: isTablet ? AppTheme.backgroundGray : const Color(0xFFF8F9FA),
                ),
                child: Center(
                  child: Container(
                    constraints: isTablet
                        ? const BoxConstraints(maxWidth: 420)
                        : null,
                    decoration: isTablet
                        ? BoxDecoration(
                            color: const Color(0xFFF8F9FA),
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
                    child: Column(
                      children: [
                        // Header section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
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
                              // Title
                              Text(
                                'আপনার ৫ ডিজিটের PIN দিয়ে দোকানে প্রবেশ করুন',
                                style: AppTheme.titleBold.copyWith(
                                  fontSize: 20, // text-xl on mobile
                                  height: 1.375, // leading-snug
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32), // mb-8 from title
                        // Form section
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // PIN input label
                                const Text(
                                  'পিন নাম্বার দিন',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Hind Siliguri',
                                    color: Color(0xFF6B7280), // gray-500
                                    fontWeight: FontWeight.w500, // medium
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // PIN input
                                PinInputRow(
                                  key: ValueKey(_attemptCount), // Reset on new attempt
                                  onChanged: _handlePinChange,
                                  onCompleted: _handlePinComplete,
                                  hasError: _hasError,
                                ),
                                // Error message
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Hind Siliguri',
                                        color: ColorPalette.red500,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                // Forgot PIN link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _handleForgotPin,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'পিন ভুলে গেছেন?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Hind Siliguri',
                                        color: Color(0xFFDC2626), // error-light
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bottom CTA button
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: PrimaryButton(
                            text: 'সাইন ইন',
                            enabled: _isFormValid && !_isLoading,
                            isLoading: _isLoading,
                            onPressed: _isFormValid && !_isLoading
                                ? _verifyPin
                                : null,
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
          color: const Color(0xFFFFC838), // Primary yellow #FFC838
          shape: BoxShape.circle, // Perfect circle
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 2),
              blurRadius: 4,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24, // Updated size from 20 to 24
          ),
        ),
      ),
    );
  }
}
