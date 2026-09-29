import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Media {
  static final _picker = ImagePicker();

  static Future<String?> pick({ImageSource source = ImageSource.gallery}) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1800);
      return file?.path;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> choose(BuildContext context, {String title = 'Lägg till bild'}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Bild från galleri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ta foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return null;
    return pick(source: source);
  }
}
