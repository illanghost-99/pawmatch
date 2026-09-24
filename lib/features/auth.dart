import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/biometrics.dart';
import '../services/cloud.dart';
import '../widgets/duo_dogs.dart';
import '../widgets/paws_bg.dart';

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
    setState(() => busy = true);
    final mail = email.text.trim();
    final mode = await Cloud.login(email: mail, password: pass.text, create: create);
    if (!mounted) return;
    final ok = mode == 'cloud';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(duration: const Duration(seconds: 6), content: Text(ok ? 'Konto kopplat till Supabase' : mode)),
    );
    if (ok || !Cloud.ready) {
      widget.state.signIn(mail.isEmpty ? 'du@pawmatch.app' : mail);
    }
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
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                child: Column(
                  children: [
                    const DuoDogs(size: 168),
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 4),
                    Text(
                      Cloud.ready ? 'Supabase är på' : 'Kör lokalt',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Cloud.ready ? const Color(0xFF1F7A6C) : const Color(0xFF8B3A32)),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: _field('E-post')),
                    const SizedBox(height: 10),
                    TextField(controller: pass, obscureText: true, decoration: _field('Lösenord')),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x55E25C3A), blurRadius: 16, offset: Offset(0, 8)),
                          ],
                        ),
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _coral,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: busy ? null : _go,
                          child: Text(
                            busy ? 'Väntar...' : (create ? 'Skapa konto' : 'Kom igång'),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    if (bioOk) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _ink,
                            side: const BorderSide(color: _ink, width: 1.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: busy
                              ? null
                              : () async {
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
