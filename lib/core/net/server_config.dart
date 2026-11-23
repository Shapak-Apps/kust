class ServerConfig {
  ServerConfig._();

  static const String apiUrl = String.fromEnvironment('API_URL');
  static const String _wsUrl = String.fromEnvironment('WS_URL');

  static bool get enabled => apiUrl.isNotEmpty;

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
