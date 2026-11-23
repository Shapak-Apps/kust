import 'dart:io';

class ServerConfig {
  ServerConfig._();

  /// The live server unless a build says otherwise: `--dart-define=API_URL=`
  /// another address for a local one, or empty to turn networking off.
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://kust.merdanusa.online',
  );
  static const String _wsUrl = String.fromEnvironment('WS_URL');

  /// Off in widget tests (`flutter test` sets FLUTTER_TEST), so they never
  /// reach the live server.
  static bool get enabled => apiUrl.isNotEmpty && !_underTest;

  static final bool _underTest = Platform.environment.containsKey(
    'FLUTTER_TEST',
  );

  static String get wsUrl => _wsUrl.isNotEmpty ? _wsUrl : deriveWsUrl(apiUrl);

  static String deriveWsUrl(String api) {
    if (api.isEmpty) return '';
    final base = api.endsWith('/') ? api.substring(0, api.length - 1) : api;
    final scheme = base.startsWith('https://')
        ? 'wss://${base.substring(8)}'
        : base.startsWith('http://')
        ? 'ws://${base.substring(7)}'
        : base;
    return '$scheme/v1/ws';
  }
}
