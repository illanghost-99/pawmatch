import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Cloud {
  static bool supabase = false;

  static bool get ready {
    if (!supabase) return false;
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> login({required String email, required String password, required bool create}) async {
    if (!ready) return 'Molnet är inte startat';
    if (!email.contains('@')) return 'Skriv en riktig e-post';
    if (password.length < 6) return 'Lösenord minst 6 tecken';
    try {
      final auth = Supabase.instance.client.auth;
      if (create) {
        final res = await auth.signUp(email: email.trim(), password: password).timeout(const Duration(seconds: 10));
        if (res.user == null) return 'Inget konto skapades. Kolla Confirm email i Supabase.';
        return 'cloud';
      }
      await auth.signInWithPassword(email: email.trim(), password: password).timeout(const Duration(seconds: 10));
      return 'cloud';
    } catch (e) {
      debugPrint('Supabase auth: $e');
      return e.toString();
    }
  }
}
