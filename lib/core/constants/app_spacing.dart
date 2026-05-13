/// Spacing scale — all layout values come from here.
///
/// Tablet-first: generous spacing keeps the UI uncluttered for ADHD users.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Minimum touch target enforced on all interactive widgets (WCAG 2.5.5).
  static const double minTouchTarget = 48;

  /// Standard card border radius.
  static const double cardRadius = 20;

  /// Standard button border radius.
  static const double buttonRadius = 16;

  /// Icon size used in icon-label pairs.
  static const double iconSizeMd = 28;
  static const double iconSizeLg = 40;
  static const double iconSizeXl = 64;
}
