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
    if (!ready) return 'local';
    final mail = email.contains('@') ? email : 'demo@pawmatch.app';
    final pass = password.length >= 6 ? password : 'pawmatch123';
    try {
      final auth = Supabase.instance.client.auth;
      if (create) {
        await auth.signUp(email: mail, password: pass).timeout(const Duration(seconds: 8));
      } else {
        await auth.signInWithPassword(email: mail, password: pass).timeout(const Duration(seconds: 8));
      }
      return 'cloud';
    } catch (e) {
      debugPrint('Supabase auth: $e');
      return 'local';
    }
  }
}
