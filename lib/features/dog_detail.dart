import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../widgets/dog_photo.dart';
import '../widgets/verified_mark.dart';

const _ink = Color(0xFF14202B);
const _cream = Color(0xFFFFF4EC);
const _coral = Color(0xFFE25C3A);
const _muted = Color(0xFF5C6B78);

class DogDetailPage extends StatefulWidget {
  const DogDetailPage({super.key, required this.state, required this.dog});
  final AppState state;
  final DogProfile dog;
  @override
  State<DogDetailPage> createState() => _DogDetailPageState();
}

class _DogDetailPageState extends State<DogDetailPage> {
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final d = widget.dog;
    final pics = d.gallery;
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.48,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: pics.isEmpty ? 1 : pics.length,
                      onPageChanged: (i) => setState(() => page = i),
                      itemBuilder: (_, i) {
                        if (pics.isEmpty) {
                          return Container(color: const Color(0xFF2A3344), alignment: Alignment.center, child: const Icon(Icons.pets, size: 80, color: Color(0xFFC9A24A)));
                        }
                        return DogPhoto(url: pics[i], memWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round().clamp(480, 1400));
                      },
                    ),
                    if (pics.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            pics.length,
                            (i) => Container(
                              width: i == page ? 18 : 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i == page ? Colors.white : Colors.white54,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text('${d.name}, ${d.age}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink))),
                        VerifiedMark(owner: d.ownerVerified, dog: d.dogVerified, size: 26),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${d.breed} · ${d.city} · ${widget.state.kmTo(d).round()} km', style: const TextStyle(fontSize: 16, color: Color(0xFF3D4A57))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (d.sexLabel.isNotEmpty) _pill(d.sexLabel),
                        _pill(d.weightLabel),
                        _pill(d.intent == 'puppies' ? 'Söker avel' : 'Söker vän'),
                        if (d.chipped) _pill('Chippad'),
                        if (d.vaccinated) _pill('Vaccinerad'),
                        if (d.hasPedigree) _pill('Stamtavla'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text('Om hunden', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
                    const SizedBox(height: 6),
                    Text(
                      d.bio.trim().isEmpty ? 'Ingen beskrivning än.' : d.bio.trim(),
                      style: const TextStyle(height: 1.4, fontSize: 16, color: _ink),
                    ),
                    const SizedBox(height: 22),
                    const Text('Hälsa och avel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
                    const SizedBox(height: 4),
                    const Text('Uppgifterna kommer från ägaren.', style: TextStyle(color: _muted, fontSize: 13)),
                    const SizedBox(height: 8),
                    _fact('Vikt', d.weightLabel),
                    _fact('Chip', d.chipped ? 'Ja' : 'Nej'),
                    _fact('Vaccin', _note(d.vaccinated, d.vaccineNote)),
                    _fact('Avmaskad', d.dewormed ? 'Ja' : 'Nej'),
                    _fact('Kastrerad', d.neutered ? 'Ja' : 'Nej'),
                    _fact('Stamtavla', _note(d.hasPedigree, d.pedigreeNote)),
                    _fact('Allergier', d.hasAllergies ? (d.allergyNote.trim().isEmpty ? 'Ja' : d.allergyNote.trim()) : 'Inga angivna'),
                    if (d.healthNote.trim().isNotEmpty) _fact('Övrigt', d.healthNote.trim()),
                    const SizedBox(height: 22),
                    const Text('Ägare', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
                    const SizedBox(height: 6),
                    Text(d.owner, style: const TextStyle(fontSize: 16, color: _ink)),
                  ],
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.state.swipe(d, like: false);
                    Navigator.pop(context);
                  },
                  child: const Text('Nej'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _coral),
                  onPressed: () {
                    widget.state.swipe(d, like: true);
                    Navigator.pop(context);
                  },
                  child: const Text('Like'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _note(bool yes, String note) {
    if (!yes) return 'Nej';
    final extra = note.trim();
    return extra.isEmpty ? 'Ja' : 'Ja · $extra';
  }

  Widget _fact(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE8D9CE)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16, color: _ink, height: 1.3))),
        ],
      ),
    );
  }

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}
