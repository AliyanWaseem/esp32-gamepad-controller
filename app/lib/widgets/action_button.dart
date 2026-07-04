import 'package:flutter/material.dart';
import '../models/btn_constants.dart';

enum ActionShape { triangle, square, circle, cross }

class ActionButton extends StatefulWidget {
  final ActionShape shape;
  final double size;
  final void Function(bool pressed) onPress;
  const ActionButton({super.key, required this.shape, required this.size, required this.onPress});
  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _pressed = false;
  void _set(bool p) { setState(() => _pressed = p); widget.onPress(p); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: Transform.scale(
        scale: _pressed ? 1.15 : 1.0,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kOutlineDim, width: 1.5),
            color: _pressed ? kFillPressed : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: CustomPaint(
            size: Size(widget.size * 0.45, widget.size * 0.45),
            painter: _ActionShapePainter(shape: widget.shape, color: kOutlineDim),
          ),
        ),
      ),
    );
  }
}

class _ActionShapePainter extends CustomPainter {
  final ActionShape shape;
  final Color color;
  _ActionShapePainter({required this.shape, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0;
    switch (shape) {
      case ActionShape.cross:
        canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
        canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
        break;
      case ActionShape.circle:
        canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.45, paint);
        break;
      case ActionShape.square:
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;
      case ActionShape.triangle:
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
        break;
    }
  }
  @override
  bool shouldRepaint(covariant _ActionShapePainter oldDelegate) => false;
}