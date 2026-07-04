import 'package:flutter/material.dart';
import '../models/btn_constants.dart';

class PillButton extends StatefulWidget {
  final String label;
  final void Function(bool pressed) onPress;
  const PillButton({super.key, required this.label, required this.onPress});
  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: kOutlineDim, width: 1.5),
            color: _pressed ? kFillPressed : Colors.transparent,
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: kOutlineDim,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}