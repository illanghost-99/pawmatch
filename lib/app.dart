import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_state.dart';
import 'features/auth.dart';
import 'features/identity.dart';
import 'features/onboarding.dart';
import 'features/shell.dart';
import 'services/store.dart';

class PawMatchApp extends StatefulWidget {
  const PawMatchApp({super.key});
  @override
  State<PawMatchApp> createState() => _PawMatchAppState();
}

class _PawMatchAppState extends State<PawMatchApp> {
  final state = AppState();

  @override
  void initState() {
    super.initState();
    state.restore();
    Store.boot((ok) {
      if (ok) state.startLaunchOffer();
    });
  }

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFE25C3A);
    const ink = Color(0xFF14202B);
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) {
        Widget home;
        if (!state.sessionReady) {
          home = const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (!state.signedIn) {
          home = AuthScreen(key: const ValueKey('auth'), state: state);
        } else if (!state.idConsent) {
          home = IdentityScreen(key: const ValueKey('id'), state: state);
        } else if (state.banNote.isNotEmpty) {
          home = _ClosedAccount(state: state);
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
          themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: coral,
              brightness: Brightness.dark,
              primary: coral,
              surface: const Color(0xFF1C1410),
              onSurface: const Color(0xFFFFF4EC),
            ),
            scaffoldBackgroundColor: const Color(0xFF1C1410),
            useMaterial3: true,
          ),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: coral,
              primary: coral,
              secondary: const Color(0xFF1F7A6C),
              surface: const Color(0xFFFFF4EC),
              onSurface: ink,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFFFF4EC),
            appBarTheme: const AppBarTheme(
              foregroundColor: ink,
              titleTextStyle: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 20),
            ),
            listTileTheme: const ListTileThemeData(
              titleTextStyle: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 16),
              subtitleTextStyle: TextStyle(color: Color(0xFF3D4A57), fontSize: 13),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: coral,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          home: home,
        );
      },
    );
  }
}

class _ClosedAccount extends StatelessWidget {
  const _ClosedAccount({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4EC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Color(0xFF8B3A32)),
              const SizedBox(height: 16),
              const Text('Kontot är avstängt', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(state.banNote, textAlign: TextAlign.center, style: const TextStyle(height: 1.4, fontSize: 16)),
              const SizedBox(height: 20),
              FilledButton(onPressed: state.signOut, child: const Text('Logga ut')),
            ],
          ),
        ),
      ),
    );
  }
}
