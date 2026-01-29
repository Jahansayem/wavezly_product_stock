import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/features/auth/widgets/language_toggle.dart';
import 'package:wavezly/features/auth/widgets/helpline_button.dart';
import 'package:wavezly/features/auth/widgets/phone_input_field.dart';
import 'package:wavezly/features/auth/widgets/info_banner.dart';
import 'package:wavezly/features/auth/widgets/primary_button.dart';
import 'package:wavezly/services/sms_service.dart';
import 'package:wavezly/features/auth/screens/otp_verification_screen.dart';
import 'package:wavezly/features/auth/screens/pin_verification_screen.dart';

/// New pixel-perfect Bangla login screen
///
/// Matches Tailwind design from code.html with:
/// - Hind Siliguri font for Bangla text
/// - Responsive design (phone full-screen, tablet/desktop centered)
/// - Yellow/blue color scheme
/// - Component-based architecture
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final SmsService _smsService = SmsService();
  bool _isPhoneValid = false;
  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();
    // Listen to phone input changes to enable/disable CTA button
    _phoneController.addListener(() {
      setState(() {
        _isPhoneValid = _phoneController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Check if user already exists in the system
  /// Returns true if user exists, false if new user
  /// Uses RPC function to bypass RLS (no auth during login)
  Future<bool> _checkUserExists(String phone) async {
    try {
      // Ensure phone has country code (88)
      final phoneWithCountryCode = phone.startsWith('88') ? phone : '88$phone';

      debugPrint('🔍 Checking if user exists: $phoneWithCountryCode');

      // Use RPC function that bypasses RLS (SECURITY DEFINER)
      final response = await SupabaseConfig.client
          .rpc('check_phone_exists', params: {'phone_number': phoneWithCountryCode});

      final exists = response == true;
      debugPrint(exists ? '✅ User exists' : '🆕 New user');

      return exists;
    } catch (e) {
      debugPrint('❌ Error checking user existence: $e');
      // On error, treat as new user and proceed with OTP (safer)
      return false;
    }
  }

  /// Validate phone number format
  bool _validatePhoneFormat(String phone) {
    // Must be 11 digits starting with 01
    return phone.length == 11 && phone.startsWith('01');
  }

  Future<void> _handleSubmit() async {
    if (!_isPhoneValid) return;

    final phone = _phoneController.text.trim();

    // Validate phone format
    if (!_validatePhoneFormat(phone)) {
      Fluttertoast.showToast(
        msg: 'সঠিক মোবাইল নম্বর দিন (01XXXXXXXXX)',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    try {
      // Add country code
      final phoneWithCountryCode = '88$phone';

      // ✨ NEW: Check if user already exists
      final userExists = await _checkUserExists(phone);

      if (userExists) {
        // EXISTING USER: Skip OTP, go directly to PIN verification
        debugPrint('╔═══════════════════════════════════════════════════╗');
        debugPrint('║ 👤 EXISTING USER DETECTED                        ║');
        debugPrint('║ Phone: $phoneWithCountryCode                      ║');
        debugPrint('║ Target: PinVerificationScreen                    ║');
        debugPrint('╚═══════════════════════════════════════════════════╝');

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PinVerificationScreen(
                phoneNumber: phoneWithCountryCode,
              ),
            ),
          );
        }
      } else {
        // NEW USER: Send OTP and proceed to OTP verification
        debugPrint('╔═══════════════════════════════════════════════════╗');
        debugPrint('║ 🆕 NEW USER DETECTED - SENDING OTP               ║');
        debugPrint('║ Phone: $phoneWithCountryCode                      ║');
        debugPrint('╚═══════════════════════════════════════════════════╝');

        // Generate OTP
        final otp = _smsService.generateOTP();

        // Send OTP
        final response = await _smsService.sendOTP(phone, otp);

        if (response.success) {
          debugPrint('✅ OTP sent successfully');

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpVerificationScreen(
                  phoneNumber: phoneWithCountryCode,
                ),
              ),
            );
          }
        } else {
          // Failed to send OTP
          setState(() {
            _isSendingOtp = false;
          });

          Fluttertoast.showToast(
            msg: response.message,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in submit: $e');

      setState(() {
        _isSendingOtp = false;
      });

      Fluttertoast.showToast(
        msg: 'সমস্যা হয়েছে। আবার চেষ্টা করুন',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  void _handleHelpline() {
    // TODO: Implement helpline functionality
    Fluttertoast.showToast(
      msg: 'Helpline tapped',
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
              // Outer container - gray background for tablet/desktop
              decoration: isTablet
                  ? const BoxDecoration(color: AppTheme.backgroundGray)
                  : const BoxDecoration(color: Colors.white),
              child: Center(
                child: Container(
                  // Inner container - white card for tablet/desktop
                  constraints: isTablet
                      ? const BoxConstraints(maxWidth: AppTheme.maxLoginWidth)
                      : null,
                  decoration: isTablet
                      ? BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppTheme.softShadow,
                        )
                      : null,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing2xl,
                        vertical: AppTheme.spacing3xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header (Language toggle + Helpline button)
                          _buildHeader(),
                          const SizedBox(height: AppTheme.spacing2xl),

                          // Decorative bars
                          _buildDecorativeBars(),
                          const SizedBox(height: AppTheme.spacing2xl),

                          // Title
                          _buildTitle(),
                          const SizedBox(height: AppTheme.spacing3xl),

                          // Form section
                          _buildFormSection(),

                          // Spacer to push CTA button to bottom
                          SizedBox(
                            height: isTablet ? 40 : 60,
                          ),

                          // Bottom CTA button
                          _buildCTAButton(),
                        ],
                      ),
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

  /// Header with language toggle and helpline button
  Widget _buildHeader() {
    return Row(
      children: [
        const LanguageToggle(),
        const Spacer(),
        HelplineButton(onTap: _handleHelpline),
      ],
    );
  }

  /// Decorative yellow bars (left-aligned, different widths)
  Widget _buildDecorativeBars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          width: 50,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          width: 24,
          height: 4,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  /// Title text
  Widget _buildTitle() {
    return Text(
      'আপনার হালখাতা অ্যাকাউন্টে\nলগ ইন করুন',
      style: AppTheme.titleBold,
    );
  }

  /// Form section (label + phone input + info banner)
  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'মোবাইল নম্বর',
          style: AppTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // Phone input field
        PhoneInputField(
          controller: _phoneController,
          onChanged: (value) {
            // State updates handled by controller listener
          },
        ),
        const SizedBox(height: AppTheme.spacingLg),

        // Info banner
        const InfoBanner(),
      ],
    );
  }

  /// Bottom CTA button
  Widget _buildCTAButton() {
    return PrimaryButton(
      text: 'এগিয়ে যান',
      enabled: _isPhoneValid && !_isSendingOtp,
      isLoading: _isSendingOtp,
      onPressed: _handleSubmit,
    );
  }
}
