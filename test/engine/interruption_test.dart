import 'package:flutter_test/flutter_test.dart';

import 'package:kust/features/game/chess/interruption_gate.dart';

void main() {
  test('a search the app was hidden during is not trusted', () {
    final gate = InterruptionGate();
    final epoch = gate.epoch;
    gate.check(epoch); // nothing happened yet
    gate.hide();
    gate.show();
    expect(() => gate.check(epoch), throwsA(isA<SearchInterruptedException>()));
    gate.check(gate.epoch); // a search started now is fine
  });

  test('hiding twice counts once', () {
    final gate = InterruptionGate();
    gate.hide();
    final epoch = gate.epoch;
    gate.hide();
    expect(gate.epoch, epoch);
  });

  test('nothing starts while hidden, and it goes on when shown', () async {
    final gate = InterruptionGate();
    gate.hide();
    var started = false;
    final run = gate.retrying(() async {
      started = true;
      return 7;
    });
    await Future<void>.delayed(Duration.zero);
    expect(started, isFalse);
    gate.show();
    expect(await run, 7);
    expect(started, isTrue);
  });

  test('an interrupted search runs again and only the second counts', () async {
    final gate = InterruptionGate();
    var calls = 0;
    final result = await gate.retrying(() async {
      calls++;
      final epoch = gate.epoch;
      if (calls == 1) {
        gate.hide();
        gate.show();
      }
      gate.check(epoch);
      return 'move $calls';
    });
    expect(result, 'move 2');
    expect(calls, 2);
  });

  test('it gives up after the attempts and tells the caller', () async {
    final gate = InterruptionGate();
    var calls = 0;
    final run = gate.retrying(() async {
      calls++;
      final epoch = gate.epoch;
      gate.hide();
      gate.show();
      gate.check(epoch);
      return 0;
    }, attempts: 2);
    await expectLater(run, throwsA(isA<SearchInterruptedException>()));
    expect(calls, 2);
  });
}
