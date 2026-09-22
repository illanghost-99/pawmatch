import 'package:flutter/material.dart';
import '../app_state.dart';

/// Enkel e-post + lösenord (lokal / Supabase när nycklar finns).
/// Apple Sign In kopplas i Xcode + Supabase Auth Providers.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool create = false;
  final email = TextEditingController();
  final pass = TextEditingController();
  late final anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();

  @override
  void dispose() {
    anim.dispose();
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text('PawMatch', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  create ? 'Skapa konto — gratis och enkelt' : 'Välkommen tillbaka',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-post', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Lösenord', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    widget.state.signIn(email.text.trim().isEmpty ? 'du@pawmatch.app' : email.text.trim());
                  },
                  child: Text(create ? 'Skapa konto' : 'Logga in'),
                ),
                TextButton(
                  onPressed: () => setState(() => create = !create),
                  child: Text(create ? 'Har redan konto? Logga in' : 'Ny här? Skapa konto'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Genom att fortsätta godkänner du villkor och integritetspolicy.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
