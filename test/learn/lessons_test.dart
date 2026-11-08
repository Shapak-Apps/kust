import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/learn/lesson_task.dart';
import 'package:kust/features/learn/lessons.dart';
import 'package:kust/l10n/gen/app_localizations.dart';

NormalMove _m(String uci) => NormalMove.fromUci(uci);

void main() {
  test('every task starts from a legal position with White to move', () {
    for (final lesson in kLessons) {
      for (final task in lesson.tasks) {
        final runner = TaskRunner(task);
        expect(runner.position.turn, Side.white, reason: task.fen);
        expect(runner.position.legalMoves, isNotEmpty, reason: task.fen);
        for (final target in task.targets) {
          expect(Square.values, contains(target));
        }
      }
    }
  });

  test('every task can be solved by following the hints', () {
    for (final lesson in kLessons) {
      for (final task in lesson.tasks) {
        final runner = TaskRunner(task);
        var step = TaskStep.progress;
        var moves = 0;
        while (step == TaskStep.progress && moves < 12) {
          final hint = runner.hint();
          expect(hint, isNotNull, reason: '${lesson.id}: ${task.fen}');
          step = runner.apply(hint!);
          moves++;
        }
        expect(step, TaskStep.done, reason: '${lesson.id}: ${task.fen}');
      }
    }
  });

  test('the star tasks need every star, in any order', () {
    final runner = TaskRunner(kLessons[1].tasks[1]); // rook to a5 and e5
    expect(runner.apply(_m('a1a5')), TaskStep.progress);
    expect(runner.remaining.length, 1);
    expect(runner.position.turn, Side.white);
    expect(runner.apply(_m('a5e5')), TaskStep.done);
  });

  test('free moves are allowed in a collect task', () {
    final runner = TaskRunner(kLessons[1].tasks[0]); // rook to a6
    expect(runner.apply(_m('a1a2')), TaskStep.progress);
    expect(runner.apply(_m('a2a6')), TaskStep.done);
  });

  test('the wrong capture is refused and the board stays', () {
    final runner = TaskRunner(kLessons[6].tasks[0]); // the queen, not the pawn
    final fen = runner.position.fen;
    expect(runner.apply(_m('d4e6')), TaskStep.wrong);
    expect(runner.position.fen, fen);
    expect(runner.apply(_m('d4f5')), TaskStep.done);
  });

  test('a mate task tells stalemate from mate and from a plain move', () {
    final mate = kLessons.firstWhere((l) => l.id == 'mate').tasks[1];
    expect(TaskRunner(mate).apply(_m('c1c8')), TaskStep.done);
    expect(TaskRunner(mate).apply(_m('c1c4')), TaskStep.stalemate);
    expect(TaskRunner(mate).apply(_m('c1c2')), TaskStep.wrong);
  });

  test('check and castling tasks', () {
    final check = kLessons.firstWhere((l) => l.id == 'check').tasks;
    expect(TaskRunner(check[0]).apply(_m('a1a2')), TaskStep.wrong);
    expect(TaskRunner(check[0]).apply(_m('a1a8')), TaskStep.done);
    // Any legal move leaves check; an illegal one is wrong.
    expect(TaskRunner(check[1]).apply(_m('e1d1')), TaskStep.done);
    expect(TaskRunner(check[1]).apply(_m('e1e2')), TaskStep.wrong);

    final special = kLessons.firstWhere((l) => l.id == 'special').tasks;
    expect(TaskRunner(special[0]).apply(_m('e1h1')), TaskStep.done);
    expect(TaskRunner(special[0]).apply(_m('e1a1')), TaskStep.wrong);
    expect(TaskRunner(special[1]).apply(_m('e1a1')), TaskStep.done);
    expect(TaskRunner(special[2]).apply(_m('e5d6')), TaskStep.done);
    expect(TaskRunner(special[3]).apply(_m('e7e8')), TaskStep.wrong);
    expect(
      TaskRunner(special[3]).apply(NormalMove.fromUci('e7e8q')),
      TaskStep.done,
    );
  });

  for (final code in ['en', 'ru', 'tk']) {
    test('every lesson has a title, an introduction and prompts ($code)', () {
      final t = lookupAppL10n(Locale(code));
      for (final lesson in kLessons) {
        expect(lesson.title(t), isNotEmpty);
        expect(lesson.intro(t).length, greaterThan(40));
        for (final task in lesson.tasks) {
          expect(taskPrompt(t, task), isNotEmpty);
        }
      }
    });
  }
}
