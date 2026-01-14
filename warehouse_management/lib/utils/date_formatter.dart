import 'number_formatter.dart';

class DateFormatter {
  // Bengali month names
  static const Map<int, String> _bengaliMonths = {
    1: 'জানুয়ারী',
    2: 'ফেব্রুয়ারী',
    3: 'মার্চ',
    4: 'এপ্রিল',
    5: 'মে',
    6: 'জুন',
    7: 'জুলাই',
    8: 'আগস্ট',
    9: 'সেপ্টেম্বর',
    10: 'অক্টোবর',
    11: 'নভেম্বর',
    12: 'ডিসেম্বর',
  };

  /// Format date to Bengali: DateTime(2026, 1, 14) → "১৪ জানুয়ারী"
  static String toBengaliDate(DateTime date) {
    final day = NumberFormatter.formatIntToBengali(date.day);
    final month = getBengaliMonth(date.month);
    return '$day $month';
  }

  /// Format date to Bengali with year: DateTime(2026, 1, 14) → "১৪ জানুয়ারী, ২০২৬"
  static String toBengaliDateFull(DateTime date) {
    final day = NumberFormatter.formatIntToBengali(date.day);
    final month = getBengaliMonth(date.month);
    final year = NumberFormatter.formatIntToBengali(date.year);
    return '$day $month, $year';
  }

  /// Get Bengali month name: 1 → "জানুয়ারী"
  static String getBengaliMonth(int month) {
    return _bengaliMonths[month] ?? '';
  }

  /// Get Bengali day: 14 → "১৪"
  static String getBengaliDay(int day) {
    return NumberFormatter.formatIntToBengali(day);
  }

  /// Get Bengali year: 2026 → "২০২৬"
  static String getBengaliYear(int year) {
    return NumberFormatter.formatIntToBengali(year);
  }
}
