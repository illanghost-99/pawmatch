import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/biometrics.dart';

const _navy = Color(0xFF152033);
const _gold = Color(0xFFC9A24A);
const _cream = Color(0xFFF7F4EE);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool create = false;
  bool bioOk = false;
  final email = TextEditingController();
  final pass = TextEditingController();
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
    paw.dispose();
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 52),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 0.94, end: 1.05).animate(CurvedAnimation(parent: paw, curve: Curves.easeInOut)),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.35), blurRadius: 20)],
                        ),
                        child: const Icon(Icons.pets, size: 40, color: _navy),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('PawMatch', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _navy)),
                    const SizedBox(height: 8),
                    Text(
                      create ? 'Skapa konto och hitta hundvänner eller avel' : 'Välkommen till PawMatch',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: _navy.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _field('E-post'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pass,
                      obscureText: true,
                      decoration: _field('Lösenord'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: _cream,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () {
                          widget.state.signIn(email.text.trim().isEmpty ? 'du@pawmatch.app' : email.text.trim());
                        },
                        child: Text(create ? 'Skapa konto' : 'Logga in'),
                      ),
                    ),
                    if (bioOk) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
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
                      child: Text(create ? 'Har redan konto? Logga in' : 'Ny här? Skapa konto'),
                    ),
                    Text(
                      'Genom att fortsätta godkänner du villkor och integritetspolicy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: _navy.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );
}
