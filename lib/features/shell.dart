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
        backgroundColor: const Color(0xFFFFF4EC),
        indicatorColor: const Color(0xFFFFD8C8),
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome, color: Color(0xFFE25C3A)), label: 'För dig'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite, color: Color(0xFFE25C3A)), label: 'Matcha'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFFE25C3A)), label: 'Chatt'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Color(0xFFE25C3A)), label: 'Profil'),
        ],
      ),
    );
  }
}
