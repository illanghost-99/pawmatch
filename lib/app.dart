import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    const navy = Color(0xFF152033);
    const gold = Color(0xFFC9A24A);
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) {
        return MaterialApp(
          title: 'PawMatch',
          locale: const Locale('sv'),
          supportedLocales: const [Locale('sv'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: navy, secondary: gold),
            textTheme: GoogleFonts.dmSansTextTheme(),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF7F4EE),
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
