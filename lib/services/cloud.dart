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
    if (!ready) return 'Ingen kontakt med servern. Stäng appen, öppna den igen och försök på nytt.';
    final mail = email.trim().toLowerCase();
    if (!mail.contains('@') || !mail.contains('.')) return 'Skriv en giltig e-post.';
    if (password.length < 6) return 'Lösenordet måste vara minst 6 tecken.';
    final auth = Supabase.instance.client.auth;
    try {
      await auth.signOut();
    } catch (_) {}
    try {
      if (create) return await _create(auth, mail, password);
      await auth.signInWithPassword(email: mail, password: password).timeout(const Duration(seconds: 15));
      return 'cloud';
    } catch (e) {
      debugPrint('auth $e');
      return _text(e);
    }
  }

  static Future<String> _create(GoTrueClient auth, String mail, String password) async {
    try {
      final res = await auth.signUp(email: mail, password: password).timeout(const Duration(seconds: 15));
      if (res.session != null) return 'cloud';
      if (res.user != null) {
        try {
          await auth.signInWithPassword(email: mail, password: password).timeout(const Duration(seconds: 15));
          return 'cloud';
        } catch (e) {
          final text = _text(e);
          if (text.contains('bekräfta')) return text;
        }
        return 'cloud';
      }
      return 'Kontot kunde inte skapas. Försök igen om en stund.';
    } on AuthException catch (e) {
      final low = e.message.toLowerCase();
      if (low.contains('already') || low.contains('registered') || low.contains('exists')) {
        try {
          await auth.signInWithPassword(email: mail, password: password).timeout(const Duration(seconds: 15));
          return 'cloud';
        } catch (_) {
          return 'Den e-posten har redan ett konto. Tryck Logga in och använd det lösenord du valde då.';
        }
      }
      return _text(e);
    }
  }

  static String _text(Object e) {
    final raw = e is AuthException ? e.message : '$e';
    final low = raw.toLowerCase();
    if (low.contains('invalid login') || low.contains('invalid credentials')) {
      return 'Fel e-post eller lösenord.';
    }
    if (low.contains('not confirmed') || low.contains('confirm')) {
      return 'Öppna mejlet och bekräfta kontot. Logga sedan in.';
    }
    if (low.contains('already') || low.contains('registered') || low.contains('exists')) {
      return 'Den e-posten har redan ett konto. Tryck Logga in.';
    }
    if (low.contains('password')) return 'Välj ett lösenord med minst 6 tecken.';
    if (low.contains('rate') || low.contains('too many') || low.contains('once every')) {
      return 'För många försök. Vänta en minut och prova igen.';
    }
    if (low.contains('disabled') || low.contains('not allowed')) {
      return 'Nya konton är tillfälligt avstängda.';
    }
    if (low.contains('network') || low.contains('socket') || low.contains('timeout') || low.contains('failed host')) {
      return 'Ingen kontakt med servern. Kolla nätet och försök igen.';
    }
    return 'Det gick inte just nu. Försök igen.';
  }
}
