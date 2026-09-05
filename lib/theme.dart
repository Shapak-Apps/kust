import 'package:flutter/material.dart';

const Color primaryGold = Color(0xFFFFBB00);
const Color secondaryGreen = Color(0xFF2E7D32);

const Color lightText = Color(0xFF181A1B);
const Color darkText = Color(0xFFFAFAFA);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryGold,
    brightness: Brightness.light,
  ).copyWith(secondary: secondaryGreen),

  scaffoldBackgroundColor: const Color(0xFFF8F8F6),

  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Color(0xFFF8F8F6),
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

  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryGold,
    brightness: Brightness.dark,
  ).copyWith(secondary: secondaryGreen),

  scaffoldBackgroundColor: const Color(0xFF101112),

  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Color(0xFF101112),
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
