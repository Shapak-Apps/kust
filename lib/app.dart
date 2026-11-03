import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:kust/features/achievements/achievement_toast.dart';
import 'package:kust/core/settings.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';

/// Bouncy scrolling everywhere, no Android glow.
class _KustScrollBehavior extends MaterialScrollBehavior {
  const _KustScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSettings.instance.themeMode,
        AppSettings.instance.language,
      ]),
      builder: (context, _) {
        final mode = AppSettings.instance.themeMode.value;
        final language = AppSettings.instance.language.value;
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: appTheme,
          darkTheme: appDarkTheme,
          themeMode: AppSettings.forceDark ? ThemeMode.dark : mode,
          scrollBehavior: const _KustScrollBehavior(),
          // A language picked in settings wins; otherwise the phone's.
          locale: language == null ? null : Locale(language),
          supportedLocales: kSupportedLocales,
          localizationsDelegates: kLocalizationDelegates,
          localeListResolutionCallback: resolveAppLocale,
          builder: (context, child) {
            AppText.sync(AppL10n.of(context));
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark,
              child: AchievementToastHost(child: child!),
            );
          },
        );
      },
    );
  }
}
