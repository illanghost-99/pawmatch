import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

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
        onPressed: () => _add(context),
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
                    'Lägg till namn, ras och om ni söker vänner eller avel. Stamtavla granskas innan profilen publiceras.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.4, color: _ink.withValues(alpha: 0.65)),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _rose,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () => _add(context),
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
      backgroundColor: const Color(0xFFFFF6F4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(99)))),
                const SizedBox(height: 16),
                const Text('Ny hund', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Namn', filled: true, fillColor: Colors.white)),
                const SizedBox(height: 8),
                TextField(controller: breed, decoration: const InputDecoration(labelText: 'Ras', filled: true, fillColor: Colors.white)),
                const SizedBox(height: 8),
                TextField(controller: city, decoration: const InputDecoration(labelText: 'Ort', filled: true, fillColor: Colors.white)),
                Text('Ålder: $age'),
                Slider(value: age.toDouble(), min: 0, max: 15, divisions: 15, activeColor: _rose, onChanged: (v) => setLocal(() => age = v.round())),
                TextField(controller: bio, decoration: const InputDecoration(labelText: 'Kort beskrivning', filled: true, fillColor: Colors.white)),
                SwitchListTile(title: const Text('Tillgänglig för hundvänner'), value: friends, activeThumbColor: _rose, onChanged: (v) => setLocal(() => friends = v)),
                SwitchListTile(
                  title: const Text('Tillgänglig för avel'),
                  subtitle: const Text('Uppgifter granskas. PawMatch ger ingen veterinärrådgivning.'),
                  value: breeding,
                  activeThumbColor: _rose,
                  onChanged: (v) => setLocal(() => breeding = v),
                ),
                TextField(controller: ped, decoration: const InputDecoration(labelText: 'Stamtavla / referens (granskas)', filled: true, fillColor: Colors.white)),
                const SizedBox(height: 8),
                TextField(controller: vac, decoration: const InputDecoration(labelText: 'Vaccin / hälsouppgifter (granskas)', filled: true, fillColor: Colors.white)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _rose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
