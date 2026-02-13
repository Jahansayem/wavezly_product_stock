import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/features/auth/models/auth_flow_type.dart';
import 'package:wavezly/features/auth/widgets/primary_button.dart';
import 'package:wavezly/features/auth/widgets/helpline_button.dart';
import 'package:wavezly/features/auth/widgets/promo_card.dart';
import 'package:wavezly/features/auth/widgets/otp_fields_row.dart';
import 'package:wavezly/features/auth/widgets/bottom_toast.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/services/sms_service.dart';
import 'package:wavezly/utils/color_palette.dart';
import 'package:wavezly/features/onboarding/screens/business_info_screen.dart';
import 'package:wavezly/features/auth/screens/pin_verification_screen.dart';
import 'package:wavezly/features/onboarding/screens/pin_setup_screen.dart';

/// OTP Verification Screen
///
/// Verifies the OTP code sent to the user's phone number
/// Features:
/// - 6-digit OTP input
/// - Resend with 30s countdown
/// - Phone number editing
/// - Error handling
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final AppAuthFlowType flowType;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.flowType =
        AppAuthFlowType.signup, // Default preserves existing behavior
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final SmsService _smsService = SmsService();

  String _currentOtp = '';
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 179; // 2:59
  Timer? _resendTimer;
  String? _errorMessage;
  bool _showToast = true;

  @override
  void initState() {
    super.initState();

    // Debug verification logs
    debugPrint('╔═══════════════════════════════════════════════════╗');
    debugPrint('║ ✅ OPENED CORRECT OTP VERIFICATION SCREEN        ║');
    debugPrint('║ Phone: ${widget.phoneNumber}                      ║');
    debugPrint('║ Screen: OtpVerificationScreen                    ║');
    debugPrint('║ File: otp_verification_screen.dart               ║');
    debugPrint('╚═══════════════════════════════════════════════════╝');

    _startResendTimer();

    // Auto-hide toast after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showToast = false);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 179;
    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _currentOtp = '';
    });

    try {
      // Generate and send new OTP
      final otp = _smsService.generateOTP();
      final response = await _smsService.sendOTP(widget.phoneNumber, otp);

      if (response.success) {
        setState(() {
          _showToast = true;
        });

        // Auto-hide toast after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _showToast = false);
          }
        });

        _startResendTimer();
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'নতুন কোড পাঠাতে সমস্যা: $e';
      });
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _handleVerify() async {
    if (_currentOtp.length != 6) {
      setState(() {
        _errorMessage = '৬ ডিজিটের কোড দিন';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final isValid =
          await _smsService.verifyOTP(widget.phoneNumber, _currentOtp);

      if (isValid) {
        // OTP verified - now handle auth based on flow type
        if (widget.flowType == AppAuthFlowType.forgotPin) {
          // FORGOT PIN FLOW: Only sign in (user must already exist)
          await _handleForgotPinAuth();
        } else {
          // SIGNUP/LOGIN FLOW: Try sign in, then sign up if needed
          await _handleSignupLoginAuth();
        }
      } else {
        setState(() {
          _errorMessage = 'ভুল বা মেয়াদ শেষ কোড';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'যাচাই ব্যর্থ: $e';
      });
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  /// Handle auth for forgot PIN flow (existing user only)
  Future<void> _handleForgotPinAuth() async {
    try {
      final supabase = SupabaseConfig.client;
      final email =
          'phone-${widget.phoneNumber}@halkhata.app'; // lowercase 'phone-'
      final newPassword =
          _generateSecurePassword(widget.phoneNumber, _currentOtp);

      debugPrint('🔄 Forgot PIN: Resetting password for $email');

      // Step 1: Reset password using RPC function (requires OTP verification first)
      final result =
          await supabase.rpc('reset_user_password_by_phone', params: {
        'user_phone': widget.phoneNumber,
        'new_password': newPassword,
      });

      // Check if password reset was successful
      if (result == null || result['success'] != true) {
        final error = result?['error'] ?? 'Password reset failed';
        throw Exception(error);
      }

      debugPrint('✅ Forgot PIN: Password reset successful');

      // Step 2: Sign in with new password
      await supabase.auth.signInWithPassword(
        email: email,
        password: newPassword,
      );

      debugPrint('✅ Forgot PIN: Sign in successful');

      // Verify session
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Failed to create auth session');
      }

      debugPrint('✅ Auth session created for user: ${currentUser.id}');

      // Navigate to PIN setup (reset mode)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PinSetupScreen(
              phoneNumber: widget.phoneNumber,
              flowType: AppAuthFlowType.forgotPin,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Forgot PIN auth error: $e');
      setState(() {
        _errorMessage = 'লগইন করতে সমস্যা হয়েছে। আবার চেষ্টা করুন';
      });
    }
  }

  /// Handle auth for signup/login flow using auth path as source of truth
  Future<void> _handleSignupLoginAuth() async {
    try {
      final supabase = SupabaseConfig.client;
      final email =
          'phone-${widget.phoneNumber}@halkhata.app'; // lowercase 'phone-'
      final password = _generateSecurePassword(widget.phoneNumber, _currentOtp);

      bool isNewUser = false;

      // Try signIn first (existing user)
      try {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        debugPrint('✅ [OTP] Existing user - signIn succeeded');
        isNewUser = false; // DETERMINISTIC: signIn success = existing user
      } catch (signInError) {
        debugPrint('⚠️ [OTP] signIn failed, attempting signUp');

        // Try signUp (new user)
        try {
          final signUpResponse = await supabase.auth.signUp(
            email: email,
            password: password,
            data: {
              'phone': widget.phoneNumber,
              'phone_verified': true,
            },
          );

          // Check if signup actually created a new user
          // Supabase returns empty identities for existing users (anti-enumeration)
          final identities = signUpResponse.user?.identities ?? [];
          if (identities.isEmpty) {
            debugPrint('⚠️ [OTP] signUp returned but user already exists (empty identities)');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PinVerificationScreen(phoneNumber: widget.phoneNumber),
                ),
              );
            }
            return;
          }

          debugPrint('✅ [OTP] New user - signUp succeeded with identities');
          isNewUser = true; // DETERMINISTIC: signUp success = new user

          // Sign in after sign up
          await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
        } catch (signUpError) {
          // Handle user_already_exists (edge case)
          if (signUpError is AuthApiException &&
              signUpError.code == 'user_already_exists') {
            debugPrint(
                '⚠️ [OTP] User exists but wrong password - redirect to PIN');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PinVerificationScreen(phoneNumber: widget.phoneNumber),
                ),
              );
            }
            return;
          }
          throw signUpError;
        }
      }

      // Verify session
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Failed to create auth session');
      }

      debugPrint('✅ [OTP] Auth session created for user: ${currentUser.id}');
      debugPrint('📊 [OTP] User type: ${isNewUser ? "NEW" : "EXISTING"}');

      // ROUTE BASED ON AUTH PATH (deterministic, no timeout queries)
      if (mounted) {
        if (isNewUser) {
          // NEW USER → Onboarding
          debugPrint('🆕 [OTP] New user - navigating to BusinessInfoScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessInfoScreen(
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        } else {
          // EXISTING USER → PIN verification
          debugPrint('✅ [OTP] Existing user - navigating to PinVerificationScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PinVerificationScreen(
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        }
      }
    } catch (authError) {
      debugPrint('❌ Auth session creation error: $authError');
      setState(() {
        _errorMessage = 'সেশন তৈরিতে ত্রুটি: ${authError.toString()}';
      });
    }
  }

  void _handleEditPhone() {
    Navigator.of(context).pop();
  }

  void _handleHelpline() {
    // TODO: Implement helpline functionality
    Fluttertoast.showToast(
      msg: 'হেল্পলাইন শীঘ্রই আসছে',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
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

            return Container(
              decoration: isTablet
                  ? const BoxDecoration(color: AppTheme.backgroundGray)
                  : const BoxDecoration(color: Colors.white),
              child: Center(
                child: Container(
                  constraints: isTablet
                      ? const BoxConstraints(maxWidth: AppTheme.maxLoginWidth)
                      : null,
                  decoration: isTablet
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppTheme.softShadow,
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Scrollable body (expanded)
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top row: Back button + Helpline button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Yellow back button
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryYellow,
                                          shape: BoxShape.circle,
                                          boxShadow: AppTheme.softShadow,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    // Helpline button
                                    HelplineButton(onTap: _handleHelpline),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Promo/Testimonial card
                                const PromoCard(
                                  title:
                                      '"৪টি ব্যবসা, সব হিসাব একটি অ্যাপে হালখাতা"',
                                  subtitle: '- মীর আবু সাইদ নোয়াখালী',
                                  currentPage: 1,
                                  totalPages: 5,
                                ),
                                const SizedBox(height: 24),

                                // Heading
                                Text(
                                  'ওটিপি যাচাই করুন',
                                  style: AppTheme.titleBold,
                                ),
                                const SizedBox(height: 12),

                                // Info banner with bold phone number
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.yellow50,
                                    border: Border.all(
                                      color:
                                          const Color(0xFFFDE047), // yellow-300
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.sms_outlined,
                                        color: ColorPalette.gray600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.textPrimary,
                                              height: 1.5,
                                              fontFamily: 'HindSiliguri',
                                            ),
                                            children: [
                                              const TextSpan(text: 'আপনার '),
                                              TextSpan(
                                                text: _formatPhone(
                                                    widget.phoneNumber),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const TextSpan(
                                                text:
                                                    ' নম্বরে একটি ৬ ডিজিটের ভেরিফিকেশন কোড পাঠানো হয়েছে',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 6 OTP input boxes
                                OtpFieldsRow(
                                  onChanged: (otp) {
                                    setState(() {
                                      _currentOtp = otp;
                                      _errorMessage = null;
                                    });
                                  },
                                  onCompleted: (otp) {
                                    // Optional: Auto-verify when all 6 digits entered
                                    // _handleVerify();
                                  },
                                ),

                                // Error message
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMessage!,
                                    style: AppTheme.smallRegular.copyWith(
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 24),

                                // Timer + Change number link
                                Column(
                                  children: [
                                    // Timer text with blue highlight
                                    RichText(
                                      text: TextSpan(
                                        style: AppTheme.labelMedium,
                                        children: [
                                          const TextSpan(
                                              text: 'আরেকবার চেষ্টা করুন '),
                                          TextSpan(
                                            text: _formatTime(_resendCountdown),
                                            style: const TextStyle(
                                              color: AppTheme.secondaryBlue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Change number link with dotted underline
                                    TextButton(
                                      onPressed: _handleEditPhone,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'মোবাইল নাম্বার পরিবর্তন করুন',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                          decoration: TextDecoration.underline,
                                          decorationStyle:
                                              TextDecorationStyle.dotted,
                                          fontFamily: 'HindSiliguri',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Bottom toast
                                Center(
                                  child: BottomToast(
                                    message:
                                        'Sent verification CODE at ${_formatPhone(widget.phoneNumber)}',
                                    visible: _showToast,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),

                        // Fixed submit button (not in scroll)
                        PrimaryButton(
                          text: 'সাবমিট',
                          enabled: _currentOtp.length == 6 && !_isVerifying,
                          isLoading: _isVerifying,
                          onPressed: _handleVerify,
                        ),
                      ],
                    ),
                  ), // Close Padding
                ), // Close inner Container
              ), // Close Center
            ); // Close outer Container
          },
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatPhone(String phone) {
    // Format: 88017XXXXXXXX → 01707346633
    if (phone.startsWith('88')) {
      return phone.substring(2);
    }
    return phone;
  }

  String _generateSecurePassword(String phone, String otp) {
    // Generate a deterministic but secure password
    // Combine phone + OTP + app secret
    final appSecret = 'wavezly_2026'; // Should be in env/config
    final combined = '$phone$otp$appSecret';

    // Simple hash (in production, use crypto library)
    return combined.hashCode.toString().padLeft(16, '0');
  }
}
