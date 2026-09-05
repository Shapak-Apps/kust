import 'package:flutter/material.dart';

const Color primaryGreen = Color(0xFF2E7D32);
const Color accentGold = Color(0xFFCD9600);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryGreen,
    brightness: Brightness.light,
  ).copyWith(secondary: accentGold),

  scaffoldBackgroundColor: const Color(0xFFF8F8F6),

  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),

  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);
