import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wavezly/models/purchase.dart';
import 'package:wavezly/models/purchase_item.dart';
import 'package:wavezly/services/purchase_service.dart';
import 'package:wavezly/utils/number_formatter.dart';

class PurchaseDetailsScreen extends StatefulWidget {
  final Purchase purchase;

  const PurchaseDetailsScreen({super.key, required this.purchase});

  @override
  State<PurchaseDetailsScreen> createState() => _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends State<PurchaseDetailsScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  List<PurchaseItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchaseItems();
  }

  Future<void> _loadPurchaseItems() async {
    try {
      if (widget.purchase.id != null) {
        final items = await _purchaseService.getPurchaseItems(widget.purchase.id!);
        setState(() {
          _items = items;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatBengaliAmount(double amount) {
    return '${NumberFormatter.formatToBengali(amount, decimals: 1)} ৳';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy | hh:mm a').format(date);
  }

  String _getPaymentMethodBengali(String method) {
    switch (method) {
      case 'cash':
        return 'নগদ';
      case 'due':
        return 'বাকি';
      case 'mobile_banking':
        return 'মোবাইল ব্যাংকিং';
      case 'bank_check':
        return 'ব্যাংক চেক';
      default:
        return method;
    }
  }

  String _getPaymentStatusBengali(String status) {
    switch (status) {
      case 'paid':
        return 'পরিশোধিত';
      case 'partial':
        return 'আংশিক পরিশোধিত';
      case 'due':
        return 'পরিশোধ করা হয়নি';
      default:
        return status;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF10B981); // Green
      case 'partial':
        return const Color(0xFFF59E0B); // Amber
      case 'due':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchase = widget.purchase;

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
          style: GoogleFonts.anekBangla(
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
                                purchase.purchaseNumber ?? 'N/A',
                                style: GoogleFonts.anekBangla(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.anekBangla(
                                    fontSize: 14,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  children: [
                                    const TextSpan(text: 'মূল্য পরিশোধ পদ্ধতি: '),
                                    TextSpan(
                                      text: _getPaymentMethodBengali(purchase.paymentMethod),
                                      style: GoogleFonts.anekBangla(
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(purchase.purchaseDate),
                                style: GoogleFonts.anekBangla(
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
                              _formatBengaliAmount(purchase.totalAmount),
                              style: GoogleFonts.anekBangla(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _getPaymentStatusColor(purchase.paymentStatus),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (purchase.receiptImagePath != null)
                              InkWell(
                                onTap: () {
                                  // TODO: Handle image tap - show full image
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
                  if (purchase.supplierName != null)
                    _SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            purchase.supplierName!,
                            style: GoogleFonts.anekBangla(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (purchase.supplierName != null) const SizedBox(height: 16),

                  // Product List Card
                  _SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ক্রয় করা পণ্যের লিস্ট',
                          style: GoogleFonts.anekBangla(
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
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF26A69A)),
                              ),
                            ),
                          )
                        else if (_items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'কোন পণ্য পাওয়া যায়নি',
                              style: GoogleFonts.anekBangla(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: _items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Column(
                                children: [
                                  _ProductRow(
                                    name: item.productName,
                                    quantity: 'X${NumberFormatter.formatIntToBengali(item.quantity)}',
                                    price: _formatBengaliAmount(item.totalCost),
                                  ),
                                  if (index < _items.length - 1) const SizedBox(height: 12),
                                ],
                              );
                            }).toList(),
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
                          value: _formatBengaliAmount(purchase.totalAmount),
                        ),
                        const SizedBox(height: 8),
                        _KeyValueRow(
                          label: 'পরিশোধিত',
                          value: _formatBengaliAmount(purchase.paidAmount),
                        ),
                        if (purchase.dueAmount > 0) ...[
                          const SizedBox(height: 8),
                          _KeyValueRow(
                            label: 'বাকি',
                            value: _formatBengaliAmount(purchase.dueAmount),
                            valueColor: const Color(0xFFEF4444),
                          ),
                        ],
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
                              style: GoogleFonts.anekBangla(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              _formatBengaliAmount(purchase.totalAmount),
                              style: GoogleFonts.anekBangla(
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
                              style: GoogleFonts.anekBangla(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              _getPaymentStatusBengali(purchase.paymentStatus),
                              style: GoogleFonts.anekBangla(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _getPaymentStatusColor(purchase.paymentStatus),
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
                  if (purchase.comment != null && purchase.comment!.isNotEmpty)
                    _FloatingLabelBox(
                      label: 'নোট',
                      content: purchase.comment!,
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
  final Color? valueColor;

  const _KeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.anekBangla(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.anekBangla(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? const Color(0xFF1F2937),
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
              style: GoogleFonts.anekBangla(
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
              style: GoogleFonts.anekBangla(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              price,
              textAlign: TextAlign.right,
              style: GoogleFonts.anekBangla(
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
                style: GoogleFonts.anekBangla(
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
              style: GoogleFonts.anekBangla(
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
