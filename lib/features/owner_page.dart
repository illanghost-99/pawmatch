import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../services/network.dart';
import '../widgets/verified_mark.dart';

const _ink = Color(0xFF14202B);
const _cream = Color(0xFFFFF4EC);
const _muted = Color(0xFF5C6B78);

class OwnerPage extends StatefulWidget {
  const OwnerPage({super.key, required this.state, required this.dog});
  final AppState state;
  final DogProfile dog;

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  String bio = '';
  String city = '';
  String photo = '';
  bool loading = true;
  DogProfile? listing;
  final pager = PageController();
  int photoPage = 0;

  @override
  void dispose() {
    pager.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    photo = widget.dog.ownerPhoto;
    city = widget.dog.city;
    _load();
  }

  DogProfile get ad {
    final dog = widget.dog;
    DogProfile best = listing ?? dog;
    for (final other in widget.state.liveDogs) {
      final same = other.id == dog.id ||
          (other.ownerEmail.toLowerCase() == dog.ownerEmail.toLowerCase() && other.name.toLowerCase() == dog.name.toLowerCase());
      if (same && other.gallery.length > best.gallery.length) best = other;
    }
    return best;
  }

  Future<void> _load() async {
    final row = await Network.ownerProfile(widget.dog.ownerEmail);
    final found = await Network.listingFor(widget.dog);
    if (!mounted) return;
    setState(() {
      loading = false;
      listing = found;
      if (row == null) return;
      final nextPhoto = '${row['photo_url'] ?? ''}';
      final nextBio = '${row['bio'] ?? ''}';
      final nextCity = '${row['city'] ?? ''}';
      if (nextPhoto.startsWith('http')) photo = nextPhoto;
      if (nextBio.trim().isNotEmpty) bio = nextBio.trim();
      if (nextCity.trim().isNotEmpty) city = nextCity.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dog = widget.dog;
    final name = dog.owner.trim().isEmpty ? 'Hundägare' : dog.owner.trim();
    final adDog = ad;
    final photos = adDog.gallery.where((p) => p.startsWith('http')).toList();
    final intent = adDog.availableForBreeding && adDog.availableForFriends
        ? 'Vänner och avel'
        : adDog.availableForBreeding
            ? 'Avel'
            : 'Vänner';
    final facts = <(String, String)>[
      ('Ras', adDog.breed.trim().isEmpty ? 'Inte angiven' : adDog.breed.trim()),
      ('Ålder', adDog.age > 0 ? '${adDog.age} år' : 'Inte angiven'),
      ('Kön', adDog.sexLabel.isEmpty ? 'Inte angivet' : adDog.sexLabel),
      ('Vikt', adDog.weightKg > 0 ? adDog.weightLabel : 'Inte angiven'),
      ('Ort', adDog.city.trim().isEmpty ? 'Inte angiven' : adDog.city.trim()),
      ('Söker', intent),
      ('Chipmärkt', adDog.chipped ? 'Ja' : 'Nej'),
      ('Vaccinerad', adDog.vaccinated ? 'Ja' : 'Nej'),
      ('Avmaskad', adDog.dewormed ? 'Ja' : 'Nej'),
      ('Kastrerad', adDog.neutered ? 'Ja' : 'Nej'),
      ('Stamtavla', adDog.hasPedigree ? (adDog.pedigreeNote.trim().isEmpty ? 'Ja' : adDog.pedigreeNote.trim()) : 'Nej'),
    ];
    if (adDog.vaccineNote.trim().isNotEmpty) facts.add(('Senaste vaccin', adDog.vaccineNote.trim()));
    if (adDog.healthNote.trim().isNotEmpty) facts.add(('Hälsotest', adDog.healthNote.trim()));
    if (adDog.hasAllergies || adDog.allergyNote.trim().isNotEmpty) {
      facts.add(('Allergier', adDog.allergyNote.trim().isEmpty ? 'Ja' : adDog.allergyNote.trim()));
    } else {
      facts.add(('Allergier', 'Inga angivna'));
    }
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(title: const Text('Hundägare', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: SizedBox(
              width: 108,
              height: 108,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: const Color(0xFFFFE0D4),
                    backgroundImage: photo.startsWith('http') ? NetworkImage(photo) : null,
                    child: photo.startsWith('http') ? null : Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _ink)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: VerifiedMark(owner: dog.ownerVerified || adDog.ownerVerified, dog: false, size: 32, corner: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _ink))),
            ],
          ),
          if (city.isNotEmpty) Text(city, textAlign: TextAlign.center, style: const TextStyle(color: _muted)),
          const SizedBox(height: 16),
          if (loading) const LinearProgressIndicator(),
          Text(bio.isEmpty ? 'Ingen beskrivning ännu.' : bio, style: const TextStyle(height: 1.4, fontSize: 16, color: _ink)),
          const SizedBox(height: 22),
          Row(
            children: [
              Flexible(child: Text(adDog.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink))),
            ],
          ),
          const SizedBox(height: 8),
          if (photos.isEmpty)
            Container(
              height: 220,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE7C7B4), width: 2),
              ),
              child: const Icon(Icons.pets, color: _muted, size: 42),
            )
          else
            Container(
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE7C7B4), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: pager,
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => photoPage = i),
                    itemBuilder: (_, i) => Image.network(photos[i], fit: BoxFit.cover, width: double.infinity),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xCC14202B), borderRadius: BorderRadius.circular(99)),
                      child: Text('${photoPage + 1} / ${photos.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: VerifiedMark(owner: false, dog: adDog.dogVerified || dog.dogVerified, size: 36, corner: true),
                  ),
                ],
              ),
            ),
          if (photos.length > 1)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Svep i ramen för att se alla bilder.', textAlign: TextAlign.center, style: TextStyle(color: _muted, fontWeight: FontWeight.w600)),
            ),
          if (adDog.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(adDog.bio.trim(), style: const TextStyle(height: 1.4, fontSize: 16, color: _ink)),
          ],
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                for (var i = 0; i < facts.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: i == facts.length - 1 ? null : const Border(bottom: BorderSide(color: Color(0xFFF0E2D8))),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 118, child: Text(facts[i].$1, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700))),
                        Expanded(child: Text(facts[i].$2, textAlign: TextAlign.right, style: const TextStyle(color: _ink, fontWeight: FontWeight.w800))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
