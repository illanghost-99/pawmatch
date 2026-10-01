import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/verified_mark.dart';
import 'dog_detail.dart';

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
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text('Inga registrerade hundar här ännu.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            )
          : _WarmList(items: items, state: state),
    );
  }
}

class _WarmList extends StatefulWidget {
  const _WarmList({required this.items, required this.state});
  final List<DogProfile> items;
  final AppState state;

  @override
  State<_WarmList> createState() => _WarmListState();
}

class _WarmListState extends State<_WarmList> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round();
    for (final dog in widget.items.take(6)) {
      final url = dog.photoUrl;
      if (!url.startsWith('http')) continue;
      precacheImage(ResizeImage(NetworkImage(url), width: width), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      cacheExtent: 900,
      itemCount: widget.items.length,
      itemBuilder: (_, n) => RepaintBoundary(child: _DogCard(dog: widget.items[n], state: widget.state)),
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
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE7A08C), width: 1.6),
          boxShadow: [BoxShadow(color: const Color(0xFFE25C3A).withValues(alpha: 0.16), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 280,
              width: double.infinity,
              child: dog.photoUrl.isNotEmpty ? _photo(context, dog.photoUrl) : _fallback(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                      Flexible(child: Text('${dog.name}, ${dog.age}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800))),
                      VerifiedMark(owner: dog.ownerVerified, dog: dog.dogVerified),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${dog.breed} · ${dog.city} · ${state.kmTo(dog).round()} km', style: const TextStyle(color: Color(0xFF3D4A57))),
                  Text(state.matchReason(dog), style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (dog.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(dog.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.3)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: () => state.swipe(dog, like: false),
                          child: const Text('Hoppa över'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: _rose, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: () => state.swipe(dog, like: true),
                          child: const Text('Matcha'),
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

  Widget _photo(BuildContext context, String url) {
    final width = (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.network(
      url,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      cacheWidth: width,
      frameBuilder: (context, child, frame, sync) {
        if (sync) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: frame == null ? const ColoredBox(color: Color(0xFFF6E7DF), child: SizedBox.expand()) : child,
        );
      },
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => Container(color: const Color(0xFF8B3A32), alignment: Alignment.center, child: const Text('🐾', style: TextStyle(fontSize: 72)));
}
