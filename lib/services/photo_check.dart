import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class PhotoCheck {
  static Future<String?> dogProblem(String path) => _problem(path, const ['dog', 'puppy', 'pup', 'canine', 'hound'], 'Bilden behöver visa en hund, inte ett annat föremål.');

  static Future<String?> profileProblem(String path) => _problem(
        path,
        const ['dog', 'puppy', 'pup', 'canine', 'hound', 'person', 'human', 'people', 'face', 'man', 'woman', 'boy', 'girl', 'portrait'],
        'Profilbilden behöver vara en hund eller en människa.',
      );

  static Future<String?> _problem(String path, List<String> words, String message) async {
    final labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.35));
    try {
      final labels = await labeler.processImage(InputImage.fromFile(File(path)));
      final text = labels.map((label) => label.label.toLowerCase()).join(' ');
      if (words.any(text.contains)) return null;
      return message;
    } catch (_) {
      return 'Kunde inte läsa bilden. Välj en tydlig bild och försök igen.';
    } finally {
      await labeler.close();
    }
  }
}
