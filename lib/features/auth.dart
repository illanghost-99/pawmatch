import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/biometrics.dart';
import '../services/cloud.dart';

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
    final mail = email.text.trim().isEmpty ? 'du@pawmatch.app' : email.text.trim();
    final mode = await Cloud.login(email: mail, password: pass.text, create: create);
    if (!mounted) return;
    widget.state.signIn(mail);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mode == 'cloud' ? 'Konto kopplat till Supabase' : 'Fortsatte lokalt (molnet svarade inte)')),
    );
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_coral, Color(0xFFF4A261)]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, size: 42, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('PawMatch', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 8),
              Text(
                create ? 'Skapa konto. Ditt konto granskas, men kan användas under tiden.' : 'Välkommen till PawMatch',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF3D4A57)),
              ),
              const SizedBox(height: 10),
              Text(
                Cloud.ready ? 'Supabase är på' : 'Kör lokalt',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Cloud.ready ? const Color(0xFF1F7A6C) : const Color(0xFF8B3A32)),
              ),
              const SizedBox(height: 28),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: _field('E-post')),
              const SizedBox(height: 12),
              TextField(controller: pass, obscureText: true, decoration: _field('Lösenord')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: busy ? null : _go,
                  child: Text(busy ? 'Väntar...' : (create ? 'Skapa konto' : 'Logga in')),
                ),
              ),
              if (bioOk) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: _ink, side: const BorderSide(color: _ink, width: 1.4)),
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
    );
  }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD7C4B5), width: 1.4)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _coral, width: 2)),
      );
}
