import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Satpam Digital: Urus Password & Validasi
class SecurityUtils {
  /// Acak-acak password pake SHA-256 biar pusing hacker
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Cek passwordnya bener kaga
  static bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  /// Cek passwordnya lemah ato kuat
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

  /// Cek format email
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

  /// Cek nomor HP (Indo punya)
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

  /// Cek nama (jangan kosong woy)
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

  /// Cek duit (harus ada angkanya)
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

  /// Bersihin input biar ga kena suntik (injection)
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>]'), '') // Remove HTML tags
        .trim();
  }
}
