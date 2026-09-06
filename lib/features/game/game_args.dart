import 'package:dartchess/dartchess.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';

class GameArgs {
  final Bot bot;
  final Side playerSide;

  const GameArgs({required this.bot, required this.playerSide});
} 