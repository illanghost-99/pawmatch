import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> pawmatchBg(RemoteMessage message) async {}

class Fcm {
  static String? token;
  static void Function(String token)? onToken;

  static Future<void> start() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(pawmatchBg);
      final m = FirebaseMessaging.instance;
      await m.requestPermission(alert: true, badge: true, sound: true);
      await m.setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: false);
      token = await _token(m);
      flush();
      m.onTokenRefresh.listen((t) {
        token = t;
        flush();
      });
    } catch (e) {
      debugPrint('FCM skip: $e');
    }
  }

  static Future<void> keepAlive() async {
    if (kIsWeb) return;
    try {
      if (token == null || token!.isEmpty) {
        token = await FirebaseMessaging.instance.getToken();
      }
    } catch (e) {
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
