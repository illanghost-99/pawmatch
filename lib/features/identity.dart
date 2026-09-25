import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/suggestions.dart';
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
  final pnr = TextEditingController();
  final addr = TextEditingController();
  final localPhone = TextEditingController();
  final mail = TextEditingController();
  bool consent = false;
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
    pnr.dispose();
    addr.dispose();
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

  DateTime? _birthFromPnr(String s) {
    final d = s.replaceAll(RegExp(r'\D'), '');
    if (d.length < 10) return null;
    int year;
    int month;
    int day;
    if (d.length >= 12) {
      year = int.tryParse(d.substring(0, 4)) ?? 0;
      month = int.tryParse(d.substring(4, 6)) ?? 0;
      day = int.tryParse(d.substring(6, 8)) ?? 0;
    } else {
      final yy = int.tryParse(d.substring(0, 2)) ?? -1;
      month = int.tryParse(d.substring(2, 4)) ?? 0;
      day = int.tryParse(d.substring(4, 6)) ?? 0;
      final now = DateTime.now();
      final y20 = 2000 + yy;
      final y19 = 1900 + yy;
      final cand20 = _validDate(y20, month, day);
      final cand19 = _validDate(y19, month, day);
      if (cand20 != null && _ageOn(cand20, now) <= 120) {
        year = y20;
      } else if (cand19 != null) {
        year = y19;
      } else {
        return null;
      }
    }
    return _validDate(year, month, day);
  }

  DateTime? _validDate(int year, int month, int day) {
    if (year < 1900 || year > DateTime.now().year) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final dt = DateTime(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) return null;
    return dt;
  }

  int _ageOn(DateTime born, DateTime today) {
    var age = today.year - born.year;
    if (today.month < born.month || (today.month == born.month && today.day < born.day)) {
      age--;
    }
    return age;
  }

  String? _pnrError(String s) {
    final born = _birthFromPnr(s);
    final digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Ogiltigt personnummer.';
    if (born == null) return 'Personnumret måste vara ett riktigt datum.';
    final age = _ageOn(born, DateTime.now());
    if (age < 18) return 'Du måste vara 18 år fyllda för att skapa konto.';
    if (age > 120) return 'Ogiltigt personnummer.';
    return null;
  }

  bool _addrOk(String s) {
    final t = s.trim();
    if (t.length < 8) return false;
    if (!RegExp(r'\d').hasMatch(t)) return false;
    return kCities.any((c) => t.toLowerCase().contains(c.toLowerCase())) ||
        kAddresses.any((a) => a.toLowerCase() == t.toLowerCase());
  }

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

  void _formatPnr(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length > 12) d = d.substring(0, 12);
    String next;
    if (d.length > 8) {
      next = '${d.substring(0, 8)}-${d.substring(8)}';
    } else {
      next = d;
    }
    if (next != pnr.text) {
      pnr.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
    }
  }

  void _submit() {
    if (!consent) {
      setState(() => error = 'Kryssa i rutan för att fortsätta.');
      return;
    }
    if (!_letters(first.text) || !_letters(last.text)) {
      setState(() => error = 'Skriv för- och efternamn med bokstäver.');
      return;
    }
    final pErr = _pnrError(pnr.text);
    if (pErr != null) {
      setState(() => error = pErr);
      return;
    }
    if (!_addrOk(addr.text)) {
      setState(() => error = 'Välj en giltig adress med gatunamn, nummer och ort.');
      return;
    }
    if (!_phoneOk()) {
      setState(() => error = 'Ogiltigt nummer. Använd $code.');
      return;
    }
    if (!_mailOk(mail.text)) {
      setState(() => error = 'Ogiltig e-postadress.');
      return;
    }
    widget.state.saveIdentity(
      first: first.text.trim(),
      last: last.text.trim(),
      pnr: pnr.text.trim(),
      addr: addr.text.trim(),
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
              TextField(
                controller: pnr,
                keyboardType: TextInputType.number,
                onChanged: _formatPnr,
                decoration: _d('Personnummer (ÅÅÅÅMMDD-XXXX)'),
              ),
              const SizedBox(height: 12),
              Autocomplete<String>(
                optionsBuilder: (v) => suggest(v.text, kAddresses),
                onSelected: (v) => addr.text = v,
                fieldViewBuilder: (context, c, focus, onSubmit) {
                  c.addListener(() => addr.text = c.text);
                  return TextField(
                    controller: c,
                    focusNode: focus,
                    textCapitalization: TextCapitalization.words,
                    decoration: _d('Adress'),
                  );
                },
              ),
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
                      decoration: _d(code == '+46' ? '73 928 27 55' : 'Nummer'),
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
