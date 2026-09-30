import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool ready = false;
  static int _id = 1;

  static Future<void> init() async {
    if (kIsWeb || ready) return;
    try {
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(iOS: ios, android: android),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      ready = true;
    } catch (e) {
      debugPrint('[Push] init: $e');
    }
  }

  static Future<void> _show(String title, String body) async {
    if (!ready) await init();
    if (!ready) return;
    try {
      await _plugin.show(
        _id++,
        title,
        body,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
          android: AndroidNotificationDetails(
            'pawmatch',
            'PawMatch',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
          ),
        ),
      );
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('[Push] show: $e');
    }
  }

  static Future<void> notifyMatch(String dogName) =>
      _show('Ny match', 'Någon vill matcha med $dogName');

  static Future<void> notifyMessage(String from) =>
      _show('Nytt meddelande', '$from har skrivit till dig');

  static Future<void> notifyApproved(String dogName) =>
      _show('Godkänd', '$dogName är godkänd och synlig');

  static Future<void> notifyLive(String dogName) =>
      _show('Publicerad', '$dogName syns nu i PawMatch');
}
