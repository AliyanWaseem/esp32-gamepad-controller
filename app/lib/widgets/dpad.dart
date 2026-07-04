import 'package:flutter/material.dart';
import '../models/btn_constants.dart';

class DPad extends StatelessWidget {
  final double buttonSize;
  final void Function(int bit, bool pressed) onPress;
  const DPad({super.key, required this.buttonSize, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonSize * 3,
      height: buttonSize * 3,
      child: Stack(
        children: [
          Positioned(
            left: buttonSize,
            top: 0,
            child: _DPadButton(
              direction: AxisDirection.up,
              size: buttonSize,
              onPress: (p) => onPress(Btn.dpadUp, p),
            ),
          ),
          Positioned(
            left: buttonSize,
            top: buttonSize * 2,
            child: _DPadButton(
              direction: AxisDirection.down,
              size: buttonSize,
              onPress: (p) => onPress(Btn.dpadDown, p),
            ),
          ),
          Positioned(
            left: 0,
            top: buttonSize,
            child: _DPadButton(
              direction: AxisDirection.left,
              size: buttonSize,
              onPress: (p) => onPress(Btn.dpadLeft, p),
            ),
          ),
          Positioned(
            left: buttonSize * 2,
            top: buttonSize,
            child: _DPadButton(
              direction: AxisDirection.right,
              size: buttonSize,
              onPress: (p) => onPress(Btn.dpadRight, p),
            ),
          ),
        ],
      ),
    );
  }
}

class _DPadButton extends StatefulWidget {
  final AxisDirection direction;
  final double size;
  final void Function(bool pressed) onPress;
  const _DPadButton({required this.direction, required this.size, required this.onPress});
  @override
  State<_DPadButton> createState() => _DPadButtonState();
}

class _DPadButtonState extends State<_DPadButton> {
  bool _pressed = false;
  void _set(bool p) { setState(() => _pressed = p); widget.onPress(p); }

  @override
  Widget build(BuildContext context) {
    double rotation;
    switch (widget.direction) {
      case AxisDirection.up: rotation = 0; break;
      case AxisDirection.right: rotation = 1.5708; break;
      case AxisDirection.down: rotation = 3.14159; break;
      case AxisDirection.left: rotation = -1.5708; break;
    }
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
            border: Border.all(color: kOutlineDim, width: 1.5),
            borderRadius: BorderRadius.circular(4),
            color: _pressed ? kFillPressed : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: rotation,
            child: CustomPaint(
              size: Size(widget.size * 0.35, widget.size * 0.30),
              painter: _TrianglePainter(color: kOutlineDim),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => false;
}