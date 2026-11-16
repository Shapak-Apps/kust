import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/game/chess/move_feedback.dart';
import 'package:kust/features/play/bot_quote.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/player_avatar.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/widgets/board_banner.dart';

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
/// behind the result, the rating change, both players, what the bot says,
/// how the player's moves were rated, and Rematch and Review.
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
    final game = ref.watch(chessControllerProvider);
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: k.display.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: k.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RatingAndAccuracy(game: game),
                          if (game.mode == GameMode.bot &&
                              game.bot != null) ...[
                            const SizedBox(height: 24),
                            _Players(game: game),
                          ],
                          if (botQuote != null) ...[
                            const SizedBox(height: 24),
                            BotSays(
                              name: botQuote!.name,
                              image: botQuote!.image,
                              text: botQuote!.text,
                            ),
                          ],
                          const SizedBox(height: 16),
                          _MoveCounts(game: game),
                        ],
                      ),
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
                                ? KustButtonStyle.outline
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
    final items = <Widget>[
      if (change != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${PlayerRatingStore.instance.rating}',
              style: k.display.copyWith(color: Colors.white, fontSize: 30),
            ),
            const SizedBox(width: 6),
            Text(
              '${change > 0 ? '+' : ''}$change',
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.track_changes_rounded, size: 20, color: k.muted),
            const SizedBox(width: 6),
            Text(
              context.t.accuracyValue(accuracy.toStringAsFixed(1)),
              style: k.body.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 20,
      runSpacing: 8,
      children: items,
    );
  }
}

/// The player and the bot side by side, the winner in gold.
class _Players extends StatelessWidget {
  const _Players({required this.game});

  final GameState game;

  Side? get _winner => switch (game.status) {
    GameStatus.checkmate => game.position.turn.opposite,
    GameStatus.resigned => game.playerSide.opposite,
    GameStatus.timeout => game.flagFell?.opposite,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    final bot = game.bot!;
    final winner = _winner;
    final store = AppStorage.instance;
    final photo = AppStorage.isReady ? store.photoPath : null;

    Widget player(Widget picture, String name, bool won) => Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: won ? k.accent : Colors.transparent,
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: picture,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: k.body.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );

    final you = AppStorage.isReady ? store.displayName(context.t) : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        player(
          PlayerAvatar(
            size: 68,
            name: you,
            photo: photo == null ? null : FileImage(io.File(photo)),
          ),
          you,
          winner == game.playerSide,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Text(
            'vs',
            style: k.body.copyWith(color: k.muted, fontWeight: FontWeight.w800),
          ),
        ),
        player(
          Image.asset(
            bot.imagePath,
            width: 68,
            height: 68,
            cacheWidth: 204,
            fit: BoxFit.cover,
          ),
          bot.name,
          winner == game.playerSide.opposite,
        ),
      ],
    );
  }
}

/// How many of the player's moves got each rating, best first and the
/// errors after, only the ratings that came up. While the game is being
/// analyzed it says so.
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
    final shown = [
      for (final q in MoveQuality.values)
        if (q != MoveQuality.book && (counts[q] ?? 0) > 0) q,
    ];
    if (shown.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - 16) / 3;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in shown)
              Container(
                width: width,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: k.surface,
                  borderRadius: BorderRadius.circular(KustSpace.rMedium),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(q.asset, width: 24, height: 24),
                        const SizedBox(width: 6),
                        Text(
                          '${counts[q]}',
                          style: k.title.copyWith(color: q.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
          ],
        );
      },
    );
  }
}
