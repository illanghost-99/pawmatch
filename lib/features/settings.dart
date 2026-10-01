import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../services/store.dart';

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
              subtitle: Text('Stäng av om du inte vill dyka upp i För dig och Matcha.', style: TextStyle(color: ink.withValues(alpha: 0.7))),
              value: state.discoverable,
              activeThumbColor: const Color(0xFFE25C3A),
              onChanged: state.setDiscoverable,
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
              title: Text('Lösenord', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
              subtitle: Text('Du loggar in med Apple. Lösenordet ändras i iPhone-inställningarna, inte här.', style: TextStyle(color: ink.withValues(alpha: 0.7))),
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
