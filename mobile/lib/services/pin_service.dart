import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the 4-digit App Lock PIN.
/// Stores PIN securely using flutter_secure_storage.
class PinService {
  static const String _pinKey = 'app_lock_pin';
  static const String _pinEnabledKey = 'app_lock_enabled';
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Returns whether the App Lock feature is enabled.
  static Future<bool> isEnabled() async {
    final val = await _storage.read(key: _pinEnabledKey);
    return val == 'true';
  }

  /// Returns true if a PIN has been saved.
  static Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Saves a new PIN and enables App Lock.
  static Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _pinEnabledKey, value: 'true');
  }

  /// Verifies the entered PIN against the stored one.
  static Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == enteredPin;
  }

  /// Disables App Lock and removes the stored PIN.
  static Future<void> disablePin() async {
    await _storage.delete(key: _pinKey);
    await _storage.write(key: _pinEnabledKey, value: 'false');
  }

  /// Changes the PIN (requires old PIN verification first).
  static Future<bool> changePin(String oldPin, String newPin) async {
    final valid = await verifyPin(oldPin);
    if (!valid) return false;
    await setPin(newPin);
    return true;
  }
}
