// lib/services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static const _keyPassword = 'admin_password_hash';
  static final _storage = FlutterSecureStorage();

  // Hash SHA-256
  static String _hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Vérifie si un mot de passe admin est déjà défini
  static Future<bool> isPasswordSet() async {
    final stored = await _storage.read(key: _keyPassword);
    return stored != null;
  }

  // Définit le mot de passe (stocke le hash)
  static Future<void> setPassword(String plain) async {
    final h = _hash(plain);
    await _storage.write(key: _keyPassword, value: h);
  }

  // Vérifie le mot de passe
  static Future<bool> verifyPassword(String plain) async {
    final stored = await _storage.read(key: _keyPassword);
    if (stored == null) return false;
    return _hash(plain) == stored;
  }

  // Supprime le mot de passe (option admin)
  static Future<void> clearPassword() async {
    await _storage.delete(key: _keyPassword);
  }
}
