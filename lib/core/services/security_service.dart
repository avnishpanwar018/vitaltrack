import '../utils/validators.dart';
import 'encryption_service.dart';

/// PIN authentication service.
class SecurityService {
  SecurityService(this._encryption);

  final EncryptionService _encryption;

  Future<void> setPin(
    String pin, {
    required String confirmation,
    String? currentPin,
  }) async {
    final error = ReadingValidator.validatePin(pin);
    if (error != null) throw PinException(error);
    if (pin != confirmation) {
      throw const PinException('PINs do not match');
    }
    await _encryption.setPin(pin, currentPin: currentPin);
  }

  Future<bool> verifyPin(String pin) async {
    if (ReadingValidator.validatePin(pin) != null) return false;
    return _encryption.verifyPin(pin);
  }

  Future<void> requireCurrentPin(String pin) =>
      _encryption.requireCurrentPin(pin);

  Future<bool> hasPin() async {
    final pin = await _encryption.getPin();
    // A malformed legacy credential must not allow unauthenticated replacement.
    return pin != null;
  }

  Future<void> removePin({required String currentPin}) =>
      _encryption.deletePin(currentPin: currentPin);
}
