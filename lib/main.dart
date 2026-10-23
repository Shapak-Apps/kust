import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kust/app.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/features/game/chess/board/svg_precache.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/sound_service.dart';
import 'package:kust/router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the Stockfish engine should be pre-warmed when the app opens.
///
/// Debug builds (e.g. `assembleDebug`, `flutter run`) skip engine
/// initialization on app open so startup stays fast; the engine is started
/// lazily on first use instead. Release/profile builds (prod) warm it up at
/// app open so the first game starts instantly.
bool get _shouldWarmUpEngine => !kDebugMode;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await AppStorage.init();
  await AppSettings.instance.load();
  if (_shouldWarmUpEngine) {
    ChessEngine.instance.warmUp();
  }
  SoundService.instance.warmUp();
  unawaited(precacheGameSvgs());
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final router = createRouter(onboardingCompleted: onboardingCompleted);
  runApp(ProviderScope(child: MyApp(router: router)));
}
