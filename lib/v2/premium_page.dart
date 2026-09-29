import 'package:flutter/material.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    const perks = [
      'Fler filter och obegränsade swipes',
      'Prioriterad profil',
      'Stamtavleverktyg',
      'Hälsorapporter',
      'AI-avelassistent',
      'Exklusiva träffar',
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF14151A),
      appBar: AppBar(title: const Text('PawMatch Plus'), backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Premium kommer via Apple In-App Purchase.\nIngen betalning i den här versionen.', style: TextStyle(color: Colors.white70, height: 1.4)),
          const SizedBox(height: 20),
          ...perks.map(
            (p) => ListTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFFF4A261)),
              title: Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
