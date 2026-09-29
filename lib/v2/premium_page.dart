import 'package:flutter/material.dart';
import '../app_state.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key, this.state});
  final AppState? state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    return Scaffold(
      backgroundColor: const Color(0xFF14151A),
      appBar: AppBar(title: const Text('PawMatch Premium'), backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Lanseringserbjudande', style: TextStyle(color: Color(0xFFF4A261), fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('5 månader gratis', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const Text('därefter 59 kr/mån i 5 månader, sedan 119 kr/mån.', style: TextStyle(color: Colors.white70, height: 1.4)),
          const SizedBox(height: 20),
          for (final p in const [
            'Obegränsade swipes',
            'Skapa och leda promenadcirklar',
            'Bjuda in, ta bort och redigera grupp',
            'Prioriterad profil i flödet',
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
            onPressed: s == null
                ? null
                : () {
                    s.startLaunchOffer();
                    Navigator.pop(context);
                  },
            child: Text(s != null && s.isPremium ? 'Premium är aktivt' : 'Starta 5 månader gratis'),
          ),
          const SizedBox(height: 8),
          const Text('Betalning kopplas till Apple In-App Purchase före App Store. I TestFlight aktiveras erbjudandet på enheten.', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
