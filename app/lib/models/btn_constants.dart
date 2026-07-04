import 'dart:ui';

class Btn {
  static const int dpadUp = 1 << 0;
  static const int dpadDown = 1 << 1;
  static const int dpadLeft = 1 << 2;
  static const int dpadRight = 1 << 3;
  static const int cross = 1 << 4;
  static const int circle = 1 << 5;
  static const int square = 1 << 6;
  static const int triangle = 1 << 7;
  static const int extra1 = 1 << 8;
  static const int extra2 = 1 << 9;
  static const int extra3 = 1 << 10;
  static const int extra4 = 1 << 11;
  static const int extra5 = 1 << 12;
  static const int l = 1 << 13;
  static const int r = 1 << 14;
  static const int select = 1 << 15;
  static const int start = 1 << 16;
  static const int pause = 1 << 17;
}

const Color kOutline = Color(0xE6FFFFFF);
const Color kOutlineDim = Color(0x99FFFFFF);
const Color kFillPressed = Color(0x40FFFFFF);