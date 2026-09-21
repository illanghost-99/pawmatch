import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final deck = state.deck;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utforska'),
        actions: [
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
        padding: const EdgeInsets.all(20),
        child: deck.isEmpty
            ? const Center(child: Text('Inga fler kort. Ändra filter.'))
            : Column(
                children: [
                  Text('${deck.length} hundar · ${state.locationLabel}'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC47A52).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text('🐾', style: TextStyle(fontSize: 72)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('${deck.first.name}, ${deck.first.age}', style: Theme.of(context).textTheme.headlineSmall),
                            Text('${deck.first.breed} · ${deck.first.city} · ${state.kmTo(deck.first).round()} km'),
                            Text(deck.first.bio),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(onPressed: () => state.swipe(deck.first, like: false), child: const Text('Nej')),
                      FilledButton(onPressed: () => state.swipe(deck.first, like: true), child: const Text('Like')),
                    ],
                  ),
                ],
              ),
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Filter', style: Theme.of(context).textTheme.titleLarge),
          TextField(controller: breed, decoration: const InputDecoration(labelText: 'Ras')),
          TextField(controller: area, decoration: const InputDecoration(labelText: 'Område / ort')),
          Text('Ålder ${s.ageMin}–${s.ageMax}'),
          RangeSlider(
            values: RangeValues(s.ageMin.toDouble(), s.ageMax.toDouble()),
            min: 0, max: 15, divisions: 15,
            onChanged: (v) => setState(() { s.ageMin = v.start.round(); s.ageMax = v.end.round(); }),
          ),
          Text('Radie ${s.radiusKm} km'),
          Slider(value: s.radiusKm.toDouble(), min: 5, max: 250, onChanged: (v) => setState(() => s.radiusKm = v.round())),
          FilledButton(
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
    );
  }
}
