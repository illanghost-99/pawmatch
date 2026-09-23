import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models.dart';

const _gold = Color(0xFFC9A24A);

class SwipeDeck extends StatefulWidget {
  const SwipeDeck({super.key, required this.state});
  final AppState state;
  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> with SingleTickerProviderStateMixin {
  Offset drag = Offset.zero;
  late final fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

  DogProfile? get dog => widget.state.deck.isEmpty ? null : widget.state.deck.first;

  @override
  void dispose() {
    fly.dispose();
    super.dispose();
  }

  void _end() {
    final w = MediaQuery.sizeOf(context).width;
    if (drag.dx.abs() > w * 0.28) {
      final like = drag.dx > 0;
      HapticFeedback.mediumImpact();
      final current = dog;
      if (current == null) return;
      setState(() => drag = Offset(like ? w * 1.4 : -w * 1.4, drag.dy + 40));
      Future.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        widget.state.swipe(current, like: like);
        setState(() => drag = Offset.zero);
      });
    } else {
      setState(() => drag = Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = dog;
    if (current == null) {
      return const Center(child: Text('Inga fler kort. Ändra filter eller titta under Sparade.'));
    }
    final angle = drag.dx / 900;
    final likeOpacity = (drag.dx / 140).clamp(0.0, 1.0);
    final noOpacity = (-drag.dx / 140).clamp(0.0, 1.0);
    final next = widget.state.deck.length > 1 ? widget.state.deck[1] : null;

    return Stack(
      children: [
        if (next != null)
          Transform.scale(
            scale: 0.96,
            child: Opacity(opacity: 0.7, child: _photo(next, widget.state.kmTo(next).round())),
          ),
        GestureDetector(
          onPanUpdate: (d) => setState(() => drag += d.delta),
          onPanEnd: (_) => _end(),
          child: AnimatedContainer(
            duration: drag == Offset.zero ? const Duration(milliseconds: 240) : Duration.zero,
            curve: Curves.easeOutBack,
            transform: Matrix4.identity()
              ..translate(drag.dx, drag.dy)
              ..rotateZ(angle),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _photo(current, widget.state.kmTo(current).round()),
                Positioned(
                  top: 28,
                  left: 22,
                  child: Opacity(
                    opacity: likeOpacity,
                    child: _stamp('LIKE', const Color(0xFF2F6B4F)),
                  ),
                ),
                Positioned(
                  top: 28,
                  right: 22,
                  child: Opacity(
                    opacity: noOpacity,
                    child: _stamp('NEJ', const Color(0xFF8B3A32)),
                  ),
                ),
              ],
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
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 1.2)),
      ),
    );
  }

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
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${d.name}, ${d.age}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                Text('${d.breed} · ${d.city} · $km km', style: const TextStyle(color: Color(0xFFE6D5A8))),
                const SizedBox(height: 6),
                Text(d.bio, style: const TextStyle(color: Colors.white70)),
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
