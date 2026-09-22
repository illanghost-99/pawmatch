import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

class MyDogsPage extends StatelessWidget {
  const MyDogsPage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mina hundar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        label: const Text('Lägg till hund'),
        icon: const Icon(Icons.add),
      ),
      body: state.myDogs.isEmpty
          ? const Center(child: Text('Lägg till din hund för att synas i närheten.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.myDogs.length,
              itemBuilder: (_, i) {
                final d = state.myDogs[i];
                return Card(
                  child: ListTile(
                    title: Text('${d.name} · ${d.breed}'),
                    subtitle: Text(
                      '${d.city}\n'
                      '${d.availableForFriends ? 'Vänner: ja' : 'Vänner: nej'} · '
                      '${d.availableForBreeding ? 'Avel: ja' : 'Avel: nej'}\n'
                      'Stamtavla: ${_rev(d.pedigreeStatus)} · Vaccin: ${_rev(d.vaccineStatus)}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  String _rev(ReviewStatus s) => switch (s) {
        ReviewStatus.none => 'saknas',
        ReviewStatus.pending => 'granskas',
        ReviewStatus.approved => 'godkänd',
        ReviewStatus.rejected => 'underkänd',
      };

  void _add(BuildContext context) {
    final name = TextEditingController();
    final breed = TextEditingController();
    final city = TextEditingController();
    final bio = TextEditingController();
    final ped = TextEditingController();
    final vac = TextEditingController();
    var age = 2;
    var friends = true;
    var breeding = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Ny hund', style: Theme.of(ctx).textTheme.titleLarge),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Namn')),
                TextField(controller: breed, decoration: const InputDecoration(labelText: 'Ras')),
                TextField(controller: city, decoration: const InputDecoration(labelText: 'Ort')),
                Text('Ålder: $age'),
                Slider(value: age.toDouble(), min: 0, max: 15, divisions: 15, onChanged: (v) => setLocal(() => age = v.round())),
                TextField(controller: bio, decoration: const InputDecoration(labelText: 'Kort beskrivning')),
                SwitchListTile(title: const Text('Tillgänglig för hundvänner'), value: friends, onChanged: (v) => setLocal(() => friends = v)),
                SwitchListTile(
                  title: const Text('Tillgänglig för avel'),
                  subtitle: const Text('Uppgifter granskas. PawMatch ger ingen veterinärrådgivning.'),
                  value: breeding,
                  onChanged: (v) => setLocal(() => breeding = v),
                ),
                TextField(controller: ped, decoration: const InputDecoration(labelText: 'Stamtavla / referens (granskas)')),
                TextField(controller: vac, decoration: const InputDecoration(labelText: 'Vaccin / hälsouppgifter (granskas)')),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    if (name.text.trim().isEmpty) return;
                    state.addMyDog(MyDog(
                      name: name.text.trim(),
                      breed: breed.text.trim().isEmpty ? 'Blandras' : breed.text.trim(),
                      age: age,
                      city: city.text.trim().isEmpty ? state.locationLabel : city.text.trim(),
                      bio: bio.text.trim(),
                      availableForFriends: friends,
                      availableForBreeding: breeding,
                      pedigreeNote: ped.text.trim(),
                      vaccineNote: vac.text.trim(),
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Spara & skicka till granskning'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
