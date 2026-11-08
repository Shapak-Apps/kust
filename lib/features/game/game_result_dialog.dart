import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kust/core/storage/player_rating_store.dart';
import 'package:kust/features/game/chess/chess_controller.dart';
import 'package:kust/features/play/bot_quote.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/ui/pressable.dart';
import 'package:kust/ui/tokens.dart';
import 'package:kust/l10n/app_locale.dart';

/// Everything inside the centered "game over" modal: title, reason, rating,
/// accuracy and two buttons side by side. All of it is centered.
class GameResultContent extends StatelessWidget {
  const GameResultContent({
    super.key,
    required this.title,
    required this.message,
    required this.onRematch,
    required this.onLobby,
    this.botQuote,
    this.onReview,
  });

  final String title;
  final String message;
  final VoidCallback onRematch;
  final VoidCallback onLobby;

  /// Opens the review of the game; given with the saved game's id.
  final void Function(String gameId)? onReview;

  /// What the opponent says about the game, with its portrait.
  final ({String name, String image, String text})? botQuote;

  @override
  Widget build(BuildContext context) {
    final k = context.k;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, textAlign: TextAlign.center, style: k.display),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: k.body.copyWith(color: k.muted),
        ),
        if (botQuote != null) ...[
          const SizedBox(height: 16),
          BotSays(
            name: botQuote!.name,
            image: botQuote!.image,
            text: botQuote!.text,
          ),
        ],
        const SizedBox(height: 20),
        const ResultRatingLine(),
        const ResultAccuracyLine(),
        const SizedBox(height: 4),
        if (onReview != null) _ReviewButton(onReview: onReview!),
        Row(
          children: [
            Expanded(
              child: KustButton(
                label: context.t.lobby,
                style: KustButtonStyle.outline,
                height: 48,
                onTap: onLobby,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KustButton(
                label: context.t.rematch,
                height: 48,
                onTap: onRematch,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// "Rating 1209 (+9)" once the game has been rated.
class ResultRatingLine extends ConsumerWidget {
  const ResultRatingLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final change = ref.watch(
      chessControllerProvider.select((g) => g.ratingChange),
    );
    if (change == null) return const SizedBox.shrink();
    final k = context.k;
    final now = PlayerRatingStore.instance.rating;
    final sign = change > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        context.t.ratingChange(now, '$sign$change'),
        textAlign: TextAlign.center,
        style: k.body.copyWith(
          fontWeight: FontWeight.w800,
          color: change > 0
              ? k.success
              : change < 0
              ? k.danger
              : k.muted,
        ),
      ),
    );
  }
}

/// "Accuracy 71.6%". While the finished game is being analyzed it says so,
/// and it is hidden when no accuracy can be worked out (pass-and-play, no
/// engine, very short games).
class ResultAccuracyLine extends ConsumerWidget {
  const ResultAccuracyLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      chessControllerProvider.select(
        (g) => (accuracy: g.accuracy, pending: g.accuracyPending),
      ),
    );
    final k = context.k;

    final Widget child;
    if (data.accuracy != null) {
      child = Row(
        key: const ValueKey('accuracy'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.track_changes_rounded, size: 18, color: k.muted),
          const SizedBox(width: 8),
          Text(
            context.t.accuracyValue(data.accuracy!.toStringAsFixed(1)),
            style: k.body.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      );
    } else if (data.pending) {
      child = Row(
        key: const ValueKey('pending'),
        mainAxisSize: MainAxisSize.min,
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
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: child,
        ),
      ),
    );
  }
}

/// "Review", once the game is saved and long enough to be worth it.
class _ReviewButton extends ConsumerWidget {
  const _ReviewButton({required this.onReview});

  final void Function(String gameId) onReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      chessControllerProvider.select(
        (g) => (id: g.savedGameId, plies: g.moves.length),
      ),
    );
    if (data.id == null || data.plies < 5) return const SizedBox.shrink();
    final k = context.k;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: () => onReview(data.id!),
        haptic: true,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: k.accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(KustSpace.rMedium),
            border: Border.all(color: k.accent, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights_rounded, color: k.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                context.t.reviewButton,
                style: k.body.copyWith(
                  color: k.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
