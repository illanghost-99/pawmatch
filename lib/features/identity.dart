import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/paws_bg.dart';

const _coral = Color(0xFFE25C3A);
const _ink = Color(0xFF14202B);
const _cream = Color(0xFFFFF4EC);

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key, required this.state});
  final AppState state;
  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  final first = TextEditingController();
  final last = TextEditingController();
  final pnr = TextEditingController();
  final addr = TextEditingController();
  final phone = TextEditingController();
  final mail = TextEditingController();
  bool consent = false;

  @override
  void initState() {
    super.initState();
    mail.text = widget.state.email;
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    pnr.dispose();
    addr.dispose();
    phone.dispose();
    mail.dispose();
    super.dispose();
  }

  InputDecoration _d(String l) => InputDecoration(
        labelText: l,
        labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0xFFD7C4B5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: _coral, width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: PawsBg(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFF6B6B), _coral, Color(0xFFF4A261)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.badge_outlined, color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dina uppgifter',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink),
              ),
              const SizedBox(height: 8),
              const Text(
                'En gång. Sen kan du använda PawMatch medan vi granskar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3D4A57)),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  value: 0.35,
                  minHeight: 7,
                  color: _coral,
                  backgroundColor: Color(0xFFFFD8C8),
                ),
              ),
              const SizedBox(height: 22),
              TextField(controller: first, textCapitalization: TextCapitalization.words, decoration: _d('Förnamn')),
              const SizedBox(height: 12),
              TextField(controller: last, textCapitalization: TextCapitalization.words, decoration: _d('Efternamn')),
              const SizedBox(height: 12),
              TextField(controller: pnr, keyboardType: TextInputType.number, decoration: _d('Personnummer (ÅÅÅÅMMDD-XXXX)')),
              const SizedBox(height: 12),
              TextField(controller: addr, decoration: _d('Adress')),
              const SizedBox(height: 12),
              TextField(controller: phone, keyboardType: TextInputType.phone, decoration: _d('Telefon')),
              const SizedBox(height: 12),
              TextField(controller: mail, keyboardType: TextInputType.emailAddress, decoration: _d('E-post')),
              const SizedBox(height: 16),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: CheckboxListTile(
                  value: consent,
                  activeColor: _coral,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onChanged: (v) => setState(() => consent = v ?? false),
                  title: const Text(
                    'Jag godkänner att PawMatch sparar uppgifterna för säkerhet och avtal.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: consent ? _coral : const Color(0xFFC9B8AD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () {
                    if (!consent) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kryssa i rutan för att fortsätta.')));
                      return;
                    }
                    if (first.text.trim().isEmpty || last.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fyll i namn.')));
                      return;
                    }
                    widget.state.saveIdentity(
                      first: first.text.trim(),
                      last: last.text.trim(),
                      pnr: pnr.text.trim(),
                      addr: addr.text.trim(),
                      tel: phone.text.trim(),
                      mail: mail.text.trim(),
                    );
                  },
                  child: const Text('Fortsätt', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
