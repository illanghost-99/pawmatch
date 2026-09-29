import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static Future<Map<String, String>> read() async {
    final p = await SharedPreferences.getInstance();
    return {
      'email': p.getString('email') ?? '',
      'signedIn': (p.getBool('signedIn') ?? false).toString(),
      'onboarded': (p.getBool('onboarded') ?? false).toString(),
      'idConsent': (p.getBool('idConsent') ?? false).toString(),
      'firstName': p.getString('firstName') ?? '',
      'lastName': p.getString('lastName') ?? '',
    };
  }

  static Future<void> write({
    required bool signedIn,
    required bool onboarded,
    required bool idConsent,
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('signedIn', signedIn);
    await p.setBool('onboarded', onboarded);
    await p.setBool('idConsent', idConsent);
    await p.setString('email', email);
    await p.setString('firstName', firstName);
    await p.setString('lastName', lastName);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('signedIn');
    await p.remove('email');
  }
}
