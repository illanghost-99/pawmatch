import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'services/cloud.dart';
import 'services/fcm.dart';
import 'services/push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kfdvwsumjoqlgytknwqn.supabase.co',
  );
  const key = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  const pub = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_0ASaNEdifhW8lwMzZ_Tj-Q_0NUFQZ73',
  );
  final resolved = pub.isNotEmpty ? pub : key;

  if (url.isNotEmpty && resolved.isNotEmpty) {
    try {
      await Supabase.initialize(url: url, publishableKey: resolved).timeout(const Duration(seconds: 8));
      Cloud.supabase = true;
    } catch (e) {
      debugPrint('Supabase startades inte: $e');
      Cloud.supabase = false;
    }
  }

  runApp(const PawMatchApp());
  PushService.init();
  Fcm.start();
}
