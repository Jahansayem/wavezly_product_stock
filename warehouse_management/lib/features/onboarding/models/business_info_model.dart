enum AgeGroup {
  age18_24('18-24'),
  age25_45('25-45'),
  age45Plus('45+');

  final String label;
  const AgeGroup(this.label);
}

class BusinessInfoModel {
  final String shopName;
  final AgeGroup ageGroup;
  final String? referralCode;
  final bool termsAccepted;

  const BusinessInfoModel({
    required this.shopName,
    required this.ageGroup,
    this.referralCode,
    required this.termsAccepted,
  });

  Map<String, dynamic> toJson() => {
        'shop_name': shopName,
        'age_group': ageGroup.label,
        'referral_code': referralCode,
        'terms_accepted': termsAccepted,
      };
}
