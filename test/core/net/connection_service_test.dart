import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/net/connection_service.dart';

class _Harness {
  _Harness({this.reachable = true}) {
    service = ConnectionService(
      probe: () async {
        probes++;
        return reachable;
      },
      connectivity: events.stream,
    );
    service.status.addListener(() => history.add(service.status.value));
  }

  bool reachable;
  int probes = 0;
  final events = StreamController<List<ConnectivityResult>>.broadcast();
  final List<ConnectionStatus> history = [];
  late final ConnectionService service;

  void start() => service.start(observeLifecycle: false);
}

void main() {
  testWidgets('stays online while the server answers', (tester) async {
    final h = _Harness();
    h.start();
    await tester.pump();
    await tester.pump(const Duration(seconds: 70));
    expect(h.service.status.value, ConnectionStatus.online);
    expect(h.history, isEmpty);
    expect(h.probes, greaterThan(2));
    h.service.dispose();
  });

  testWidgets('goes offline only after the grace period', (tester) async {
    final h = _Harness(reachable: false);
    h.start();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(h.service.status.value, ConnectionStatus.online);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(h.service.status.value, ConnectionStatus.offline);
    h.service.dispose();
  });

  testWidgets('stop (signing out) hides offline and stops probing', (
    tester,
  ) async {
    final h = _Harness(reachable: false);
    h.start();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(h.service.status.value, ConnectionStatus.offline);
    h.service.stop();
    expect(h.service.status.value, ConnectionStatus.online);
    final probes = h.probes;
    await tester.pump(const Duration(seconds: 70));
    expect(h.probes, probes);
    expect(h.service.status.value, ConnectionStatus.online);
    h.service.dispose();
  });

  testWidgets('a short blip never shows offline', (tester) async {
    final h = _Harness(reachable: false);
    h.start();
    await tester.pump();
    h.reachable = true;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 6));
    expect(h.history, isEmpty);
    expect(h.service.status.value, ConnectionStatus.online);
    h.service.dispose();
  });

  testWidgets('recovery shows restored for a moment, then online', (
    tester,
  ) async {
    final h = _Harness(reachable: false);
    h.start();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(h.service.status.value, ConnectionStatus.offline);

    h.reachable = true;
    for (var i = 0; i < 12; i++) {
      if (h.service.status.value == ConnectionStatus.restored) break;
      await tester.pump(const Duration(seconds: 1));
    }
    expect(h.service.status.value, ConnectionStatus.restored);
    await tester.pump(const Duration(milliseconds: 2100));
    expect(h.service.status.value, ConnectionStatus.online);
    expect(h.history, [
      ConnectionStatus.offline,
      ConnectionStatus.restored,
      ConnectionStatus.online,
    ]);
    h.service.dispose();
  });

  testWidgets('losing every network interface starts the grace timer', (
    tester,
  ) async {
    final h = _Harness();
    h.start();
    await tester.pump();
    final before = h.probes;
    h.reachable = false;
    h.events.add([ConnectivityResult.none]);
    await tester.pump();
    expect(h.probes, before);
    await tester.pump(const Duration(milliseconds: 2100));
    expect(h.service.status.value, ConnectionStatus.offline);
    h.service.dispose();
  });

  testWidgets('a network coming back triggers a probe at once', (tester) async {
    final h = _Harness();
    h.start();
    await tester.pump();
    final before = h.probes;
    h.events.add([ConnectivityResult.wifi]);
    await tester.pump();
    expect(h.probes, before + 1);
    h.service.dispose();
  });

  testWidgets('pause stops probing and resume probes right away', (
    tester,
  ) async {
    final h = _Harness();
    h.start();
    await tester.pump();
    h.service.pause();
    final paused = h.probes;
    await tester.pump(const Duration(minutes: 2));
    expect(h.probes, paused);
    h.service.resume();
    await tester.pump();
    expect(h.probes, paused + 1);
    h.service.dispose();
  });

  testWidgets('a probe that throws counts as unreachable', (tester) async {
    final service = ConnectionService(probe: () async => throw Exception('x'));
    service.start(observeLifecycle: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));
    expect(service.status.value, ConnectionStatus.offline);
    service.dispose();
  });

  testWidgets('does nothing before start', (tester) async {
    final h = _Harness(reachable: false);
    await tester.pump(const Duration(minutes: 1));
    expect(h.probes, 0);
    expect(h.service.status.value, ConnectionStatus.online);
    h.service.dispose();
  });
}
