import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BackgroundPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double t; // 0..1 loop

  _BackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // ----- Dynamic gradient (deep blue ↔ dark red) -----
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(
          const Color(0xFF0B0E2A),
          const Color(0xFF1A0E1E),
          (math.sin(t * 2 * math.pi) + 1) / 2,
        )!,
        Color.lerp(
          const Color(0xFF1A0E1E),
          const Color(0xFF2A0A12),
          (math.cos(t * 2 * math.pi) + 1) / 2,
        )!,
        const Color(0xFF0B0E2A),
      ],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // ----- Drifting glowing orbs -----
    final blobs = [
      _Blob(const Color(0xFF3A5F9E), 0.0), // blue
      _Blob(const Color(0xFFB22234), 0.33), // red
      _Blob(const Color(0xFF4A3B7A), 0.66), // purple
    ];

    for (final blob in blobs) {
      final phase = (t + blob.offset) % 1.0;
      final angle = phase * 2 * math.pi;
      final cx = size.width * 0.5 + math.cos(angle) * size.width * 0.35;
      final cy = size.height * 0.5 + math.sin(angle * 1.3) * size.height * 0.35;
      final radius = size.shortestSide * 0.40;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.color.withOpacity(0.25),
            blob.color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
        ..blendMode = BlendMode.plus;

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }

    // ----- Optional: floating particles for extra depth -----
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.06);
    for (int i = 0; i < 30; i++) {
      final seed = (i * 137.508) % 1.0;
      final px = (seed * size.width + t * 20) % size.width;
      final py = (seed * size.height + t * 15) % size.height;
      canvas.drawCircle(Offset(px, py), 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _Blob {
  final Color color;
  final double offset;
  _Blob(this.color, this.offset);
}