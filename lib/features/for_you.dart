import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

const _rose = Color(0xFFC23B2E);

class ForYouPage extends StatelessWidget {
  const ForYouPage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final items = state.forYou;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('För dig', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.feedSort,
                items: const [
                  DropdownMenuItem(value: 'forYou', child: Text('För dig')),
                  DropdownMenuItem(value: 'nearest', child: Text('Närmast dig')),
                  DropdownMenuItem(value: 'friends', child: Text('Hundvänner')),
                  DropdownMenuItem(value: 'puppies', child: Text('Avel')),
                ],
                onChanged: (v) {
                  if (v != null) state.setFeedSort(v);
                },
              ),
            ),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Inga hundar matchar dina intressen ännu.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: items.length,
              itemBuilder: (_, n) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: Duration(milliseconds: 280 + (n % 4) * 40),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(opacity: v.clamp(0.4, 1), child: Transform.scale(scale: v, child: child)),
                child: _DogCard(dog: items[n], state: state),
              ),
            ),
    );
  }
}

class _DogCard extends StatelessWidget {
  const _DogCard({required this.dog, required this.state});
  final DogProfile dog;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final intent = dog.intent == 'puppies' ? 'Söker avel' : 'Söker vän';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 420,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (dog.photoUrl.isNotEmpty)
            Image.network(dog.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
          else
            _fallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.transparent, Color(0xCC1A0B08)],
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _rose, borderRadius: BorderRadius.circular(99)),
                  child: Text(intent, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const SizedBox(height: 8),
                Text('${dog.name}, ${dog.age}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                Text('${dog.breed} · ${dog.city} · ${state.kmTo(dog).round()} km', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 6),
                Text(dog.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, height: 1.3)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => state.swipe(dog, like: false),
                          child: const Text('Hoppa över'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _rose,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => state.swipe(dog, like: true),
                          child: const Text('Matcha'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(color: const Color(0xFF8B3A32), alignment: Alignment.center, child: const Text('🐾', style: TextStyle(fontSize: 72)));
}
