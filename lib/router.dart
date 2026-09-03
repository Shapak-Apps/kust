import 'package:go_router/go_router.dart';
import 'package:kust/features/play/play_screen.dart';
import 'package:kust/features/puzzles/puzzles_screen.dart';
import 'package:kust/widgets/app_shell.dart';

final router = GoRouter(
  initialLocation: '/play',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/play',
          builder: (context, state) => PlayScreen(),
        ),
        GoRoute(
          path: '/puzzles',
          builder: (context, state) => PuzzlesScreen(),
        ),
      ],
    ),
  ],
);