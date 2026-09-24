import 'dart:math';
import 'package:flutter/material.dart';

class DuoDogs extends StatefulWidget {
  const DuoDogs({super.key, this.size = 168});
  final double size;
  @override
  State<DuoDogs> createState() => _DuoDogsState();
}

class _DuoDogsState extends State<DuoDogs> with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);

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
        final bob = sin(c.value * pi) * 6;
        final tilt = (c.value - 0.5) * 0.06;
        return SizedBox(
          width: widget.size,
          height: widget.size * 0.78,
          child: CustomPaint(painter: _DuoPainter(bob, tilt)),
        );
      },
    );
  }
}

class _DuoPainter extends CustomPainter {
  _DuoPainter(this.bob, this.tilt);
  final double bob;
  final double tilt;

  @override
  void paint(Canvas canvas, Size size) {
    final plate = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.08, size.width, size.height * 0.84),
      const Radius.circular(28),
    );
    canvas.drawRRect(
      plate,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE8D6), Color(0xFFFFF4EC), Color(0xFFD8F3EF)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(plate, Paint()..color = const Color(0x33E25C3A)..style = PaintingStyle.stroke..strokeWidth = 3);

    canvas.save();
    canvas.translate(size.width * 0.34, size.height * 0.58 + bob);
    canvas.rotate(-0.08 + tilt);
    _rottie(canvas, size.width * 0.42);
    canvas.restore();

    canvas.save();
    canvas.translate(size.width * 0.68, size.height * 0.66 - bob);
    canvas.rotate(0.12 - tilt);
    _pom(canvas, size.width * 0.22);
    canvas.restore();

    final heart = Paint()..color = const Color(0xFFE25C3A);
    final hx = size.width * 0.52;
    final hy = size.height * 0.22 + bob * 0.3;
    final path = Path()
      ..moveTo(hx, hy + 8)
      ..cubicTo(hx - 16, hy - 6, hx - 8, hy - 16, hx, hy - 4)
      ..cubicTo(hx + 8, hy - 16, hx + 16, hy - 6, hx, hy + 8);
    canvas.drawPath(path, heart);
  }

  void _rottie(Canvas canvas, double w) {
    final body = Paint()..color = const Color(0xFF2B211C);
    final tan = Paint()..color = const Color(0xFFC97B4A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, 8), width: w, height: w * 0.72), const Radius.circular(18)), body);
    canvas.drawCircle(Offset(0, -w * 0.28), w * 0.28, body);
    canvas.drawCircle(Offset(-w * 0.16, -w * 0.48), w * 0.12, body);
    canvas.drawCircle(Offset(w * 0.16, -w * 0.48), w * 0.12, body);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -w * 0.22), width: w * 0.22, height: w * 0.16), tan);
    canvas.drawCircle(Offset(-w * 0.1, -w * 0.3), 3.2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.1, -w * 0.3), 3.2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(0, -w * 0.16), 3.4, Paint()..color = const Color(0xFF111111));
  }

  void _pom(Canvas canvas, double w) {
    final fur = Paint()..color = const Color(0xFFE8B86D);
    canvas.drawCircle(Offset.zero, w * 0.62, fur);
    canvas.drawCircle(Offset(0, -w * 0.08), w * 0.38, Paint()..color = const Color(0xFFF3D19A));
    canvas.drawCircle(Offset(-w * 0.28, -w * 0.42), w * 0.18, fur);
    canvas.drawCircle(Offset(w * 0.28, -w * 0.42), w * 0.18, fur);
    canvas.drawCircle(Offset(-w * 0.1, -w * 0.1), 2.6, Paint()..color = const Color(0xFF3A2A1A));
    canvas.drawCircle(Offset(w * 0.1, -w * 0.1), 2.6, Paint()..color = const Color(0xFF3A2A1A));
    canvas.drawCircle(Offset(0, 0.02 * w), 2.4, Paint()..color = const Color(0xFF2B211C));
  }

  @override
  bool shouldRepaint(covariant _DuoPainter old) => old.bob != bob;
}
