import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:med_journal/l10n/l10n_lookup.dart';

class AppLockService {
  static final AppLockService instance = AppLockService._();
  AppLockService._();

  static const _secure = FlutterSecureStorage();

  static const _kEnabled = 'app_lock_enabled';
  static const _kTimeoutSeconds = 'app_lock_timeout_seconds';
  static const _kLastBackgroundMs = 'app_lock_last_background_ms';
  static const _kLastUnlockMs = 'app_lock_last_unlock_ms';
  static const _kFailedAttempts = 'app_lock_failed_attempts';
  static const _kLockoutUntilMs = 'app_lock_lockout_until_ms';

  static const _kPinSalt = 'app_lock_pin_salt';
  static const _kPinHash = 'app_lock_pin_hash';
  static const _kBiometricEnabled = 'app_lock_biometric_enabled';

  static const int maxAttempts = 3;
  static const Duration lockoutDuration = Duration(minutes: 2);

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> isEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_kEnabled) ?? false;
  }

  Future<void> setEnabled(bool v) async {
    final prefs = await _prefs;
    await prefs.setBool(_kEnabled, v);
  }

  Future<int> getTimeoutSeconds() async {
    final prefs = await _prefs;
    return prefs.getInt(_kTimeoutSeconds) ?? 0; // 0 = inmediato al volver
  }

  Future<void> setTimeoutSeconds(int seconds) async {
    final prefs = await _prefs;
    await prefs.setInt(_kTimeoutSeconds, seconds.clamp(0, 86400));
  }

  Future<void> markBackgroundedNow() async {
    final prefs = await _prefs;
    await prefs.setInt(
      _kLastBackgroundMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> markUnlockedNow() async {
    final prefs = await _prefs;
    await prefs.setInt(_kLastUnlockMs, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> shouldRequireUnlockNow() async {
    if (!await isEnabled()) return false;
    if (!await hasPin()) return false;

    final prefs = await _prefs;
    final lastBg = prefs.getInt(_kLastBackgroundMs);
    final lastUnlock = prefs.getInt(_kLastUnlockMs);
    final timeout = await getTimeoutSeconds();

    // Cold start: si nunca se desbloqueó en este dispositivo, pedir.
    if (lastUnlock == null) return true;

    // Si nunca se fue a background desde que existe el lock, no pedir.
    if (lastBg == null) return false;

    // Si ya se desbloqueó DESPUÉS del último background, no pedir.
    if (lastUnlock >= lastBg) return false;

    final elapsedMs = DateTime.now().millisecondsSinceEpoch - lastBg;
    return elapsedMs >= (timeout * 1000);
  }

  Future<bool> hasPin() async {
    final salt = await _secure.read(key: _kPinSalt);
    final hash = await _secure.read(key: _kPinHash);
    return (salt != null && salt.isNotEmpty) &&
        (hash != null && hash.isNotEmpty);
  }

  Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    final hash = _hashPin(pin, salt);
    await _secure.write(key: _kPinSalt, value: salt);
    await _secure.write(key: _kPinHash, value: hash);
  }

  Future<void> clearPin() async {
    await _secure.delete(key: _kPinSalt);
    await _secure.delete(key: _kPinHash);
  }

  Future<int> failedAttempts() async {
    final prefs = await _prefs;
    return prefs.getInt(_kFailedAttempts) ?? 0;
  }

  Future<DateTime?> lockoutUntil() async {
    final prefs = await _prefs;
    final ms = prefs.getInt(_kLockoutUntilMs);
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<Duration?> lockoutRemaining() async {
    final until = await lockoutUntil();
    if (until == null) return null;
    final diff = until.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Future<void> _setLockoutUntil(DateTime? until) async {
    final prefs = await _prefs;
    await prefs.setInt(_kLockoutUntilMs, until?.millisecondsSinceEpoch ?? 0);
  }

  Future<void> _setFailedAttempts(int n) async {
    final prefs = await _prefs;
    await prefs.setInt(_kFailedAttempts, n);
  }

  Future<void> resetLockoutState() async {
    await _setFailedAttempts(0);
    await _setLockoutUntil(null);
  }

  Future<bool> verifyPin(String pin) async {
    final remaining = await lockoutRemaining();
    if (remaining != null && remaining > Duration.zero) {
      return false;
    }

    final salt = await _secure.read(key: _kPinSalt);
    final storedHash = await _secure.read(key: _kPinHash);
    if (salt == null || storedHash == null) return false;

    final isOk = _hashPin(pin, salt) == storedHash;

    if (isOk) {
      await resetLockoutState();
      await markUnlockedNow();
      return true;
    }

    final attempts = (await failedAttempts()) + 1;
    if (attempts >= maxAttempts) {
      await _setFailedAttempts(0);
      await _setLockoutUntil(DateTime.now().add(lockoutDuration));
    } else {
      await _setFailedAttempts(attempts);
    }
    return false;
  }

  String _randomSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final normalized = pin.trim();
    final bytes = utf8.encode('$salt:$normalized');
    return sha256.convert(bytes).toString();
  }

  // ========== Biometric Authentication ==========

  /// Check si si la autenticación biométrica está habilitada.
  Future<bool> isBiometricEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  /// Habilitar o deshabilitar la autenticación biométrica.
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_kBiometricEnabled, enabled);
  }

  /// Check si el dispositivo soporta la autenticación biométrica.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Check si el dispositivo tiene biometría inscrita.
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Obtener los tipos de biometría disponibles.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Autenticar usando biometría.
  ///
  /// Retorna true si la autenticación biométrica tiene éxito.
  /// Si la autenticación biométrica falla o no está disponible, retorna false (el llamador debe volver a PIN).
  Future<bool> authenticateWithBiometrics() async {
    if (!await isBiometricEnabled()) {
      if (kDebugMode) {
        debugPrint('Biometric auth not enabled');
      }
      return false;
    }

    try {
      final l10n = lookupL10n();
      final authenticated = await _localAuth.authenticate(
        localizedReason: l10n.appLockBiometricReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await resetLockoutState();
        await markUnlockedNow();
      }

      return authenticated;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Biometric auth error: $e');
      }
      return false;
    }
  }
}
