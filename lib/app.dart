import 'package:flutter/material.dart';

import 'package:Kust/router.dart';
import 'package:Kust/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
