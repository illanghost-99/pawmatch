import 'package:flutter/foundation.dart';

/// Push via Firebase Cloud Messaging (FCM) + APNs på iOS.
///
/// Setup (du gör en gång):
/// 1. Lägg GoogleService-Info.plist i ios/Runner/ (committas INTE)
/// 2. flutter pub add firebase_core firebase_messaging
/// 3. flutterfire configure  (eller manuellt)
/// 4. APNs .p8 i Firebase Console → Cloud Messaging
/// 5. Xcode: Push Notifications capability
///
/// Tills FCM är inkopplat loggar vi bara — appen kraschar inte.
class PushService {
  static bool ready = false;

  static Future<void> init() async {
    try {
      // När du lagt till paketen, avkommentera:
      // await Firebase.initializeApp();
      // final messaging = FirebaseMessaging.instance;
      // await messaging.requestPermission(alert: true, badge: true, sound: true);
      // final token = await messaging.getToken();
      // debugPrint('[FCM] token=$token');
      // // Spara token till Supabase profiles.fcm_token
      ready = false;
      debugPrint('[Push] Klar för FCM — lägg plist + firebase_core/messaging');
    } catch (e) {
      debugPrint('[Push] init skip: $e');
    }
  }

  static Future<void> notifyMatch(String dogName) async {
    debugPrint('[Push] Ny match med $dogName');
    // FCM: skicka via backend/Edge Function till mottagarens token
  }

  static Future<void> notifyMessage(String from) async {
    debugPrint('[Push] Nytt meddelande från $from');
  }

  static Future<void> notifyApproved(String dogName) async {
    debugPrint('[Push] $dogName godkänd och synlig');
  }

  static Future<void> notifyLive(String dogName) async {
    debugPrint('[Push] $dogName publicerad');
  }
}
