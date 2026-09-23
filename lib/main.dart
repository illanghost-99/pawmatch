import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'services/cloud.dart';
import 'services/push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  const pub = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');
  final resolved = pub.isNotEmpty ? pub : key;
  if (url.isNotEmpty && resolved.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: resolved);
    Cloud.supabase = true;
  }

  await PushService.init();
  runApp(const PawMatchApp());
}
