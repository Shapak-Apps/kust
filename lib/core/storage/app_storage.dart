import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:kust/core/error_log.dart';
import 'package:kust/l10n/app_locale.dart';

class AppStorage {
  AppStorage._();
  static final AppStorage instance = AppStorage._();

  static const String userBoxName = 'kust_user';
  static const String botProgressBoxName = 'bot_progress';
  static const String puzzleBoxName = 'puzzle_progress';
  static const String historyBoxName = 'game_history';
  static const String analysisBoxName = 'move_analysis';

  static const String _guestIdKey = 'guest_id';
  static const String _guestNameKey = 'guest_name';
  static const String _guestCreatedKey = 'guest_created_ms';
  static const String _usernameKey = 'username';
  static const String _bioKey = 'bio';
  static const String _photoKey = 'photo_path';

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

  /// Boxes that could not be read at start and were emptied. A damaged file
  /// costs that box's data, but never stops the app from opening.
  static final List<String> resetBoxes = [];

  static Future<void> init() async {
    resetBoxes.clear();
    await _openSafe(userBoxName);
    await _openSafe(botProgressBoxName);
    await _openSafe(puzzleBoxName);
    await _openSafe(historyBoxName);
    await _openSafe(analysisBoxName);
    await instance._ensureGuest();
    await instance._migrate();
  }

  static const String _schemaKey = 'schema';

  /// The version of what is stored. Raise it, and add a case to [_migrate],
  /// when a stored shape changes.
  static const int schemaVersion = 1;

  Future<void> _migrate() async {
    final stored = _user.get(_schemaKey);
    var from = stored is int ? stored : 0;
    while (from < schemaVersion) {
      // No migrations yet: version 1 is the first marked state.
      from++;
    }
    if (stored != from) await _user.put(_schemaKey, from);
  }

  /// Opens a box; replaced in tests to simulate an unreadable file.
  @visibleForTesting
  static Future<Box> Function(String name) opener = Hive.openBox;

  static Future<Box> _openSafe(String name) async {
    try {
      return await opener(name);
    } catch (e, st) {
      ErrorLog.record(e, st);
      resetBoxes.add(name);
      await Hive.deleteBoxFromDisk(name);
      return opener(name);
    }
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

  /// Whether the storage has been opened (it is not in some widget tests).
  static bool get isReady => Hive.isBoxOpen(userBoxName);

  static const int maxNameLength = 16;

  /// The name to show: the one the player chose, or "Player" in the app's
  /// language while it is still one of the random guest names.
  String displayName(AppL10n t) =>
      _guestNames.contains(guestName) ? t.defaultPlayerName : guestName;

  /// Saves the player's name (trimmed, at most [maxNameLength] characters).
  /// An empty name is ignored.
  Future<void> setGuestName(String name) async {
    final value = name.trim();
    if (value.isEmpty) return;
    await _user.put(
      _guestNameKey,
      value.length > maxNameLength ? value.substring(0, maxNameLength) : value,
    );
  }

  ValueListenable nameListenable() =>
      _user.listenable(keys: [_guestNameKey, _photoKey]);

  /// 3 to 20 lowercase letters, digits or underscores. Only the format is
  /// checked: making it unique across players needs a server.
  static final RegExp usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

  static const int maxBioLength = 160;

  String? get username => _user.get(_usernameKey) as String?;
  String get bio => _user.get(_bioKey, defaultValue: '') as String;

  /// Where the profile photo is kept; set at start (the app's support
  /// folder). Only the file name is stored, because on iOS the folder's path
  /// changes when the app is updated.
  static String? filesDir;

  /// The saved profile photo, if there is one.
  String? get photoPath {
    final file = _user.get(_photoKey) as String?;
    final dir = filesDir;
    return file == null || dir == null ? null : '$dir/$file';
  }

  ValueListenable profileListenable() =>
      _user.listenable(keys: [_guestNameKey, _usernameKey, _bioKey, _photoKey]);

  /// Saves the profile. Returns false, saving nothing, when the name is empty
  /// or the username does not match [usernamePattern].
  Future<bool> saveProfile({
    required String name,
    required String username,
    required String bio,
  }) async {
    final handle = username.trim().toLowerCase();
    if (name.trim().isEmpty || !usernamePattern.hasMatch(handle)) return false;
    await setGuestName(name);
    final about = bio.trim();
    await _user.putAll({
      _usernameKey: handle,
      _bioKey: about.length > maxBioLength
          ? about.substring(0, maxBioLength)
          : about,
    });
    return true;
  }

  /// Copies the picture at [picked] in as the profile photo, or removes the
  /// photo when null.
  Future<void> setPhoto(String? picked) async {
    final old = photoPath;
    if (picked == null) {
      await _user.delete(_photoKey);
    } else {
      final dir = filesDir;
      if (dir == null) return;
      // A new name each time, so the old picture is not shown from cache.
      final name = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(picked).copy('$dir/$name');
      await _user.put(_photoKey, name);
    }
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
  }

  ValueListenable botProgressListenable() => _bots.listenable();

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
