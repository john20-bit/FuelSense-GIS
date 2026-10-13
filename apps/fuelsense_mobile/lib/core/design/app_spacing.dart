import 'package:flutter/widgets.dart';

abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  static const EdgeInsets screen = EdgeInsets.fromLTRB(20, 16, 20, 32);

  static const EdgeInsets screenCompact = EdgeInsets.fromLTRB(16, 16, 16, 24);
}
