import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
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
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_openNotice);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openNotice());
  }

  @override
  void dispose() {
    widget.state.removeListener(_openNotice);
    super.dispose();
  }

  void _openNotice() {
    if (!mounted || _opening) return;
    final kind = widget.state.pendingKind;
    if (kind == null || kind.isEmpty) return;
    final peer = (widget.state.pendingPeer ?? '').toLowerCase();
    final groupId = widget.state.pendingGroup ?? '';
    if (kind == 'group') {
      GroupChat? group;
      for (final g in widget.state.groups) {
        if (g.id == groupId) group = g;
      }
      if (group == null) {
        if (!widget.state.groupsReady) return;
        widget.state.clearNotice();
        setState(() => i = 2);
        return;
      }
      final open = group;
      _opening = true;
      widget.state.clearNotice();
      widget.state.markGroupRead(open);
      setState(() => i = 2);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _opening = false;
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupChatPage(state: widget.state, group: open)));
      });
      return;
    }
    MatchThread? thread;
    for (final m in widget.state.matches) {
      if (m.accepted && peer.isNotEmpty && m.peerEmail.toLowerCase() == peer) {
        thread = m;
        break;
      }
    }
    if (thread == null) {
      if (!widget.state.chatsReady) return;
      widget.state.clearNotice();
      setState(() => i = kind == 'match' ? 0 : 2);
      return;
    }
    final open = thread;
    _opening = true;
    widget.state.clearNotice();
    widget.state.markRead(open);
    setState(() => i = 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _opening = false;
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(state: widget.state, thread: open)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final pages = [
      DiscoverPage(state: s),
      ForYouPage(state: s),
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
          const NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite, color: Color(0xFFE25C3A)), label: 'Matcha'),
          const NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome, color: Color(0xFFE25C3A)), label: 'För dig'),
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
