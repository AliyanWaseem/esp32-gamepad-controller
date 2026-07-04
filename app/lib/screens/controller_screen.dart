import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/btn_constants.dart';
import '../widgets/dpad.dart';
import '../widgets/action_button.dart';
import '../widgets/number_button.dart';
import '../widgets/pill_button.dart';
import '../widgets/shoulder_button.dart';
import '../widgets/joystick.dart';
import '../widgets/animated_background.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});
  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  static const String espIp = '192.168.4.1';
  static const int espPort = 4210;

  RawDatagramSocket? _socket;
  int _buttonMask = 0;
  int _joyX = 128;
  int _joyY = 128;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  Future<void> _initSocket() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  }

  void _sendPacket() {
    if (_socket == null) return;
    final mask = _buttonMask;
    final b0 = mask & 0xFF;
    final b1 = (mask >> 8) & 0xFF;
    final b2 = (mask >> 16) & 0xFF;
    final b3 = (mask >> 24) & 0xFF;
    final x = _joyX & 0xFF;
    final y = _joyY & 0xFF;
    final checksum = (0xAA ^ b0 ^ b1 ^ b2 ^ b3 ^ x ^ y) & 0xFF;
    final packet = [0xAA, b0, b1, b2, b3, x, y, checksum];
    _socket!.send(packet, InternetAddress(espIp), espPort);
  }

  void _setButton(int bit, bool pressed) {
    setState(() {
      if (pressed)
        _buttonMask |= bit;
      else
        _buttonMask &= ~bit;
    });
    _sendPacket();
  }

  void _updateJoystick(double dx, double dy) {
    setState(() {
      _joyX = (128 + dx * 127).clamp(0, 255).toInt();
      _joyY = (128 + dy * 127).clamp(0, 255).toInt();
    });
    _sendPacket();
  }

  void _resetJoystick() {
    setState(() {
      _joyX = 128;
      _joyY = 128;
    });
    _sendPacket();
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.black,
  //     body: OrientationBuilder(
  //       builder: (context, orientation) {
  //         if (orientation == Orientation.portrait) {
  //           return const _RotateDevicePrompt();
  //         }
  //         return SafeArea(child: _buildLayout(context));
  //       },
  //     ),
  //   );
  // }

  // In ControllerScreen's build method:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // important
      body: Stack(
        children: [
          // Animated background
          const AnimatedBackground(),
          // Layout (OrientationBuilder)
          OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.portrait) {
                return const _RotateDevicePrompt();
              }
              return SafeArea(child: _buildLayout(context));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double clusterCenterX = 160;
        final double clusterCenterY = 160;

        return Stack(
          children: [
            // --- 1. GREEN STATUS BANNER ---
            // Positioned(
            //   top: 0,
            //   left: 0,
            //   right: 0,
            //   child: Center(
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            //       color: const Color(0xFF007A00),
            //       child: const Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Icon(Icons.check, color: Colors.white, size: 18),
            //           SizedBox(width: 6),
            //           Text(
            //             "Mangoes developer",
            //             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),

            // --- 2. LEFT SHOULDER (L) ---
            Positioned(
              top: 20,
              // left: 20,
              left: 15,
              child: CustomPaint(
                painter: ShoulderButtonOutlinePainter(isLeft: true),
                child: ShoulderButton(
                  label: 'L',
                  width: 110,
                  height: 40,
                  alignLeft: true,
                  onPress: (p) => _setButton(Btn.l, p),
                ),
              ),
            ),

            // --- 3. RIGHT SHOULDER (R) ---
            Positioned(
              top: 20,
              right: 20,
              child: CustomPaint(
                painter: ShoulderButtonOutlinePainter(isLeft: false),
                child: ShoulderButton(
                  label: 'R',
                  width: 110,
                  height: 40,
                  alignLeft: false,
                  onPress: (p) => _setButton(Btn.r, p),
                ),
              ),
            ),

            // --- 4. D-PAD ---
            Positioned(
              bottom: 150,
              // left: 50,
              left: 20,
              child: SizedBox(
                width: 140,
                height: 140,
                child: DPad(
                  buttonSize: 45,
                  onPress: (bit, p) => _setButton(bit, p),
                ),
              ),
            ),

            // --- 5. JOYSTICK ---
            Positioned(
              bottom: 25,
              // left: 60,
              left: 30,
              child: Joystick(
                baseRadius: 60,
                onChanged: _updateJoystick,
                onRelease: _resetJoystick,
              ),
            ),

            // --- 6. UTILITY BAR ---
            Positioned(
              bottom: 25,
              left: 0,
              right: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PillButton(
                    label: '▶▶',
                    onPress: (p) => _setButton(Btn.pause, p),
                  ),
                  const SizedBox(width: 8),
                  PillButton(
                    label: 'SELECT',
                    onPress: (p) => _setButton(Btn.select, p),
                  ),
                  const SizedBox(width: 8),
                  PillButton(
                    label: 'START',
                    onPress: (p) => _setButton(Btn.start, p),
                  ),
                ],
              ),
            ),

            // --- 7. ACTION & MACRO CLUSTER ---
            Positioned(
              bottom: 20,
              // right: 40,
              right: 20,
              child: SizedBox(
                width: 320,
                height: 320,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Diamond
                    Positioned(
                      left: clusterCenterX + 24,
                      top: clusterCenterY - 26,
                      child: ActionButton(
                        shape: ActionShape.triangle,
                        size: 52,
                        onPress: (p) => _setButton(Btn.triangle, p),
                      ),
                    ),
                    Positioned(
                      left: clusterCenterX - 26,
                      top: clusterCenterY + 24,
                      child: ActionButton(
                        shape: ActionShape.square,
                        size: 52,
                        onPress: (p) => _setButton(Btn.square, p),
                      ),
                    ),
                    Positioned(
                      left: clusterCenterX + 80,
                      top: clusterCenterY + 24,
                      child: ActionButton(
                        shape: ActionShape.circle,
                        size: 52,
                        onPress: (p) => _setButton(Btn.circle, p),
                      ),
                    ),
                    Positioned(
                      left: clusterCenterX + 24,
                      top: clusterCenterY + 72,
                      child: ActionButton(
                        shape: ActionShape.cross,
                        size: 52,
                        onPress: (p) => _setButton(Btn.cross, p),
                      ),
                    ),
                    // Macros
                    Positioned(
                      // left: clusterCenterX + 24,
                      left: clusterCenterX + 30,
                      // top: clusterCenterY - 124,
                      top: clusterCenterY - 104,
                      child: NumberButton(
                        number: 1,
                        size: 50,
                        onPress: (p) => _setButton(Btn.extra1, p),
                      ),
                    ),
                    Positioned(
                      left: clusterCenterX - 26,
                      top: clusterCenterY - 76,
                      child: NumberButton(
                        number: 2,
                        size: 50,
                        onPress: (p) => _setButton(Btn.extra2, p),
                      ),
                    ),
                    Positioned(
                      left: clusterCenterX - 76,
                      top: clusterCenterY - 26,
                      child: NumberButton(
                        number: 5,
                        size: 50,
                        onPress: (p) => _setButton(Btn.extra5, p),
                      ),
                    ),
                    Positioned(
                      left: clusterCenterX - 134,
                      top: clusterCenterY + 24,
                      child: NumberButton(
                        number: 3,
                        size: 50,
                        onPress: (p) => _setButton(Btn.extra3, p),
                      ),
                    ),
                    Positioned(
                      left: clusterCenterX - 110,
                      top: clusterCenterY + 84,
                      child: NumberButton(
                        number: 4,
                        size: 50,
                        onPress: (p) => _setButton(Btn.extra4, p),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RotateDevicePrompt extends StatelessWidget {
  const _RotateDevicePrompt();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.screen_rotation, color: kOutline, size: 56),
          const SizedBox(height: 16),
          const Text(
            'Rotate your device to landscape',
            style: TextStyle(color: kOutlineDim, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
