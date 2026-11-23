import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kust/app.dart';
import 'package:kust/core/error_log.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/core/net/connection_service.dart';
import 'package:kust/core/net/live_socket.dart';
import 'package:kust/core/net/server_config.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/core/storage/app_storage.dart';
import 'package:kust/core/warm_up.dart';
import 'package:kust/features/game/chess/board/svg_precache.dart';
import 'package:kust/features/game/chess/chess_engine.dart';
import 'package:kust/features/game/chess/openings.dart';
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
  await runZonedGuarded(_start, ErrorLog.record);
}

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (d) {
    FlutterError.presentError(d);
    ErrorLog.record(d.exception, d.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLog.record(error, stack);
    return true;
  };
  await ErrorLog.init();
  // Touch events are lined up with the frames, so a dragged piece moves
  // smoothly even when the screen runs faster than the touch panel reports.
  GestureBinding.instance.resamplingEnabled = true;
  // Portrait only: the layouts are made for an upright phone.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  await AppStorage.init();
  try {
    AppStorage.filesDir = (await getApplicationSupportDirectory()).path;
  } catch (e, st) {
    ErrorLog.record(e, st);
  }
  try {
    await AppSettings.instance.load();
  } catch (e, st) {
    ErrorLog.record(e, st);
  }
  if (_shouldWarmUpEngine) {
    ChessEngine.instance.warmUp();
  }
  SoundService.instance.warmUp();
  // Heavy art drawn while the native splash still shows, so the tabs open
  // at once; the boards follow in the background during the splash.
  warmBeforeStart();
  unawaited(precacheGameSvgs());
  unawaited(openingBook());
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  final router = createRouter(onboardingCompleted: onboardingCompleted);
  runApp(ProviderScope(child: MyApp(router: router)));
  if (ServerConfig.enabled) _startServerLink();
  unawaited(warmBoards());
}

void _startServerLink() {
  AuthService.instance.state.addListener(_syncLiveSocket);
  unawaited(AuthService.instance.restore());
}

/// Signed in: watch the connection; verified too: join the live server.
/// Signed out, the app is fully offline and never says so.
void _syncLiveSocket() {
  final auth = AuthService.instance.state.value;
  if (auth.isSignedIn) {
    ConnectionService.instance.start();
  } else {
    ConnectionService.instance.stop();
  }
  if (auth.isVerified) {
    LiveSocket.instance.connect();
  } else {
    unawaited(LiveSocket.instance.close());
  }
}
