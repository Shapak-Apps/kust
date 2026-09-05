import 'package:go_router/go_router.dart';

import 'package:Kust/features/onboarding/onboarding_screen.dart';
import 'package:Kust/features/game/game_screen.dart';
import 'package:Kust/features/play/pick_opponent_modal.dart';
import 'package:Kust/features/play/play_screen.dart';
import 'package:Kust/features/puzzles/puzzles_screen.dart';
import 'package:Kust/widgets/app_shell.dart';

GoRouter createRouter({required bool onboardingCompleted}) {
  return GoRouter(
    initialLocation: onboardingCompleted ? '/play' : '/onboarding',

    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(),
      ),

      GoRoute(
        path: '/game',
        builder: (context, state) => GameScreen(bot: state.extra as Bot),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/play',
            builder: (context, state) => const PlayScreen(),
          ),

          GoRoute(
            path: '/puzzles',
            builder: (context, state) => const PuzzlesScreen(),
          ),
        ],
      ),
    ],
  );
}
