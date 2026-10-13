import 'package:flutter/material.dart';

abstract class AppMotion {
  static const Duration instant = Duration(milliseconds: 100);

  static const Duration fast = Duration(milliseconds: 160);

  static const Duration standard = Duration(milliseconds: 240);

  static const Duration deliberate = Duration(milliseconds: 360);

  static const Curve standardCurve = Curves.easeOutCubic;

  static const Curve emphasisCurve = Curves.easeOutBack;
}
