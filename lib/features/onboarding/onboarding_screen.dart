import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/server_config.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/auth/auth_support.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/features/onboarding/onboarding_level.dart';
import 'package:kust/ui/kust_button_3d.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_splash.dart';
import 'package:kust/ui/kust_text_field.dart';
import 'package:kust/ui/kust_top_bar.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

/// First run: a welcome on the brand's gold (sign up, sign in or go on as a
/// guest), then the player's name and username, then their level.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.initialStep = 0});

  /// 1 or 2 when coming back from signing up or in on the welcome screen.
  final int initialStep;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late int _step = widget.initialStep;
  bool _forward = true;
  bool _finishing = false;
  OnboardingLevel? _level;
  final _name = TextEditingController();
  final _username = TextEditingController();

  /// The username the app suggested from the name; while the field still
  /// holds it, typing the name keeps updating it.
  String _suggested = '';

  /// Signed in on the welcome screen: the username is the account's.
  late final bool _signedIn =
      ServerConfig.enabled && AuthService.instance.state.value.isSignedIn;

  @override
  void initState() {
    super.initState();
    final account = _signedIn ? AuthService.instance.state.value.account : null;
    if (account != null) {
      _name.text = account.displayName;
      _username.text = account.username;
    }
    _name.addListener(_nameChanged);
    _username.addListener(_changed);
  }

  void _changed() => setState(() {});

  void _nameChanged() {
    if (!_signedIn && _username.text == _suggested) {
      _suggested = suggestUsername(_name.text);
      _username.text = _suggested;
    }
    setState(() {});
  }

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
      if (_signedIn) await pushLocalProfile(AuthService.instance);
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
    // The system back button steps back too; on the first step it leaves.
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_step - 1);
      },
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
            0 => _Welcome(onGuest: () => _goTo(1)),
            1 => _StepPage(
              step: 1,
              onBack: () => _goTo(0),
              title: t.onbNameTitle,
              subtitle: t.onbNameSub,
              button: t.cont,
              onButton: _named ? () => _goTo(2) : null,
              children: [
                _PlayerPreview(
                  name: _name.text.trim(),
                  username: _username.text.trim(),
                ),
                const SizedBox(height: 28),
                KustSectionLabel(t.yourName),
                KustTextField(
                  controller: _name,
                  maxLength: AppStorage.maxNameLength,
                  autofocus: true,
                  capitalization: TextCapitalization.words,
                  action: _signedIn
                      ? TextInputAction.done
                      : TextInputAction.next,
                  onSubmitted: _signedIn
                      ? (_) => _named ? _goTo(2) : null
                      : null,
                ),
                if (!_signedIn) ...[
                  const SizedBox(height: 16),
                  KustSectionLabel(t.username),
                  KustTextField.username(
                    controller: _username,
                    helper: t.usernameRule,
                    onSubmitted: (_) => _named ? _goTo(2) : null,
                  ),
                ],
              ],
            ),
            _ => _StepPage(
              step: 2,
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
              above: _LevelNote(level: _level),
              children: [
                _LevelGrid(
                  selected: _level,
                  onSelect: (level) => setState(() => _level = level),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

/// A username made from a name: lowercase Latin letters, digits and _,
/// Turkmen letters without their marks; empty when nothing is left.
String suggestUsername(String name) {
  const plain = {
    'ä': 'a', 'ç': 'c', 'ň': 'n', 'ö': 'o', 'ş': 's', 'ü': 'u', //
    'ý': 'y', 'ž': 'z', ' ': '_', '-': '_', '.': '_',
  };
  final out = StringBuffer();
  for (final c in name.trim().toLowerCase().split('')) {
    final p = plain[c] ?? c;
    if (RegExp(r'[a-z0-9_]').hasMatch(p)) out.write(p);
  }
  final handle = out.toString().replaceAll(RegExp(r'_+'), '_');
  return handle.length > 20 ? handle.substring(0, 20) : handle;
}

/// The first screen: the wordmark on gold, just where the opening
/// animation leaves it, a line about the app under it and the way in:
/// an account, or straight in as a guest.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.onGuest});

  final VoidCallback onGuest;

  static const Color _ink = Color(0xFF17181A);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final size = MediaQuery.sizeOf(context);
    final accounts = ServerConfig.enabled;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Material(
        color: KustTokens.gold,
        child: Stack(
          children: [
            // Laid out on the whole screen, as the animation is.
            const Positioned.fill(child: SplashArt()),
            Positioned(
              left: 24,
              right: 24,
              top:
                  size.height / 2 + SplashArt.reachBelowMiddle(size.width) + 28,
              child: Text(
                t.onbTitle,
                textAlign: TextAlign.center,
                style: context.k.title.copyWith(
                  color: _ink.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 16),
                child: _WelcomeButton(
                  label: t.onbGetStarted,
                  filled: true,
                  // With a server, the way in is an account (or skip).
                  onTap: accounts
                      ? () => context.push(
                          withNext('/register', '/onboarding?step=name'),
                        )
                      : onGuest,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A button on the gold: ink with white text, or an ink outline.
class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const ink = _Welcome._ink;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        haptic: true,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? ink : Colors.transparent,
            borderRadius: BorderRadius.circular(KustSpace.rMedium),
            border: filled ? null : Border.all(color: ink, width: 2),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: filled ? Colors.white : ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A question: back and how far along, a title and a line under it, the
/// answers, and the button that moves on, with an optional skip under it.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.step,
    required this.onBack,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onButton,
    required this.children,
    this.onSkip,
    this.above,
  });

  static const int _steps = 2;

  final int step;
  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback? onButton;
  final VoidCallback? onSkip;

  /// Shown right above the button, so it reads with it.
  final Widget? above;
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
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  KustIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: context.t.back,
                    onTap: onBack,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: context.t.onbStepOf(step, _steps),
                      child: Row(
                        children: [
                          for (var i = 1; i <= _steps; i++) ...[
                            if (i > 1) const SizedBox(width: 6),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i <= step
                                      ? KustButton3D.face
                                      : k.surfaceAlt,
                                  borderRadius: BorderRadius.circular(3),
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
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                  ?above,
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

/// The player as others will see them, filled in while they type: the
/// avatar, the name and the @username, with a queen behind.
class _PlayerPreview extends StatelessWidget {
  const _PlayerPreview({required this.name, required this.username});

  final String name;
  final String username;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: squircle(
        20,
        color: k.surface,
        side: BorderSide(color: k.line),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -18,
            child: Opacity(
              opacity: 0.14,
              child: const LearnPiece(Role.queen, height: 112),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.onbPreview.toUpperCase(),
                  style: k.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    PlayerAvatar(size: 56, name: name.isEmpty ? null : name),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? t.yourName : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: k.title.copyWith(
                              color: name.isEmpty ? k.muted : k.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${username.isEmpty ? t.username.toLowerCase() : username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: k.body.copyWith(color: k.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

/// The four levels in two rows, the piece growing from the pawn to the
/// king.
class _LevelGrid extends StatelessWidget {
  const _LevelGrid({required this.selected, required this.onSelect});

  final OnboardingLevel? selected;
  final ValueChanged<OnboardingLevel> onSelect;

  @override
  Widget build(BuildContext context) {
    const levels = OnboardingLevel.values;
    Widget tile(int i) => Expanded(
      child: _LevelTile(
        level: levels[i],
        pieceHeight: 56 + i * 8,
        selected: selected == levels[i],
        onTap: () => onSelect(levels[i]),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [tile(0), const SizedBox(width: 12), tile(1)]),
        const SizedBox(height: 12),
        Row(children: [tile(2), const SizedBox(width: 12), tile(3)]),
      ],
    );
  }
}

/// What the chosen level means, just above the button that confirms it.
class _LevelNote extends StatelessWidget {
  const _LevelNote({required this.level});

  final OnboardingLevel? level;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final level = this.level;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: level == null
          ? const SizedBox(width: double.infinity)
          : Container(
              key: ValueKey(level),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              decoration: squircle(14, color: k.surfaceAlt),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 26,
                    color: KustTokens.gold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      level.descriptionIn(context.t),
                      style: k.body.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// A level: its piece on a light square, its name and the rating it
/// starts at; ringed in gold with a tick when chosen.
class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.pieceHeight,
    required this.selected,
    required this.onTap,
  });

  final OnboardingLevel level;
  final double pieceHeight;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final t = context.t;
    const gold = KustTokens.gold;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${level.titleIn(t)}, ${level.startingRating}, ${level.descriptionIn(t)}',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        haptic: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 172,
          decoration: squircle(
            20,
            color: selected ? gold.withValues(alpha: 0.12) : k.surface,
            side: BorderSide(
              color: selected ? gold : k.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: LearnPiece(_pieceFor(level), height: pieceHeight),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    level.titleIn(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: k.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${level.startingRating}',
                    style: k.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: selected ? gold : k.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: gold,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
