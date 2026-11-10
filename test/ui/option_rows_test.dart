import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/l10n/app_locale.dart';
import 'package:kust/l10n/gen/app_localizations.dart';
import 'package:kust/theme.dart';
import 'package:kust/ui/kust_controls.dart';

void main() {
  testWidgets('option rows in a list are the same height in Turkmen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: appDarkTheme,
        locale: const Locale('tk'),
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final t = lookupAppL10n(const Locale('tk'));
              final rows = [
                (t.boardImage, t.boardImageSub),
                (t.copyFen, t.copyFenSub),
                (t.copyPgn, t.copyPgnSub),
                (t.sharePgn, t.sharePgnSub),
                (t.playWithBots, t.playWithBotsSub),
                (t.playLocally, t.playLocallySub),
              ];
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  for (final (i, r) in rows.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: KustOption(
                        key: ValueKey(i),
                        title: r.$1,
                        subtitle: r.$2,
                        leading: const KustIconTile(
                          Icons.image_rounded,
                          color: Color(0xFF5AA9E6),
                        ),
                        onTap: () {},
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final heights = {
      for (var i = 0; i < 6; i++)
        tester.getSize(find.byKey(ValueKey(i))).height,
    };
    expect(heights, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
