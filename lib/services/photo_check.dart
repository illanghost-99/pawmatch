import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class PhotoCheck {
  static Future<String?> dogProblem(String path) => _problem(path, const ['dog', 'puppy', 'pup', 'canine', 'hound'], 'Bilden behöver visa en hund, inte ett annat föremål.');

  static Future<String?> profileProblem(String path) => _problem(
        path,
        const [
          'dog',
          'puppy',
          'pup',
          'canine',
          'hound',
          'person',
          'selfie',
          'smile',
          'beard',
          'moustache',
          'skin',
          'hair',
          'mouth',
          'eyelash',
          'glasses',
          'sunglasses',
          'laugh',
          'baby',
          'flesh',
          'bangs',
          'bride',
          'groom',
          'crowd',
          'dude',
          'grandparent',
        ],
        'Profilbilden behöver vara en hund eller en människa.',
        threshold: 0.2,
      );

  static const _exact = {
    'person',
    'selfie',
    'smile',
    'beard',
    'moustache',
    'skin',
    'hair',
    'mouth',
    'eyelash',
    'glasses',
    'sunglasses',
    'laugh',
    'baby',
    'flesh',
    'bangs',
    'bride',
    'groom',
    'crowd',
    'dude',
    'grandparent',
  };

  static Future<String?> _problem(String path, List<String> words, String message, {double threshold = 0.35}) async {
    final labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: threshold));
    try {
      final labels = await labeler.processImage(InputImage.fromFile(File(path)));
      final hit = labels.any((label) {
        final text = label.label.toLowerCase();
        if (_exact.contains(text)) return words.contains(text);
        return words.any((word) => !_exact.contains(word) && text.contains(word));
      });
      if (hit) return null;
      return message;
    } catch (_) {
      return 'Kunde inte läsa bilden. Välj en tydlig bild och försök igen.';
    } finally {
      await labeler.close();
    }
  }
}
