import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/store.dart';

const _coral = Color(0xFFE25C3A);
const _cream = Color(0xFFFFF4EC);
const _ink = Color(0xFF14202B);

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key, this.state});
  final AppState? state;
  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> with SingleTickerProviderStateMixin {
  String note = '';
  bool busy = false;
  late final AnimationController intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  static const _perks = [
    'Obegränsade swipes',
    'Gruppchatt för promenader',
    'Prioriterad profil',
    'Avancerade filter',
    'Fler sparade hundar',
  ];

  @override
  void dispose() {
    intro.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final s = widget.state;
    if (s == null || busy) return;
    setState(() {
      busy = true;
      note = '';
    });
    final storeOk = await Store.buy();
    if (!storeOk) {
      note = 'Apple hittar inte prenumerationen än. Ingen betalning har gjorts.';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final active = s?.isPremium == true;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Premium', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
        backgroundColor: Colors.transparent,
        foregroundColor: _ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            FadeTransition(
              opacity: CurvedAnimation(parent: intro, curve: const Interval(0, 0.45, curve: Curves.easeOut)),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(color: const Color(0xFFFFE0D4), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.pets, color: _coral, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text('Lanseringserbjudande', style: TextStyle(color: _coral, fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('6 månader gratis', style: TextStyle(color: _ink, fontSize: 34, fontWeight: FontWeight.w900, height: 1.05)),
                    const SizedBox(height: 10),
                    const Text(
                      'Därefter 119 kr i månaden. Betalningen går via Apple, och du avslutar när du vill.',
                      style: TextStyle(color: Color(0xFF3D4A57), fontSize: 16, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _perks.length; i++)
              _Perk(
                label: _perks[i],
                animation: CurvedAnimation(
                  parent: intro,
                  curve: Interval(0.2 + i * 0.1, 0.55 + i * 0.09, curve: Curves.easeOut),
                ),
              ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: CurvedAnimation(parent: intro, curve: const Interval(0.7, 1, curve: Curves.easeOut)),
              child: Column(
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _coral,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                    onPressed: busy || s == null || active ? null : _go,
                    child: Text(active ? 'Premium är aktivt' : (busy ? 'Öppnar Apple…' : 'Starta 6 månader gratis')),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => Store.restore(),
                    child: const Text('Återställ köp', style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
                  ),
                  const Text(
                    'Ingen betalning nu. Gratisperioden syns i Apples köpruta innan du bekräftar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF5C6B78), fontSize: 13, height: 1.4),
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(note, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF3D4A57), fontSize: 13, height: 1.35)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.label, required this.animation});
  final String label;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.18), end: Offset.zero).animate(animation),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: _coral, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }
}
