import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

class BadgeCount {
  static int _shown = -1;

  static Future<void> set(int count) async {
    final n = count < 0 ? 0 : count;
    if (n == _shown) return;
    _shown = n;
    try {
      await AppBadgePlus.updateBadge(n);
    } catch (e) {
      debugPrint('badge $e');
    }
  }
}
