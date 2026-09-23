import 'package:flutter/material.dart';
import '../app_state.dart';
import 'edit_profile.dart';
import 'legal.dart';
import 'my_dogs.dart';
import 'support.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final photo = state.photoUrl;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F1),
      appBar: AppBar(title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(state: state))),
              child: Ink(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE25C3A), Color(0xFFF4A261)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
                      child: photo.isEmpty ? const Icon(Icons.pets, color: Color(0xFFE25C3A)) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.fullName.isEmpty ? (state.email.isEmpty ? 'Konto' : state.email) : state.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(
                            state.ownerBio.isEmpty ? 'Tryck för att redigera profil och bio' : state.ownerBio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _tile(context, const Color(0xFFE25C3A), Icons.pets, 'Mina hundar', '${state.myDogs.length} sparade', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MyDogsPage(state: state)));
          }),
          _tile(context, const Color(0xFF2A9D8F), Icons.support_agent, 'Kundsupport', 'AI + mejl', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage()));
          }),
          _tile(context, const Color(0xFF3D5A80), Icons.description_outlined, 'Användarvillkor', 'Regler för appen', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Villkor', body: kTerms)));
          }),
          _tile(context, const Color(0xFF6B4C9A), Icons.privacy_tip_outlined, 'Integritetspolicy', 'GDPR och Apple', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Integritet', body: kPrivacy)));
          }),
          _tile(context, const Color(0xFFE9C46A), Icons.groups_outlined, 'Communityregler', 'Så här är vi mot varandra', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Community', body: kCommunity)));
          }),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B2430), minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
