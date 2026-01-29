import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// SMS service for BulkSMS BD API integration
/// Handles OTP generation, verification, and customer notifications
class SmsService {
  // API Configuration
  static const String _apiUrl = 'http://bulksmsbd.net/api/smsapi';
  static const String _apiKey = '0PZE9ZsVOBNCjRuT4Ybs';
  static const String _senderId = '8809617611031';
  static const String _brandName = 'Halkhata';

  // OTP Configuration
  static const int _otpLength = 6;
  static const Duration _otpExpiry = Duration(minutes: 5);
  static const int _maxOtpRetries = 3;

  // OTP Cache (in-memory)
  static final Map<String, OtpEntry> _otpCache = {};
  static final Map<String, int> _otpAttempts = {};

  // Error code to Bengali message mapping
  static final Map<String, String> _errorMessages = {
    '202': 'SMS পাঠানো হয়েছে',
    '1001': 'ভুল নম্বর',
    '1002': 'Sender ID সমস্যা',
    '1003': 'সব তথ্য দিন',
    '1005': 'সার্ভার সমস্যা',
    '1006': 'Balance নেই',
    '1007': 'Balance কম',
    '1008': 'ভুল API Key',
    '1009': 'Sender ID inactive',
    '1010': 'API Key সমস্যা',
    '1011': 'User খুঁজে পাওয়া যায়নি',
    '1012': 'নম্বর সমস্যা',
    '1013': 'নম্বর ফরম্যাট ভুল',
    '1014': 'বার্তা খালি',
    '1015': 'বার্তা অনেক বড়',
    '1016': 'ভুল Sender ID',
    '1017': 'SMS পাঠানো যায়নি',
    '1018': 'Connection সমস্যা',
    '1019': 'Request সমস্যা',
    '1020': 'নম্বর সমস্যা',
    '1021': 'নম্বর inactive',
    '1022': 'নম্বর খালি',
    '1031': 'Account verify করুন',
    '1032': 'API limit exceeded',
  };

  /// Generate a random 6-digit OTP
  String generateOTP() {
    final random = Random.secure();
    final otp = (random.nextInt(900000) + 100000).toString();
    return otp;
  }

  /// Send OTP to phone number
  Future<SmsResponse> sendOTP(String phone, String otp) async {
    final formattedPhone = _formatPhoneForAPI(phone);

    // Check rate limiting
    final attempts = _otpAttempts[formattedPhone] ?? 0;
    if (attempts >= _maxOtpRetries) {
      return SmsResponse(
        success: false,
        message: 'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন',
        code: 'RATE_LIMIT',
      );
    }

    // Store OTP in cache
    _otpCache[formattedPhone] = OtpEntry(
      otp,
      DateTime.now().add(_otpExpiry),
    );

    // Increment attempt counter
    _otpAttempts[formattedPhone] = attempts + 1;

    // Reset attempt counter after 1 hour
    Future.delayed(const Duration(hours: 1), () {
      _otpAttempts.remove(formattedPhone);
    });

    // Send SMS
    final message = 'Your $_brandName OTP is $otp';
    final response = await sendSms(formattedPhone, message);

    if (!response.success) {
      // Remove from cache if send failed
      _otpCache.remove(formattedPhone);
    }

    return response;
  }

  /// Verify OTP code
  Future<bool> verifyOTP(String phone, String otp) async {
    final formattedPhone = _formatPhoneForAPI(phone);

    // Clean expired OTPs
    _cleanExpiredOTPs();

    // Check if OTP exists
    final entry = _otpCache[formattedPhone];
    if (entry == null) {
      debugPrint('OTP not found for phone: $formattedPhone');
      return false;
    }

    // Check expiry
    if (entry.expiresAt.isBefore(DateTime.now())) {
      debugPrint('OTP expired for phone: $formattedPhone');
      _otpCache.remove(formattedPhone);
      return false;
    }

    // Verify OTP
    final isValid = entry.otp == otp;

    if (isValid) {
      // Remove from cache after successful verification
      _otpCache.remove(formattedPhone);
      _otpAttempts.remove(formattedPhone);
    }

    return isValid;
  }

  /// Send generic SMS
  Future<SmsResponse> sendSms(String phone, String message) async {
    try {
      final formattedPhone = _formatPhoneForAPI(phone);

      // Validate phone
      if (!_isValidBangladeshPhone(formattedPhone)) {
        return SmsResponse(
          success: false,
          message: 'ভুল নম্বর ফরম্যাট',
          code: 'INVALID_PHONE',
        );
      }

      // Build request URL
      final encodedMessage = Uri.encodeComponent(message);
      final url = Uri.parse(
        '$_apiUrl?api_key=$_apiKey&type=text&number=$formattedPhone&senderid=$_senderId&message=$encodedMessage',
      );

      debugPrint('Sending SMS to: $formattedPhone');

      // Make API request
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      debugPrint('SMS API Response: ${response.statusCode} - ${response.body}');

      // Parse response
      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          final responseCode = jsonResponse['response_code']?.toString() ?? '';

          // Success code is 202
          if (responseCode == '202') {
            return SmsResponse(
              success: true,
              message: 'SMS পাঠানো হয়েছে',
              code: responseCode,
            );
          } else {
            // Error response
            final errorMessage =
                _errorMessages[responseCode] ?? 'SMS পাঠানো যায়নি ($responseCode)';
            return SmsResponse(
              success: false,
              message: errorMessage,
              code: responseCode,
            );
          }
        } catch (e) {
          debugPrint('Error parsing SMS response: $e');
          return SmsResponse(
            success: false,
            message: 'Response parse সমস্যা',
            code: 'PARSE_ERROR',
          );
        }
      } else {
        return SmsResponse(
          success: false,
          message: 'Server সমস্যা (${response.statusCode})',
          code: 'HTTP_${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('SMS sending error: $e');
      return SmsResponse(
        success: false,
        message: 'Network সমস্যা: ${e.toString()}',
        code: 'NETWORK_ERROR',
      );
    }
  }

  /// Send due notification SMS
  Future<SmsResponse> sendDueNotification({
    required String phone,
    required String customerName,
    required double amount,
    required String transactionType,
  }) async {
    String message;

    switch (transactionType.toLowerCase()) {
      case 'received':
        // Customer paid money
        message =
            'Dear $customerName, you paid ${amount.toStringAsFixed(0)} BDT to $_brandName. Thank you!';
        break;

      case 'given':
        // Shop gave credit
        message =
            'Dear $customerName, your due at $_brandName is now ${amount.toStringAsFixed(0)} BDT. Please pay soon.';
        break;

      case 'reminder':
        // Reminder for existing due
        message =
            'Dear $customerName, reminder: your due balance at $_brandName is ${amount.toStringAsFixed(0)} BDT.';
        break;

      case 'paid':
        // Due fully paid
        message =
            'Dear $customerName, your due at $_brandName has been cleared. Thank you!';
        break;

      default:
        message =
            'Dear $customerName, transaction of ${amount.toStringAsFixed(0)} BDT at $_brandName.';
    }

    return await sendSms(phone, message);
  }

  /// Validate Bangladesh phone number
  bool _isValidBangladeshPhone(String phone) {
    // Remove spaces, dashes
    phone = phone.replaceAll(RegExp(r'[\s-]'), '');

    // Check format: 01XXXXXXXXX (11 digits)
    if (phone.length == 11 && phone.startsWith('01')) {
      return true;
    }

    // Check with country code: 8801XXXXXXXXX (13 digits)
    if (phone.length == 13 && phone.startsWith('880')) {
      return true;
    }

    return false;
  }

  /// Format phone number for API (add 88 prefix if needed)
  String _formatPhoneForAPI(String phone) {
    // Remove non-digits
    phone = phone.replaceAll(RegExp(r'\D'), '');

    // Add 88 prefix if missing
    if (phone.startsWith('01')) {
      phone = '88$phone';
    }

    return phone; // Returns 8801XXXXXXXXX
  }

  /// Clean expired OTPs from cache
  void _cleanExpiredOTPs() {
    final now = DateTime.now();
    _otpCache.removeWhere((key, value) => value.expiresAt.isBefore(now));
  }

  /// Get OTP cache size (for debugging)
  int get otpCacheSize => _otpCache.length;

  /// Clear all OTP cache (for testing)
  void clearOtpCache() {
    _otpCache.clear();
    _otpAttempts.clear();
  }
}

/// OTP Entry with expiry
class OtpEntry {
  final String otp;
  final DateTime expiresAt;

  OtpEntry(this.otp, this.expiresAt);
}

/// SMS Response model
class SmsResponse {
  final bool success;
  final String message;
  final String? code;

  SmsResponse({
    required this.success,
    required this.message,
    this.code,
  });

  @override
  String toString() {
    return 'SmsResponse(success: $success, message: $message, code: $code)';
  }
}
