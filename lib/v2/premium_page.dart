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

  @override
  void initState() {
    super.initState();
    final s = widget.state;
    Store.boot((ok) {
      if (ok && s != null) s.startLaunchOffer();
      if (mounted) setState(() {});
    });
  }

  Future<void> _go() async {
    final s = widget.state;
    if (s == null) return;
    setState(() => busy = true);
    final storeOk = await Store.buy();
    if (!storeOk) {
      s.startLaunchOffer();
      note = Store.status.isEmpty
          ? 'Erbjudandet är aktivt på enheten. Apple-kortet kopplas när produkten är godkänd i App Store Connect.'
          : Store.status;
    } else {
      note = 'Köpet skickades till Apple.';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final active = s?.isPremium == true;
    return Scaffold(
      backgroundColor: const Color(0xFF14151A),
      appBar: AppBar(title: const Text('Abonnemang'), backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Lanseringserbjudande', style: TextStyle(color: Color(0xFFF4A261), fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('5 månader gratis', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const Text('Sedan 59 kr/mån i 5 månader. Därefter 119 kr/mån. Avslutas i Inställningar → Apple-ID → Prenumerationer.', style: TextStyle(color: Colors.white70, height: 1.4)),
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
            onPressed: busy || s == null ? null : _go,
            child: Text(active ? 'Premium är aktivt' : (busy ? 'Kontaktar Apple…' : 'Starta 5 månader gratis')),
          ),
          TextButton(
            onPressed: () => Store.restore(),
            child: const Text('Återställ köp', style: TextStyle(color: Colors.white54)),
          ),
          if (note.isNotEmpty) Text(note, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          const Text('Betalning går via Apple. Vi ser aldrig kortnummer. Prissteget 59 → 119 sätts som erbjudande på prenumerationen i App Store Connect.', style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.35)),
        ],
      ),
    );
  }
}
