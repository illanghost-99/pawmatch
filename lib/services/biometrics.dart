import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Face ID / Touch ID / biometri på enheten (iOS & Android).
class Biometrics {
  static final _auth = LocalAuthentication();

  static Future<bool> available() async {
    if (kIsWeb) return false;
    try {
      final can = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      return can;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unlock({String reason = 'Lås upp PawMatch'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
