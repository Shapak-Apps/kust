import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/move_feedback.dart';
import 'package:kust/features/game/quality_badge.dart';
import 'package:kust/features/play/bot_quote.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/count_up.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/kust_dialog.dart';
import 'package:kust/widgets/static_board.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/board_banner.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/widgets/piece_image.dart';

/// Opens the result over the whole screen. Closing it (the X or Back)
/// leaves the finished game on the board to look through.
Future<void> showGameResult(
  BuildContext context, {
  required GameResultScreen Function(BuildContext context) builder,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// The end of a game, full screen: the player's board fading into the page
/// behind the result and the rating change, the position the game ended in
/// as the picture, what the bot says, how the player's moves were rated,
/// and Rematch and Review.
class GameResultScreen extends ConsumerWidget {
  const GameResultScreen({
    super.key,
    required this.title,
    required this.message,
    required this.onRematch,
    required this.onClose,
    this.onShare,
    this.botQuote,
    this.onReview,
  });

  final String title;
  final String message;
  final VoidCallback onRematch;
  final VoidCallback onClose;
  final VoidCallback? onShare;

  /// Opens the review of the game; given with the saved game's id.
  final void Function(String gameId)? onReview;

  /// What the opponent says about the game, with its portrait.
  final ({String name, String image, String text})? botQuote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.k;
    // Rebuilt only when what it shows changes, not on every update of the
    // game behind it (the engine, the clocks, analysis in the background).
    ref.watch(
      chessControllerProvider.select(
        (g) => (
          g.status,
          g.ratingChange,
          g.accuracy,
          g.accuracyPending,
          g.moveCounts,
          g.savedGameId,
          g.moves.length,
        ),
      ),
    );
    final game = ref.read(chessControllerProvider);
    final canReview =
        onReview != null && game.savedGameId != null && game.moves.length >= 5;
    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: k.bg,
        child: Stack(
          children: [
            BoardBanner(
              height: size.height * 0.42,
              pieces: false,
              dim: 0.45,
              fadeFrom: 0.3,
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        if (onShare != null)
                          IconButton(
                            onPressed: onShare,
                            tooltip: context.t.exportGame,
                            color: Colors.white,
                            icon: const Icon(Icons.ios_share_rounded),
                          ),
                        const Spacer(),
                        IconButton(
                          onPressed: onClose,
                          tooltip: context.t.close,
                          color: Colors.white,
                          icon: const Icon(Icons.close_rounded, size: 28),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: k.display.copyWith(
                            color: Colors.white,
                            fontSize: 34,
                          ),
                        ),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: k.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _RatingAndAccuracy(game: game),
                      ],
                    ),
                  ),
                  // The position the game ended in is the picture: it takes
                  // whatever room the screen has.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: StaticBoard(
                              position: game.position,
                              flipped:
                                  game.mode == GameMode.bot &&
                                  game.playerSide == Side.black,
                              highlight: game.moveSquares,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (botQuote != null) ...[
                          BotSays(
                            name: botQuote!.name,
                            image: botQuote!.image,
                            text: botQuote!.text,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _MoveCounts(game: game),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      // Tops level: the green button's lip hangs below.
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: KustButton(
                            label: context.t.rematch,
                            style: canReview
                                ? KustButtonStyle.secondary
                                : KustButtonStyle.primary,
                            height: 52,
                            onTap: onRematch,
                          ),
                        ),
                        if (canReview) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: KustButton(
                              label: context.t.reviewButton,
                              icon: Icons.insights_rounded,
                              height: 52,
                              onTap: () => onReview!(game.savedGameId!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "1209 +9" and the player's accuracy, or that the moves are being
/// analyzed.
class _RatingAndAccuracy extends StatelessWidget {
  const _RatingAndAccuracy({required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final change = game.ratingChange;
    final accuracy = game.accuracy;
    return Column(
      children: [
        if (change != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // The rating counts from what it was to what it is.
              CountUp(
                from: PlayerRatingStore.instance.rating - change,
                to: PlayerRatingStore.instance.rating,
                style: k.display.copyWith(color: Colors.white, fontSize: 28),
              ),
              const SizedBox(width: 6),
              CountUp(
                from: 0,
                to: change.abs(),
                prefix: change > 0
                    ? '+'
                    : change < 0
                    ? '\u2212'
                    : '',
                style: k.title.copyWith(
                  color: change > 0
                      ? k.success
                      : change < 0
                      ? k.danger
                      : k.muted,
                ),
              ),
            ],
          ),
        if (accuracy != null)
          Text(
            context.t.accuracyValue(accuracy.toStringAsFixed(1)),
            style: k.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

/// How many of the player's moves got each rating, in three tiles side by
/// side (see [pickMoveCounts]). While the game is being analyzed it says
/// so.
class _MoveCounts extends StatelessWidget {
  const _MoveCounts({required this.game});

  final GameState game;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    if (game.accuracyPending) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: k.accent),
          ),
          const SizedBox(width: 10),
          Text(context.t.analyzingYourMoves, style: k.caption),
        ],
      );
    }
    final counts = game.moveCounts ?? const {};
    final shown = pickMoveCounts(counts);
    if (shown.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (final (i, q) in shown.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: squircle(KustSpace.rMedium, color: k.surface),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      QualityBadge(quality: q, size: 34),
                      const SizedBox(width: 8),
                      Text(
                        '${counts[q]}',
                        style: k.display.copyWith(
                          color: q.color,
                          fontSize: 26,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    q.labelIn(context.t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: k.caption.copyWith(
                      color: q.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The (at most) three ratings the result shows, as chess.com does: the
/// best ones the player earned, and the worst error when there was one, so
/// a blunder is never hidden behind good moves. Book moves count as good
/// ones, after the rest.
List<MoveQuality> pickMoveCounts(Map<MoveQuality, int> counts) {
  bool had(MoveQuality q) => (counts[q] ?? 0) > 0;
  const good = [
    MoveQuality.brilliant,
    MoveQuality.great,
    MoveQuality.best,
    MoveQuality.excellent,
    MoveQuality.good,
    // Known theory: below the good moves, but worth showing.
    MoveQuality.book,
  ];
  const bad = [
    MoveQuality.blunder,
    MoveQuality.miss,
    MoveQuality.mistake,
    MoveQuality.inaccuracy,
  ];
  final goods = good.where(had).toList();
  final bads = bad.where(had).toList();
  final picked = [...goods.take(bads.isEmpty ? 3 : 2), ...bads.take(1)];
  // Too few of one kind: fill up from the other.
  for (final q in [...goods, ...bads]) {
    if (picked.length >= 3) break;
    if (!picked.contains(q)) picked.add(q);
  }
  // Good ones first, then errors from the mildest to the worst.
  return picked..sort((a, b) => a.index.compareTo(b.index));
}

/// The game begins: which side the player has, for a moment.
void showGameStartModal(
  BuildContext context, {
  required bool white,
  String? message,
}) {
  final pieceAsset = white
      ? AppSettings.instance.pieceSet.value.asset('w', 'K')
      : AppSettings.instance.pieceSet.value.asset('b', 'K');

  showKustDialog<void>(
    context,
    barrierDismissible: false,
    builder: (dialogContext) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (dialogContext.mounted && Navigator.canPop(dialogContext)) {
          Navigator.of(dialogContext).pop();
        }
      });

      return Dialog(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PieceImage(pieceAsset, width: 64, height: 64),
              const SizedBox(height: 16),
              Text(
                dialogContext.t.gameStartTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message ??
                    (white
                        ? dialogContext.t.youPlayAsWhite
                        : dialogContext.t.youPlayAsBlack),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    },
  );
}
