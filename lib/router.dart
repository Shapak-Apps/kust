import 'package:go_router/go_router.dart';
import 'package:kust/features/home/home_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [GoRoute(path: '/', builder: (context, state) => HomeScreen())],
);
