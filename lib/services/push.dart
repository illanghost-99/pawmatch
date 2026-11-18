import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool ready = false;
  static int _id = 1;
  static String? _pending;
  static void Function(String kind)? _onTap;

  static set onTap(void Function(String kind) cb) {
    _onTap = cb;
    final waiting = _pending;
    if (waiting != null && waiting.isNotEmpty) {
      _pending = null;
      cb(waiting);
    }
  }

  static void _deliverTap(String? kind) {
    final value = (kind ?? '').trim();
    if (value.isEmpty) return;
    final cb = _onTap;
    if (cb == null) {
      _pending = value;
      return;
    }
    cb(value);
  }

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
        onDidReceiveNotificationResponse: (response) => _deliverTap(response.payload),
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _deliverTap(launch?.notificationResponse?.payload);
      }
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      ready = true;
    } catch (e) {
      debugPrint('[Push] init: $e');
    }
  }

  static Future<void> _show(String title, String body, {String kind = ''}) async {
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
        payload: kind,
      );
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('[Push] show: $e');
    }
  }

  static Future<void> notifyLike(String dogName) =>
      _show('Någon vill matcha', dogName.trim().isEmpty ? 'Någon vill matcha med din hund.' : 'Någon vill matcha med $dogName', kind: 'match');

  static Future<void> notifyMatch(String dogName) =>
      _show('Ny matchning', dogName.trim().isEmpty ? 'Ni matchade. Öppna chatten.' : 'Ny matchning med $dogName', kind: 'matched');

  static Future<void> notifyMessage(String from) =>
      _show('Nytt meddelande', '$from har skrivit till dig', kind: 'chat');

  static Future<void> notifyGroup(String name) =>
      _show('Grupp', 'Nytt meddelande i $name', kind: 'group');

  static Future<void> notifySupport() =>
      _show('Support', 'PawMatch har svarat på ditt ärende', kind: 'support');

  static Future<void> notifyApproved(String dogName) =>
      _show('PawMatch', '$dogName är godkänd och synlig');

  static Future<void> notifyLive(String dogName) =>
      _show('PawMatch', '$dogName syns nu i PawMatch');
}
