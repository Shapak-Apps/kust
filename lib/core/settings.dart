import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/board_theme.dart';
import 'package:kust/core/piece_set.dart';
import 'package:kust/features/game/chess/sound_service.dart';

/// User-facing preferences. Backed by SharedPreferences.
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  final ValueNotifier<bool> sound = ValueNotifier(true);
  final ValueNotifier<bool> haptics = ValueNotifier(true);
  final ValueNotifier<BoardTheme> boardTheme = ValueNotifier(
    BoardTheme.defaultTheme,
  );

  final ValueNotifier<PieceSet> pieceSet = ValueNotifier(PieceSet.defaultSet);

  SharedPreferences? _prefs;

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    themeMode.value = switch (prefs.getString('theme_mode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    sound.value = prefs.getBool('sound_enabled') ?? true;
    haptics.value = prefs.getBool('haptics_enabled') ?? true;
    boardTheme.value = BoardTheme.fromName(prefs.getString('board_theme'));
    pieceSet.value = PieceSet.fromName(prefs.getString('piece_set'));
    _apply();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _prefs?.setString('theme_mode', mode.name);
  }

  Future<void> setSound(bool value) async {
    sound.value = value;
    _apply();
    await _prefs?.setBool('sound_enabled', value);
  }

  Future<void> setHaptics(bool value) async {
    haptics.value = value;
    _apply();
    await _prefs?.setBool('haptics_enabled', value);
  }

  Future<void> setBoardTheme(BoardTheme theme) async {
    boardTheme.value = theme;
    await _prefs?.setString('board_theme', theme.name);
  }

  Future<void> setPieceSet(PieceSet set) async {
    pieceSet.value = set;
    await _prefs?.setString('piece_set', set.name);
  }

  void _apply() {
    SoundService.instance.soundEnabled = sound.value;
    SoundService.instance.hapticsEnabled = haptics.value;
  }
}
