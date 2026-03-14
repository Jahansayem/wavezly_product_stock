import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wavezly/app/app_theme.dart';
import 'package:wavezly/config/supabase_config.dart';
import 'package:wavezly/features/auth/screens/otp_verification_screen.dart';
import 'package:wavezly/features/auth/screens/pin_verification_screen.dart';
import 'package:wavezly/features/auth/widgets/helpline_button.dart';
import 'package:wavezly/features/auth/widgets/info_banner.dart';
import 'package:wavezly/features/auth/widgets/language_toggle.dart';
import 'package:wavezly/features/auth/widgets/phone_input_field.dart';
import 'package:wavezly/features/auth/widgets/primary_button.dart';
import 'package:wavezly/localization/app_strings.dart';
import 'package:wavezly/services/sms_service.dart';

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

  Future<bool> _checkUserExists(String phone) async {
    try {
      final phoneWithCountryCode = phone.startsWith('88') ? phone : '88$phone';

      debugPrint('Checking if user exists: $phoneWithCountryCode');

      final response = await SupabaseConfig.client.rpc('check_phone_exists',
          params: {'phone_number': phoneWithCountryCode});

      final exists = response == true;
      debugPrint(exists ? 'User exists' : 'New user');

      return exists;
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      return true;
    }
  }

  bool _validatePhoneFormat(String phone) {
    return phone.length == 11 && phone.startsWith('01');
  }

  Future<void> _handleSubmit() async {
    if (!_isPhoneValid) {
      return;
    }

    final strings = AppStrings.of(context);
    final phone = _phoneController.text.trim();

    if (!_validatePhoneFormat(phone)) {
      Fluttertoast.showToast(
        msg: strings.invalidPhoneFormat,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    try {
      final phoneWithCountryCode = '88$phone';
      final userExists = await _checkUserExists(phone);

      if (userExists) {
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
        final otp = _smsService.generateOTP();
        final response = await _smsService.sendOTP(phone, otp);

        if (response.success) {
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
      debugPrint('Error in submit: $e');

      setState(() {
        _isSendingOtp = false;
      });

      Fluttertoast.showToast(
        msg: strings.genericRetryError,
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
    Fluttertoast.showToast(
      msg: AppStrings.of(context).helplineTapped,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

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
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing2xl,
                        vertical: AppTheme.spacing3xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: AppTheme.spacing2xl),
                          _buildDecorativeBars(),
                          const SizedBox(height: AppTheme.spacing2xl),
                          _buildTitle(strings),
                          const SizedBox(height: AppTheme.spacing3xl),
                          _buildFormSection(strings),
                          SizedBox(
                            height: isTablet ? 40 : 60,
                          ),
                          _buildCTAButton(strings),
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

  Widget _buildHeader() {
    return Row(
      children: [
        const LanguageToggle(),
        const Spacer(),
        HelplineButton(onTap: _handleHelpline),
      ],
    );
  }

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

  Widget _buildTitle(AppStrings strings) {
    return Text(
      strings.loginTitle,
      style: AppTheme.titleBold,
    );
  }

  Widget _buildFormSection(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.mobileNumberLabel,
          style: AppTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        PhoneInputField(
          controller: _phoneController,
          onChanged: (value) {},
        ),
        const SizedBox(height: AppTheme.spacingLg),
        const InfoBanner(),
      ],
    );
  }

  Widget _buildCTAButton(AppStrings strings) {
    return PrimaryButton(
      text: strings.continueText,
      enabled: _isPhoneValid && !_isSendingOtp,
      isLoading: _isSendingOtp,
      onPressed: _handleSubmit,
    );
  }
}
