import 'package:flutter/material.dart';

class VerifiedMark extends StatefulWidget {
  const VerifiedMark({super.key, required this.owner, required this.dog, this.size = 22});
  final bool owner;
  final bool dog;
  final double size;

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
    if (!widget.owner) return const SizedBox.shrink();
    final both = widget.dog;
    final color = both ? const Color(0xFF1F8A4C) : const Color(0xFF2F80ED);
    return ScaleTransition(
      scale: Tween(begin: 0.9, end: 1.0).animate(pulse),
      child: Container(
        width: widget.size,
        height: widget.size,
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
        ),
        alignment: Alignment.center,
        child: Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: widget.size * 0.52, height: 1)),
      ),
    );
  }
}
