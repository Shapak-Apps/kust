import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:Kust/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
