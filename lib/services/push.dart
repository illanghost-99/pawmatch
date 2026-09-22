import 'package:flutter/foundation.dart';

/// Push-notiser: struktur klar för FCM/APNs.
/// Riktiga push kräver Firebase-projekt + Apple Push (APNs) på Mac/Xcode.
/// Här loggas händelser så UI och backend kan kopplas utan att krascha.
class PushService {
  static Future<void> init() async {
    // TODO: Firebase.initializeApp() + FirebaseMessaging.instance.requestPermission()
    debugPrint('[Push] init (placeholder — lägg Firebase när du har Mac + APNs)');
  }

  static Future<void> notifyMatch(String dogName) async {
    debugPrint('[Push] Ny match med $dogName');
  }

  static Future<void> notifyMessage(String from) async {
    debugPrint('[Push] Nytt meddelande från $from');
  }

  static Future<void> notifyApproved(String dogName) async {
    debugPrint('[Push] $dogName är godkänd och syns i appen');
  }

  static Future<void> notifyLive(String dogName) async {
    debugPrint('[Push] $dogName är publicerad');
  }
}
