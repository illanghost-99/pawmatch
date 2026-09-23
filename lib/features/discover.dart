import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../data/suggestions.dart';
import '../widgets/suggest_field.dart';
import 'swipe_deck.dart';

const _navy = Color(0xFF152033);
const _gold = Color(0xFFC9A24A);

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final deck = state.deck;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Matcha', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Sparade',
            icon: Badge(
              isLabelVisible: state.saved.isNotEmpty,
              label: Text('${state.saved.length}'),
              child: const Icon(Icons.bookmark_border),
            ),
            onPressed: () => _openSaved(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => FiltersSheet(state: state),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: deck.isEmpty
            ? const Center(child: Text('Inga fler kort. Ändra filter eller titta under Sparade.'))
            : Column(
                children: [
                  Text('${deck.length} hundar · ${state.locationLabel}', style: const TextStyle(color: _navy)),
                  const Text('Svep höger för like, vänster för nej', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 8),
                  const Expanded(child: SizedBox.expand()),
                  Expanded(flex: 0, child: const SizedBox.shrink()),
                  Expanded(child: SwipeDeck(state: state)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RoundAction(
                        color: const Color(0xFF5C6473),
                        icon: Icons.thumb_down_alt_rounded,
                        label: 'Nej',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          state.swipe(deck.first, like: false);
                        },
                      ),
                      _RoundAction(
                        color: _gold,
                        icon: state.isSaved(deck.first) ? Icons.bookmark : Icons.bookmark_border,
                        label: 'Spara',
                        big: false,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          state.saveDog(deck.first);
                        },
                      ),
                      _RoundAction(
                        color: const Color(0xFF2F6B4F),
                        icon: Icons.thumb_up_alt_rounded,
                        label: 'Like',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          state.swipe(deck.first, like: true);
                        },
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  void _openSaved(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => AnimatedBuilder(
        animation: state,
        builder: (_, __) {
          if (state.saved.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Text('Inga sparade hundar än. Tryck Spara när du vill titta senare.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Sparade', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final d in state.saved)
                ListTile(
                  leading: CircleAvatar(backgroundImage: d.photoUrl.isEmpty ? null : NetworkImage(d.photoUrl), child: d.photoUrl.isEmpty ? const Text('🐾') : null),
                  title: Text('${d.name}, ${d.age}'),
                  subtitle: Text('${d.breed} · ${d.city}'),
                  trailing: TextButton(onPressed: () => state.swipe(d, like: true), child: const Text('Matcha')),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RoundAction extends StatefulWidget {
  const _RoundAction({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    this.big = true,
  });
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool big;

  @override
  State<_RoundAction> createState() => _RoundActionState();
}

class _RoundActionState extends State<_RoundAction> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 140), lowerBound: 0.9, upperBound: 1);

  @override
  void initState() {
    super.initState();
    c.value = 1;
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.big ? 72.0 : 62.0;
    return Column(
      children: [
        ScaleTransition(
          scale: c,
          child: Material(
            color: widget.color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                await c.reverse();
                await c.forward();
                widget.onTap();
              },
              child: SizedBox(width: size, height: size, child: Icon(widget.icon, color: Colors.white, size: widget.big ? 30 : 26)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class FiltersSheet extends StatefulWidget {
  const FiltersSheet({super.key, required this.state});
  final AppState state;
  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late final breed = TextEditingController(text: widget.state.breedQuery);
  late final area = TextEditingController(text: widget.state.area);

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Filter', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SuggestField(controller: breed, label: 'Ras', hint: 'Börja skriv — förslag visas', options: kBreeds),
            const SizedBox(height: 8),
            SuggestField(controller: area, label: 'Område / ort', hint: 'T.ex. Upplands Väsby', options: kCities),
            Text('Ålder ${s.ageMin}–${s.ageMax}'),
            RangeSlider(
              values: RangeValues(s.ageMin.toDouble(), s.ageMax.toDouble()),
              min: 0,
              max: 15,
              divisions: 15,
              onChanged: (v) => setState(() {
                s.ageMin = v.start.round();
                s.ageMax = v.end.round();
              }),
            ),
            Text('Radie ${s.radiusKm} km'),
            Slider(value: s.radiusKm.toDouble(), min: 5, max: 400, onChanged: (v) => setState(() => s.radiusKm = v.round())),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _navy),
              onPressed: () {
                s.breedQuery = breed.text;
                s.area = area.text;
                s.applyFilters();
                Navigator.pop(context);
              },
              child: const Text('Visa hundar'),
            ),
          ],
        ),
      ),
    );
  }
}
