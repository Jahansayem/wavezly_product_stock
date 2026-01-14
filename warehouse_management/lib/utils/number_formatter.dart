class NumberFormatter {
  // Bengali to English digit mapping
  static const Map<String, String> _bengaliToEnglishMap = {
    '০': '0',
    '১': '1',
    '২': '2',
    '৩': '3',
    '৪': '4',
    '৫': '5',
    '৬': '6',
    '৭': '7',
    '৮': '8',
    '৯': '9',
  };

  // English to Bengali digit mapping
  static const Map<String, String> _englishToBengaliMap = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  /// Convert Bengali digits to English
  /// Example: "৫০" → "50"
  static String bengaliToEnglish(String bengaliNumber) {
    if (bengaliNumber.isEmpty) return '';

    String result = bengaliNumber;
    _bengaliToEnglishMap.forEach((bengali, english) {
      result = result.replaceAll(bengali, english);
    });
    return result;
  }

  /// Convert English digits to Bengali
  /// Example: "50" → "৫০"
  static String englishToBengali(String englishNumber) {
    if (englishNumber.isEmpty) return '';

    String result = englishNumber;
    _englishToBengaliMap.forEach((english, bengali) {
      result = result.replaceAll(english, bengali);
    });
    return result;
  }

  /// Parse Bengali number string to double
  /// Example: "৫০.৫" → 50.5
  static double parseBengaliNumber(String bengaliNumber) {
    if (bengaliNumber.isEmpty) return 0.0;

    final englishNumber = bengaliToEnglish(bengaliNumber);
    return double.tryParse(englishNumber) ?? 0.0;
  }

  /// Format double to Bengali string
  /// Example: 50.5 → "৫০.৫"
  static String formatToBengali(double number, {int decimals = 0}) {
    final formatted = number.toStringAsFixed(decimals);
    return englishToBengali(formatted);
  }

  /// Format integer to Bengali string
  /// Example: 50 → "৫০"
  static String formatIntToBengali(int number) {
    return englishToBengali(number.toString());
  }
}
