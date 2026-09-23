import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/biometrics.dart';

const _coral = Color(0xFFE25C3A);
const _ink = Color(0xFF1B2430);
const _cream = Color(0xFFFFF6F1);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool create = false;
  bool bioOk = false;
  bool consent = false;
  final email = TextEditingController();
  final pass = TextEditingController();
  final first = TextEditingController();
  final last = TextEditingController();
  final pnr = TextEditingController();
  final addr = TextEditingController();
  final phone = TextEditingController();
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
    first.dispose();
    last.dispose();
    pnr.dispose();
    addr.dispose();
    phone.dispose();
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 0.94, end: 1.05).animate(CurvedAnimation(parent: paw, curve: Curves.easeInOut)),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_coral, Color(0xFFF4A261)]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _coral.withValues(alpha: 0.35), blurRadius: 20)],
                        ),
                        child: const Icon(Icons.pets, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('PawMatch', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _ink)),
                    const SizedBox(height: 6),
                    Text(
                      create ? 'Skapa konto — identitet granskas före avtal' : 'Välkommen till PawMatch',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: _ink.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 22),
                    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: _field('E-post')),
                    const SizedBox(height: 10),
                    TextField(controller: pass, obscureText: true, decoration: _field('Lösenord')),
                    if (create) ...[
                      const SizedBox(height: 10),
                      TextField(controller: first, textCapitalization: TextCapitalization.words, decoration: _field('Förnamn')),
                      const SizedBox(height: 10),
                      TextField(controller: last, textCapitalization: TextCapitalization.words, decoration: _field('Efternamn')),
                      const SizedBox(height: 10),
                      TextField(controller: pnr, keyboardType: TextInputType.number, decoration: _field('Personnummer (ÅÅÅÅMMDD-XXXX)')),
                      const SizedBox(height: 10),
                      TextField(controller: addr, decoration: _field('Adress')),
                      const SizedBox(height: 10),
                      TextField(controller: phone, keyboardType: TextInputType.phone, decoration: _field('Telefon')),
                      CheckboxListTile(
                        value: consent,
                        onChanged: (v) => setState(() => consent = v ?? false),
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Jag samtycker till att PawMatch behandlar mina uppgifter för identitetskontroll och för att skicka avelsavtal. BankID kommer senare.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: _coral, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                        onPressed: () {
                          if (create && !consent) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Du måste godkänna behandlingen av uppgifter.')));
                            return;
                          }
                          final mail = email.text.trim().isEmpty ? 'du@pawmatch.app' : email.text.trim();
                          widget.state.signIn(mail);
                          if (create) {
                            widget.state.saveIdentity(
                              first: first.text.trim(),
                              last: last.text.trim(),
                              pnr: pnr.text.trim(),
                              addr: addr.text.trim(),
                              tel: phone.text.trim(),
                              mail: mail,
                            );
                          }
                        },
                        child: Text(create ? 'Skapa konto och skicka till granskning' : 'Logga in'),
                      ),
                    ),
                    if (bioOk && !create) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await Biometrics.unlock(reason: 'Logga in i PawMatch');
                            if (ok && mounted) widget.state.signIn(widget.state.email.isEmpty ? 'faceid@pawmatch.app' : widget.state.email);
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
                      'Genom att fortsätta godkänner du villkor och integritetspolicy. Personnummer lagras för avtal och raderas om du tar bort kontot.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: _ink.withValues(alpha: 0.55)),
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
