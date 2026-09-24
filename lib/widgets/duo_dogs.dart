import 'package:flutter/material.dart';

class DuoDogs extends StatelessWidget {
  const DuoDogs({super.key, this.size = 196});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.82,
      child: Image.asset(
        'assets/welcome_dogs.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
