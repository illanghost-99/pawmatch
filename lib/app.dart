import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_state.dart';
import 'features/auth.dart';
import 'features/onboarding.dart';
import 'features/shell.dart';

class PawMatchApp extends StatefulWidget {
  const PawMatchApp({super.key});
  @override
  State<PawMatchApp> createState() => _PawMatchAppState();
}

class _PawMatchAppState extends State<PawMatchApp> {
  final state = AppState();

  @override
  Widget build(BuildContext context) {
    const rose = Color(0xFFC23B2E);
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) {
        return MaterialApp(
          title: 'PawMatch',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: rose),
            textTheme: GoogleFonts.dmSansTextTheme(),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFFFF6F4),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: rose, brightness: Brightness.dark),
            textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
            useMaterial3: true,
          ),
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: !state.signedIn
                ? AuthScreen(key: const ValueKey('auth'), state: state)
                : !state.onboarded
                    ? OnboardingFlow(key: const ValueKey('onboard'), state: state)
                    : AppShell(key: const ValueKey('shell'), state: state),
          ),
        );
      },
    );
  }
}
