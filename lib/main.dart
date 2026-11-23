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
import 'package:kust/core/net/chat_repository.dart';
import 'package:kust/core/net/players_repository.dart';
import 'package:kust/core/net/profile_sync.dart';
import 'package:kust/core/net/push_service.dart';
import 'package:kust/core/storage/player_rating_store.dart';
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
  if (ServerConfig.enabled) {
    _startServerLink();
    PushService.instance.start(router);
  }
  unawaited(warmBoards());
}

void _startServerLink() {
  AuthService.instance.state.addListener(_syncLiveSocket);
  AuthService.instance.state.addListener(_syncRating);
  PlayerRatingStore.instance.listenable().addListener(_syncRating);
  ProfileSync.instance.start();
  unawaited(AuthService.instance.restore());
}

bool _sendingRating = false;

/// Bot games are played on the phone, so the server learns the player's
/// rating from here: on sign-in and after every rated game. Each answer
/// updates the account, which calls this again and stops once they agree.
void _syncRating() {
  final auth = AuthService.instance.state.value;
  final local = PlayerRatingStore.instance.rating.clamp(100, 3500);
  if (!auth.isSignedIn || _sendingRating || auth.account?.rating == local) {
    return;
  }
  _sendingRating = true;
  AuthService.instance.updateProfile(rating: local).then<void>(
    (_) {
      _sendingRating = false;
      _syncRating(); // In case it changed while this was on its way.
    },
    // Offline or refused: tried again on the next change or sign-in.
    onError: (Object _) => _sendingRating = false,
  );
}

/// Signed in: watch the connection; verified too: join the live server.
/// Signed out, the app is fully offline and never says so.
bool _wasSignedIn = false;

void _syncLiveSocket() {
  final auth = AuthService.instance.state.value;
  // Signed out (by hand or because the session ended): the phone forgets
  // that account's games and achievements.
  if (_wasSignedIn && auth.status == AuthStatus.signedOut) {
    unawaited(ProfileSync.instance.forget());
  }
  if (auth.status != AuthStatus.unknown) _wasSignedIn = auth.isSignedIn;
  if (auth.isSignedIn) {
    ConnectionService.instance.start();
  } else {
    ConnectionService.instance.stop();
  }
  if (auth.isVerified) {
    // The bell on the home screen counts friend requests waiting.
    unawaited(PlayersRepository.instance.refreshIncoming());
    unawaited(ChatRepository.instance.refreshUnread());
    LiveSocket.instance.connect();
  } else {
    unawaited(LiveSocket.instance.close());
  }
}
