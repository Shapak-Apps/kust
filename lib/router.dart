import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/onboarding/onboarding_screen.dart';
import 'package:kust/features/game/game_screen.dart';
import 'package:kust/features/game/game_args.dart';
import 'package:kust/features/play/play_screen.dart';
import 'package:kust/features/puzzles/puzzle_game_screen.dart';
import 'package:kust/features/history/history_screen.dart';
import 'package:kust/features/history/replay_screen.dart';
import 'package:kust/features/puzzles/puzzles_screen.dart';
import 'package:kust/widgets/app_shell.dart';

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
        builder: (context, state) {
          final args = state.extra as GameArgs;
          return GameScreen(
            bot: args.bot,
            isLocal: args.isLocal,
            playerSide: args.playerSide,
            timeControl: args.timeControl,
            practiceMode: args.practiceMode,
          );
        },
      ),

      GoRoute(
        path: '/puzzle/:level/:index',
        builder: (context, state) => PuzzleGameScreen(
          level: int.parse(state.pathParameters['level']!),
          index: int.parse(state.pathParameters['index']!),
          daily: state.uri.queryParameters['daily'] == '1',
        ),
      ),

      GoRoute(
        path: '/history/:id',
        builder: (context, state) =>
            ReplayScreen(gameId: state.pathParameters['id']!),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/play',
            pageBuilder: (context, state) =>
                _tabPage(state, const PlayScreen()),
          ),

          GoRoute(
            path: '/puzzles',
            pageBuilder: (context, state) =>
                _tabPage(state, const PuzzlesScreen()),
          ),

          GoRoute(
            path: '/history',
            pageBuilder: (context, state) =>
                _tabPage(state, const HistoryScreen()),
          ),
        ],
      ),
    ],
  );
}

/// Tab switch: quick fade with a slight rise, like iOS cross-fades.
CustomTransitionPage<void> _tabPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
