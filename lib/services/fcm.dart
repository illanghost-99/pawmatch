import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> pawmatchBg(RemoteMessage message) async {}

class Fcm {
  static String? token;
  static String? lastError;
  static void Function(String token)? onToken;

  static Future<void> start() async {
    if (kIsWeb) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(pawmatchBg);
      final m = FirebaseMessaging.instance;
      await m.requestPermission(alert: true, badge: true, sound: true);
      await m.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      token = await _token(m);
      lastError = token == null ? 'ingen token' : null;
      flush();
      m.onTokenRefresh.listen((t) {
        token = t;
        lastError = null;
        flush();
      });
    } catch (e) {
      lastError = '$e';
      debugPrint('FCM skip: $e');
    }
  }

  static Future<void> keepAlive() async {
    if (kIsWeb) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final m = FirebaseMessaging.instance;
      final settings = await m.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        await m.requestPermission(alert: true, badge: true, sound: true);
      }
      if (token == null || token!.isEmpty) {
        final apns = await m.getAPNSToken();
        if (apns == null || apns.isEmpty) {
          lastError = 'Apple har inte gett appen en notisnyckel än';
          return;
        }
        token = await m.getToken();
        lastError = token == null ? 'ingen token' : null;
      }
    } catch (e) {
      lastError = '$e';
      debugPrint('FCM keep: $e');
    }
    flush();
  }

  static void flush() {
    final t = token;
    final cb = onToken;
    if (t != null && t.isNotEmpty && cb != null) cb(t);
  }

  static Future<String?> _token(FirebaseMessaging m) async {
    try {
      for (var i = 0; i < 6; i++) {
        final apns = await m.getAPNSToken();
        if (apns != null && apns.isNotEmpty) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      debugPrint('APNs wait: $e');
    }
    try {
      return await m.getToken();
    } catch (e) {
      debugPrint('FCM token: $e');
      return null;
    }
  }
}
