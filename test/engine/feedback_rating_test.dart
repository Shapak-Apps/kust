import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/accuracy.dart';
import 'package:kust/features/game/chess/move_feedback.dart';

Position _fen(String fen) => Chess.fromSetup(Setup.parseFen(fen));

bool _brilliant(String fen, String uci, {int playedCp = 50}) {
  final before = _fen(fen);
  final move = NormalMove.fromUci(uci);
  return isBrilliantSacrifice(
    before: before,
    after: before.play(move),
    move: move,
    playedCp: playedCp,
    isBest: true,
  );
}

void main() {
  group('labels by how much of the game a move gives away', () {
    test('chess.com limits, the same against every opponent', () {
      expect(classifyByLoss(0), MoveQuality.best);
      expect(classifyByLoss(0.002), MoveQuality.best);
      expect(classifyByLoss(0.015), MoveQuality.excellent);
      expect(classifyByLoss(0.04), MoveQuality.good);
      expect(classifyByLoss(0.08), MoveQuality.inaccuracy);
      expect(classifyByLoss(0.15), MoveQuality.mistake);
      expect(classifyByLoss(0.25), MoveQuality.blunder);
    });

    test('labels and accuracy use the same winning-chance curve', () {
      for (final cp in [-800, -300, -50, 0, 120, 450, 900]) {
        expect(expectedPointsFromCp(cp), closeTo(winPercent(cp) / 100, 1e-12));
      }
      // So an excellent move scores at least ~90% accuracy, a blunder far
      // less.
      double accuracyAt(double lost) {
        // Find a played score losing [lost] from an equal position.
        var played = 0;
        while (expectedPointsLost(bestCp: 0, playedCp: played) < lost) {
          played -= 1;
        }
        return moveAccuracy(bestCp: 0, playedCp: played);
      }

      expect(accuracyAt(0.02), greaterThan(90));
      expect(accuracyAt(0.21), lessThan(45));
    });

    test('a slightly worse move in a won game is not a blunder', () {
      // +9 to +6 still wins; from equal to -3 does not.
      expect(
        classifyByLoss(expectedPointsLost(bestCp: 900, playedCp: 600)),
        isNot(anyOf(MoveQuality.mistake, MoveQuality.blunder)),
      );
      expect(
        classifyByLoss(expectedPointsLost(bestCp: 0, playedCp: -300)),
        MoveQuality.blunder,
      );
    });

    test('the engine\'s own move is best, or better', () {
      final before = Chess.initial;
      final move = NormalMove.fromUci('e2e4');
      MoveQuality rate({required bool isBest, int played = 30}) =>
          classifyPlayedMove(
            before: before,
            after: before.play(move),
            move: move,
            bestCp: 30,
            playedCp: played,
            secondBestCp: 25,
            isBest: isBest,
          );
      expect(rate(isBest: true), MoveQuality.best);
      // Another move scoring the same, within search noise, is best too.
      expect(rate(isBest: false, played: 29), MoveQuality.best);
      expect(rate(isBest: false, played: 15), MoveQuality.excellent);
      expect(rate(isBest: false, played: -10), MoveQuality.good);
    });

    test('only the standout labels are checked again, deeper', () {
      expect(MoveQuality.values.where((q) => q.needsCheck), [
        MoveQuality.brilliant,
        MoveQuality.great,
        MoveQuality.mistake,
        MoveQuality.blunder,
      ]);
    });
  });

  group('brilliant', () {
    test('a piece left hanging by moving another counts as a sacrifice', () {
      // The queen leaves d1, and the bishop on d3 is no longer defended.
      expect(_brilliant('3r2k1/8/8/8/8/3B4/8/3Q2K1 w - - 0 1', 'd1h5'), isTrue);
    });

    test('a piece hanging to a pinned attacker is no sacrifice', () {
      // Ne7 is pinned to its king by the rook, so it cannot take on f5.
      expect(_brilliant('4k3/4n3/8/8/7N/8/8/4R1K1 w - - 0 1', 'h4f5'), isFalse);
      // Without the pin it is a real knight sacrifice.
      expect(_brilliant('4k3/4n3/8/8/7N/8/8/R5K1 w - - 0 1', 'h4f5'), isTrue);
    });

    test('an even trade is not a sacrifice', () {
      expect(
        _brilliant(
          'r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 4',
          'b5c6',
        ),
        isFalse,
      );
    });

    test('something already hanging does not hide a new sacrifice', () {
      // The bishop on c5 hangs before and after; Rxf7 adds the rook.
      expect(
        _brilliant(
          'rnnqk2r/5pb1/1p4pp/p1BPp3/2P4N/3P2P1/PP4BP/R2Q1RK1 w kq - 0 16',
          'f1f7',
        ),
        isTrue,
      );
    });
  });

  group('look', () {
    test('every label has its own colour and an icon that exists', () {
      final colours = MoveQuality.values.map((q) => q.color).toSet();
      expect(colours.length, MoveQuality.values.length);
      for (final q in MoveQuality.values) {
        expect(io.File(q.asset).existsSync(), isTrue, reason: q.asset);
      }
      // Mistake and blunder no longer share one icon.
      expect(MoveQuality.mistake.asset, isNot(MoveQuality.blunder.asset));
    });

    test('the banner reads naturally', () {
      const bad = MoveFeedback(
        quality: MoveQuality.blunder,
        bestSan: 'Nf3',
        playedSan: 'Qh5',
      );
      expect(bad.bannerText, 'Qh5 was a blunder · Nf3 was best');
      const good = MoveFeedback(
        quality: MoveQuality.best,
        bestSan: 'e4',
        playedSan: 'e4',
      );
      expect(good.bannerText, 'e4 · best move');
    });
  });
}
