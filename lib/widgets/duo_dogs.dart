import 'package:flutter/material.dart';

class DuoDogs extends StatelessWidget {
  const DuoDogs({super.key, this.size = 196});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.72,
      child: CustomPaint(painter: _DuoPainter()),
    );
  }
}

class _DuoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final big = Paint()..color = const Color(0xFF3A2A22);
    final small = Paint()..color = const Color(0xFFE8A87C);
    final cream = Paint()..color = const Color(0xFFFFF4EC);
    final blush = Paint()..color = const Color(0xFFE25C3A);

    final cx = size.width * 0.38;
    final cy = size.height * 0.62;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 8), width: size.width * 0.46, height: size.height * 0.52), big);
    canvas.drawCircle(Offset(cx, cy - size.height * 0.18), size.width * 0.16, big);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 22, cy - size.height * 0.32), width: 22, height: 34), big);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 22, cy - size.height * 0.32), width: 22, height: 34), big);
    canvas.drawCircle(Offset(cx - 7, cy - size.height * 0.20), 3.2, cream);
    canvas.drawCircle(Offset(cx + 8, cy - size.height * 0.20), 3.2, cream);

    final sx = size.width * 0.68;
    final sy = size.height * 0.70;
    canvas.drawOval(Rect.fromCenter(center: Offset(sx, sy), width: size.width * 0.28, height: size.height * 0.32), small);
    canvas.drawCircle(Offset(sx, sy - size.height * 0.16), size.width * 0.11, small);
    canvas.drawOval(Rect.fromCenter(center: Offset(sx - 16, sy - size.height * 0.26), width: 14, height: 18), small);
    canvas.drawOval(Rect.fromCenter(center: Offset(sx + 16, sy - size.height * 0.26), width: 14, height: 18), small);
    canvas.drawCircle(Offset(sx - 5, sy - size.height * 0.17), 2.4, cream);
    canvas.drawCircle(Offset(sx + 6, sy - size.height * 0.17), 2.4, cream);
    canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.42), 5, blush);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
