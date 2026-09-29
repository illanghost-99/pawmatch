import 'dart:io';
import 'package:flutter/material.dart';
import '../services/media.dart';

class PhotoSlots extends StatelessWidget {
  const PhotoSlots({
    super.key,
    required this.paths,
    required this.onChanged,
    this.minCount = 2,
    this.maxCount = 4,
    this.title = 'Bilder',
    this.hint = 'Minst två bilder på hunden.',
  });
  final List<String> paths;
  final ValueChanged<List<String>> onChanged;
  final int minCount;
  final int maxCount;
  final String title;
  final String hint;

  Future<void> _pick(BuildContext context, int i) async {
    final path = await Media.choose(context);
    if (path == null) return;
    final next = List<String>.from(paths.where((p) => p.isNotEmpty));
    if (i < next.length) {
      next[i] = path;
    } else {
      next.add(path);
    }
    if (next.length > maxCount) next.removeRange(maxCount, next.length);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title *', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 4),
        Text(hint, style: const TextStyle(color: Color(0xFF5C534C))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < maxCount; i++)
              SizedBox(
                width: (MediaQuery.sizeOf(context).width - 54) / 2,
                child: _slot(context, i),
              ),
          ],
        ),
      ],
    );
  }

  Widget _slot(BuildContext context, int i) {
    final path = i < paths.length ? paths[i] : '';
    return InkWell(
      onTap: () => _pick(context, i),
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
