import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isMobile => screenWidth < 600;

  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  bool get isDesktop => screenWidth >= 1200;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
