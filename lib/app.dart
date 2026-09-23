import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_state.dart';
import 'features/auth.dart';
import 'features/identity.dart';
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
    const coral = Color(0xFFE25C3A);
    const ink = Color(0xFF1B2430);
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) {
        Widget home;
        if (!state.signedIn) {
          home = AuthScreen(key: const ValueKey('auth'), state: state);
        } else if (!state.idConsent) {
          home = IdentityScreen(key: const ValueKey('id'), state: state);
        } else if (!state.onboarded) {
          home = OnboardingFlow(key: const ValueKey('onboard'), state: state);
        } else {
          home = AppShell(key: const ValueKey('shell'), state: state);
        }
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
            colorScheme: ColorScheme.fromSeed(
              seedColor: coral,
              primary: coral,
              secondary: const Color(0xFF2A9D8F),
              surface: const Color(0xFFFFF6F1),
            ),
            textTheme: GoogleFonts.dmSansTextTheme(),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFFFF6F1),
            appBarTheme: const AppBarTheme(foregroundColor: ink),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          home: AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: home),
        );
      },
    );
  }
}
