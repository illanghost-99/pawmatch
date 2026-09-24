import 'dart:math';
import 'package:flutter/material.dart';

class PawsBg extends StatefulWidget {
  const PawsBg({super.key, this.child, this.color = const Color(0x33E25C3A)});
  final Widget? child;
  final Color color;
  @override
  State<PawsBg> createState() => _PawsBgState();
}

class _PawsBgState extends State<PawsBg> with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        return CustomPaint(
          painter: _PawPainter(c.value, widget.color),
          child: widget.child,
        );
      },
    );
  }
}

class _PawPainter extends CustomPainter {
  _PawPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const spots = [
      Offset(0.12, 0.82),
      Offset(0.28, 0.90),
      Offset(0.78, 0.86),
      Offset(0.90, 0.74),
      Offset(0.08, 0.18),
      Offset(0.88, 0.14),
    ];
    for (var i = 0; i < spots.length; i++) {
      final p = spots[i];
      final wave = sin((t + i * 0.17) * 2 * pi) * 10;
      final dx = p.dx * size.width;
      final dy = p.dy * size.height + wave;
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.pets.codePoint),
          style: TextStyle(
            fontFamily: Icons.pets.fontFamily,
            package: Icons.pets.fontPackage,
            fontSize: 28 + (i % 3) * 6,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(-0.4 + i * 0.22);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PawPainter old) => old.t != t;
}
