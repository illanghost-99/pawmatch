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

  @override
  void initState() {
    super.initState();
    photo = widget.dog.ownerPhoto;
    city = widget.dog.city;
    _load();
  }

  Future<void> _load() async {
    final row = await Network.ownerProfile(widget.dog.ownerEmail);
    if (!mounted) return;
    setState(() {
      loading = false;
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
    final dogs = <DogProfile>[
      dog,
      for (final other in widget.state.liveDogs)
        if (other.ownerEmail.toLowerCase() == dog.ownerEmail.toLowerCase() && other.id != dog.id) other,
    ];
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
          const Text('Hundar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _ink)),
          const SizedBox(height: 8),
          for (final d in dogs)
            Card(
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: d.photoUrl.startsWith('http') ? NetworkImage(d.photoUrl) : null,
                  child: d.photoUrl.startsWith('http') ? null : const Icon(Icons.pets),
                ),
                title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${d.breed} · ${d.age} år'),
              ),
            ),
        ],
      ),
    );
  }
}
