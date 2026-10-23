import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:Kust/ui/tokens.dart';

const Color primaryGold = KustTokens.gold;

ThemeData _build(KustTokens k, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: k.accent,
    onPrimary: k.accentInk,
    secondary: k.accent,
    onSecondary: k.accentInk,
    surface: k.bg,
    onSurface: k.ink,
    surfaceContainerHighest: k.surfaceAlt,
    outline: k.muted,
    outlineVariant: k.line,
    onSurfaceVariant: k.muted,
    error: k.danger,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: k.bg,
    canvasColor: k.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    visualDensity: VisualDensity.standard,
    dividerColor: k.line,
    // Cupertino-style push transition and swipe-back everywhere.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),
    textTheme: TextTheme(
      bodyLarge: k.body,
      bodyMedium: k.body.copyWith(fontSize: 14),
      bodySmall: k.caption,
      titleLarge: k.title,
      titleSmall: k.body.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: k.display,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: k.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KustSpace.rLarge),
        side: BorderSide(color: k.line),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: k.ink,
      contentTextStyle: k.body.copyWith(color: k.bg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KustSpace.rMedium),
      ),
    ),
    extensions: [k],
  );
}

final ThemeData appTheme = _build(KustTokens.light, Brightness.light);
final ThemeData appDarkTheme = _build(KustTokens.dark, Brightness.dark);
