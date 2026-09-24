import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/suggestions.dart';
import '../models.dart';
import '../widgets/suggest_field.dart';

const _rose = Color(0xFFC23B2E);
const _ink = Color(0xFF1C1410);

void openDogForm(BuildContext context, AppState state, {int? index, bool forceBreeding = false}) {
  final existing = index != null ? state.myDogs[index] : null;
  final name = TextEditingController(text: existing?.name ?? '');
  final breed = TextEditingController(text: existing?.breed ?? '');
  final city = TextEditingController(text: existing?.city ?? '');
  final bio = TextEditingController(text: existing?.bio ?? '');
  final weight = TextEditingController(text: (existing == null || existing.weightKg <= 0) ? '' : existing.weightKg.toString());
  final ped = TextEditingController(text: existing?.pedigreeNote ?? '');
  final vac = TextEditingController(text: existing?.vaccineNote ?? '');
  final health = TextEditingController(text: existing?.healthNote ?? '');
  final allergy = TextEditingController(text: existing?.allergyNote ?? '');
  var age = existing?.age ?? 2;
  var sex = existing?.sex.isNotEmpty == true ? existing!.sex : 'Tik';
  var friends = existing?.availableForFriends ?? true;
  var breeding = forceBreeding || (existing?.availableForBreeding ?? false);
  var vaccinated = existing?.vaccinated ?? false;
  var dewormed = existing?.dewormed ?? false;
  var chipped = existing?.chipped ?? false;
  var neutered = existing?.neutered ?? false;
  var hasPedigree = existing?.hasPedigree ?? false;
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
              TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: _dec('Namn *')),
              const SizedBox(height: 8),
              SuggestField(controller: breed, label: 'Ras *', hint: 'Skriv pom', options: kBreeds),
              const SizedBox(height: 8),
              SuggestField(controller: city, label: 'Ort *', hint: 'Skriv upplands', options: kCities),
              Text('Ålder: $age år', style: const TextStyle(fontWeight: FontWeight.w700)),
              Slider(value: age.toDouble(), min: 0, max: 15, divisions: 15, activeColor: _rose, onChanged: (v) => setLocal(() => age = v.round())),
              TextField(controller: bio, decoration: _dec('Kort beskrivning')),
              SwitchListTile(title: const Text('Tillgänglig för hundvänner'), value: friends, activeThumbColor: _rose, onChanged: (v) => setLocal(() => friends = v)),
              SwitchListTile(
                title: const Text('Tillgänglig för avel'),
                value: breeding && !neutered,
                activeThumbColor: _rose,
                onChanged: neutered ? null : (v) => setLocal(() => breeding = v),
              ),
              if (breeding && !neutered) ...[
                const SizedBox(height: 8),
                const Text('Uppgifter för avel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Kön *', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _sexChip(current: sex, value: 'Tik', onTap: () => setLocal(() => sex = 'Tik'))),
                    const SizedBox(width: 8),
                    Expanded(child: _sexChip(current: sex, value: 'Hane', onTap: () => setLocal(() => sex = 'Hane'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _dec('Vikt (kg) *'),
                ),
                SwitchListTile(title: const Text('Vaccinerad *'), value: vaccinated, activeThumbColor: _rose, onChanged: (v) => setLocal(() => vaccinated = v)),
                SwitchListTile(title: const Text('Avmaskad'), value: dewormed, activeThumbColor: _rose, onChanged: (v) => setLocal(() => dewormed = v)),
                SwitchListTile(title: const Text('Chipmärkt'), value: chipped, activeThumbColor: _rose, onChanged: (v) => setLocal(() => chipped = v)),
                SwitchListTile(
                  title: const Text('Kastrerad / steriliserad'),
                  value: neutered,
                  activeThumbColor: _rose,
                  onChanged: (v) => setLocal(() {
                    neutered = v;
                    if (v) breeding = false;
                  }),
                ),
                TextField(controller: vac, decoration: _dec('Senaste vaccination')),
                const SizedBox(height: 8),
                TextField(controller: health, decoration: _dec('Hälsotest (höft, armbåge, ögon)')),
                const SizedBox(height: 8),
                TextField(controller: allergy, decoration: _dec('Allergier')),
                SwitchListTile(title: const Text('Har stamtavla'), value: hasPedigree, activeThumbColor: _rose, onChanged: (v) => setLocal(() => hasPedigree = v)),
                if (hasPedigree) TextField(controller: ped, decoration: _dec('Stamtavla / registreringsnummer')),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _rose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    if (name.text.trim().isEmpty || breed.text.trim().isEmpty || city.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fyll i namn, ras och ort.')));
                      return;
                    }
                    final kg = double.tryParse(weight.text.replaceAll(',', '.')) ?? existing?.weightKg ?? 0;
                    if (breeding && !neutered) {
                      if (kg <= 0 || !vaccinated) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('För avel behövs vikt och att hunden är vaccinerad.')));
                        return;
                      }
                    }
                    final dog = MyDog(
                      name: name.text.trim(),
                      breed: breed.text.trim(),
                      age: age,
                      city: city.text.trim(),
                      bio: bio.text.trim(),
                      sex: sex,
                      weightKg: kg,
                      availableForFriends: friends,
                      availableForBreeding: breeding && !neutered,
                      pedigreeNote: ped.text.trim().isEmpty ? (existing?.pedigreeNote ?? '') : ped.text.trim(),
                      vaccineNote: vac.text.trim().isEmpty ? (existing?.vaccineNote ?? '') : vac.text.trim(),
                      allergyNote: allergy.text.trim().isEmpty ? (existing?.allergyNote ?? '') : allergy.text.trim(),
                      healthNote: health.text.trim().isEmpty ? (existing?.healthNote ?? '') : health.text.trim(),
                      hasPedigree: hasPedigree,
                      vaccinated: vaccinated,
                      dewormed: dewormed,
                      chipped: chipped,
                      neutered: neutered,
                    );
                    if (index == null) {
                      state.addMyDog(dog);
                    } else {
                      state.updateMyDog(index, dog);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(index == null ? 'Spara hund' : 'Spara ändringar'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _sexChip({required String current, required String value, required VoidCallback onTap}) {
  final on = current == value;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? _rose : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: on ? _rose : const Color(0xFFE2C4B3)),
      ),
      child: Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: on ? Colors.white : _ink)),
    ),
  );
}

InputDecoration _dec(String label) => InputDecoration(labelText: label, filled: true, fillColor: Colors.white);

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
        onPressed: () => openDogForm(context, state),
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
                    'Börja med namn, ras och ort. Avelsuppgifter fylls i bara om ni söker avel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.4, color: _ink.withValues(alpha: 0.65)),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: _rose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                      onPressed: () => openDogForm(context, state),
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
                      '${d.availableForFriends ? 'Vänner' : 'Ej vänner'} · '
                      '${d.availableForBreeding ? 'Avel' : 'Ej avel'}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') openDogForm(context, state, index: i);
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
}
