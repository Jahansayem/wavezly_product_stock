import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PurchaseDetailsScreen extends StatelessWidget {
  const PurchaseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF26A69A),
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ক্রয়ের বিবরণ',
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Purchase Header Card
                  _SoftCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '9216735951270',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 14,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  children: [
                                    const TextSpan(text: 'মূল্য পরিশোধ পদ্ধতি: '),
                                    TextSpan(
                                      text: 'বাকি',
                                      style: GoogleFonts.hindSiliguri(
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '09 January 2026 | 12:00 AM',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 14,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '৮,৮৬৫.৩ ৳',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                // TODO: Handle image tap
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  size: 20,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Supplier Info Card
                  _SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'স্টার এন্টারপ্রাইজ',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+8801914794604',
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dhaka, Bangladesh',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product List Card
                  _SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ক্রয় করা পণ্যের লিস্ট',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const Divider(
                          height: 20,
                          thickness: 1,
                          color: Color(0xFFF3F4F6),
                        ),
                        Column(
                          children: [
                            _ProductRow(
                              name: 'আপেল',
                              quantity: 'X16',
                              price: '২,০৩৫.২ ৳',
                            ),
                            const SizedBox(height: 12),
                            _ProductRow(
                              name: 'আলু',
                              quantity: 'X12',
                              price: '৩৬৫.৬ ৳',
                            ),
                            const SizedBox(height: 12),
                            _ProductRow(
                              name: 'দই',
                              quantity: 'X45',
                              price: '১০,৩৩৮.১ ৳',
                            ),
                            const SizedBox(height: 12),
                            _ProductRow(
                              name: 'সাবান',
                              quantity: 'X32',
                              price: '৩৮৮.৩ ৳',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary Card
                  _SoftCard(
                    child: Column(
                      children: [
                        _KeyValueRow(
                          label: 'মোট',
                          value: '১৩,১২৭.১ ৳',
                        ),
                        const SizedBox(height: 8),
                        _KeyValueRow(
                          label: 'ডেলিভারী চার্জ',
                          value: '০ ৳',
                        ),
                        const SizedBox(height: 8),
                        _KeyValueRow(
                          label: 'ডিস্কাউন্ট',
                          value: '০ ৳',
                        ),
                        const Divider(
                          height: 20,
                          thickness: 1,
                          color: Color(0xFFF3F4F6),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'সর্বমোট',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              '৮,৮৬৫.৩ ৳',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'পেমেন্ট অবস্থা',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              'পরিশোধ করা হয়নি',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Supplier Balance Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'সাপ্লায়ার ব্যালেন্স',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '0',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF26A69A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Transform.rotate(
                              angle: -0.785398, // -45 degrees in radians
                              child: const Icon(
                                Icons.arrow_upward,
                                size: 20,
                                color: Color(0xFF26A69A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actions Grid
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.print,
                          label: 'রিসিপ্ট প্রিন্ট করুন',
                          onTap: () {
                            // TODO: Handle print
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.share,
                          label: 'রিসিপ্ট শেয়ার',
                          onTap: () {
                            // TODO: Handle share
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notes Field
                  _FloatingLabelBox(
                    label: 'নোট',
                    content: 'Stock replenishment',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable Widgets

class _SoftCard extends StatelessWidget {
  final Widget child;

  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final String name;
  final String quantity;
  final String price;

  const _ProductRow({
    required this.name,
    required this.quantity,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.category,
              size: 18,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              quantity,
              style: GoogleFonts.hindSiliguri(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 70,
            child: Text(
              price,
              textAlign: TextAlign.right,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: const Color(0xFF26A69A),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingLabelBox extends StatelessWidget {
  final String label;
  final String content;

  const _FloatingLabelBox({
    required this.label,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFFF3F4F6),
            child: Text(
              label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
