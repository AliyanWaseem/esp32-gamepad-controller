import 'package:flutter/material.dart';
import '../models/btn_constants.dart';

class Joystick extends StatefulWidget {
  final double baseRadius;
  final void Function(double dx, double dy) onChanged;
  final VoidCallback onRelease;
  const Joystick({
    super.key,
    required this.onChanged,
    required this.onRelease,
    required this.baseRadius,
  });
  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _knobOffset = Offset.zero;
  bool get _isActive => _knobOffset != Offset.zero;
  double get _knobRadius => widget.baseRadius * 0.6;

  void _handleDrag(Offset localPos) {
    final baseRadius = widget.baseRadius;
    final center = Offset(baseRadius, baseRadius);
    Offset delta = localPos - center;
    final distance = delta.distance;
    final maxDistance = baseRadius - 10;
    if (distance > maxDistance) delta = delta / distance * maxDistance;
    setState(() => _knobOffset = delta);
    widget.onChanged(delta.dx / maxDistance, delta.dy / maxDistance);
  }

  void _handleRelease() {
    setState(() => _knobOffset = Offset.zero);
    widget.onRelease();
  }

  @override
  Widget build(BuildContext context) {
    final baseRadius = widget.baseRadius;
    return GestureDetector(
      onPanUpdate: (details) => _handleDrag(details.localPosition),
      onPanEnd: (_) => _handleRelease(),
      onPanCancel: _handleRelease,
      child: Container(
        width: baseRadius * 2,
        height: baseRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: kOutlineDim, width: 1.5),
          color: Colors.transparent,
        ),
        child: Center(
          child: Transform.translate(
            offset: _knobOffset,
            child: Transform.scale(
              scale: _isActive ? 1.15 : 1.0,
              child: Container(
                width: _knobRadius * 2,
                height: _knobRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kOutlineDim, width: 3.0),
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}