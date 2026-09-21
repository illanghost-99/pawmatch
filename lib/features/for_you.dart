import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

class ForYouPage extends StatelessWidget {
  const ForYouPage({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final items = state.forYou;
    return Scaffold(
      appBar: AppBar(
        title: const Text('För dig'),
        actions: [
          DropdownButton<String>(
            value: state.intentFilter,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Alla')),
              DropdownMenuItem(value: 'friends', child: Text('Vänner')),
              DropdownMenuItem(value: 'puppies', child: Text('Valpar')),
            ],
            onChanged: (v) {
              state.intentFilter = v ?? 'all';
              state.applyFilters();
            },
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('Inga hundar matchar dina intressen ännu.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, n) {
                final dog = items[n];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${dog.name}, ${dog.age}', style: Theme.of(context).textTheme.titleLarge),
                        Text('${dog.breed} · ${dog.city} · ${state.kmTo(dog).round()} km'),
                        const SizedBox(height: 8),
                        Text(dog.bio),
                        Wrap(
                          spacing: 6,
                          children: dog.tags.map((t) => Chip(label: Text(t))).toList(),
                        ),
                        Row(
                          children: [
                            TextButton(onPressed: () => state.swipe(dog, like: false), child: const Text('Hoppa över')),
                            const Spacer(),
                            FilledButton(onPressed: () => state.swipe(dog, like: true), child: const Text('Matcha')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
