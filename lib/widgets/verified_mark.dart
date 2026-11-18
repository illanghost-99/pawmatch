import 'package:flutter/material.dart';

class VerifiedMark extends StatefulWidget {
  const VerifiedMark({super.key, required this.owner, required this.dog, this.size = 22, this.corner = false});
  final bool owner;
  final bool dog;
  final double size;
  final bool corner;

  @override
  State<VerifiedMark> createState() => _VerifiedMarkState();
}

class _VerifiedMarkState extends State<VerifiedMark> with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.owner && !widget.dog) return const SizedBox.shrink();
    const color = Color(0xFF39FF6A);
    return ScaleTransition(
      scale: Tween(begin: 0.92, end: 1.0).animate(pulse),
      child: Container(
        width: widget.size,
        height: widget.size,
        margin: widget.corner ? EdgeInsets.zero : const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: widget.size > 28 ? 2 : 1.4),
          boxShadow: const [BoxShadow(color: Color(0xAA39FF6A), blurRadius: 10)],
        ),
        alignment: Alignment.center,
        child: Text('V', style: TextStyle(color: const Color(0xFF083018), fontWeight: FontWeight.w900, fontSize: widget.size * 0.52, height: 1)),
      ),
    );
  }
}
