import 'package:flutter/material.dart';
import '../app_state.dart';
import 'legal.dart';
import 'my_dogs.dart';
import 'support.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF152033), Color(0xFF2A3B55)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: Color(0xFFC9A24A), child: Icon(Icons.pets, color: Colors.white)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.email.isEmpty ? 'Konto' : state.email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('${state.myDogs.length} hundar · ${state.matches.length} matcher', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _tile(context, const Color(0xFFC47A52), Icons.pets, 'Mina hundar', '${state.myDogs.length} sparade', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MyDogsPage(state: state)));
          }),
          _tile(context, const Color(0xFF2F6B4F), Icons.support_agent, 'Kundsupport', 'Mejl till support@pawmatch.app', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage()));
          }),
          _tile(context, const Color(0xFF3D5A80), Icons.description_outlined, 'Användarvillkor', 'Regler för appen', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Villkor', body: kTerms)));
          }),
          _tile(context, const Color(0xFF6B4C9A), Icons.privacy_tip_outlined, 'Integritetspolicy', 'GDPR och Apple', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Integritet', body: kPrivacy)));
          }),
          _tile(context, const Color(0xFFB86B2A), Icons.groups_outlined, 'Communityregler', 'Så här är vi mot varandra', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Community', body: kCommunity)));
          }),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Premium / BankID / provision'),
            subtitle: const Text('Inte i v1 — tillväxt först'),
            leading: CircleAvatar(backgroundColor: const Color(0xFFC9A24A).withValues(alpha: 0.2), child: const Icon(Icons.workspace_premium, color: Color(0xFFC9A24A))),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF152033), minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => state.signOut(),
            child: const Text('Logga ut'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B3A32),
              side: const BorderSide(color: Color(0xFF8B3A32)),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              state.onboarded = false;
              state.matches.clear();
              state.interests.clear();
              state.myDogs.clear();
              state.signOut();
            },
            child: const Text('Radera konto på enheten'),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Color color, IconData icon, String title, String sub, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
