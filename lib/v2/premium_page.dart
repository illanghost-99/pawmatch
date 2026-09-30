import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/store.dart';

const _gold = Color(0xFFC6A15A);
const _goldDeep = Color(0xFF8C6A2F);
const _goldSoft = Color(0xFFF8E7C2);
const _cream = Color(0xFFFFF4EC);
const _ink = Color(0xFF2B2116);

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key, this.state});
  final AppState? state;
  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> with TickerProviderStateMixin {
  String note = '';
  bool busy = false;
  late final AnimationController intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  late final AnimationController shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

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
    shine.dispose();
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
    final glow = CurvedAnimation(parent: shine, curve: Curves.easeInOut);
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
              opacity: CurvedAnimation(parent: intro, curve: const Interval(0, 0.4, curve: Curves.easeOut)),
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: intro, curve: const Interval(0, 0.45, curve: Curves.easeOut))),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF9EE), Colors.white, Color(0xFFF8E7C2)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE7D3A4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 0.94, end: 1.0).animate(glow),
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFF6E2A8), _gold]),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [BoxShadow(color: Color(0x55C6A15A), blurRadius: 16, offset: Offset(0, 8))],
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: _ink, size: 30),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Lanseringserbjudande', style: TextStyle(color: _goldDeep, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                      const SizedBox(height: 4),
                      AnimatedBuilder(
                        animation: shine,
                        builder: (context, _) {
                          final x = (shine.value * 2) - 0.6;
                          return ShaderMask(
                            shaderCallback: (rect) => LinearGradient(
                              begin: Alignment(x - 0.8, 0),
                              end: Alignment(x + 0.2, 0),
                              colors: const [_goldDeep, Color(0xFFFFF6D8), _goldDeep],
                            ).createShader(rect),
                            child: const Text('6 månader gratis', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, height: 1.05)),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Därefter 119 kr i månaden. Betalningen går via Apple, och du avslutar när du vill.',
                        style: TextStyle(color: Color(0xFF5C4A32), fontSize: 16, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _perks.length; i++)
              _Perk(
                label: _perks[i],
                animation: CurvedAnimation(parent: intro, curve: Interval(0.22 + i * 0.1, 0.58 + i * 0.08, curve: Curves.easeOutBack)),
              ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: CurvedAnimation(parent: intro, curve: const Interval(0.75, 1, curve: Curves.easeOut)),
              child: Column(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE8C77A), _gold, Color(0xFFB68B3E)]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [BoxShadow(color: Color(0x44C6A15A), blurRadius: 16, offset: Offset(0, 8))],
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: _ink,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      onPressed: busy || s == null || active ? null : _go,
                      child: Text(active ? 'Premium är aktivt' : (busy ? 'Öppnar Apple…' : 'Starta 6 månader gratis')),
                    ),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => Store.restore(),
                    child: const Text('Återställ köp', style: TextStyle(color: _goldDeep, fontWeight: FontWeight.w700)),
                  ),
                  const Text(
                    'Ingen betalning nu. Gratisperioden syns i Apples köpruta innan du bekräftar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B5A45), fontSize: 13, height: 1.4),
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(note, textAlign: TextAlign.center, style: const TextStyle(color: _ink, fontSize: 13, height: 1.35)),
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
        position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _goldSoft),
          ),
          child: Row(
            children: [
              ScaleTransition(
                scale: animation,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF3D48A), _gold]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_rounded, color: _ink, size: 18),
                ),
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
