import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/validators.dart';

class PinException implements Exception {
  const PinException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Encrypted local storage for sensitive data (PIN, tokens).
class EncryptionService {
  EncryptionService({FlutterSecureStorage? storage})
      : _storage = storage ?? _defaultStorage;

  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  final FlutterSecureStorage _storage;

  static const _pinKey = 'user_pin';
  static const _keyKey = 'encryption_key';

  Future<String?> getPin() => _storage.read(key: _pinKey);

  Future<void> setPin(String pin, {String? currentPin}) async {
    final error = ReadingValidator.validatePin(pin);
    if (error != null) throw PinException(error);
    if (await getPin() != null) {
      await requireCurrentPin(currentPin);
    }
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<void> deletePin({required String currentPin}) async {
    await requireCurrentPin(currentPin);
    await _storage.delete(key: _pinKey);
  }

  Future<void> requireCurrentPin(String? pin) async {
    if (pin == null || !await verifyPin(pin)) {
      throw const PinException('Current PIN is incorrect');
    }
  }

  Future<bool> verifyPin(String pin) async {
    if (ReadingValidator.validatePin(pin) != null) return false;
    final stored = await getPin();
    if (ReadingValidator.validatePin(stored) != null) return false;
    var difference = 0;
    for (var i = 0; i < pin.length; i++) {
      difference |= stored!.codeUnitAt(i) ^ pin.codeUnitAt(i);
    }
    return difference == 0;
  }

  /// Encrypt sensitive string data.
  Future<String> encryptData(String plainText) async {
    final key = await _getOrCreateKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  Future<String> decryptData(String cipherText) async {
    final parts = cipherText.split(':');
    if (parts.length != 2) throw const FormatException('Invalid cipher format');
    final key = await _getOrCreateKey();
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt(encrypt.Encrypted.fromBase64(parts[1]), iv: iv);
  }

  Future<encrypt.Key> _getOrCreateKey() async {
    var keyStr = await _storage.read(key: _keyKey);
    if (keyStr == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      keyStr = key.base64;
      await _storage.write(key: _keyKey, value: keyStr);
    }
    return encrypt.Key.fromBase64(keyStr);
  }
}
