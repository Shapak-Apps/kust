import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kust/core/settings.dart';
import 'package:kust/features/onboarding/onboarding_screen.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';
import 'package:kust/ui/kust_button.dart';
import 'package:kust/widgets/more_sheet.dart';

Map<String, dynamic> _arb(String lang) =>
    jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String text) =>
    RegExp(r'\{([A-Za-z_]\w*)')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();

void main() {
  group('language from the phone', () {
    Locale pick(List<String> codes) =>
        resolveAppLocale([for (final c in codes) Locale(c)], kSupportedLocales);

    test(
      'Russian phone gets Russian',
      () => expect(pick(['ru']), const Locale('ru')),
    );
    test(
      'English phone gets English',
      () => expect(pick(['en']), const Locale('en')),
    );
    test(
      'Turkmen phone gets Turkmen',
      () => expect(pick(['tk']), const Locale('tk')),
    );
    test(
      'Turkish phone gets Turkmen',
      () => expect(pick(['tr']), const Locale('tk')),
    );
    test('anything else gets English', () {
      expect(pick(['de']), const Locale('en'));
      expect(pick([]), const Locale('en'));
    });
    test('the first language the person ranked that we have wins', () {
      expect(pick(['de', 'ru', 'en']), const Locale('ru'));
      expect(pick(['tr', 'en']), const Locale('tk'));
    });
  });

  group('translation files', () {
    final en = _arb('en');
    for (final lang in ['ru', 'tk']) {
      test('$lang has every English text, with the same placeholders', () {
        final other = _arb(lang);
        for (final key in en.keys.where((k) => !k.startsWith('@'))) {
          expect(other.containsKey(key), isTrue, reason: '$lang lacks $key');
          expect(
            _placeholders(other[key] as String),
            _placeholders(en[key] as String),
            reason: '$lang placeholders of $key',
          );
          expect(
            (other[key] as String).trim(),
            isNotEmpty,
            reason: '$lang $key',
          );
        }
      });
    }
  });

  testWidgets('Turkmen shows Turkmen texts and framework widgets still work', (
    tester,
  ) async {
    late String play;
    late String cancel;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tk'),
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationDelegates,
        home: Builder(
          builder: (context) {
            play = context.t.navPlay;
            cancel = MaterialLocalizations.of(context).cancelButtonLabel;
            return const Scaffold(body: TextField());
          },
        ),
      ),
    );
    expect(play, 'Oýna');
    expect(cancel, isNotEmpty); // borrowed from Turkish
    expect(tester.takeException(), isNull);
  });

  testWidgets('Russian plural for the daily streak', (tester) async {
    late AppL10n t;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationDelegates,
        home: Builder(
          builder: (context) {
            t = context.t;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(t.streakDays(1), '1 день');
    expect(t.streakDays(3), '3 дня');
    expect(t.streakDays(5), '5 дней');
  });

  for (final lang in ['ru', 'tk']) {
    testWidgets('onboarding in $lang fits a narrow phone', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 740 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          locale: Locale(lang),
          supportedLocales: kSupportedLocales,
          localizationsDelegates: kLocalizationDelegates,
          home: const OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final texts = lang == 'ru'
          ? 'Шахматы, которые помогают расти'
          : 'Gowulaşmaga kömek edýän şahmat';
      expect(find.text(texts), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Through the steps: the level cards, then the last page.
      await tester.tap(find.byType(KustButton).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(lang == 'ru' ? 'Любитель' : 'Orta'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(KustButton).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the language picker in settings changes the language', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    addTearDown(() => AppSettings.instance.setLanguage(null));
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ListenableBuilder(
        listenable: AppSettings.instance.language,
        builder: (context, _) {
          final code = AppSettings.instance.language.value;
          return MaterialApp(
            theme: appTheme,
            locale: code == null ? const Locale('en') : Locale(code),
            supportedLocales: kSupportedLocales,
            localizationsDelegates: kLocalizationDelegates,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showSettingsSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    expect(AppSettings.instance.language.value, 'ru');
    expect(find.text('Язык'), findsOneWidget); // the sheet follows at once
    expect(tester.takeException(), isNull);
  });
}
