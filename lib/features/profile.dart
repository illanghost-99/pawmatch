import 'package:flutter/material.dart';
import '../app_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        children: [
          ListTile(title: const Text('Intressen'), subtitle: Text(state.interests.join(', '))),
          const ListTile(title: Text('Premium'), subtitle: Text('Kommer senare. Inte i v1.')),
          const ListTile(title: Text('BankID / avtal / provision'), subtitle: Text('Avstängt i starten.')),
          ListTile(
            title: const Text('Radera konto på enheten'),
            onTap: () {
              state.onboarded = false;
              state.matches.clear();
              state.interests.clear();
              state.notifyListeners();
            },
          ),
        ],
      ),
    );
  }
}
