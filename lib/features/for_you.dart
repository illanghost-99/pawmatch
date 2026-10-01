import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/verified_mark.dart';
import 'dog_detail.dart';
import 'owner_page.dart';

const _rose = Color(0xFFC23B2E);

class ForYouPage extends StatelessWidget {
  const ForYouPage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final items = state.forYou;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('För dig', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Använd min plats',
            onPressed: () async {
              final ok = await state.locate();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'Plats på — visar hundar närmast dig' : 'Tillåt plats i Inställningar')),
              );
              if (ok) state.setFeedSort('nearest');
            },
            icon: Icon(state.gpsOn ? Icons.my_location : Icons.location_searching),
          ),
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
              itemBuilder: (_, n) => _DogCard(dog: items[n], state: state),
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
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DogDetailPage(state: state, dog: dog))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 460,
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
                  Row(
                    children: [
                      Flexible(child: Text('${dog.name}, ${dog.age}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))),
                      VerifiedMark(owner: dog.ownerVerified, dog: dog.dogVerified),
                    ],
                  ),
                  Text('${dog.breed} · ${dog.city} · ${state.kmTo(dog).round()} km', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(state.matchReason(dog), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(dog.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, height: 1.3)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerPage(state: state, dog: dog))),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: Colors.white, width: 1.4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: Colors.white24,
                                backgroundImage: dog.ownerPhoto.startsWith('http') ? NetworkImage(dog.ownerPhoto) : null,
                                child: dog.ownerPhoto.startsWith('http') ? null : Text((dog.owner.isEmpty ? '?' : dog.owner[0]).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 8),
                              Flexible(child: Text(dog.owner.isEmpty ? 'Hundägare' : dog.owner, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                              const Icon(Icons.chevron_right, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
      ),
    );
  }

  Widget _fallback() => Container(color: const Color(0xFF8B3A32), alignment: Alignment.center, child: const Text('🐾', style: TextStyle(fontSize: 72)));
}
