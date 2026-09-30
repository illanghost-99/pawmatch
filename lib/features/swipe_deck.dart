import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/verified_mark.dart';
import 'dog_detail.dart';

const _gold = Color(0xFFC9A24A);

class SwipeDeck extends StatefulWidget {
  const SwipeDeck({super.key, required this.state});
  final AppState state;
  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> with SingleTickerProviderStateMixin {
  Offset drag = Offset.zero;
  bool flying = false;
  late final AnimationController fly;

  DogProfile? get dog => widget.state.deck.isEmpty ? null : widget.state.deck.first;

  @override
  void initState() {
    super.initState();
    fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  }

  @override
  void dispose() {
    fly.dispose();
    super.dispose();
  }

  Future<void> _animateTo(Offset target, {required VoidCallback? onDone}) async {
    flying = true;
    final start = drag;
    fly.duration = Duration(milliseconds: target == Offset.zero ? 420 : 520);
    fly.reset();
    late void Function() tick;
    tick = () {
      final t = Curves.easeOutCubic.transform(fly.value);
      setState(() => drag = Offset.lerp(start, target, t)!);
    };
    fly.addListener(tick);
    await fly.forward();
    fly.removeListener(tick);
    flying = false;
    onDone?.call();
  }

  void _end() {
    if (flying) return;
    final w = MediaQuery.sizeOf(context).width;
    if (drag.dx.abs() > w * 0.24) {
      final like = drag.dx > 0;
      HapticFeedback.lightImpact();
      final current = dog;
      if (current == null) return;
      _animateTo(
        Offset(like ? w * 1.4 : -w * 1.4, drag.dy * 0.28 + 18),
        onDone: () {
          widget.state.swipe(current, like: like);
          if (mounted) setState(() => drag = Offset.zero);
        },
      );
    } else {
      _animateTo(Offset.zero, onDone: null);
    }
  }

  void _open(DogProfile d) {
    if (drag.distance > 8 || flying) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => DogDetailPage(state: widget.state, dog: d)));
  }

  @override
  Widget build(BuildContext context) {
    final current = dog;
    if (current == null) {
      return const Center(child: Text('Inga fler kort. Ändra filter eller titta under Sparade.'));
    }
    final angle = drag.dx / 1600;
    final likeOpacity = (drag.dx / 160).clamp(0.0, 1.0);
    final noOpacity = (-drag.dx / 160).clamp(0.0, 1.0);
    final next = widget.state.deck.length > 1 ? widget.state.deck[1] : null;
    final pull = (drag.dx.abs() / 320).clamp(0.0, 1.0);

    return Stack(
      children: [
        if (next != null)
          Transform.scale(
            scale: 0.93 + (0.07 * pull),
            child: Opacity(opacity: 0.5 + (0.5 * pull), child: _photo(next, widget.state.kmTo(next).round())),
          ),
        GestureDetector(
          onTap: () => _open(current),
          onPanUpdate: (d) {
            if (flying) return;
            setState(() => drag += d.delta);
          },
          onPanEnd: (_) => _end(),
          child: Transform.translate(
            offset: drag,
            child: Transform.rotate(
              angle: angle,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _photo(current, widget.state.kmTo(current).round()),
                  Positioned(top: 28, left: 22, child: Opacity(opacity: likeOpacity, child: _stamp('LIKE', const Color(0xFF2F6B4F)))),
                  Positioned(top: 28, right: 22, child: Opacity(opacity: noOpacity, child: _stamp('NEJ', const Color(0xFF8B3A32)))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stamp(String text, Color color) {
    return Transform.rotate(
      angle: -0.25,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: color, width: 3), borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      );

  Widget _photo(DogProfile d, int km) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (d.photoUrl.isNotEmpty)
            Image.network(d.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
          else
            _fallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC101826)],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(d.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))),
                    VerifiedMark(owner: d.ownerVerified, dog: d.dogVerified),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip('${d.age} år'),
                    if (d.sexLabel.isNotEmpty) _chip(d.sexLabel),
                    _chip(d.breed),
                    _chip(d.city),
                    _chip('$km km'),
                    _chip(d.intent == 'puppies' ? 'Avel' : 'Vän'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(d.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFF2A3344),
        alignment: Alignment.center,
        child: const Icon(Icons.pets, size: 72, color: _gold),
      );
}
