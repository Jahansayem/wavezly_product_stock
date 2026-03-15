import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wavezly/utils/color_palette.dart';

class AppTrainingScreen extends StatelessWidget {
  const AppTrainingScreen({super.key});

  static final Uri _supportCallUri = Uri.parse('tel:+8809638011199');

  Future<void> _callSupport(BuildContext context) async {
    final launched = await launchUrl(_supportCallUri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ColorPalette.nileBlue,
          content: Text(
            'কল করা যাচ্ছে না। পরে আবার চেষ্টা করুন।',
            style: _bodyStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  void _showComingSoonMessage(BuildContext context, [String? label]) {
    final message = label == null
        ? 'এই ট্রেনিংটি শীঘ্রই চালু হবে।'
        : '$label শীঘ্রই চালু হবে।';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColorPalette.nileBlue,
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
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'অ্যাপ ট্রেনিং',
          style: _bodyStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showComingSoonMessage(context, 'সাহায্য'),
            icon: const Icon(Icons.help_outline_rounded, color: Colors.black),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'হালখাতা অ্যাপ কিভাবে ব্যবহার করবেন বুঝতে পারছেন না?',
                style: _bodyStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.gray800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 20),
              _SupportCard(
                onCallTap: () => _callSupport(context),
              ),
              const SizedBox(height: 24),
              _TrainingTimeline(
                steps: _trainingSteps,
                onStepTap: (label) => _showComingSoonMessage(context, label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.onCallTap});

  final VoidCallback onCallTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'যেকোনো প্রয়োজনে কল করুন',
                  style: _bodyStyle(
                    fontSize: 13,
                    color: ColorPalette.gray500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+৮৮০৯৬৩৮০১১১৯৯',
                  style: _bodyStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorPalette.gray800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: const Color(0xFF16A34A),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onCallTap,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingTimeline extends StatelessWidget {
  const _TrainingTimeline({
    required this.steps,
    required this.onStepTap,
  });

  final List<String> steps;
  final ValueChanged<String> onStepTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 7,
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            color: const Color(0xFF22C55E),
          ),
        ),
        Column(
          children: List.generate(steps.length, (index) {
            final isHighlighted = index == 0;
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == steps.length - 1 ? 0 : 14),
              child: _TrainingStepTile(
                label: steps[index],
                isHighlighted: isHighlighted,
                onTap: () => onStepTap(steps[index]),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TrainingStepTile extends StatelessWidget {
  const _TrainingStepTile({
    required this.label,
    required this.isHighlighted,
    required this.onTap,
  });

  final String label;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isHighlighted
                        ? const Color(0xFF22C55E)
                        : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: _bodyStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.gray800,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: ColorPalette.gray400,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const List<String> _trainingSteps = [
  'হালখাতার উপকারিতা দেখুন',
  'পণ্য যুক্ত করে ব্যবসাকে গুছিয়ে নিন',
  'সহজেই পণ্য বিক্রি করুন',
  'পার্টি-অনুযায়ী সকল পার্টির হিসাব রাখুন',
  'সহজেই প্রতিটি বিক্রির হিসাব রাখুন',
  'সহজেই খাত-অনুযায়ী মোট খরচের হিসাব রাখুন',
  'সহজেই পণ্য কেনা শুরু করুন',
  'সহজেই সকল কেনার হিসাব রাখুন',
  'ব্যবসার যাবতীয় ব্যবসায়িক রিপোর্ট দেখুন',
  'হিসাব রাখার পাশাপাশি অনলাইন ব্যবসা করুন',
  'টপ অ্যাপ এর মাধ্যমে বাড়তি আয় করুন',
  'কর্মচারী বা পার্টনারকে অ্যাপ অ্যাক্সেস দিন',
  'কাস্টমার/কর্মচারী/সাপ্লায়ারকে এক স্ক্রিন থেকে যোগাযোগ করুন',
  'সহজেই কাস্টমার বা সাপ্লায়ারকে সহজেই এসএমএস পাঠান',
  'কেনা, বেচার রসিদ প্রিন্ট করুন',
  'সহজেই সকল মজুদের হিসাব রাখুন',
];

TextStyle _bodyStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w500,
  Color color = ColorPalette.gray700,
  double height = 1.2,
}) {
  return GoogleFonts.hindSiliguri(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}
