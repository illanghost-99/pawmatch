import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/store.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key, this.state});
  final AppState? state;
  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  String note = '';
  bool busy = false;

  Future<void> _go() async {
    final s = widget.state;
    if (s == null || busy) return;
    setState(() {
      busy = true;
      note = '';
    });
    final storeOk = await Store.buy();
    if (!storeOk) {
      note = 'Apple hittar inte prenumerationen än. Kontrollera att Product ID är pawmatch_premium_month. Ingen betalning har gjorts.';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final active = s?.isPremium == true;
    return Scaffold(
      backgroundColor: const Color(0xFF14151A),
      appBar: AppBar(
        title: const Text('Abonnemang'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        toolbarHeight: 72,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text('Lanseringserbjudande', style: TextStyle(color: Color(0xFFF4A261), fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('6 månader gratis', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            const Text('Därefter 119 kr/mån. Avslutas i Inställningar → Apple-ID → Prenumerationer.', style: TextStyle(color: Colors.white70, height: 1.4)),
            const SizedBox(height: 20),
            for (final p in const [
              'Obegränsade swipes',
              'Skapa och leda promenadcirklar',
              'Prioriterad profil',
              'Avancerade filter',
              'Fler sparade hundar',
            ])
              ListTile(
                leading: const Icon(Icons.check_circle, color: Color(0xFFF4A261)),
                title: Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE25C3A), minimumSize: const Size.fromHeight(54)),
              onPressed: busy || s == null || active ? null : _go,
              child: Text(active ? 'Premium är aktivt via Apple' : (busy ? 'Öppnar Apple…' : 'Starta 6 månader gratis')),
            ),
            TextButton(
              onPressed: busy ? null : () => Store.restore(),
              child: const Text('Återställ köp', style: TextStyle(color: Colors.white54)),
            ),
            if (note.isNotEmpty) Text(note, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35)),
          ],
        ),
      ),
    );
  }
}
