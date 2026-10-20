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

  /// Format currency with ৳ symbol and Bengali digits (with decimals)
  /// Example: 1234.56 → "৳১,২৩৪.৫৬"
  static String formatCurrency(double amount) {
    // Format with thousand separators and 2 decimal places
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    // Add thousand separators
    String formatted = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = ',$formatted';
      }
      formatted = '${integerPart[i]}$formatted';
      count++;
    }

    final withDecimals = '$formatted.$decimalPart';
    return '৳${englishToBengali(withDecimals)}';
  }

  /// Format currency with ৳ symbol and Bengali digits (integer only)
  /// Example: 1234 → "৳১,২৩৪"
  static String formatCurrencyInt(double amount) {
    final integerPart = amount.round().toString();

    // Add thousand separators
    String formatted = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = ',$formatted';
      }
      formatted = '${integerPart[i]}$formatted';
      count++;
    }

    return '৳${englishToBengali(formatted)}';
  }

  /// Format date with Bangla numerals and month names
  /// Example: DateTime(2025, 1, 15) → "১৫ জানু"
  static String formatBanglaDate(DateTime date) {
    final months = {
      1: 'জানু',
      2: 'ফেব',
      3: 'মার্চ',
      4: 'এপ্রিল',
      5: 'মে',
      6: 'জুন',
      7: 'জুলাই',
      8: 'আগ',
      9: 'সেপ্ট',
      10: 'অক্টো',
      11: 'নভে',
      12: 'ডিসে',
    };

    final day = formatIntToBengali(date.day);
    final month = months[date.month] ?? '';

    return '$day $month';
  }

  /// Format full date with year: "১৫ জানু ২০২৬"
  static String formatBanglaDateFull(DateTime date) {
    return '${formatBanglaDate(date)} ${formatIntToBengali(date.year)}';
  }
}
