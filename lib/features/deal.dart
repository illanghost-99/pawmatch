import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models.dart';

class DealSheet {
  static Future<void> open(BuildContext context, AppState state, MatchThread thread) async {
    final mine = state.myDogs.where((d) => d.availableForBreeding).toList();
    final myName = TextEditingController(text: state.displayName);
    final myDog = TextEditingController(text: mine.isNotEmpty ? mine.first.name : '');
    final price = TextEditingController(text: '12000');
    final pups = TextEditingController(text: '4');
    final place = TextEditingController(text: state.locationLabel);
    final notes = TextEditingController();
    final sign = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F4EE),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Förhandla avel', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Fyll i underlaget. PawMatch skapar ett avtal ni kan signera. Ingen provision i version 1.'),
              const SizedBox(height: 12),
              TextField(controller: myName, decoration: const InputDecoration(labelText: 'Ditt namn', filled: true, fillColor: Colors.white)),
              const SizedBox(height: 8),
              TextField(controller: myDog, decoration: const InputDecoration(labelText: 'Din hund', filled: true, fillColor: Colors.white)),
              const SizedBox(height: 8),
              TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pris per valp (kr)', filled: true, fillColor: Colors.white)),
              const SizedBox(height: 8),
              TextField(controller: pups, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Förväntat antal valpar', filled: true, fillColor: Colors.white)),
              const SizedBox(height: 8),
              TextField(controller: place, decoration: const InputDecoration(labelText: 'Plats för parning / överlämning', filled: true, fillColor: Colors.white)),
              const SizedBox(height: 8),
              TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Övrigt ni kommit överens om', filled: true, fillColor: Colors.white)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF152033), minimumSize: const Size.fromHeight(50)),
                onPressed: () {
                  final body = _draft(
                    partyA: myName.text.trim().isEmpty ? 'Part A' : myName.text.trim(),
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
                    partyA: myName.text.trim(),
                    partyB: thread.dog.owner,
                    body: body,
                  );
                  thread.messages.add(const ChatLine(true, 'Jag har skapat ett avelsavtal. Öppna Förhandla för att läsa och signera.'));
                  state.notifyListeners();
                  Navigator.pop(ctx);
                  _showContract(context, state, thread, sign);
                },
                child: const Text('Skapa avtal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showContract(BuildContext context, AppState state, MatchThread thread, TextEditingController sign) {
    final deal = thread.deal;
    if (deal == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Avelsavtal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                SelectableText(deal.body, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 16),
                TextField(controller: sign, decoration: const InputDecoration(labelText: 'Skriv ditt namn som underskrift', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    if (sign.text.trim().isEmpty) return;
                    deal.signedByMe = sign.text.trim();
                    deal.signedByOther = thread.dog.owner;
                    thread.messages.add(ChatLine(true, 'Avtalet är signerat av ${deal.signedByMe}.'));
                    state.notifyListeners();
                    setLocal(() {});
                  },
                  child: const Text('Signera'),
                ),
                if (deal.signedByMe.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Signerat av dig: ${deal.signedByMe}\nAndra parten bekräftar i chatten.'),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: deal.body));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avtalet kopierat. Klistra in i Anteckningar och spara/dela.')));
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Ladda ner / kopiera avtal'),
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
    return '''PAWMATCH AVELSAVTAL (utkast)
Datum: $day

Parter
1. $partyA, ägare av $dogA
2. $partyB, ägare av $dogB ($breed)

Överenskommelse
Parterna avser avel mellan ovan hundar. Förväntat antal valpar: $pups.
Överenskommet pris per valp: $price kr.
Plats: $place.

Övrigt
${notes.isEmpty ? 'Inget ytterligare angivet.' : notes}

Ansvar
PawMatch är inte part i avtalet och ger ingen veterinärrådgivning. Parterna ansvarar för hälsokontroll, stamtavla och att följa svensk lag och SKK:s rekommendationer där det är relevant.

Provision
I version 1 tar PawMatch ingen provision. En framtida avgift om 7 % per såld valp kan införas enligt då gällande villkor.

Detta är en mall, inte juridisk rådgivning.
''';
  }
}
