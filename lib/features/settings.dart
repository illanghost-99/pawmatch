import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../services/cloud.dart';
import '../services/store.dart';
import '../v2/premium_page.dart';

const _cream = Color(0xFFFFF4EC);
const _ink = Color(0xFF14202B);

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.state});
  final AppState state;

  Future<void> _subs(BuildContext context) async {
    final uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Öppna Inställningar → ditt namn → Prenumerationer.')));
    }
  }

  Future<void> _restore(BuildContext context) async {
    final text = await Store.restore();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final dark = state.darkMode;
        final bg = dark ? const Color(0xFF1C1410) : _cream;
        final card = dark ? const Color(0xFF2A211C) : Colors.white;
        final ink = dark ? const Color(0xFFFFF4EC) : _ink;
        return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Inställningar', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _card(
            card,
            SwitchListTile(
              title: Text('Mörkt läge', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
              subtitle: Text('Ljust är standard.', style: TextStyle(color: ink.withValues(alpha: 0.7))),
              value: state.darkMode,
              activeThumbColor: const Color(0xFFE25C3A),
              onChanged: state.setDarkMode,
            ),
          ),
          _card(
            card,
            SwitchListTile(
              title: Text('Synas för andra', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
              subtitle: Text(state.isPremium ? 'Stäng av om du vill bläddra utan att synas.' : 'Premium kan pausa profilen och ändå bläddra.', style: TextStyle(color: ink.withValues(alpha: 0.7))),
              value: state.discoverable,
              activeThumbColor: const Color(0xFFE25C3A),
              onChanged: (v) async {
                final ok = await state.setDiscoverable(v);
                if (!ok && context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PremiumPage(state: state)));
                }
              },
            ),
          ),
          _card(
            card,
            SwitchListTile(
              title: Text('Notiser', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
              subtitle: Text('Matchningar och nya meddelanden.', style: TextStyle(color: ink.withValues(alpha: 0.7))),
              value: state.notifyOn,
              activeThumbColor: const Color(0xFFE25C3A),
              onChanged: state.setNotify,
            ),
          ),
          _card(
            card,
            ListTile(
              title: Text('Kontoinformation', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
              subtitle: Text('Namn, telefon, e-post och lösenord.', style: TextStyle(color: ink.withValues(alpha: 0.7))),
              trailing: Icon(Icons.chevron_right, color: ink),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountInfoPage(state: state))),
            ),
          ),
          _card(
            card,
            ListTile(
              title: Text('Hantera abonnemang', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
              subtitle: Text('Sägs upp i App Store.', style: TextStyle(color: ink.withValues(alpha: 0.7))),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _subs(context),
            ),
          ),
          _card(
            card,
            ListTile(
              title: Text('Återställ köp', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
              subtitle: Text('Om du bytt telefon.', style: TextStyle(color: ink.withValues(alpha: 0.7))),
              onTap: () => _restore(context),
            ),
          ),
          _card(
            card,
            ListTile(
              title: Text('Radera mitt konto', style: TextStyle(fontWeight: FontWeight.w800, color: const Color(0xFFE25C3A))),
              subtitle: Text('Tar bort dina hundar, chattar och inloggning. Det går inte att ångra.', style: TextStyle(color: ink.withValues(alpha: 0.7))),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Radera kontot?'),
                    content: const Text('Dina hundar och chattar tas bort. Du loggas ut.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Radera')),
                    ],
                  ),
                );
                if (ok != true) return;
                await state.eraseAccount();
              },
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _card(Color color, Widget child) {
    return Card(
      color: color,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key, required this.state});
  final AppState state;

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final next = TextEditingController();
  final again = TextEditingController();
  final code = TextEditingController();
  bool sent = false;
  bool busy = false;
  String note = '';

  @override
  void dispose() {
    next.dispose();
    again.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (busy) return;
    if (next.text.length < 6) {
      setState(() => note = 'Lösenordet måste vara minst 6 tecken.');
      return;
    }
    if (next.text != again.text) {
      setState(() => note = 'Lösenorden matchar inte.');
      return;
    }
    setState(() {
      busy = true;
      note = '';
    });
    final err = await Cloud.sendPasswordCode();
    if (!mounted) return;
    setState(() {
      busy = false;
      sent = err.isEmpty;
      note = err.isEmpty ? 'Koden är skickad till ${widget.state.email}.' : err;
    });
  }

  Future<void> _save() async {
    if (busy) return;
    if (next.text.length < 6 || next.text != again.text) {
      setState(() => note = 'Skriv samma lösenord i båda fälten.');
      return;
    }
    setState(() {
      busy = true;
      note = '';
    });
    final err = await Cloud.setPassword(password: next.text, code: code.text);
    if (!mounted) return;
    setState(() {
      busy = false;
      note = err.isEmpty ? 'Lösenordet är ändrat.' : err;
      if (err.isEmpty) sent = false;
    });
    if (err.isEmpty) {
      next.clear();
      again.clear();
      code.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final dark = s.darkMode;
    final bg = dark ? const Color(0xFF1C1410) : _cream;
    final card = dark ? const Color(0xFF2A211C) : Colors.white;
    final ink = dark ? const Color(0xFFFFF4EC) : _ink;
    final name = '${s.firstName} ${s.lastName}'.trim();
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Kontoinformation', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _row(card, ink, 'Namn', name.isEmpty ? 'Inte angivet' : name),
          _row(card, ink, 'Telefon', s.phone.trim().isEmpty ? 'Inte angivet' : s.phone.trim()),
          _row(card, ink, 'E-post', s.email.isEmpty ? 'Inte angivet' : s.email),
          const SizedBox(height: 8),
          Text('Ändra lösenord', style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 6),
          Text('Skriv det nya lösenordet. Vi skickar en kod till din e-post innan det sparas.', style: TextStyle(color: ink.withValues(alpha: 0.7))),
          const SizedBox(height: 12),
          TextField(
            controller: next,
            obscureText: true,
            decoration: _field(ink, 'Nytt lösenord'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: again,
            obscureText: true,
            decoration: _field(ink, 'Upprepa lösenord'),
          ),
          if (sent) ...[
            const SizedBox(height: 10),
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              decoration: _field(ink, 'Kod från mejlet'),
            ),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(note, style: TextStyle(color: note.contains('ändrat') || note.contains('skickad') ? const Color(0xFF1F7A6C) : const Color(0xFF8B3A32), fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE25C3A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: busy ? null : (sent ? _save : _send),
            child: Text(busy ? 'Väntar...' : (sent ? 'Spara lösenord' : 'Skicka kod till mejlen')),
          ),
        ],
      ),
    );
  }

  InputDecoration _field(Color ink, String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD7C4B5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFD7C4B5))),
      );

  Widget _row(Color card, Color ink, String label, String value) {
    return Card(
      color: card,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(label, style: TextStyle(color: ink.withValues(alpha: 0.6), fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Text(value, style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}
