import 'package:flutter/material.dart';

const Color primaryGold = Color(0xFFFFBB00);

const Color lightText = Color(0xFF181A1B);
const Color darkText = Color(0xFFFAFAFA);

const Color lightBackground = Color(0xFFF8F8F6);
const Color darkBackground = Color.fromARGB(255, 32, 32, 32);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  colorScheme: const ColorScheme.light(
    primary: primaryGold,
    onPrimary: lightText,
    secondary: primaryGold,
    onSecondary: lightText,
    surface: lightBackground,
    onSurface: lightText,
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
  ),

  scaffoldBackgroundColor: lightBackground,

  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: lightBackground,
    foregroundColor: lightText,
  ),

  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 16, color: lightText),
    bodyMedium: TextStyle(fontSize: 14, color: lightText),
    bodySmall: TextStyle(color: lightText),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    headlineMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: lightText,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    labelStyle: const TextStyle(color: lightText),
    hintStyle: TextStyle(color: lightText.withValues(alpha: 0.45)),
    prefixIconColor: lightText.withValues(alpha: 0.65),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);

final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  colorScheme: const ColorScheme.dark(
    primary: primaryGold,
    onPrimary: Color(0xFF000000),
    secondary: primaryGold,
    onSecondary: Color(0xFF000000),
    surface: darkBackground,
    onSurface: darkText,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
  ),

  scaffoldBackgroundColor: darkBackground,

  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: darkBackground,
    foregroundColor: darkText,
  ),

  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 16, color: darkText),
    bodyMedium: TextStyle(fontSize: 14, color: darkText),
    bodySmall: TextStyle(color: darkText),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: darkText,
    ),
    headlineMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: darkText,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    labelStyle: const TextStyle(color: darkText),
    hintStyle: TextStyle(color: darkText.withValues(alpha: 0.45)),
    prefixIconColor: darkText.withValues(alpha: 0.65),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);
