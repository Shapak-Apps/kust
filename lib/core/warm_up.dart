import 'package:dartchess/dartchess.dart';

import 'package:kust/core/error_log.dart';
import 'package:kust/features/learn/learn_progress.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/features/puzzles/loom.dart';
import 'package:kust/features/puzzles/puzzles_screen.dart' show kLoomLevels;
import 'package:kust/features/train/train_openings.dart';
import 'package:kust/widgets/board_thumbnail.dart';

/// The Puzzles carpet, drawn before the app shows: it is one heavy step,
/// hidden behind the native splash instead of stalling the first visit.
void warmBeforeStart() {
  try {
    warmLoom([for (final l in kLoomLevels) l.gol]);
  } catch (e, st) {
    ErrorLog.record(e, st);
  }
}

/// The boards the tabs show, drawn while the splash plays, one at a time
/// so the animation keeps its frames: every Train card and the next
/// Learn lesson.
Future<void> warmBoards() async {
  try {
    for (final o in kTrainOpenings) {
      final main = o.lines.first;
      await BoardThumbnail.warm(
        main.positions.last,
        width: 132,
        flipped: o.side == Side.black,
        highlight: main.lastSquares,
      );
    }
    await LearnProgress.instance.load();
    final next = LearnProgress.instance.next;
    if (next != null) {
      final cover = lessonCover(next);
      await BoardThumbnail.warm(
        cover.position,
        width: 120,
        highlight: cover.marked,
      );
    }
  } catch (e, st) {
    ErrorLog.record(e, st);
  }
}
