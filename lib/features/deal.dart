import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models.dart';

class DealSheet {
  static Future<void> open(BuildContext context, AppState state, MatchThread thread) async {
    if (thread.deal != null) {
      _showContract(context, state, thread);
      return;
    }
    final mine = state.myDogs.where((d) => d.availableForBreeding).toList();
    final myDog = TextEditingController(text: mine.isNotEmpty ? mine.first.name : '');
    final price = TextEditingController(text: '12000');
    final pups = TextEditingController(text: '4');
    final place = TextEditingController(text: state.locationLabel);
    final notes = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF6F1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Förhandla avel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _OwnerChip(label: state.fullName, color: const Color(0xFFE25C3A), onTap: () => _me(context, state))),
                  const SizedBox(width: 8),
                  Expanded(child: _OwnerChip(label: thread.dog.owner, color: const Color(0xFF2A9D8F), onTap: () => _them(context, thread.dog))),
                ],
              ),
              const SizedBox(height: 8),
              Text('Avtal skickas till ${state.email.isEmpty ? 'din e-post' : state.email} när det skapats.', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              TextField(controller: myDog, decoration: _dec('Din hund')),
              const SizedBox(height: 8),
              TextField(controller: price, keyboardType: TextInputType.number, decoration: _dec('Pris per valp (kr)')),
              const SizedBox(height: 8),
              TextField(controller: pups, keyboardType: TextInputType.number, decoration: _dec('Förväntat antal valpar')),
              const SizedBox(height: 8),
              TextField(controller: place, decoration: _dec('Plats')),
              const SizedBox(height: 8),
              TextField(controller: notes, maxLines: 3, decoration: _dec('Övrigt')),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE25C3A), minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                onPressed: () {
                  final body = _draft(
                    partyA: state.fullName,
                    mailA: state.email,
                    phoneA: state.phone,
                    dogA: myDog.text.trim().isEmpty ? 'Min hund' : myDog.text.trim(),
                    partyB: thread.dog.owner,
                    dogB: thread.dog.name,
                    breed: thread.dog.breed,
                    price: price.text.trim(),
                    pups: pups.text.trim(),
                    place: place.text.trim(),
                    notes: notes.text.trim(),
                  );
                  thread.deal = BreedingDeal(
                    pricePerPuppy: price.text.trim(),
                    expectedPups: pups.text.trim(),
                    place: place.text.trim(),
                    notes: notes.text.trim(),
                    partyA: state.fullName,
                    partyB: thread.dog.owner,
                    body: body,
                  );
                  thread.messages.add(ChatLine(true, 'Avtal skapat. Kopia kan skickas till ${state.email}.'));
                  state.bump();
                  Navigator.pop(ctx);
                  _showContract(context, state, thread);
                },
                child: const Text('Skapa avtal med AI-mall'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _dec(String l) => InputDecoration(labelText: l, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none));

  static void _me(BuildContext context, AppState s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(s.identityPending ? 'Identitet: väntar på granskning' : 'Identitet ifylld'),
            const SizedBox(height: 8),
            Text('E-post: ${s.email}'),
            Text('Telefon: ${s.phone.isEmpty ? '—' : s.phone}'),
            Text('Adress: ${s.address.isEmpty ? '—' : s.address}'),
            Text('Personnummer: ${s.personalNumber.isEmpty ? '—' : 'sparat (dolt)'}'),
          ],
        ),
      ),
    );
  }

  static void _them(BuildContext context, DogProfile d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.owner, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text('${d.name} · ${d.breed} · ${d.city}'),
            const SizedBox(height: 8),
            Text(d.bio),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [for (final r in d.reviews) Chip(label: Text(r))]),
          ],
        ),
      ),
    );
  }

  static void _showContract(BuildContext context, AppState state, MatchThread thread) {
    final deal = thread.deal;
    if (deal == null) return;
    final sign = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF6F1),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Avelsavtal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _OwnerChip(label: deal.partyA.isEmpty ? state.fullName : deal.partyA, color: const Color(0xFFE25C3A), onTap: () => _me(context, state))),
                    const SizedBox(width: 8),
                    Expanded(child: _OwnerChip(label: deal.partyB, color: const Color(0xFF2A9D8F), onTap: () => _them(context, thread.dog))),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: SelectableText(deal.body, style: const TextStyle(height: 1.4)),
                ),
                const SizedBox(height: 16),
                TextField(controller: sign, decoration: _dec('Skriv ditt namn som underskrift')),
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2A9D8F), minimumSize: const Size.fromHeight(52)),
                  onPressed: () {
                    if (sign.text.trim().isEmpty) return;
                    deal.signedByMe = sign.text.trim();
                    thread.messages.add(ChatLine(true, 'Avtalet är signerat av ${deal.signedByMe}.'));
                    state.bump();
                    setLocal(() {});
                  },
                  child: const Text('Signera'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE25C3A), side: const BorderSide(color: Color(0xFFE25C3A)), minimumSize: const Size.fromHeight(48)),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: deal.body));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kopierat. Kan mejlas till ${state.email}.')));
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Ladda ner / kopiera'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _draft({
    required String partyA,
    required String mailA,
    required String phoneA,
    required String dogA,
    required String partyB,
    required String dogB,
    required String breed,
    required String price,
    required String pups,
    required String place,
    required String notes,
  }) {
    final day = DateTime.now().toIso8601String().split('T').first;
    return '''PAWMATCH AVELSAVTAL\nDatum: $day\n\nParter\n1. $partyA ($mailA, $phoneA), ägare av $dogA\n2. $partyB, ägare av $dogB ($breed)\n\nÖverenskommelse\nAvel mellan ovan hundar. Förväntat antal valpar: $pups.\nPris per valp: $price kr.\nPlats: $place.\n\nÖvrigt\n${notes.isEmpty ? 'Inget ytterligare.' : notes}\n\nAvtalet kan skickas till parternas e-post.\nPawMatch är inte part och ger ingen veterinärrådgivning.\nProvision 7 % är reserverad för senare version.\nMall, inte juridisk rådgivning.\n''';
  }
}

class _OwnerChip extends StatelessWidget {
  const _OwnerChip({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: color, width: 1.5)),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
