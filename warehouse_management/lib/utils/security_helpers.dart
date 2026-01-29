import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Security utility functions for PIN management
class SecurityHelpers {
  /// Hashes a PIN using SHA-256
  ///
  /// Takes a plaintext PIN string and returns a secure hash.
  /// This hash is stored in the database instead of the plaintext PIN.
  ///
  /// Example:
  /// ```dart
  /// final hashedPin = SecurityHelpers.hashPin('12345');
  /// // Returns: "5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5"
  /// ```
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies a plaintext PIN against a stored hash
  ///
  /// Takes an input PIN (entered by user) and compares it to the stored hash.
  /// Returns true if they match, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final storedHash = SecurityHelpers.hashPin('12345');
  /// final isValid = SecurityHelpers.verifyPin('12345', storedHash);
  /// // Returns: true
  /// ```
  static bool verifyPin(String inputPin, String storedHash) {
    return hashPin(inputPin) == storedHash;
  }

  /// Validates PIN format (5 digits, numeric only)
  ///
  /// Returns true if the PIN meets format requirements:
  /// - Exactly 5 characters
  /// - Contains only digits (0-9)
  ///
  /// Example:
  /// ```dart
  /// SecurityHelpers.isValidPinFormat('12345'); // true
  /// SecurityHelpers.isValidPinFormat('1234');  // false (too short)
  /// SecurityHelpers.isValidPinFormat('1234a'); // false (contains letter)
  /// ```
  static bool isValidPinFormat(String pin) {
    if (pin.length != 5) return false;
    return RegExp(r'^\d{5}$').hasMatch(pin);
  }
}
