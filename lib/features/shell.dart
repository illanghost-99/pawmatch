import 'package:flutter/material.dart';
import '../app_state.dart';
import 'deals.dart';
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
    final pages = [
      ForYouPage(state: s),
      DiscoverPage(state: s),
      MatchesPage(state: s),
      DealsPage(state: s),
      ProfilePage(state: s),
    ];
    final n = s.chatBadge;
    return Scaffold(
      body: pages[i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        backgroundColor: const Color(0xFFFFF4EC),
        indicatorColor: const Color(0xFFFFD8C8),
        onDestinationSelected: (v) => setState(() => i = v),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome, color: Color(0xFFE25C3A)), label: 'För dig'),
          const NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite, color: Color(0xFFE25C3A)), label: 'Matcha'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: n > 0,
              label: Text('$n'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: n > 0,
              label: Text('$n'),
              child: const Icon(Icons.chat_bubble, color: Color(0xFFE25C3A)),
            ),
            label: 'Chatt',
          ),
          const NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description, color: Color(0xFFE25C3A)), label: 'Avtal'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Color(0xFFE25C3A)), label: 'Profil'),
        ],
      ),
    );
  }
}
