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
    final facts = [
      if (adDog.breed.isNotEmpty) adDog.breed,
      if (adDog.age > 0) '${adDog.age} år',
      if (adDog.sexLabel.isNotEmpty) adDog.sexLabel,
      if (adDog.weightKg > 0) adDog.weightLabel,
      if (adDog.city.isNotEmpty) adDog.city,
    ].join(' · ');
    final intent = adDog.availableForBreeding && adDog.availableForFriends
        ? 'Vänner och avel'
        : adDog.availableForBreeding
            ? 'Avel'
            : 'Vänner';
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(title: const Text('Hundägare', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: CircleAvatar(
              radius: 54,
              backgroundColor: const Color(0xFFFFE0D4),
              backgroundImage: photo.startsWith('http') ? NetworkImage(photo) : null,
              child: photo.startsWith('http') ? null : Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _ink)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _ink))),
              VerifiedMark(owner: dog.ownerVerified, dog: false, size: 22),
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
              VerifiedMark(owner: false, dog: adDog.dogVerified, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          if (photos.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.pets, color: _muted, size: 42),
            )
          else
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(photos[i], width: 240, height: 280, fit: BoxFit.cover),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (facts.isNotEmpty) Text(facts, style: const TextStyle(color: _muted, height: 1.35)),
          const SizedBox(height: 6),
          Text(intent, style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
          if (adDog.bio.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(adDog.bio.trim(), style: const TextStyle(height: 1.4, fontSize: 16, color: _ink)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (adDog.vaccinated) _chip('Vaccinerad'),
              if (adDog.dewormed) _chip('Avmaskad'),
              if (adDog.chipped) _chip('Chipmärkt'),
              if (adDog.neutered) _chip('Kastrerad'),
              if (adDog.hasPedigree) _chip(adDog.pedigreeNote.isEmpty ? 'Stamtavla' : 'Stamtavla: ${adDog.pedigreeNote}'),
              if (adDog.vaccineNote.isNotEmpty) _chip('Vaccin: ${adDog.vaccineNote}'),
              if (adDog.healthNote.isNotEmpty) _chip(adDog.healthNote),
              if (adDog.hasAllergies) _chip(adDog.allergyNote.isEmpty ? 'Allergier' : adDog.allergyNote),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _chip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
  );
}
