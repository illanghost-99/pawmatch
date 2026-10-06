import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/dog_photo.dart';
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
    warmDogPhotos(context, widget.items.take(8).map((d) => d.photoUrl));
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
    final h = MediaQuery.sizeOf(context).height * 0.68;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DogDetailPage(state: state, dog: dog))),
      child: Container(
        height: h,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1814),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE7A08C), width: 1.6),
          boxShadow: [BoxShadow(color: const Color(0xFFE25C3A).withValues(alpha: 0.16), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            dog.photoUrl.isNotEmpty ? _photo(context, dog.photoUrl) : _fallback(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.transparent, Color(0xE61A0B08)],
                  stops: [0.35, 0.55, 1],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
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
                      Flexible(child: Text('${dog.name}, ${dog.age}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))),
                      VerifiedMark(owner: dog.ownerVerified, dog: dog.dogVerified),
                    ],
                  ),
                  Text('${dog.breed} · ${dog.city} · ${state.kmTo(dog).round()} km', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                  Text(state.matchReason(dog), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => state.swipe(dog, like: false),
                          child: const Text('Hoppa över'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _rose,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
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
    return DogPhoto(url: url, memWidth: width);
  }

  Widget _fallback() => const ColoredBox(color: Color(0xFF8B3A32), child: Center(child: Text('🐾', style: TextStyle(fontSize: 72))));
}
