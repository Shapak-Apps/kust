import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Kust/app.dart';
import 'package:Kust/router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  final router = createRouter(onboardingCompleted: onboardingCompleted);

  runApp(ProviderScope(child: MyApp(router: router)));
}
