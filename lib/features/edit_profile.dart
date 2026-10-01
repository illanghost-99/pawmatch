import 'dart:io';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/media.dart';
import '../services/photo_check.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.state});
  final AppState state;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final first = TextEditingController(text: widget.state.firstName);
  late final last = TextEditingController(text: widget.state.lastName);
  late final bio = TextEditingController(text: widget.state.ownerBio);
  late final city = TextEditingController(text: widget.state.locationLabel);
  late String photo = widget.state.photoUrl;
  bool saving = false;

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    bio.dispose();
    city.dispose();
    super.dispose();
  }

  InputDecoration _d(String l) => InputDecoration(
        labelText: l,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );

  ImageProvider? get _image {
    if (photo.isEmpty) return null;
    if (photo.startsWith('http')) return NetworkImage(photo);
    return FileImage(File(photo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F1),
      appBar: AppBar(title: const Text('Min profil', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: GestureDetector(
              onTap: () async {
                final path = await Media.choose(context, title: 'Profilbild');
                if (path == null || !mounted) return;
                final problem = await PhotoCheck.profileProblem(path);
                if (!mounted) return;
                if (problem != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
                  return;
                }
                setState(() => photo = path);
              },
              child: CircleAvatar(
                radius: 52,
                backgroundColor: const Color(0xFFE25C3A),
                backgroundImage: _image,
                child: photo.isEmpty ? const Icon(Icons.add_a_photo, color: Colors.white, size: 32) : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tryck på bilden för att välja från galleri eller kamera', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextField(controller: first, textCapitalization: TextCapitalization.words, decoration: _d('Förnamn')),
          const SizedBox(height: 10),
          TextField(controller: last, textCapitalization: TextCapitalization.words, decoration: _d('Efternamn')),
          const SizedBox(height: 10),
          TextField(controller: city, decoration: _d('Ort')),
          const SizedBox(height: 10),
          TextField(controller: bio, maxLines: 4, decoration: _d('Bio — vem är du och hur är era hundar?')),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    await widget.state.saveProfile(
                      first: first.text.trim(),
                      last: last.text.trim(),
                      bio: bio.text.trim(),
                      city: city.text.trim(),
                      photo: photo,
                    );
                    if (mounted) Navigator.pop(context);
                  },
            child: Text(saving ? 'Sparar...' : 'Spara profil'),
          ),
        ],
      ),
    );
  }
}
