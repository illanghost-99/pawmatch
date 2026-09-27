import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/paws_bg.dart';

const _coral = Color(0xFFE25C3A);
const _ink = Color(0xFF14202B);
const _cream = Color(0xFFFFF4EC);

const _codes = [
  ('+46', 'Sverige'),
  ('+47', 'Norge'),
  ('+45', 'Danmark'),
  ('+49', 'Tyskland'),
];

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key, required this.state});
  final AppState state;
  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  final first = TextEditingController();
  final last = TextEditingController();
  final localPhone = TextEditingController();
  final mail = TextEditingController();
  bool consent = false;
  bool adult = false;
  String code = '+46';
  String? error;

  @override
  void initState() {
    super.initState();
    mail.text = widget.state.email;
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    localPhone.dispose();
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

  bool _letters(String s) => RegExp(r"^[A-Za-zÅÄÖåäöÉéÜü\-\s]{2,}$").hasMatch(s.trim());
  bool _mailOk(String s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

  bool _phoneOk() {
    final n = localPhone.text.replaceAll(RegExp(r'\D'), '');
    if (code == '+46') {
      if (n.startsWith('07')) return n.length == 10;
      if (n.startsWith('7')) return n.length == 9;
      return n.length == 9;
    }
    return n.length >= 8 && n.length <= 11;
  }

  String get _fullPhone {
    var n = localPhone.text.replaceAll(RegExp(r'\D'), '');
    if (code == '+46' && n.startsWith('0')) n = n.substring(1);
    return '$code$n';
  }

  void _formatPhone(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) d = d.substring(1);
    if (d.length > 9) d = d.substring(0, 9);
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 2 || i == 5 || i == 7) buf.write(' ');
      buf.write(d[i]);
    }
    final next = buf.toString();
    if (next != localPhone.text) {
      localPhone.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
    }
  }

  void _submit() {
    if (!adult) {
      setState(() => error = 'Du måste vara 18 år för att använda PawMatch.');
      return;
    }
    if (!consent) {
      setState(() => error = 'Godkänn att vi sparar namn, telefon och e-post.');
      return;
    }
    if (!_letters(first.text) || !_letters(last.text)) {
      setState(() => error = 'Skriv för- och efternamn.');
      return;
    }
    if (!_phoneOk()) {
      setState(() => error = 'Ogiltigt nummer.');
      return;
    }
    if (!_mailOk(mail.text)) {
      setState(() => error = 'Ogiltig e-post.');
      return;
    }
    widget.state.saveIdentity(
      first: first.text.trim(),
      last: last.text.trim(),
      pnr: '',
      addr: '',
      tel: _fullPhone,
      mail: mail.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: PawsBg(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            children: [
              const Text('Lite om dig', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink)),
              const SizedBox(height: 8),
              const Text(
                'Bara namn, telefon och e-post. Inget personnummer.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3D4A57)),
              ),
              const SizedBox(height: 22),
              TextField(controller: first, textCapitalization: TextCapitalization.words, decoration: _d('Förnamn')),
              const SizedBox(height: 12),
              TextField(controller: last, textCapitalization: TextCapitalization.words, decoration: _d('Efternamn')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFD7C4B5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: code,
                        onChanged: (v) => setState(() => code = v ?? '+46'),
                        items: [
                          for (final c in _codes)
                            DropdownMenuItem(value: c.$1, child: Text('${c.$1}  ${c.$2}')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: localPhone,
                      keyboardType: TextInputType.phone,
                      onChanged: _formatPhone,
                      decoration: _d('Telefon'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: mail, keyboardType: TextInputType.emailAddress, decoration: _d('E-post')),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Color(0xFF8B3A32), fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 12),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: CheckboxListTile(
                  value: adult,
                  activeColor: _coral,
                  onChanged: (v) => setState(() => adult = v ?? false),
                  title: const Text('Jag är 18 år eller äldre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: CheckboxListTile(
                  value: consent,
                  activeColor: _coral,
                  onChanged: (v) => setState(() => consent = v ?? false),
                  title: const Text('Jag godkänner att PawMatch sparar namn, telefon och e-post.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: (consent && adult) ? _coral : const Color(0xFFC9B8AD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: _submit,
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
