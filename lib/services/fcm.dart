import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> pawmatchBg(RemoteMessage message) async {}

class Fcm {
  static String? token;

  static Future<void> start() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(pawmatchBg);
      final m = FirebaseMessaging.instance;
      await m.requestPermission(alert: true, badge: true, sound: true);
      token = await m.getToken();
      FirebaseMessaging.onMessage.listen((msg) {
        debugPrint('FCM foreground ${msg.notification?.title}');
      });
    } catch (e) {
      debugPrint('FCM skip: $e');
    }
  }
}
