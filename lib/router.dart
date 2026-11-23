import 'package:flutter/foundation.dart';
import 'package:kust/features/learn/learn_screen.dart';
import 'package:kust/features/learn/lesson_screen.dart';
import 'package:kust/features/review/retry_screen.dart';
import 'package:kust/features/review/review_screen.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/achievements/achievements_screen.dart';
import 'package:kust/core/net/auth_service.dart';
import 'package:kust/features/auth/login_screen.dart';
import 'package:kust/features/auth/register_screen.dart';
import 'package:kust/features/auth/verify_email_screen.dart';
import 'package:kust/features/onboarding/onboarding_screen.dart';
import 'package:kust/features/players/players_screen.dart';
import 'package:kust/features/game/game_screen.dart';
import 'package:kust/features/game/game_args.dart';
import 'package:kust/features/play/play_screen.dart';
import 'package:kust/features/profile/profile_screen.dart';
import 'package:kust/features/puzzles/puzzle_game_screen.dart';
import 'package:kust/features/history/history_screen.dart';
import 'package:kust/features/history/replay_screen.dart';
import 'package:kust/features/puzzles/puzzles_screen.dart';
import 'package:kust/features/train/train_opening_screen.dart';
import 'package:kust/features/train/train_screen.dart';
import 'package:kust/widgets/app_shell.dart';

GoRouter createRouter({required bool onboardingCompleted}) {
  return GoRouter(
    initialLocation: onboardingCompleted ? '/play' : '/onboarding',

    routes: [
      GoRoute(
        path: '/onboarding',
        // Keyed by the step, so coming back from signing in starts afresh.
        builder: (context, state) => OnboardingScreen(
          key: ValueKey(state.uri.queryParameters['step']),
          initialStep: switch (state.uri.queryParameters['step']) {
            'name' => 1,
            'level' => 2,
            _ => 0,
          },
        ),
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
            resume: args.resume,
            line: args.line,
            lineName: args.lineName,
            onLineDone: args.onLineDone,
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
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),

      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(next: state.uri.queryParameters['next']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            RegisterScreen(next: state.uri.queryParameters['next']),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) => VerifyEmailScreen(
          initialCooldown: state.extra is int ? state.extra as int : 0,
          next: state.uri.queryParameters['next'],
        ),
      ),
      GoRoute(
        path: '/players',
        redirect: (context, state) {
          final auth = AuthService.instance.state.value;
          if (auth.status == AuthStatus.signedOut) return '/login';
          if (auth.isSignedIn && !auth.isVerified) return '/verify';
          return null;
        },
        builder: (context, state) => const PlayersScreen(),
      ),

      GoRoute(
        path: '/train/:id',
        builder: (context, state) =>
            TrainOpeningScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/history/:id',
        builder: (context, state) => ReplayScreen(
          gameId: state.pathParameters['id']!,
          initialPly: int.tryParse(state.uri.queryParameters['ply'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/lesson/:id',
        builder: (context, state) =>
            LessonScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/review/:id',
        builder: (context, state) =>
            ReviewScreen(gameId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/review/:id/retry/:ply',
        builder: (context, state) => RetryScreen(
          gameId: state.pathParameters['id']!,
          ply: int.tryParse(state.pathParameters['ply']!) ?? 0,
        ),
      ),

      // The tabs stay built once visited, each in its own branch, so
      // switching back to one is instant; the hidden ones are paused.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/play',
                builder: (context, state) => const PlayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/puzzles',
                builder: (context, state) => const PuzzlesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learn',
                builder: (context, state) => const LearnScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/train',
                builder: (context, state) => const TrainScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
