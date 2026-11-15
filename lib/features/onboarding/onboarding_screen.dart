import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/features/onboarding/onboarding_level.dart';
import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_logo.dart';
import 'package:kust/ui/kust_text_field.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

/// First run: a welcome on the brand's gold, then the player's name and
/// username, then their level.
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
  final _name = TextEditingController();
  final _username = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(_changed);
    _username.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  bool get _named =>
      _name.text.trim().isNotEmpty &&
      AppStorage.usernamePattern.hasMatch(_username.text.trim());

  void _goTo(int step) {
    setState(() {
      _forward = step > _step;
      _step = step;
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    if (AppStorage.isReady) {
      await AppStorage.instance.saveProfile(
        name: _name.text,
        username: _username.text,
        bio: '',
      );
    }
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
    final t = context.t;
    return AnimatedSwitcher(
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
          0 => _Welcome(onStart: () => _goTo(1)),
          1 => _StepPage(
            onBack: () => _goTo(0),
            title: t.onbNameTitle,
            subtitle: t.onbNameSub,
            button: t.cont,
            onButton: _named ? () => _goTo(2) : null,
            children: [
              KustSectionLabel(t.yourName),
              KustTextField(
                controller: _name,
                maxLength: AppStorage.maxNameLength,
                autofocus: true,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              KustSectionLabel(t.username),
              KustTextField.username(
                controller: _username,
                helper: t.usernameRule,
                onSubmitted: (_) => _named ? _goTo(2) : null,
              ),
            ],
          ),
          _ => _StepPage(
            onBack: () => _goTo(1),
            title: t.onbHowStrong,
            subtitle: t.onbHowStrongSub,
            button: _level == OnboardingLevel.beginner
                ? t.onbStartLesson
                : t.onbStartPlaying,
            onButton: _level == null || _finishing ? null : _finish,
            onSkip: _finishing
                ? null
                : () {
                    setState(() => _level = null);
                    _finish();
                  },
            children: [
              for (final level in OnboardingLevel.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LevelCard(
                    level: level,
                    selected: _level == level,
                    onTap: () => setState(() => _level = level),
                  ),
                ),
            ],
          ),
        },
      ),
    );
  }
}

/// The first screen: the Square K on gold, as on the splash screen before
/// it, a line about the app and one button.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});

  final VoidCallback onStart;

  static const Color _ink = Color(0xFF17181A);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Material(
        color: KustTokens.gold,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const KustSymbol(
                  height: 128,
                  color: _ink,
                  lastMove: Colors.white,
                ),
                const SizedBox(height: 40),
                Text(
                  t.onbTitle,
                  textAlign: TextAlign.center,
                  style: context.k.title.copyWith(
                    color: _ink.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(flex: 4),
                Semantics(
                  button: true,
                  label: t.onbGetStarted,
                  excludeSemantics: true,
                  child: Pressable(
                    onTap: onStart,
                    haptic: true,
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _ink,
                        borderRadius: BorderRadius.circular(KustSpace.rMedium),
                      ),
                      child: Text(
                        t.onbGetStarted,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A question: back, a title and a line under it, the answers, and the
/// button that moves on, with an optional skip under it.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.onBack,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onButton,
    required this.children,
    this.onSkip,
  });

  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback? onButton;
  final VoidCallback? onSkip;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Scaffold(
      backgroundColor: k.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: KustIconButton(
                icon: Icons.arrow_back_rounded,
                label: context.t.back,
                onTap: onBack,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  Text(title, style: k.display),
                  const SizedBox(height: 8),
                  Text(subtitle, style: k.body.copyWith(color: k.muted)),
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  KustButton3D(expand: true, label: button, onTap: onButton),
                  if (onSkip != null) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onSkip,
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
          ],
        ),
      ),
    );
  }
}

/// The piece that stands for a level, from the pawn to the king.
Role _pieceFor(OnboardingLevel? level) => switch (level) {
  OnboardingLevel.beginner || null => Role.pawn,
  OnboardingLevel.intermediate => Role.knight,
  OnboardingLevel.advanced => Role.rook,
  OnboardingLevel.competitive => Role.king,
};

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
            color: selected ? green.withValues(alpha: 0.14) : k.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? green : k.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 64,
                decoration: BoxDecoration(
                  color: selected ? green.withValues(alpha: 0.2) : k.surfaceAlt,
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
