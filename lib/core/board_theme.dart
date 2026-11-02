import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kust/l10n/app_locale.dart';

/// The colours the chess board can be drawn in. Picked in settings and used
/// by every board in the app.
enum BoardTheme {
  brown('Brown', Color(0xFFF0E6D2), Color(0xFFB58863)),
  green('Green', Color(0xFFEEEED2), Color(0xFF769656)),
  blue('Dark Blue', Color(0xFFEEEED2), Color(0xFF4D6F99)),
  wood('Wood', Color(0xFFE6CB9E), Color(0xFF9A6B3C), grain: true);

  const BoardTheme(this.label, this.light, this.dark, {this.grain = false});

  /// The English name, also used as the saved value's label.
  final String label;

  /// The name in the language in use.
  String labelIn(AppL10n t) => switch (this) {
    BoardTheme.brown => t.boardBrown,
    BoardTheme.green => t.boardGreen,
    BoardTheme.blue => t.boardDarkBlue,
    BoardTheme.wood => t.boardWood,
  };
  final Color light;
  final Color dark;

  /// Whether squares get a faint wood grain on top of their colour.
  final bool grain;

  /// The board in use when nothing is saved.
  static const BoardTheme defaultTheme = BoardTheme.brown;

  /// The theme saved under [name], or the default for an unknown name.
  static BoardTheme fromName(String? name) => BoardTheme.values.firstWhere(
    (t) => t.name == name,
    orElse: () => defaultTheme,
  );
}

/// Faint wood grain drawn over one square. The lines depend only on the
/// square, so the grain stays put when pieces move.
class WoodGrainPainter extends CustomPainter {
  const WoodGrainPainter({required this.seed, required this.light});

  /// Different for each square, so neighbours do not repeat each other.
  final int seed;

  /// Light squares get dark grain; dark squares get slightly darker grain.
  final bool light;

  static const int _lines = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed * 7919 + 13);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, size.height * 0.012)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _lines; i++) {
      final y =
          size.height * (i + 0.5 + (random.nextDouble() - 0.5) * 0.6) / _lines;
      final bend = (random.nextDouble() - 0.5) * size.height * 0.1;
      final alpha = 0.05 + random.nextDouble() * (light ? 0.07 : 0.09);
      paint.color = Colors.black.withValues(alpha: alpha);
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * 0.5, y + bend, size.width, y - bend);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WoodGrainPainter old) =>
      old.seed != seed || old.light != light;
}
