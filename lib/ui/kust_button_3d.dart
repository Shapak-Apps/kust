import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The big green call to action: a chunky button standing on a darker lip,
/// pressed down onto it on tap. Used for the main action of Learn and
/// Puzzles, so both read the same.
class KustButton3D extends StatefulWidget {
  const KustButton3D({
    super.key,
    required this.label,
    required this.onTap,
    this.expand = false,
    this.icon,
    this.height = 50,
    this.colors = green,
  });

  /// Face top, face and lip; green by default.
  final ({Color top, Color face, Color lip, Color ink}) colors;

  static const green = (
    top: faceTop,
    face: KustButton3D.face,
    lip: lipColor,
    ink: Colors.white,
  );

  /// The brand's gold, with white text like the green (Challenge).
  static const gold = (
    // A warm, slightly deeper gold than the logo's, easy on the eye with
    // white text.
    top: Color(0xFFEEB23A),
    face: Color(0xFFDE9C14),
    lip: Color(0xFF9A6A08),
    ink: Colors.white,
  );

  final String label;
  final VoidCallback? onTap;
  final bool expand;
  final IconData? icon;
  final double height;

  static const Color face = Color(0xFF3CB77C);
  static const Color faceTop = Color(0xFF52C98E);
  static const Color lipColor = Color(0xFF1F7A4B);

  @override
  State<KustButton3D> createState() => _KustButton3DState();
}

class _KustButton3DState extends State<KustButton3D> {
  bool _down = false;

  static const double _lip = 4;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: enabled ? widget.colors.ink : const Color(0xFF8E8C86),
        shadows: enabled
            ? const [Shadow(color: Color(0x55000000), offset: Offset(0, 1.5))]
            : null,
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapCancel: () => _set(false),
        onTapUp: enabled
            ? (_) {
                _set(false);
                HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        // The face stands on a darker lip; pressed, it sinks onto it and
        // the lip disappears, keeping the same overall height.
        child: AnimatedContainer(
          // Sinks fast, comes back a little slower.
          duration: Duration(milliseconds: _down ? 70 : 120),
          curve: _down ? Curves.easeOut : Curves.easeOutCubic,
          margin: EdgeInsets.only(top: _down ? _lip : 0),
          padding: EdgeInsets.only(bottom: _down ? 0 : _lip),
          decoration: BoxDecoration(
            color: enabled ? widget.colors.lip : const Color(0xFF2A2724),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              gradient: enabled
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [widget.colors.top, widget.colors.face],
                    )
                  : null,
              color: enabled ? null : const Color(0xFF3A3632),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: widget.colors.ink, size: 22),
                  const SizedBox(width: 8),
                ],
                Flexible(child: label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
