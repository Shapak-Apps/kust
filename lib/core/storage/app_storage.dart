import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Local storage for guest identity + bot progress.
/// No auth yet — we act as guest. Everything is Hive-backed and reactive
/// via [botProgressListenable] so the UI ticks update live.
class AppStorage {
  AppStorage._();
  static final AppStorage instance = AppStorage._();

  static const String userBoxName = 'kust_user';
  static const String botProgressBoxName = 'bot_progress';

  static const String _guestIdKey = 'guest_id';
  static const String _guestNameKey = 'guest_name';
  static const String _guestCreatedKey = 'guest_created_ms';

  static const List<String> _guestNames = [
    'Guest Knight',
    'Pawn Pusher',
    'Blitz Fox',
    'Quiet Rook',
    'Night Bishop',
    'Rapid Wolf',
  ];

  Box get _user => Hive.box(userBoxName);
  Box get _bots => Hive.box(botProgressBoxName);

  /// Must be called once from main() after Hive.initFlutter().
  static Future<void> init() async {
    await Hive.openBox(userBoxName);
    await Hive.openBox(botProgressBoxName);
    await instance._ensureGuest();
  }

  Future<void> _ensureGuest() async {
    if (_user.get(_guestIdKey) != null) return;
    final rand = Random();
    final id =
        '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${rand.nextInt(1 << 32).toRadixString(36)}';
    await _user.putAll({
      _guestIdKey: 'guest_$id',
      _guestNameKey: _guestNames[rand.nextInt(_guestNames.length)],
      _guestCreatedKey: DateTime.now().millisecondsSinceEpoch,
    });
  }

  String get guestId => _user.get(_guestIdKey, defaultValue: 'guest') as String;
  String get guestName =>
      _user.get(_guestNameKey, defaultValue: 'Guest') as String;

  /// Reactive signal for bot-progress UI (bot ticks update live).
  ValueListenable botProgressListenable() => _bots.listenable();

  /// Stable key for a bot. Use explicit id everywhere.
  bool isBotBeaten(String botId) => _bots.get(_beatenKey(botId)) == true;

  Set<String> get beatenBotIds => _bots.keys
      .where((k) => k is String && (k).startsWith('beaten_'))
      .where((k) => _bots.get(k) == true)
      .map((k) => (k as String).substring('beaten_'.length))
      .toSet();

  Future<void> markBotBeaten(String botId) async {
    if (isBotBeaten(botId)) return;
    await _bots.put(_beatenKey(botId), true);
    await _bots.put(
      'beaten_${botId}_at',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  String _beatenKey(String botId) => 'beaten_$botId';
}
