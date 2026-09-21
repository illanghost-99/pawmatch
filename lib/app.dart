import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_state.dart';
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
    const rust = Color(0xFFC47A52);
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) {
        return MaterialApp(
          title: 'PawMatch',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: rust),
            textTheme: GoogleFonts.dmSansTextTheme(),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: rust, brightness: Brightness.dark),
            textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
            useMaterial3: true,
          ),
          home: state.onboarded ? AppShell(state: state) : OnboardingFlow(state: state),
        );
      },
    );
  }
}
