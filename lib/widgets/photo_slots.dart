import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoSlots extends StatelessWidget {
  const PhotoSlots({super.key, required this.paths, required this.onChanged});
  final List<String> paths;
  final ValueChanged<List<String>> onChanged;

  Future<void> _pick(int i) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 78, maxWidth: 1600);
    if (file == null) return;
    final next = List<String>.from(paths);
    while (next.length <= i) {
      next.add('');
    }
    next[i] = file.path;
    onChanged(next.where((p) => p.isNotEmpty).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bilder *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 4),
        const Text('Minst två bilder på hunden.', style: TextStyle(color: Color(0xFF5C534C))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _slot(0)),
            const SizedBox(width: 10),
            Expanded(child: _slot(1)),
          ],
        ),
      ],
    );
  }

  Widget _slot(int i) {
    final path = i < paths.length ? paths[i] : '';
    return InkWell(
      onTap: () => _pick(i),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2C4B3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: path.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: Color(0xFFE25C3A)),
                  SizedBox(height: 6),
                  Text('Lägg till', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              )
            : Image.file(File(path), fit: BoxFit.cover, width: double.infinity, height: 120),
      ),
    );
  }
}
