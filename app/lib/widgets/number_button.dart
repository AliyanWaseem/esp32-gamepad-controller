import 'package:flutter/material.dart';
import '../models/btn_constants.dart';

class NumberButton extends StatefulWidget {
  final int number;
  final double size;
  final void Function(bool pressed) onPress;
  const NumberButton({super.key, required this.number, required this.size, required this.onPress});
  @override
  State<NumberButton> createState() => _NumberButtonState();
}

class _NumberButtonState extends State<NumberButton> {
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
          child: Text(
            '${widget.number}',
            style: TextStyle(
              color: kOutlineDim,
              fontSize: widget.size * 0.5,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}