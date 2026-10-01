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
    return Stack(
      children: [
        Scaffold(
          body: pages[i],
          bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        backgroundColor: s.darkMode ? const Color(0xFF1C1410) : const Color(0xFFFFF4EC),
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
        ),
        if (s.celebrate.isNotEmpty)
          _MatchBurst(
            name: s.celebrate,
            onDone: s.clearCelebrate,
          ),
      ],
    );
  }
}

class _MatchBurst extends StatefulWidget {
  const _MatchBurst({required this.name, required this.onDone});
  final String name;
  final VoidCallback onDone;

  @override
  State<_MatchBurst> createState() => _MatchBurstState();
}

class _MatchBurstState extends State<_MatchBurst> with SingleTickerProviderStateMixin {
  late final AnimationController ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: ctrl, curve: const Interval(0, 0.25, curve: Curves.easeOut))),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(CurvedAnimation(parent: ctrl, curve: const Interval(0.7, 1, curve: Curves.easeIn))),
          child: Center(
            child: ScaleTransition(
              scale: Tween(begin: 0.86, end: 1.0).animate(CurvedAnimation(parent: ctrl, curve: const Interval(0, 0.35, curve: Curves.easeOutBack))),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B2116),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Color(0xFFE8C77A), size: 28),
                    const SizedBox(height: 6),
                    const Text('Ni matchade', style: TextStyle(color: Color(0xFFF6E2A8), fontWeight: FontWeight.w800, fontSize: 18)),
                    Text(widget.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
