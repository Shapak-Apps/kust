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

  const GameArgs({
    this.bot,
    required this.playerSide,
    this.isLocal = false,
    this.timeControl,
    this.practiceMode = false,
    this.resume,
  });
}
