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
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);

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
        final bob = sin(c.value * pi) * 2.5;
        return SizedBox(
          width: widget.size * 1.15,
          height: widget.size * 0.72,
          child: CustomPaint(painter: _DuoPainter(bob)),
        );
      },
    );
  }
}

class _DuoPainter extends CustomPainter {
  _DuoPainter(this.bob);
  final double bob;

  @override
  void paint(Canvas canvas, Size size) {
    final plate = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18));
    canvas.drawRRect(plate, Paint()..color = const Color(0xFFF3EEE8));
    canvas.drawRRect(
      plate,
      Paint()
        ..color = const Color(0xFFC9B8A8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.save();
    canvas.translate(size.width * 0.34, size.height * 0.62 + bob);
    _rottweiler(canvas, size.width * 0.46);
    canvas.restore();

    canvas.save();
    canvas.translate(size.width * 0.74, size.height * 0.70 - bob * 0.6);
    _pomeranian(canvas, size.width * 0.20);
    canvas.restore();
  }

  void _rottweiler(Canvas canvas, double w) {
    final black = Paint()..color = const Color(0xFF1A1513);
    final rust = Paint()..color = const Color(0xFFB35A2A);
    final cream = Paint()..color = const Color(0xFFD9A06A);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(4, 10), width: w * 0.95, height: w * 0.52), const Radius.circular(10)),
      black,
    );
    canvas.drawOval(Rect.fromCenter(center: Offset(-w * 0.18, 8), width: w * 0.22, height: w * 0.16), rust);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-w * 0.18, w * 0.18, w * 0.16, w * 0.28), const Radius.circular(4)),
      rust,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, w * 0.18, w * 0.16, w * 0.28), const Radius.circular(4)),
      rust,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-w * 0.02, w * 0.18, w * 0.12, w * 0.26), const Radius.circular(4)),
      black,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, w * 0.18, w * 0.12, w * 0.26), const Radius.circular(4)),
      black,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-w * 0.38, -w * 0.18), width: w * 0.42, height: w * 0.38), const Radius.circular(8)),
      black,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-w * 0.56, -w * 0.10), width: w * 0.22, height: w * 0.16), const Radius.circular(5)),
      black,
    );
    canvas.drawOval(Rect.fromCenter(center: Offset(-w * 0.52, -w * 0.08), width: w * 0.12, height: w * 0.08), rust);
    canvas.drawOval(Rect.fromCenter(center: Offset(-w * 0.34, -w * 0.22), width: w * 0.10, height: w * 0.06), rust);
    canvas.drawOval(Rect.fromLTWH(-w * 0.30, -w * 0.40, w * 0.10, w * 0.20), black);
    canvas.drawCircle(Offset(-w * 0.44, -w * 0.22), 3.2, Paint()..color = const Color(0xFFE8E0D4));
    canvas.drawCircle(Offset(-w * 0.45, -w * 0.22), 1.6, Paint()..color = const Color(0xFF111111));
    canvas.drawCircle(Offset(-w * 0.64, -w * 0.08), 2.6, Paint()..color = const Color(0xFF0E0E0E));
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.42, 2), width: w * 0.16, height: w * 0.10), black);
    canvas.drawCircle(Offset(-w * 0.58, -w * 0.02), 1.4, cream);
  }

  void _pomeranian(Canvas canvas, double w) {
    final coat = Paint()..color = const Color(0xFFD4923A);
    final light = Paint()..color = const Color(0xFFE8B56A);
    final dark = Paint()..color = const Color(0xFF5A3A22);
    final white = Paint()..color = const Color(0xFFF7F1E8);

    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.18, 0), width: w * 1.15, height: w * 0.95), coat);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.42, -w * 0.08), width: w * 0.55, height: w * 0.70), light);
    canvas.drawOval(Rect.fromCenter(center: Offset(-w * 0.02, -w * 0.06), width: w * 0.55, height: w * 0.48), light);

    final earL = Path()
      ..moveTo(-w * 0.18, -w * 0.28)
      ..lineTo(-w * 0.08, -w * 0.58)
      ..lineTo(w * 0.06, -w * 0.28)
      ..close();
    final earR = Path()
      ..moveTo(w * 0.02, -w * 0.22)
      ..lineTo(w * 0.16, -w * 0.55)
      ..lineTo(w * 0.24, -w * 0.18)
      ..close();
    canvas.drawPath(earL, coat);
    canvas.drawPath(earR, coat);

    canvas.drawOval(Rect.fromCenter(center: Offset(-w * 0.22, 0.02), width: w * 0.28, height: w * 0.18), light);
    canvas.drawCircle(Offset(-w * 0.08, -w * 0.10), 2.4, dark);
    canvas.drawCircle(Offset(-w * 0.32, 0.02), 2.0, Paint()..color = const Color(0xFF2A1A12));
    canvas.drawCircle(Offset(-w * 0.10, -w * 0.12), 0.7, white);

    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.38, w * 0.22), width: w * 0.18, height: w * 0.28), coat);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.18, w * 0.22), width: w * 0.16, height: w * 0.26), coat);
  }

  @override
  bool shouldRepaint(covariant _DuoPainter old) => old.bob != bob;
}
