import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kust/ui/kust_logo.dart';
import 'package:kust/ui/tokens.dart';

/// The opening animation, laid over the app as it starts. It begins as the
/// native splash ends, the Square K on gold, plays [SplashArt] to the
/// wordmark and fades into the app. Skipped when the system asks for less
/// motion.
class KustSplash extends StatefulWidget {
  const KustSplash({super.key, required this.child});

  final Widget child;

  @override
  State<KustSplash> createState() => _KustSplashState();
}

class _KustSplashState extends State<KustSplash>
    with SingleTickerProviderStateMixin {
  // The art plays for 1250 ms, holds, then fades from 1350 to 1650.
  late final AnimationController _c =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1650),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() => _done = true);
      });
  bool _done = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _done = true;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (!_done)
          Positioned.fill(
            // Taps wait for the app to show, rather than landing on it unseen.
            child: AbsorbPointer(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.dark,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final ms = _c.value * 1650;
                    return Opacity(
                      opacity: 1 - _at(ms, 1350, 1650, Curves.easeIn),
                      child: SplashArt(t: ms / 1250),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The Square K turning into the wordmark on gold, full screen: at [t] 0 the
/// K as on the native splash, at 1 the settled wordmark, which is also what
/// the first-run welcome shows, so the splash hands over without a jump.
class SplashArt extends StatelessWidget {
  const SplashArt({super.key, this.t = 1});

  final double t;

  /// The K's height on the native splash: the splash image's K in Android
  /// 12's 288 dp icon (740 of 2048 px), and the K of the 512 pt image used
  /// on iOS and older Android (416 of 2048 px).
  static const double startHeight = 104;

  /// The settled K's height on a screen [width] wide.
  static double endHeight(double width) =>
      (width * 0.6 / _wordWidth).clamp(48.0, 96.0);

  /// How far the settled wordmark reaches below the screen's middle: half
  /// the K, and the tail of the ş under it.
  static double reachBelowMiddle(double width) =>
      endHeight(width) * (0.5 + (_tailBottom - _kBottom) / _kHeight);

  // The wordmark's SVG units: its box starts at (214, 136) and is 1180 by
  // 540; the K spans x 221.95 to 543.95 and y 146.5 to 549, the t ends at
  // about x 1327.74 and the tail of the ş at y 672.05.
  static const double _kLeft = 221.95 - 214;
  static const double _kTop = 146.5 - 136;
  static const double _kHeight = 402.5;
  static const double _kRight = 543.95;
  static const double _kBottom = 549;
  static const double _tailBottom = 672.05;
  static const double _end = 1327.74;
  static const double _boxRight = 214 + 1180;
  static const double _wordWidth = (_end - 221.95) / _kHeight; // in K heights

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const ink = Color(0xFF17181A);
    // Milliseconds out of 1250.
    final ms = t * 1250;
    final move = _at(ms, 120, 620, Curves.easeInOutCubic);
    final slide = _at(ms, 420, 1000, Curves.easeOutCubic);
    final drop = _at(ms, 950, 1250, Curves.easeOutBack);

    // The K, from the size and place of the native splash to its place in
    // the centred wordmark.
    final endH = endHeight(size.width);
    final h = _lerp(startHeight, endH, move);
    final endCenterX = (size.width - _wordWidth * endH) / 2 + endH * 0.4;
    final cx = _lerp(size.width / 2, endCenterX, move);
    final left = cx - h * 0.4;
    final top = size.height / 2 - h / 2;

    final u = h / _kHeight;
    // Hidden at the start: the whole box, not just the letters, is pushed
    // behind the K, since curves and the t's bar reach past the outline.
    final boxLeft = left - _kLeft * u - (1 - slide) * (_boxRight - _kRight) * u;
    final boxTop = top - _kTop * u;
    Widget layer(String asset, Color color) => SvgPicture.asset(
      asset,
      width: 1180 * u,
      height: 540 * u,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

    return ColoredBox(
      color: KustTokens.gold,
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          // "üşt" slides out from behind the K: drawn only right of it.
          ClipRect(
            clipper: _RightOf(left + 0.8 * h),
            child: Stack(
              alignment: Alignment.topLeft,
              children: [
                // The dots and the tail, white on gold, drop in last,
                // behind the letters so the ş stays whole, as in KustLogo.
                Positioned(
                  left: boxLeft,
                  top: boxTop - (1 - drop) * 60 * u,
                  child: Opacity(
                    opacity: drop.clamp(0.0, 1.0),
                    child: layer(
                      'assets/images/wordmark_dots.svg',
                      Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  left: boxLeft,
                  top: boxTop,
                  child: layer('assets/images/wordmark_letters.svg', ink),
                ),
              ],
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: KustSymbol(height: h, color: ink, lastMove: Colors.white),
          ),
        ],
      ),
    );
  }
}

double _at(double ms, double from, double to, Curve curve) =>
    curve.transform(((ms - from) / (to - from)).clamp(0.0, 1.0));

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Everything right of [x].
class _RightOf extends CustomClipper<Rect> {
  const _RightOf(this.x);

  final double x;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(x, 0, size.width, size.height);

  @override
  bool shouldReclip(_RightOf old) => old.x != x;
}
