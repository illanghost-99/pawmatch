import 'package:flutter/material.dart';
import '../app_state.dart';

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
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F1),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            const Text('Dina uppgifter', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Fyll i en gång efter första inloggningen. Kontot granskas, men du kan använda appen under tiden.'),
            const SizedBox(height: 20),
            TextField(controller: first, textCapitalization: TextCapitalization.words, decoration: _d('Förnamn')),
            const SizedBox(height: 10),
            TextField(controller: last, textCapitalization: TextCapitalization.words, decoration: _d('Efternamn')),
            const SizedBox(height: 10),
            TextField(controller: pnr, keyboardType: TextInputType.number, decoration: _d('Personnummer (ÅÅÅÅMMDD-XXXX)')),
            const SizedBox(height: 10),
            TextField(controller: addr, decoration: _d('Adress')),
            const SizedBox(height: 10),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: _d('Telefon')),
            const SizedBox(height: 10),
            TextField(controller: mail, keyboardType: TextInputType.emailAddress, decoration: _d('E-post')),
            CheckboxListTile(
              value: consent,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => consent = v ?? false),
              title: const Text(
                'Jag godkänner att PawMatch sparar uppgifterna för säkerhet och för att kunna skicka avtal till mig.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: FilledButton(
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
                child: const Text('Fortsätt'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
