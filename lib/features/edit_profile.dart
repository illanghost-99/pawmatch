import 'package:flutter/material.dart';
import '../app_state.dart';

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
  late final photo = TextEditingController(text: widget.state.photoUrl);

  static const presets = [
    'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=400',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
  ];

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    bio.dispose();
    city.dispose();
    photo.dispose();
    super.dispose();
  }

  InputDecoration _d(String l) => InputDecoration(
        labelText: l,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final url = photo.text.trim();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F1),
      appBar: AppBar(title: const Text('Min profil', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: GestureDetector(
              onTap: () {
                if (url.isNotEmpty) return;
              },
              child: CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFE25C3A),
                backgroundImage: url.isEmpty ? null : NetworkImage(url),
                child: url.isEmpty ? const Icon(Icons.add_a_photo, color: Colors.white, size: 32) : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Välj en bild eller klistra in en länk', textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final p in presets)
                GestureDetector(
                  onTap: () => setState(() => photo.text = p),
                  child: CircleAvatar(radius: 22, backgroundImage: NetworkImage(p)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: photo, decoration: _d('Bildlänk (valfritt)'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 10),
          TextField(controller: first, textCapitalization: TextCapitalization.words, decoration: _d('Förnamn')),
          const SizedBox(height: 10),
          TextField(controller: last, textCapitalization: TextCapitalization.words, decoration: _d('Efternamn')),
          const SizedBox(height: 10),
          TextField(controller: city, decoration: _d('Ort')),
          const SizedBox(height: 10),
          TextField(controller: bio, maxLines: 4, decoration: _d('Bio — vem är du och hur är era hundar?')),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              widget.state.saveProfile(
                first: first.text.trim(),
                last: last.text.trim(),
                bio: bio.text.trim(),
                city: city.text.trim(),
                photo: photo.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Spara profil'),
          ),
        ],
      ),
    );
  }
}
