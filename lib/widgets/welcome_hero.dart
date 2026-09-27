import 'package:flutter/material.dart';
import 'duo_dogs.dart';

class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key, this.size = 196});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/welcome_dogs.png',
      width: size,
      height: size * 0.72,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => DuoDogs(size: size),
    );
  }
}
