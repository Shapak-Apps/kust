import 'package:dartchess/dartchess.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';
import 'package:Kust/features/game/time_control.dart';

class GameArgs {
  final Bot? bot;
  final Side playerSide;
  final bool isLocal;
  final TimeControl? timeControl;

  const GameArgs({
    this.bot,
    required this.playerSide,
    this.isLocal = false,
    this.timeControl,
  });
}
