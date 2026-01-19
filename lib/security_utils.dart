import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Security utilities untuk password hashing dan validation
class SecurityUtils {
  /// Hash password menggunakan SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify password dengan hash
  static bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  /// Validate password strength
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (password.length < 6) {
      return 'Password minimal 6 karakter';
    }
    // Optional: Check for complexity
    // if (!password.contains(RegExp(r'[A-Z]'))) {
    //   return 'Password harus mengandung huruf besar';
    // }
    return null; // Valid
  }

  /// Validate email format
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Format email tidak valid';
    }
    return null; // Valid
  }

  /// Validate phone number (Indonesia)
  static String? validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return null; // Optional field
    }
    // Remove spaces and dashes
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
    
    if (cleanPhone.length < 10 || cleanPhone.length > 13) {
      return 'Nomor HP harus 10-13 digit';
    }
    if (!cleanPhone.startsWith('0') && !cleanPhone.startsWith('62')) {
      return 'Nomor HP harus diawali 0 atau 62';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return 'Nomor HP hanya boleh angka';
    }
    return null; // Valid
  }

  /// Validate nama (tidak boleh kosong, minimal 3 karakter)
  static String? validateName(String name) {
    if (name.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (name.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return 'Nama hanya boleh huruf dan spasi';
    }
    return null; // Valid
  }

  /// Validate amount (harus angka positif)
  static String? validateAmount(String amount) {
    if (amount.isEmpty) {
      return 'Jumlah tidak boleh kosong';
    }
    final numAmount = int.tryParse(amount);
    if (numAmount == null) {
      return 'Jumlah harus berupa angka';
    }
    if (numAmount <= 0) {
      return 'Jumlah harus lebih dari 0';
    }
    return null; // Valid
  }

  /// Sanitize input (remove dangerous characters)
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>]'), '') // Remove HTML tags
        .trim();
  }
}
