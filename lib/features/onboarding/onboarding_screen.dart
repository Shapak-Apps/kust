import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/onboarding/onboarding_level.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/tokens.dart';

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
    context.go('/play');
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
                            label: 'Back',
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
                  KustButton(
                    label: switch (_step) {
                      0 => 'Get started',
                      1 => 'Continue',
                      _ => 'Start playing',
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
                          'Skip for now',
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
              height: 4,
              decoration: BoxDecoration(
                color: i <= step ? k.accent : k.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset('assets/images/header.svg', height: 44),
          const SizedBox(height: 32),
          Text('Chess that helps you improve', style: k.display),
          const SizedBox(height: 12),
          Text(
            'Play bots at your level, train with puzzles and replay your '
            'games to learn from them.',
            style: k.body.copyWith(color: k.muted),
          ),
          const SizedBox(height: 28),
          const _Feature(
            icon: Icons.smart_toy_outlined,
            title: 'Play bots',
            subtitle: 'From 400 to 2000 Elo, or pass the phone to a friend',
          ),
          const _Feature(
            icon: Icons.extension_outlined,
            title: 'Solve puzzles',
            subtitle: 'Short tactics with hints and a rating',
          ),
          const _Feature(
            icon: Icons.history_rounded,
            title: 'Review your games',
            subtitle: 'Every finished game is saved for replay',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: k.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No account needed. Your games and progress stay on this '
                  'device.',
                  style: k.caption,
                ),
              ),
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
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          KustIconTile(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: k.body.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(subtitle, style: k.caption),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How strong are you?', style: k.display),
          const SizedBox(height: 12),
          Text(
            'This sets your starting rating. It adjusts as you play, so '
            'don’t overthink it.',
            style: k.body.copyWith(color: k.muted),
          ),
          const SizedBox(height: 24),
          for (final level in OnboardingLevel.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: KustOption(
                title: level.title,
                subtitle: level.description,
                leading: KustIconTile(level.icon),
                selected: selected == level,
                onTap: () => onSelected(level),
              ),
            ),
        ],
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
    final rating = level?.startingRating ?? PlayerRatingStore.startRating;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: k.accent,
                borderRadius: BorderRadius.circular(KustSpace.rLarge),
              ),
              child: Icon(Icons.check_rounded, size: 44, color: k.accentInk),
            ),
            const SizedBox(height: 28),
            Text('You’re all set', style: k.display),
            const SizedBox(height: 12),
            Text(
              'Your starting rating is $rating.\nYour first game is one tap away.',
              textAlign: TextAlign.center,
              style: k.body.copyWith(color: k.muted),
            ),
          ],
        ),
      ),
    );
  }
}
