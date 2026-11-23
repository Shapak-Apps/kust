import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/net/live_socket.dart';
import 'package:kust/core/net/presence.dart';

class _Server {
  _Server._(this.http);

  final HttpServer http;
  final List<WebSocket> sockets = [];
  final List<Map<String, dynamic>> received = [];
  int connections = 0;
  bool answerHello = true;
  bool answerPing = true;
  List<String> users = const ['alpha'];

  static Future<_Server> start() async {
    final server = _Server._(await HttpServer.bind('127.0.0.1', 0));
    server.http.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      server.connections++;
      server.sockets.add(socket);
      socket.listen((raw) {
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        server.received.add(msg);
        if (msg['type'] == 'auth' && server.answerHello) {
          socket.add(
            jsonEncode({
              'type': 'hello',
              'data': {'users': server.users},
            }),
          );
        }
        if (msg['type'] == 'ping' && server.answerPing) {
          socket.add(jsonEncode({'type': 'pong'}));
        }
      });
    });
    return server;
  }

  Uri get url => Uri.parse('ws://127.0.0.1:${http.port}/v1/ws');

  void broadcast(String type, Map<String, dynamic> data) {
    for (final s in sockets) {
      s.add(jsonEncode({'type': type, 'data': data}));
    }
  }

  Future<void> stop() async {
    for (final s in sockets) {
      await s.close();
    }
    await http.close(force: true);
  }
}

Future<void> _until(bool Function() test, {int ms = 3000}) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (!test()) {
    if (DateTime.now().isAfter(end)) fail('timed out waiting');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

LiveSocket _socket(
  _Server server, {
  Future<String?> Function()? token,
  Duration ping = const Duration(seconds: 25),
}) => LiveSocket(
  url: server.url,
  tokenProvider: token ?? () async => 'tok',
  pingEvery: ping,
  initialBackoff: const Duration(milliseconds: 20),
  maxBackoff: const Duration(milliseconds: 80),
);

void main() {
  test('connects, authenticates and turns connected on hello', () async {
    final server = await _Server.start();
    final socket = _socket(server);
    final events = <LiveEvent>[];
    socket.events.listen(events.add);

    socket.connect();
    await _until(() => socket.state.value == LiveState.connected);

    expect(server.received.first, {
      'type': 'auth',
      'data': {'token': 'tok'},
    });
    expect(events.single.type, 'hello');

    await socket.dispose();
    await server.stop();
  });

  test('does not connect without a token', () async {
    final server = await _Server.start();
    final socket = _socket(server, token: () async => null);
    socket.connect();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(server.connections, 0);
    expect(socket.state.value, LiveState.idle);
    await socket.dispose();
    await server.stop();
  });

  test('reconnects after the server drops the connection', () async {
    final server = await _Server.start();
    final socket = _socket(server);
    socket.connect();
    await _until(() => socket.state.value == LiveState.connected);

    await server.sockets.first.close();
    await _until(() => server.connections >= 2);
    await _until(() => socket.state.value == LiveState.connected);
    expect(server.received.where((m) => m['type'] == 'auth').length, 2);

    await socket.dispose();
    await server.stop();
  });

  test('keeps retrying while the server is unreachable', () async {
    final server = await _Server.start();
    final url = server.url;
    await server.stop();
    final socket = LiveSocket(
      url: url,
      tokenProvider: () async => 'tok',
      initialBackoff: const Duration(milliseconds: 20),
      maxBackoff: const Duration(milliseconds: 40),
      connectTimeout: const Duration(milliseconds: 200),
    );
    socket.connect();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(socket.state.value, LiveState.connecting);
    await socket.dispose();
  });

  test('close stops reconnecting', () async {
    final server = await _Server.start();
    final socket = _socket(server);
    socket.connect();
    await _until(() => socket.state.value == LiveState.connected);
    await socket.close();
    final seen = server.connections;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(server.connections, seen);
    expect(socket.state.value, LiveState.idle);
    await socket.dispose();
    await server.stop();
  });

  test('a silent server is treated as dead and reconnected', () async {
    final server = await _Server.start();
    server.answerPing = false;
    final socket = _socket(server, ping: const Duration(milliseconds: 40));
    socket.connect();
    await _until(() => socket.state.value == LiveState.connected);
    await _until(() => server.connections >= 2);
    await socket.dispose();
    await server.stop();
  });

  test('send reaches the server only while connected', () async {
    final server = await _Server.start();
    final socket = _socket(server);
    socket.send('chat', {'x': 1});
    socket.connect();
    await _until(() => socket.state.value == LiveState.connected);
    socket.send('chat', {'x': 2});
    await _until(() => server.received.any((m) => m['type'] == 'chat'));
    final chats = server.received.where((m) => m['type'] == 'chat').toList();
    expect(chats.single['data'], {'x': 2});
    await socket.dispose();
    await server.stop();
  });

  test('presence follows hello, join and leave, and clears on drop', () async {
    final server = await _Server.start();
    server.users = ['alpha', 'bravo'];
    final socket = _socket(server);
    final presence = PresenceService(socket);

    socket.connect();
    await _until(() => presence.isOnline('alpha'));
    expect(presence.online.value, {'alpha', 'bravo'});

    server.broadcast('join', {'username': 'charlie'});
    await _until(() => presence.isOnline('charlie'));
    server.broadcast('leave', {'username': 'alpha'});
    await _until(() => !presence.isOnline('alpha'));
    expect(presence.online.value, {'bravo', 'charlie'});

    await socket.close();
    await _until(() => presence.online.value.isEmpty);

    presence.dispose();
    await socket.dispose();
    await server.stop();
  });
}
