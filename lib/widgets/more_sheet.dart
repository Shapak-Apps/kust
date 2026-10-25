import 'package:flutter/material.dart';

import 'package:kust/widgets/piece_image.dart';
import 'package:kust/core/board_theme.dart';
import 'package:kust/core/piece_set.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/ui/kust_controls.dart';
import 'package:kust/ui/kust_sheet.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';

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
        const KustSheetHeader(title: 'Settings'),
        const KustSectionLabel('Appearance'),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: s.themeMode,
          builder: (_, mode, _) => KustSegmented<ThemeMode>(
            value: mode,
            options: const {
              ThemeMode.system: 'Auto',
              ThemeMode.light: 'Light',
              ThemeMode.dark: 'Dark',
            },
            onChanged: s.setThemeMode,
          ),
        ),
        const SizedBox(height: 24),
        const KustSectionLabel('Board'),
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
        const KustSectionLabel('Pieces'),
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
        const KustSectionLabel('Moves'),
        ValueListenableBuilder<bool>(
          valueListenable: s.castleOnRook,
          builder: (_, v, _) => KustToggleRow(
            icon: Icons.swap_horiz_rounded,
            title: 'Castle on the rook',
            subtitle: 'Tap the king, then its rook, to castle',
            value: v,
            onChanged: s.setCastleOnRook,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: s.premoves,
          builder: (_, v, _) => KustToggleRow(
            icon: Icons.fast_forward_rounded,
            title: 'Premoves',
            subtitle: 'Queue your next move while the bot thinks',
            value: v,
            onChanged: s.setPremoves,
          ),
        ),
        const SizedBox(height: 24),
        const KustSectionLabel('Feedback'),
        ValueListenableBuilder<bool>(
          valueListenable: s.sound,
          builder: (_, v, _) => KustToggleRow(
            icon: Icons.volume_up_rounded,
            title: 'Sound effects',
            value: v,
            onChanged: s.setSound,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: s.haptics,
          builder: (_, v, _) => KustToggleRow(
            icon: Icons.vibration_rounded,
            title: 'Haptics',
            value: v,
            onChanged: s.setHaptics,
          ),
        ),
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
      label: '${theme.label} board',
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
              theme.label,
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
      label: '${set.label} pieces',
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
              set.label,
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
