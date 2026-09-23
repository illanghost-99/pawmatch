import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/suggestions.dart';
import '../models.dart';
import '../widgets/suggest_field.dart';

const _rose = Color(0xFFC23B2E);
const _ink = Color(0xFF1C1410);

class MyDogsPage extends StatelessWidget {
  const MyDogsPage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F4),
      appBar: AppBar(title: const Text('Mina hundar'), backgroundColor: Colors.transparent),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _rose,
        foregroundColor: Colors.white,
        onPressed: () => _form(context),
        label: const Text('Lägg till hund'),
        icon: const Icon(Icons.add),
      ),
      body: state.myDogs.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4DF),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _rose.withValues(alpha: 0.25), blurRadius: 24)],
                    ),
                    child: const Icon(Icons.pets, size: 52, color: _rose),
                  ),
                  const SizedBox(height: 24),
                  const Text('Din hund syns här', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 10),
                  Text(
                    'Lägg till namn, ras och om ni söker vänner eller avel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.4, color: _ink.withValues(alpha: 0.65)),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: _rose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                      onPressed: () => _form(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Lägg till din första hund'),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.myDogs.length,
              itemBuilder: (_, i) {
                final d = state.myDogs[i];
                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFFFE4DF),
                      child: Text(d.name.isEmpty ? '?' : d.name[0].toUpperCase(), style: const TextStyle(color: _rose, fontWeight: FontWeight.w800)),
                    ),
                    title: Text('${d.name} · ${d.breed}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      '${d.city}\n'
                      '${d.availableForFriends ? 'Vänner: ja' : 'Vänner: nej'} · '
                      '${d.availableForBreeding ? 'Avel: ja' : 'Avel: nej'}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _form(context, index: i);
                        if (v == 'delete') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Radera hund?'),
                              content: Text('Ta bort ${d.name} från din profil.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Avbryt')),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B3A32)),
                                  onPressed: () {
                                    state.removeMyDog(i);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Radera'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Redigera')),
                        PopupMenuItem(value: 'delete', child: Text('Radera')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _form(BuildContext context, {int? index}) {
    final existing = index != null ? state.myDogs[index] : null;
    final name = TextEditingController(text: existing?.name ?? '');
    final breed = TextEditingController(text: existing?.breed ?? '');
    final city = TextEditingController(text: existing?.city ?? '');
    final bio = TextEditingController(text: existing?.bio ?? '');
    final ped = TextEditingController(text: existing?.pedigreeNote ?? '');
    final vac = TextEditingController(text: existing?.vaccineNote ?? '');
    var age = existing?.age ?? 2;
    var friends = existing?.availableForFriends ?? true;
    var breeding = existing?.availableForBreeding ?? false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF6F4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(index == null ? 'Ny hund' : 'Redigera hund', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Namn', filled: true, fillColor: Colors.white)),
                const SizedBox(height: 8),
                SuggestField(controller: breed, label: 'Ras', hint: 'Skriv pom', options: kBreeds),
                const SizedBox(height: 8),
                SuggestField(controller: city, label: 'Ort', hint: 'Skriv upplands', options: kCities),
                Text('Ålder: $age'),
                Slider(value: age.toDouble(), min: 0, max: 15, divisions: 15, activeColor: _rose, onChanged: (v) => setLocal(() => age = v.round())),
                TextField(controller: bio, decoration: const InputDecoration(labelText: 'Kort beskrivning', filled: true, fillColor: Colors.white)),
                SwitchListTile(title: const Text('Tillgänglig för hundvänner'), value: friends, activeThumbColor: _rose, onChanged: (v) => setLocal(() => friends = v)),
                SwitchListTile(title: const Text('Tillgänglig för avel'), value: breeding, activeThumbColor: _rose, onChanged: (v) => setLocal(() => breeding = v)),
                TextField(controller: ped, decoration: const InputDecoration(labelText: 'Stamtavla / referens', filled: true, fillColor: Colors.white)),
                const SizedBox(height: 8),
                TextField(controller: vac, decoration: const InputDecoration(labelText: 'Vaccin / hälsa', filled: true, fillColor: Colors.white)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _rose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () {
                      if (name.text.trim().isEmpty) return;
                      final dog = MyDog(
                        name: name.text.trim(),
                        breed: breed.text.trim().isEmpty ? 'Blandras' : breed.text.trim(),
                        age: age,
                        city: city.text.trim().isEmpty ? state.locationLabel : city.text.trim(),
                        bio: bio.text.trim(),
                        availableForFriends: friends,
                        availableForBreeding: breeding,
                        pedigreeNote: ped.text.trim(),
                        vaccineNote: vac.text.trim(),
                      );
                      if (index == null) {
                        state.addMyDog(dog);
                      } else {
                        state.updateMyDog(index, dog);
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(index == null ? 'Spara & skicka till granskning' : 'Spara ändringar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
