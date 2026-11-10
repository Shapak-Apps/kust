import 'dart:math' as math;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/features/onboarding/onboarding_level.dart';
import 'package:kust/features/learn/garden_map.dart';
import 'package:kust/features/puzzles/speech_bubble.dart';
import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/kust_logo.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

const int _stepCount = 3;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  bool _forward = true;
  bool _finishing = false;
  OnboardingLevel? _level;

  void _goTo(int step) {
    setState(() {
      _forward = step > _step;
      _step = step;
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final prefs = await SharedPreferences.getInstance();
    await completeOnboarding(
      prefs: prefs,
      ratingStore: PlayerRatingStore.instance,
      level: _level,
    );
    if (!mounted) return;
    final router = GoRouter.of(context);
    if (_level == OnboardingLevel.beginner) {
      // Someone new to chess starts with the first lesson.
      router.go('/learn');
      router.push('/lesson/${kLessons.first.id}');
    } else {
      router.go('/play');
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = context.k;

    return Scaffold(
      backgroundColor: k.bg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: _step > 0
                        ? KustIconButton(
                            icon: Icons.arrow_back_rounded,
                            label: context.t.back,
                            onTap: () => _goTo(_step - 1),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _ProgressBars(step: _step)),
                  const SizedBox(width: 56),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final entering = child.key == ValueKey(_step);
                final dx = (_forward ? 1 : -1) * (entering ? 0.08 : -0.08);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: Offset(entering ? dx : 0, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: switch (_step) {
                  0 => const _WelcomeStep(),
                  1 => _LevelStep(
                    selected: _level,
                    onSelected: (l) => setState(() => _level = l),
                  ),
                  _ => _ReadyStep(level: _level),
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KustButton3D(
                    expand: true,
                    label: switch (_step) {
                      0 => context.t.onbGetStarted,
                      1 => context.t.cont,
                      _ =>
                        _level == OnboardingLevel.beginner
                            ? context.t.onbStartLesson
                            : context.t.onbStartPlaying,
                    },
                    onTap: switch (_step) {
                      0 => () => _goTo(1),
                      1 => _level == null ? null : () => _goTo(2),
                      _ => _finishing ? null : _finish,
                    },
                  ),
                  if (_step == 1) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() => _level = null);
                        _goTo(2);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          context.t.onbSkip,
                          style: k.body.copyWith(
                            color: k.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Row(
      children: [
        for (var i = 0; i < _stepCount; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 6,
              decoration: BoxDecoration(
                color: i <= step ? KustButton3D.face : k.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

const String _coachImage = 'assets/bots/Bahar.webp';

/// The piece that stands for a level, from the pawn to the king.
Role _pieceFor(OnboardingLevel? level) => switch (level) {
  OnboardingLevel.beginner || null => Role.pawn,
  OnboardingLevel.intermediate => Role.knight,
  OnboardingLevel.advanced => Role.rook,
  OnboardingLevel.competitive => Role.king,
};

/// Bahar with a line in a speech bubble.
class _Coach extends StatelessWidget {
  const _Coach(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            _coachImage,
            width: 64,
            height: 64,
            cacheWidth: 192,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: CustomPaint(
            painter: SpeechBubblePainter(fill: k.surfaceAlt, border: k.line),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                BubbleMetrics.tail + 14,
                12,
                14,
                12,
              ),
              child: Text(
                text,
                style: k.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A raised gold tile on a patch of the Learn garden, for pieces to stand
/// on.
class _StagePainter extends CustomPainter {
  const _StagePainter({this.tileWidth = 180, this.garden = true});

  final double tileWidth;
  final bool garden;

  static Path _diamond(Offset c, double w, double h) {
    final side = w / math.sqrt2;
    final square = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: side, height: side),
          Radius.circular(side * 0.2),
        ),
      );
    final m = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(1, h / w, 1, 1)
      ..rotateZ(math.pi / 4);
    return square.transform(m.storage);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (garden) {
      canvas.drawRect(Offset.zero & size, Paint()..color = GardenColors.ground);
      final light = Paint()..color = GardenColors.groundLight;
      const w = 120.0, h = 70.0;
      for (var y = 0.0; y < size.height + h; y += h) {
        for (var x = 0.0; x < size.width + w; x += w) {
          canvas.drawPath(
            Path()
              ..moveTo(x, y - h / 2)
              ..lineTo(x + w / 2, y)
              ..lineTo(x, y + h / 2)
              ..lineTo(x - w / 2, y)
              ..close(),
            light,
          );
        }
      }
    }
    final tw = tileWidth, th = tileWidth * 0.57;
    const depth = 20.0;
    final c = Offset(size.width / 2, size.height - th / 2 - depth - 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: c + const Offset(6, depth + 12),
        width: tw,
        height: th * 0.7,
      ),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final face = _diamond(c, tw, th);
    final b = face.getBounds();
    final side = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB98A1C), Color(0xFF86620F)],
      ).createShader(Rect.fromLTRB(b.left, c.dy, b.right, b.bottom + depth));
    canvas.drawPath(face.shift(const Offset(0, depth)), side);
    canvas.drawRect(Rect.fromLTRB(b.left, c.dy, b.right, c.dy + depth), side);
    canvas.drawPath(face, Paint()..color = const Color(0xFFF7C746));
    for (final k in [0.74, 0.48]) {
      canvas.drawPath(
        _diamond(c, tw * k, th * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = const Color(0xFFE8B02B),
      );
    }
    canvas.drawPath(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xCCFFE394),
    );
  }

  @override
  bool shouldRepaint(_StagePainter old) =>
      old.tileWidth != tileWidth || old.garden != garden;
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KustLogo(height: 26),
          const SizedBox(height: 18),
          // Three pieces on a raised tile in the Learn garden.
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: const _StagePainter(),
                  child: Align(
                    alignment: const Alignment(0, 0.42),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        LearnPiece(Role.knight, height: 104),
                        LearnPiece(Role.king, height: 150),
                        LearnPiece(Role.queen, height: 124),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _Coach(t.onbCoachHi),
          const SizedBox(height: 22),
          Text(t.onbTitle, style: k.display),
          const SizedBox(height: 16),
          _Feature(
            icon: Icons.smart_toy_rounded,
            color: const Color(0xFFFFBB00),
            title: t.onbPlayBots,
            subtitle: t.onbPlayBotsSub,
          ),
          _Feature(
            icon: Icons.school_rounded,
            color: const Color(0xFF3CB77C),
            title: t.onbLearn,
            subtitle: t.onbLearnSub,
          ),
          _Feature(
            icon: Icons.extension_rounded,
            color: const Color(0xFF5AA9E6),
            title: t.onbSolve,
            subtitle: t.onbSolveSub,
          ),
          _Feature(
            icon: Icons.insights_rounded,
            color: const Color(0xFFE5795A),
            title: t.onbReview,
            subtitle: t.onbReviewSub,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: k.muted),
              const SizedBox(width: 8),
              Expanded(child: Text(t.onbNoAccount, style: k.caption)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: k.body.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(subtitle, style: k.caption.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelStep extends StatelessWidget {
  const _LevelStep({required this.selected, required this.onSelected});

  final OnboardingLevel? selected;
  final ValueChanged<OnboardingLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.onbHowStrong, style: k.display),
          const SizedBox(height: 8),
          Text(t.onbHowStrongSub, style: k.body.copyWith(color: k.muted)),
          const SizedBox(height: 18),
          _Coach(t.onbCoachLevel),
          const SizedBox(height: 18),
          for (final level in OnboardingLevel.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LevelCard(
                level: level,
                selected: selected == level,
                onTap: () => onSelected(level),
              ),
            ),
        ],
      ),
    );
  }
}

/// A level: its piece, name, a line about it and the rating it starts at.
class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final OnboardingLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    const green = KustButton3D.face;
    return Semantics(
      button: true,
      selected: selected,
      label: '${level.titleIn(t)}, ${level.descriptionIn(t)}',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        haptic: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          decoration: BoxDecoration(
            color: selected
                ? green.withValues(alpha: 0.14)
                : Color.alphaBlend(const Color(0x0DFFFFFF), k.surface),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? green : const Color(0x14FFFFFF),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 64,
                decoration: BoxDecoration(
                  color: selected
                      ? green.withValues(alpha: 0.2)
                      : const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 2),
                child: LearnPiece(_pieceFor(level), height: 60),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.titleIn(t),
                      style: k.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      level.descriptionIn(t),
                      maxLines: 2,
                      style: k.caption.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('on'),
                        color: green,
                        size: 26,
                      )
                    : Text(
                        '${level.startingRating}',
                        key: const ValueKey('off'),
                        style: k.caption.copyWith(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep({required this.level});

  final OnboardingLevel? level;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    final rating = level?.startingRating ?? PlayerRatingStore.startRating;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The level's piece rises onto its tile.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Transform.translate(
                offset: Offset(0, 30 * (1 - v)),
                child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
              ),
              child: SizedBox(
                width: 240,
                height: 230,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 230,
                      height: 230,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0x553CB77C), Color(0x003CB77C)],
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: CustomPaint(
                        painter: _StagePainter(tileWidth: 150, garden: false),
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      child: LearnPiece(_pieceFor(level), height: 150),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(t.onbAllSet, textAlign: TextAlign.center, style: k.display),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: Color.alphaBlend(const Color(0x0DFFFFFF), k.surface),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Column(
                children: [
                  Text(
                    t.onbRatingLabel,
                    style: k.caption.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$rating',
                    style: k.display.copyWith(
                      fontSize: 40,
                      color: GardenColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Coach(t.onbCoachReady),
            const SizedBox(height: 12),
            Text(
              t.onbStartingRating(rating),
              textAlign: TextAlign.center,
              style: k.caption.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
