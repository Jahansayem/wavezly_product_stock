import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wavezly/utils/color_palette.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _logoAssetPath = 'assets/help_support/halkhata_logo.png';
  static final Uri _callUri = Uri.parse('tel:+8809649132132');
  static final Uri _emailUri = Uri.parse('mailto:support@wavezly.com');

  bool _isEnglish(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en';
  }

  String _text(BuildContext context, String bangla, String english) {
    return _isEnglish(context) ? english : bangla;
  }

  Future<void> _launchOrShowError(
    BuildContext context, {
    required Uri uri,
    required String banglaError,
    required String englishError,
  }) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showMessage(
        context,
        _text(context, banglaError, englishError),
        backgroundColor: ColorPalette.nileBlue,
      );
    }
  }

  void _showPlaceholder(BuildContext context, String label) {
    final message = _isEnglish(context)
        ? '$label coming soon.'
        : '$label শীঘ্রই যুক্ত হবে।';
    _showMessage(
      context,
      message,
      backgroundColor: ColorPalette.nileBlue,
    );
  }

  void _showMessage(
    BuildContext context,
    String message, {
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
        ),
        title: Text(
          _text(context, 'হেল্প & সাপোর্ট', 'Help & Support'),
          style: _bodyStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            children: [
              _HeroSection(labelBuilder: (bn, en) => _text(context, bn, en)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.facebook_rounded,
                      iconColor: const Color(0xFF2563EB),
                      label: _text(context, 'ফেসবুক', 'Facebook'),
                      onTap: () => _showPlaceholder(
                        context,
                        _text(context, 'ফেসবুক', 'Facebook'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.play_circle_fill_rounded,
                      iconColor: ColorPalette.red600,
                      label: _text(context, 'ইউটিউব', 'YouTube'),
                      onTap: () => _showPlaceholder(
                        context,
                        _text(context, 'ইউটিউব', 'YouTube'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.mail_outline_rounded,
                      iconColor: ColorPalette.gray600,
                      label: _text(context, 'ইমেইল', 'Email'),
                      onTap: () => _launchOrShowError(
                        context,
                        uri: _emailUri,
                        banglaError:
                            'ইমেইল অ্যাপ খোলা যাচ্ছে না। পরে আবার চেষ্টা করুন।',
                        englishError:
                            'Could not open the email app. Please try again later.',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _PrimaryCallCard(
                labelBuilder: (bn, en) => _text(context, bn, en),
                onCallTap: () => _launchOrShowError(
                  context,
                  uri: _callUri,
                  banglaError: 'কল করা যাচ্ছে না। পরে আবার চেষ্টা করুন।',
                  englishError:
                      'Could not place the call. Please try again later.',
                ),
              ),
              const SizedBox(height: 24),
              _LiveChatCard(
                labelBuilder: (bn, en) => _text(context, bn, en),
                onChatTap: () => _showPlaceholder(
                  context,
                  _text(context, 'লাইভ চ্যাট', 'Live chat'),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                '© 2023 Wavezly Technologies Ltd.',
                textAlign: TextAlign.center,
                style: _bodyStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.gray400,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.1.6',
                style: _bodyStyle(
                  fontSize: 10,
                  color: ColorPalette.gray400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.labelBuilder});

  final String Function(String bangla, String english) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              HelpSupportScreen._logoAssetPath,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'HALKHATA',
          style: _bodyStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ColorPalette.gray500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Wavezly Technologies Limited',
          textAlign: TextAlign.center,
          style: _headingStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ColorPalette.gray800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 52,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFFACC15),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          labelBuilder(
            'সাপোর্ট, কল ও ইমেইল এক জায়গা থেকে',
            'Support, call, and email in one place',
          ),
          textAlign: TextAlign.center,
          style: _bodyStyle(
            color: ColorPalette.gray500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _bodyStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.gray700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryCallCard extends StatelessWidget {
  const _PrimaryCallCard({
    required this.labelBuilder,
    required this.onCallTap,
  });

  final String Function(String bangla, String english) labelBuilder;
  final VoidCallback onCallTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorPalette.green600,
              boxShadow: [
                BoxShadow(
                  color: ColorPalette.green600.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.call_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            labelBuilder(
              'জরুরি প্রয়োজনে আমাদের কল করুন',
              'Call us for urgent support',
            ),
            textAlign: TextAlign.center,
            style: _bodyStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.gray600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+880 9649 132 132',
            textAlign: TextAlign.center,
            style: _headingStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: ColorPalette.gray900,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCallTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                labelBuilder('এখনই কল করুন', 'Call Now'),
                style: _bodyStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveChatCard extends StatelessWidget {
  const _LiveChatCard({
    required this.labelBuilder,
    required this.onChatTap,
  });

  final String Function(String bangla, String english) labelBuilder;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ColorPalette.blue50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: ColorPalette.blue50,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: ColorPalette.navBlue,
                      size: 30,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: ColorPalette.green500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelBuilder('লাইভ চ্যাট সাপোর্ট', 'Live Chat Support'),
                      style: _headingStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: ColorPalette.gray800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labelBuilder(
                        'আমাদের প্রতিনিধিরা অনলাইনে আছেন',
                        'Our support agents are online',
                      ),
                      style: _bodyStyle(
                        fontSize: 13,
                        color: ColorPalette.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onChatTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.gray900,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                labelBuilder('চ্যাট শুরু করুন', 'Start Chat'),
                style: _bodyStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _headingStyle({
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.hindSiliguri(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle _bodyStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w500,
  required Color color,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.hindSiliguri(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
