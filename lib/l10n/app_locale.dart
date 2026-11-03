import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:kust/l10n/gen/app_localizations.dart';

export 'package:kust/l10n/gen/app_localizations.dart';

/// The languages of the app: English, Russian and Turkmen.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('ru'),
  Locale('tk'),
];

/// Picks the app's language from the phone's languages, in the order the
/// person ranked them: Russian for a Russian phone, Turkmen for a Turkmen
/// phone and also for a Turkish one (many people in Turkmenistan set their
/// phone to Turkish), English for anything else.
Locale resolveAppLocale(List<Locale>? phone, Iterable<Locale> supported) {
  for (final locale in phone ?? const <Locale>[]) {
    switch (locale.languageCode) {
      case 'ru':
        return const Locale('ru');
      case 'tk':
      case 'tr':
        return const Locale('tk');
      case 'en':
        return const Locale('en');
    }
  }
  return const Locale('en');
}

/// Flutter's own texts (the date picker, "Copy" in a text field, screen
/// reader labels) have no Turkmen. This borrows the Turkish ones for it.
class _TurkmenAsTurkish<T> extends LocalizationsDelegate<T> {
  const _TurkmenAsTurkish(this.base);

  final LocalizationsDelegate<T> base;

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'tk' || base.isSupported(locale);

  @override
  Future<T> load(Locale locale) =>
      base.load(locale.languageCode == 'tk' ? const Locale('tr') : locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<T> old) => false;
}

/// Every delegate the app needs.
const List<LocalizationsDelegate<dynamic>> kLocalizationDelegates = [
  AppL10n.delegate,
  _TurkmenAsTurkish<MaterialLocalizations>(
    GlobalMaterialLocalizations.delegate,
  ),
  _TurkmenAsTurkish<WidgetsLocalizations>(GlobalWidgetsLocalizations.delegate),
  _TurkmenAsTurkish<CupertinoLocalizations>(
    GlobalCupertinoLocalizations.delegate,
  ),
];

/// The texts in the language in use, for code that has no [BuildContext]
/// (a game's result message, an achievement's name). Kept current by
/// [syncAppText] whenever the app builds.
class AppText {
  AppText._();

  static AppL10n _current = lookupAppL10n(const Locale('en'));

  static AppL10n get now => _current;

  static void sync(AppL10n texts) => _current = texts;
}

extension AppL10nContext on BuildContext {
  /// The texts in the language in use; asking for them makes the widget
  /// rebuild when the language changes. Without localizations above (a
  /// widget shown on its own) it is English.
  AppL10n get t => Localizations.of<AppL10n>(this, AppL10n) ?? AppText.now;
}
