import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

const _ink = Color(0xFF14202B);
const _cream = Color(0xFFFFF4EC);
const _coral = Color(0xFFE25C3A);

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
                height: MediaQuery.sizeOf(context).height * 0.52,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: pics.isEmpty ? 1 : pics.length,
                      onPageChanged: (i) => setState(() => page = i),
                      itemBuilder: (_, i) {
                        if (pics.isEmpty) {
                          return Container(color: const Color(0xFF2A3344), alignment: Alignment.center, child: const Icon(Icons.pets, size: 80, color: Color(0xFFC9A24A)));
                        }
                        return Image.network(pics[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2A3344)));
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
                    Text('${d.name}, ${d.age}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _ink)),
                    const SizedBox(height: 6),
                    Text('${d.breed} · ${d.city} · ${widget.state.kmTo(d).round()} km', style: const TextStyle(fontSize: 16, color: Color(0xFF3D4A57))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (d.sexLabel.isNotEmpty) _pill(d.sexLabel),
                        if (d.weightKg > 0) _pill('${d.weightKg} kg'),
                        _pill(d.intent == 'puppies' ? 'Söker avel' : 'Söker vän'),
                        if (d.pedigreeStatus == ReviewStatus.approved) _pill('Stamtavla'),
                        if (d.vaccineStatus == ReviewStatus.approved) _pill('Vaccinerad'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Om hunden', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
                    const SizedBox(height: 6),
                    Text(d.bio, style: const TextStyle(height: 1.4, fontSize: 16, color: _ink)),
                    const SizedBox(height: 18),
                    const Text('Ägare', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
                    const SizedBox(height: 6),
                    Text(d.owner, style: const TextStyle(fontSize: 16)),
                    if (d.reviews.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(d.reviews.join(' · '), style: const TextStyle(color: Color(0xFF3D4A57))),
                    ],
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

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}
