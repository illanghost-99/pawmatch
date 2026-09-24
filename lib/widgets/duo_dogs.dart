import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class DuoDogs extends StatefulWidget {
  const DuoDogs({super.key, this.size = 168});
  final double size;
  @override
  State<DuoDogs> createState() => _DuoDogsState();
}

class _DuoDogsState extends State<DuoDogs> with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3800))..repeat(reverse: true);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        return SizedBox(
          width: s,
          height: s,
          child: CustomPaint(painter: _MarkPainter(c.value)),
        );
      },
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.22));
    canvas.save();
    canvas.clipRRect(r);

    final glow = 0.35 + 0.08 * sin(t * pi);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFFFFE0B2), const Color(0xFFFFB74D), glow)!,
            const Color(0xFFFF6B9D),
            const Color(0xFFE91E8C),
          ],
        ).createShader(Offset.zero & size),
    );

    final cx = size.width * 0.52;
    final cy = size.height * 0.42;
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.34,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    final floorY = size.height * 0.86;
    canvas.drawRect(
      Rect.fromLTWH(0, floorY - 8, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0x33FFFFFF), const Color(0x44E91E8C)],
        ).createShader(Rect.fromLTWH(0, floorY - 8, size.width, 40)),
    );

    final sil = Paint()..color = const Color(0xFF2A0518);
    final lift = sin(t * pi) * size.height * 0.006;

    canvas.save();
    canvas.translate(0, lift);
    canvas.drawPath(_rottie(size), sil);
    canvas.restore();

    canvas.save();
    canvas.translate(0, -lift * 0.6);
    canvas.drawPath(_pom(size), sil);
    canvas.restore();

    canvas.restore();
    canvas.drawRRect(
      r,
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Path _rottie(Size s) {
    final w = s.width;
    final h = s.height;
    final p = Path();
    p.moveTo(w * 0.10, h * 0.84);
    p.quadraticBezierTo(w * 0.08, h * 0.72, w * 0.16, h * 0.70);
    p.lineTo(w * 0.18, h * 0.54);
    p.quadraticBezierTo(w * 0.16, h * 0.40, w * 0.22, h * 0.34);
    p.lineTo(w * 0.24, h * 0.26);
    p.quadraticBezierTo(w * 0.27, h * 0.20, w * 0.32, h * 0.24);
    p.lineTo(w * 0.38, h * 0.30);
    p.quadraticBezierTo(w * 0.50, h * 0.28, w * 0.52, h * 0.36);
    p.quadraticBezierTo(w * 0.56, h * 0.40, w * 0.50, h * 0.44);
    p.lineTo(w * 0.46, h * 0.48);
    p.lineTo(w * 0.44, h * 0.70);
    p.lineTo(w * 0.40, h * 0.84);
    p.lineTo(w * 0.34, h * 0.84);
    p.lineTo(w * 0.33, h * 0.72);
    p.lineTo(w * 0.30, h * 0.84);
    p.close();
    return p;
  }

  Path _pom(Size s) {
    final w = s.width;
    final h = s.height;
    final p = Path();
    p.moveTo(w * 0.56, h * 0.84);
    p.quadraticBezierTo(w * 0.54, h * 0.70, w * 0.58, h * 0.62);
    p.quadraticBezierTo(w * 0.55, h * 0.52, w * 0.60, h * 0.46);
    p.lineTo(w * 0.61, h * 0.40);
    p.quadraticBezierTo(w * 0.63, h * 0.34, w * 0.67, h * 0.38);
    p.quadraticBezierTo(w * 0.72, h * 0.36, w * 0.74, h * 0.42);
    p.quadraticBezierTo(w * 0.82, h * 0.44, w * 0.86, h * 0.52);
    p.quadraticBezierTo(w * 0.92, h * 0.58, w * 0.88, h * 0.70);
    p.quadraticBezierTo(w * 0.90, h * 0.78, w * 0.84, h * 0.84);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.t != t;
}
