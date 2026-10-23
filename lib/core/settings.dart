import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Kust/features/game/chess/sound_service.dart';

/// User-facing preferences. Backed by SharedPreferences.
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  final ValueNotifier<bool> sound = ValueNotifier(true);
  final ValueNotifier<bool> haptics = ValueNotifier(true);

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

  void _apply() {
    SoundService.instance.soundEnabled = sound.value;
    SoundService.instance.hapticsEnabled = haptics.value;
  }
}
