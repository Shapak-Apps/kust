import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/server_config.dart';

enum LiveState { idle, connecting, connected }

class LiveEvent {
  const LiveEvent(this.type, this.data);

  final String type;
  final Map<String, dynamic> data;
}

typedef SocketConnector = WebSocketChannel Function(Uri url);

WebSocketChannel _defaultConnector(Uri url) => WebSocketChannel.connect(url);

class LiveSocket {
  LiveSocket({
    required this.url,
    required this.tokenProvider,
    SocketConnector? connector,
    this.pingEvery = const Duration(seconds: 25),
    this.initialBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
    this.connectTimeout = const Duration(seconds: 10),
  }) : _connector = connector ?? _defaultConnector;

  static final LiveSocket instance = LiveSocket(
    url: Uri.parse(ServerConfig.wsUrl),
    tokenProvider: () => AuthService.instance.accessToken(),
  );

  final Uri url;
  final Future<String?> Function() tokenProvider;
  final Duration pingEvery;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final Duration connectTimeout;
  final SocketConnector _connector;

  final StreamController<LiveEvent> _events = StreamController.broadcast();
  final ValueNotifier<LiveState> _state = ValueNotifier(LiveState.idle);
  final Random _random = Random();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _retryTimer;
  Timer? _heartbeat;
  DateTime _lastSeen = DateTime.now();
  int _attempt = 0;
  bool _wanted = false;
  bool _disposed = false;

  Stream<LiveEvent> get events => _events.stream;

  ValueListenable<LiveState> get state => _state;

  void connect() {
    if (_wanted || _disposed) return;
    _wanted = true;
    _attempt = 0;
    _open();
  }

  void send(String type, [Map<String, dynamic> data = const {}]) {
    if (_state.value != LiveState.connected) return;
    _channel?.sink.add(jsonEncode({'type': type, 'data': data}));
  }

  Future<void> close() async {
    _wanted = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    final channel = _teardown();
    _setState(LiveState.idle);
    try {
      await channel?.sink.close();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _disposed = true;
    await close();
    await _events.close();
    _state.dispose();
  }

  Future<void> _open() async {
    if (!_wanted || _disposed) return;
    _setState(LiveState.connecting);
    WebSocketChannel? channel;
    try {
      final token = await tokenProvider();
      if (!_wanted || _disposed) return;
      if (token == null) {
        _wanted = false;
        _setState(LiveState.idle);
        return;
      }
      channel = _connector(url);
      _channel = channel;
      await channel.ready.timeout(connectTimeout);
      if (!_wanted || _disposed || _channel != channel) {
        await channel.sink.close();
        return;
      }
      _lastSeen = DateTime.now();
      _sub = channel.stream.listen(
        _onMessage,
        onError: (_) => _lost(channel),
        onDone: () => _lost(channel),
        cancelOnError: true,
      );
      _heartbeat = Timer.periodic(pingEvery, (_) => _beat(channel!));
      channel.sink.add(jsonEncode({'type': 'auth', 'data': {'token': token}}));
    } catch (_) {
      _lost(channel);
    }
  }

  void _onMessage(dynamic raw) {
    _lastSeen = DateTime.now();
    if (raw is! String) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;
    final type = decoded['type'];
    if (type is! String) return;
    final data = decoded['data'];
    final payload = data is Map<String, dynamic> ? data : <String, dynamic>{};
    if (type == 'pong') return;
    if (type == 'hello') {
      _attempt = 0;
      _setState(LiveState.connected);
    }
    if (!_events.isClosed) _events.add(LiveEvent(type, payload));
  }

  void _beat(WebSocketChannel channel) {
    if (_channel != channel) return;
    final silent = DateTime.now().difference(_lastSeen);
    if (silent > pingEvery * 2) {
      _lost(channel);
      return;
    }
    try {
      channel.sink.add(jsonEncode({'type': 'ping'}));
    } catch (_) {
      _lost(channel);
    }
  }

  void _lost(WebSocketChannel? channel) {
    if (channel != null && _channel != channel) return;
    final old = _teardown();
    old?.sink.close().catchError((_) {});
    if (!_wanted || _disposed) {
      _setState(LiveState.idle);
      return;
    }
    _setState(LiveState.connecting);
    _scheduleRetry();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final base = initialBackoff.inMilliseconds * pow(2, _attempt).toInt();
    final capped = min(base, maxBackoff.inMilliseconds);
    final jitter = (capped * 0.2 * _random.nextDouble()).round();
    _attempt = min(_attempt + 1, 16);
    _retryTimer = Timer(Duration(milliseconds: capped + jitter), _open);
  }

  WebSocketChannel? _teardown() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _sub?.cancel();
    _sub = null;
    final channel = _channel;
    _channel = null;
    return channel;
  }

  void _setState(LiveState value) {
    if (_disposed || _state.value == value) return;
    _state.value = value;
  }
}
