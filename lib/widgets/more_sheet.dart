import 'package:flutter/material.dart';

import 'package:kust/widgets/piece_image.dart';
import 'package:kust/core/board_theme.dart';
import 'package:kust/core/piece_set.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showKustSheet<void>(context, builder: (_) => const _SettingsSheet());
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KustSheetHeader(title: context.t.settings),
        // Hidden while the app is dark only (see AppSettings.forceDark).
        if (!AppSettings.forceDark) ...[
          KustSectionLabel(context.t.appearance),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: s.themeMode,
            builder: (_, mode, _) => KustSegmented<ThemeMode>(
              value: mode,
              options: {
                ThemeMode.system: context.t.themeAuto,
                ThemeMode.light: context.t.themeLight,
                ThemeMode.dark: context.t.themeDark,
              },
              onChanged: s.setThemeMode,
            ),
          ),
          const SizedBox(height: 24),
        ],
        KustSectionLabel(context.t.boardSection),
        ValueListenableBuilder<BoardTheme>(
          valueListenable: s.boardTheme,
          builder: (_, selected, _) => Row(
            children: [
              for (final theme in BoardTheme.values) ...[
                if (theme != BoardTheme.values.first) const SizedBox(width: 10),
                Expanded(
                  child: BoardThemeSwatch(
                    theme: theme,
                    selected: theme == selected,
                    onTap: () => s.setBoardTheme(theme),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        KustSectionLabel(context.t.piecesSection),
        ValueListenableBuilder<BoardTheme>(
          valueListenable: s.boardTheme,
          builder: (_, board, _) => ValueListenableBuilder<PieceSet>(
            valueListenable: s.pieceSet,
            builder: (_, selected, _) => Row(
              children: [
                for (final set in PieceSet.values) ...[
                  if (set != PieceSet.values.first) const SizedBox(width: 10),
                  Expanded(
                    child: PieceSetSwatch(
                      set: set,
                      board: board,
                      selected: set == selected,
                      onTap: () => s.setPieceSet(set),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        KustSectionLabel(context.t.movesSection),
        ValueListenableBuilder<bool>(
          valueListenable: s.castleOnRook,
          builder: (_, v, _) => KustToggleRow(
            icon: Icons.swap_horiz_rounded,
            title: context.t.castleOnRook,
            subtitle: context.t.castleOnRookSub,
            value: v,
            onChanged: s.setCastleOnRook,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: s.premoves,
          builder: (_, v, _) => KustToggleRow(
            icon: Icons.fast_forward_rounded,
            title: context.t.premoves,
            subtitle: context.t.premovesSub,
            value: v,
            onChanged: s.setPremoves,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: s.botChat,
          builder: (_, v, _) => KustToggleRow(
            icon: Icons.chat_bubble_outline_rounded,
            title: context.t.botChat,
            subtitle: context.t.botChatSub,
            value: v,
            onChanged: s.setBotChat,
          ),
        ),
        const SizedBox(height: 24),
        KustSectionLabel(context.t.feedbackSection),
        ValueListenableBuilder<bool>(
          valueListenable: s.sound,
          builder: (_, v, _) => KustToggleRow(
            icon: Icons.volume_up_rounded,
            title: context.t.soundEffects,
            value: v,
            onChanged: s.setSound,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: s.haptics,
          builder: (_, v, _) => KustToggleRow(
            icon: Icons.vibration_rounded,
            title: context.t.haptics,
            value: v,
            onChanged: s.setHaptics,
          ),
        ),
        const _LanguagePicker(),
      ],
    );
  }
}

/// A tappable 2x2 sample of a board theme with its name underneath.
class BoardThemeSwatch extends StatelessWidget {
  const BoardThemeSwatch({
    super.key,
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final BoardTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      label: context.t.boardThemeSemantics(theme.labelIn(context.t)),
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        haptic: true,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KustSpace.rSmall),
                  border: Border.all(
                    color: selected ? k.accent : k.line,
                    width: selected ? 2.5 : 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(KustSpace.rSmall - 4),
                  child: Column(
                    children: [
                      for (var row = 0; row < 2; row++)
                        Expanded(
                          child: Row(
                            children: [
                              for (var col = 0; col < 2; col++)
                                Expanded(
                                  child: ColoredBox(
                                    color: (row + col).isEven
                                        ? theme.light
                                        : theme.dark,
                                    child: theme.grain
                                        ? CustomPaint(
                                            size: Size.infinite,
                                            painter: WoodGrainPainter(
                                              seed: row * 2 + col + 3,
                                              light: (row + col).isEven,
                                            ),
                                          )
                                        : const SizedBox.expand(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              theme.labelIn(context.t),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: k.caption.copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? k.ink : k.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable sample of a piece set, a white knight and a black pawn on the
/// board in use, with the set's name underneath.
class PieceSetSwatch extends StatelessWidget {
  const PieceSetSwatch({
    super.key,
    required this.set,
    required this.board,
    required this.selected,
    required this.onTap,
  });

  final PieceSet set;
  final BoardTheme board;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Semantics(
      button: true,
      selected: selected,
      label: context.t.pieceSetSemantics(set.labelIn(context.t)),
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        haptic: true,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KustSpace.rSmall),
                  border: Border.all(
                    color: selected ? k.accent : k.line,
                    width: selected ? 2.5 : 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(KustSpace.rSmall - 4),
                  child: Row(
                    children: [
                      for (final (color, role, light) in const [
                        ('w', 'N', true),
                        ('b', 'P', false),
                      ])
                        Expanded(
                          child: ColoredBox(
                            color: light ? board.light : board.dark,
                            child: Center(
                              child: PieceImage(set.asset(color, role)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              set.labelIn(context.t),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: k.caption.copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? k.ink : k.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The languages to pick from, each in its own language.
const List<(String?, String)> _languages = [
  ('en', 'English'),
  ('ru', 'Русский'),
  ('tk', 'Türkmençe'),
];

/// A plain row showing the language in use; tapping it opens the list to
/// pick from.
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  static String _name(BuildContext context, String? code) => code == null
      ? context.t.languageAuto
      : _languages.firstWhere((l) => l.$1 == code).$2;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return ValueListenableBuilder<String?>(
      valueListenable: AppSettings.instance.language,
      builder: (context, code, _) => Pressable(
        onTap: () => showKustSheet<void>(
          context,
          builder: (sheetContext) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KustSheetHeader(title: sheetContext.t.language),
              for (final option in [
                (null, sheetContext.t.languageAuto),
                ..._languages,
              ])
                Pressable(
                  onTap: () {
                    AppSettings.instance.setLanguage(option.$1);
                    Navigator.of(sheetContext).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.$2,
                            style: sheetContext.k.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (AppSettings.instance.language.value == option.$1)
                          Icon(
                            Icons.check_rounded,
                            size: 22,
                            color: sheetContext.k.accent,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Laid out like the switch rows above: the same padding, a row as
        // tall as theirs (the switch is 28 high), the same icon and text
        // sizes.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 28),
            child: Row(
              children: [
                // The globe glyph fills its box more than the others, so it
                // is drawn a little smaller to look the same size.
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Center(
                    child: Icon(
                      Icons.translate_rounded,
                      size: 19,
                      color: k.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.t.language,
                    style: k.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _name(context, code),
                  style: k.body.copyWith(color: k.muted),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 22, color: k.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
