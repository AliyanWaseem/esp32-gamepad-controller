import 'package:flutter/material.dart';
import '../models/btn_constants.dart';

class ShoulderButton extends StatefulWidget {
  final String label;
  final double width;
  final double height;
  final bool alignLeft;
  final void Function(bool pressed) onPress;
  const ShoulderButton({
    super.key,
    required this.label,
    required this.width,
    required this.height,
    required this.alignLeft,
    required this.onPress,
  });
  @override
  State<ShoulderButton> createState() => _ShoulderButtonState();
}

class _ShoulderButtonState extends State<ShoulderButton> {
  bool _pressed = false;
  void _set(bool p) { setState(() => _pressed = p); widget.onPress(p); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: Transform.scale(
        scale: _pressed ? 1.12 : 1.0,
        child: Container(
          width: widget.width,
          height: widget.height,
          color: _pressed ? kFillPressed : Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: kOutlineDim,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Outline painter for L/R trapezoid shape
class ShoulderButtonOutlinePainter extends CustomPainter {
  final bool isLeft;
  ShoulderButtonOutlinePainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kOutlineDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    if (isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(20, 0);
      path.quadraticBezierTo(0, 0, 0, 16);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width - 20, 0);
      path.quadraticBezierTo(size.width, 0, size.width, 16);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}