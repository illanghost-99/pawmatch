import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/biometrics.dart';

const _rust = Color(0xFFC47A52);
const _ink = Color(0xFF1C1410);
const _cream = Color(0xFFF7F1EA);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool create = false;
  bool bioOk = false;
  final email = TextEditingController();
  final pass = TextEditingController();
  late final fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  late final paw = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Biometrics.available().then((v) {
      if (mounted) setState(() => bioOk = v);
    });
  }

  @override
  void dispose() {
    fade.dispose();
    paw.dispose();
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _rust, width: 1.6),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8F2), Color(0xFFEED9C8), Color(0xFFD4A574)],
          ),
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: fade, curve: Curves.easeOut),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  ScaleTransition(
                    scale: Tween(begin: 0.92, end: 1.06).animate(CurvedAnimation(parent: paw, curve: Curves.easeInOut)),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: _rust.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: const Icon(Icons.pets, size: 44, color: _rust),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'PawMatch',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: _ink, letterSpacing: -0.8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    create ? 'Skapa konto och hitta hundvänner eller avel' : 'Välkommen till PawMatch',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: _ink.withValues(alpha: 0.72), height: 1.35),
                  ),
                  const Spacer(),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: _field('E-post')),
                  const SizedBox(height: 12),
                  TextField(controller: pass, obscureText: true, decoration: _field('Lösenord')),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: _cream,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () {
                        widget.state.signIn(email.text.trim().isEmpty ? 'du@pawmatch.app' : email.text.trim());
                      },
                      child: Text(create ? 'Skapa konto' : 'Logga in', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (bioOk) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ink,
                          side: BorderSide(color: _ink.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () async {
                          final ok = await Biometrics.unlock(reason: 'Logga in i PawMatch');
                          if (ok && mounted) {
                            widget.state.signIn(widget.state.email.isEmpty ? 'faceid@pawmatch.app' : widget.state.email);
                          }
                        },
                        icon: const Icon(Icons.face),
                        label: const Text('Face ID / biometri'),
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: () => setState(() => create = !create),
                    child: Text(
                      create ? 'Har redan konto? Logga in' : 'Ny här? Skapa konto',
                      style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    'Genom att fortsätta godkänner du villkor och integritetspolicy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: _ink.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
