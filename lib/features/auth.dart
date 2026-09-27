import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/biometrics.dart';
import '../services/cloud.dart';
import '../widgets/paws_bg.dart';
import '../widgets/welcome_hero.dart';

const _coral = Color(0xFFE25C3A);
const _ink = Color(0xFF14202B);
const _cream = Color(0xFFFFF4EC);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool create = false;
  bool bioOk = false;
  bool busy = false;
  final email = TextEditingController();
  final pass = TextEditingController();

  @override
  void initState() {
    super.initState();
    Biometrics.available().then((v) {
      if (mounted) setState(() => bioOk = v);
    });
  }

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (busy) return;
    final mail = email.text.trim();
    if (!mail.contains('@') || pass.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skriv e-post och lösenord (minst 6 tecken).')),
      );
      return;
    }
    setState(() => busy = true);
    final mode = await Cloud.login(email: mail, password: pass.text, create: create);
    if (!mounted) return;
    final ok = mode == 'cloud';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text(
          ok
              ? (create ? 'Konto skapat' : 'Välkommen in')
              : (mode.contains('rate') ? 'Försök igen om en stund' : 'Kunde inte logga in. $mode'),
        ),
      ),
    );
    if (ok) widget.state.signIn(mail);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: PawsBg(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                child: Column(
                  children: [
                    const WelcomeHero(size: 176),
                    const SizedBox(height: 8),
                    const Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: _ink, height: 1),
                        children: [
                          TextSpan(text: 'Paw'),
                          TextSpan(text: 'Match', style: TextStyle(color: _coral)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Stor som liten. Vän eller avel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3D4A57)),
                    ),
                    const SizedBox(height: 20),
                    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: _field('E-post')),
                    const SizedBox(height: 10),
                    TextField(controller: pass, obscureText: true, decoration: _field('Lösenord')),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _coral,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: busy ? null : _go,
                        child: Text(
                          busy ? 'Väntar...' : (create ? 'Skapa konto' : 'Logga in'),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (bioOk) ...[
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('eller', style: TextStyle(color: Color(0xFF8A7A70), fontWeight: FontWeight.w600)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _ink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: busy
                              ? null
                              : () async {
                                  final ok = await Biometrics.unlock(reason: 'Logga in i PawMatch');
                                  if (ok && mounted && widget.state.email.contains('@')) {
                                    widget.state.signIn(widget.state.email);
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Logga in med e-post först. Face ID låser upp nästa gång.')),
                                    );
                                  }
                                },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.face_retouching_natural, size: 22),
                              SizedBox(width: 8),
                              Text('Face ID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    TextButton(
                      onPressed: () => setState(() => create = !create),
                      child: Text(
                        create ? 'Har redan konto? Logga in' : 'Ny här? Skapa konto',
                        style: const TextStyle(color: _coral, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Text(
                      'Genom att fortsätta godkänner du villkor och integritetspolicy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF3D4A57)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600, fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2C4B3), width: 1.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _coral, width: 2.2),
        ),
      );
}
