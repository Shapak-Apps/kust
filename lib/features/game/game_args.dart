import 'package:dartchess/dartchess.dart';
import 'package:kust/core/storage/live_game_store.dart';
import 'package:kust/features/play/pick_opponent_modal.dart';
import 'package:kust/features/game/time_control.dart';

class GameArgs {
  final Bot? bot;
  final Side playerSide;
  final bool isLocal;
  final TimeControl? timeControl;
  final bool practiceMode;

  /// A saved game to pick up instead of starting a new one.
  final LiveGame? resume;

  /// An opening line from Train to drill from the first move, in
  /// dartchess UCI, and its name for the banner.
  final List<String>? line;
  final String? lineName;

  /// Called when the player has played the whole [line].
  final void Function()? onLineDone;

  const GameArgs({
    this.bot,
    required this.playerSide,
    this.isLocal = false,
    this.timeControl,
    this.practiceMode = false,
    this.resume,
    this.line,
    this.lineName,
    this.onLineDone,
  });
}
