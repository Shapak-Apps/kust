import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:kust/core/net/live_socket.dart';

class PresenceService {
  PresenceService(this._socket) {
    _sub = _socket.events.listen(_onEvent);
    _socket.state.addListener(_onState);
  }

  static final PresenceService instance = PresenceService(LiveSocket.instance);

  final LiveSocket _socket;
  late final StreamSubscription<LiveEvent> _sub;

  final ValueNotifier<Set<String>> _online = ValueNotifier(const {});

  ValueListenable<Set<String>> get online => _online;

  bool isOnline(String username) => _online.value.contains(username);

  void _onEvent(LiveEvent event) {
    switch (event.type) {
      case 'hello':
        final users = event.data['users'];
        _online.value = users is List
            ? users.whereType<String>().toSet()
            : const {};
      case 'join':
        final user = event.data['username'];
        if (user is String) _online.value = {..._online.value, user};
      case 'leave':
        final user = event.data['username'];
        if (user is String) {
          _online.value = _online.value.where((u) => u != user).toSet();
        }
    }
  }

  void _onState() {
    if (_socket.state.value != LiveState.connected &&
        _online.value.isNotEmpty) {
      _online.value = const {};
    }
  }

  void dispose() {
    _sub.cancel();
    _socket.state.removeListener(_onState);
    _online.dispose();
  }
}
