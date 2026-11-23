import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:kust/core/net/api_client.dart';
import 'package:kust/core/net/server_config.dart';

enum ConnectionStatus { online, offline, restored }

class ConnectionService {
  ConnectionService({
    required this.probe,
    this.connectivity,
    this.offlineGrace = const Duration(seconds: 2),
    this.onlineInterval = const Duration(seconds: 20),
    this.offlineInterval = const Duration(seconds: 5),
    this.restoredFor = const Duration(seconds: 2),
  });

  static final ConnectionService instance = _create();

  static ConnectionService _create() {
    final api = ApiClient(baseUrl: ServerConfig.apiUrl);
    return ConnectionService(
      probe: api.ping,
      connectivity: Connectivity().onConnectivityChanged,
    );
  }

  final Future<bool> Function() probe;
  final Stream<List<ConnectivityResult>>? connectivity;
  final Duration offlineGrace;
  final Duration onlineInterval;
  final Duration offlineInterval;
  final Duration restoredFor;

  final ValueNotifier<ConnectionStatus> _status = ValueNotifier(
    ConnectionStatus.online,
  );

  ValueListenable<ConnectionStatus> get status => _status;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  AppLifecycleListener? _lifecycle;
  Timer? _probeTimer;
  Timer? _graceTimer;
  Timer? _restoredTimer;
  bool _started = false;
  bool _paused = false;
  bool _probing = false;
  bool _disposed = false;

  void start({bool observeLifecycle = true}) {
    if (_started || _disposed) return;
    _started = true;
    _connectivitySub = connectivity?.listen(_onConnectivity);
    if (observeLifecycle) {
      _lifecycle = AppLifecycleListener(onResume: resume, onPause: pause);
    }
    checkNow();
  }

  void pause() {
    _paused = true;
    _probeTimer?.cancel();
    _probeTimer = null;
  }

  void resume() {
    if (!_started || _disposed) return;
    _paused = false;
    checkNow();
  }

  Future<void> checkNow() async {
    if (!_started || _paused || _disposed || _probing) return;
    _probing = true;
    _probeTimer?.cancel();
    bool reachable;
    try {
      reachable = await probe();
    } catch (_) {
      reachable = false;
    }
    _probing = false;
    if (_disposed) return;
    if (reachable) {
      _onReachable();
    } else {
      _onUnreachable();
    }
    _scheduleNext();
  }

  void _onConnectivity(List<ConnectivityResult> results) {
    final none =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (none) {
      _onUnreachable();
    } else {
      checkNow();
    }
  }

  void _onReachable() {
    _graceTimer?.cancel();
    _graceTimer = null;
    if (_status.value == ConnectionStatus.offline) {
      _status.value = ConnectionStatus.restored;
      _restoredTimer?.cancel();
      _restoredTimer = Timer(restoredFor, () {
        if (_status.value == ConnectionStatus.restored) {
          _status.value = ConnectionStatus.online;
        }
      });
    }
  }

  void _onUnreachable() {
    if (_status.value == ConnectionStatus.offline || _graceTimer != null) {
      return;
    }
    _graceTimer = Timer(offlineGrace, () {
      _graceTimer = null;
      _status.value = ConnectionStatus.offline;
    });
  }

  void _scheduleNext() {
    if (_paused || _disposed) return;
    final Duration next;
    if (_graceTimer != null) {
      next = offlineGrace ~/ 2;
    } else if (_status.value == ConnectionStatus.offline) {
      next = offlineInterval;
    } else {
      next = onlineInterval;
    }
    _probeTimer?.cancel();
    _probeTimer = Timer(next, checkNow);
  }

  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    _lifecycle?.dispose();
    _probeTimer?.cancel();
    _graceTimer?.cancel();
    _restoredTimer?.cancel();
    _status.dispose();
  }
}
