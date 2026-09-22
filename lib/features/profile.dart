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
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        children: [
          ListTile(title: Text(state.email.isEmpty ? 'Konto' : state.email), subtitle: const Text('Inloggad')),
          ListTile(
            leading: const Icon(Icons.pets),
            title: const Text('Mina hundar'),
            subtitle: Text('${state.myDogs.length} sparade'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyDogsPage(state: state))),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Kundsupport'),
            subtitle: const Text('Mejl till support@pawmatch.app'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage())),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Användarvillkor'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Villkor', body: kTerms))),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Integritetspolicy'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Integritet', body: kPrivacy))),
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Communityregler'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Community', body: kCommunity))),
          ),
          const ListTile(title: Text('Premium / BankID / provision'), subtitle: Text('Inte i v1 — tillväxt först')),
          ListTile(
            title: const Text('Logga ut'),
            onTap: () => state.signOut(),
          ),
          ListTile(
            title: const Text('Radera konto på enheten'),
            onTap: () {
              state.onboarded = false;
              state.matches.clear();
              state.interests.clear();
              state.myDogs.clear();
              state.signOut();
            },
          ),
        ],
      ),
    );
  }
}
