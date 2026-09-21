import 'package:flutter/material.dart';
import '../app_state.dart';
import 'discover.dart';
import 'for_you.dart';
import 'matches.dart';
import 'profile.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});
  final AppState state;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final pages = [ForYouPage(state: s), DiscoverPage(state: s), MatchesPage(state: s), ProfilePage(state: s)];
    return Scaffold(
      body: pages[i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'För dig'),
          NavigationDestination(icon: Icon(Icons.style), label: 'Utforska'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chatt'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
