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
    final auth = Supabase.instance.client.auth;
    final mail = email.trim();
    try {
      if (create) {
        return await _signUpThenIn(auth, mail, password);
      }
      await auth.signInWithPassword(email: mail, password: password).timeout(const Duration(seconds: 10));
      return 'cloud';
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login') || msg.contains('invalid_credentials') || e.statusCode == '400') {
        return await _signUpThenIn(auth, mail, password);
      }
      if (msg.contains('already')) {
        try {
          await auth.signInWithPassword(email: mail, password: password).timeout(const Duration(seconds: 10));
          return 'cloud';
        } catch (e2) {
          return e2.toString();
        }
      }
      return e.message;
    } catch (e) {
      debugPrint('Supabase auth: $e');
      final t = e.toString().toLowerCase();
      if (t.contains('invalid login') || t.contains('invalid_credentials')) {
        return await _signUpThenIn(auth, mail, password);
      }
      return e.toString();
    }
  }

  static Future<String> _signUpThenIn(GoTrueClient auth, String mail, String password) async {
    try {
      final res = await auth.signUp(email: mail, password: password).timeout(const Duration(seconds: 10));
      if (res.user == null) return 'Inget konto skapades. Kolla Confirm email i Supabase.';
      if (res.session == null) {
        try {
          await auth.signInWithPassword(email: mail, password: password).timeout(const Duration(seconds: 10));
        } catch (_) {}
      }
      return 'cloud';
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already')) {
        await auth.signInWithPassword(email: mail, password: password).timeout(const Duration(seconds: 10));
        return 'cloud';
      }
      return e.message;
    }
  }
}
