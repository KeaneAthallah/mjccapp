import 'package:flutter/widgets.dart';

/// Centralized spacing scale for the MJCC app.
///
/// Mirrors the fine-grained Tailwind spacing values used across the Laravel
/// website (`space-y-*`, `gap-*`, `p-*`) so the Flutter app uses the same
/// relaxed, airy rhythm. Prefer these constants over ad-hoc pixel values.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal page gutter for scrollable screens.
  static const EdgeInsets page = EdgeInsets.all(md);

  static const EdgeInsets card = EdgeInsets.all(md);

  /// Inset used inside a card's padded body.
  static const EdgeInsets cardBody = EdgeInsets.all(md);

  /// Uniform spacing between vertically stacked dashboard sections.
  static const double sectionGap = lg;
}
