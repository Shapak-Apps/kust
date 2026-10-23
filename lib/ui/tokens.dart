import 'package:flutter/material.dart';

/// Kust design tokens. Flat surfaces, hairline borders, one accent.
@immutable
class KustTokens extends ThemeExtension<KustTokens> {
  const KustTokens({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentInk,
    required this.success,
    required this.danger,
    required this.scrim,
  });

  static const Color gold = Color(0xFFFFBB00);

  static const light = KustTokens(
    bg: Color(0xFFF7F5F0),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEFECE4),
    ink: Color(0xFF17181A),
    muted: Color(0xFF858580),
    line: Color(0xFFE6E2D8),
    accent: gold,
    accentInk: Color(0xFF17181A),
    success: Color(0xFF2FA36B),
    danger: Color(0xFFD64545),
    scrim: Color(0x66000000),
  );

  static const dark = KustTokens(
    bg: Color(0xFF131313),
    surface: Color(0xFF1C1C1C),
    surfaceAlt: Color(0xFF262626),
    ink: Color(0xFFF2F0EA),
    muted: Color(0xFF8E8C86),
    line: Color(0xFF2D2D2D),
    accent: gold,
    accentInk: Color(0xFF17181A),
    success: Color(0xFF3CB77C),
    danger: Color(0xFFE5645F),
    scrim: Color(0x99000000),
  );

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color muted;
  final Color line;
  final Color accent;
  final Color accentInk;
  final Color success;
  final Color danger;
  final Color scrim;

  /// Four sizes only: 28 / 20 / 15 / 12.
  TextStyle get display => TextStyle(
    fontSize: 28,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.9,
    color: ink,
  );
  TextStyle get title => TextStyle(
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: ink,
  );
  TextStyle get body => TextStyle(
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: ink,
  );
  TextStyle get caption => TextStyle(
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: muted,
  );

  @override
  KustTokens copyWith() => this;

  @override
  KustTokens lerp(ThemeExtension<KustTokens>? other, double t) {
    if (other is! KustTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return KustTokens(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      line: l(line, other.line),
      accent: l(accent, other.accent),
      accentInk: l(accentInk, other.accentInk),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      scrim: l(scrim, other.scrim),
    );
  }
}

extension KustContext on BuildContext {
  KustTokens get k => Theme.of(this).extension<KustTokens>()!;
}

/// Spacing and radii on a 4/8 grid.
class KustSpace {
  KustSpace._();
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;

  static const double rSmall = 12;
  static const double rMedium = 16;
  static const double rLarge = 24;
  static const double rSheet = 28;
}
