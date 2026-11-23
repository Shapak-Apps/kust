import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/net/connection_service.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';
import 'package:kust/ui/kust_nav_bar.dart';
import 'package:kust/widgets/offline_bar.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: appTheme,
  locale: locale,
  supportedLocales: kSupportedLocales,
  localizationsDelegates: kLocalizationDelegates,
  home: Scaffold(
    body: Align(alignment: Alignment.bottomCenter, child: child),
  ),
);

double _height(WidgetTester tester) =>
    tester.getSize(find.byType(OfflineBar)).height;

void main() {
  testWidgets('hidden while online, shown when offline, then restored', (
    tester,
  ) async {
    var reachable = true;
    final service = ConnectionService(probe: () async => reachable);
    await tester.pumpWidget(_app(OfflineBar(service: service)));
    service.start(observeLifecycle: false);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_height(tester), 0);

    reachable = false;
    await tester.pump(const Duration(seconds: 21));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(service.status.value, ConnectionStatus.offline);
    expect(_height(tester), kOfflineBarHeight);
    expect(find.text("You're offline"), findsOneWidget);

    reachable = true;
    for (var i = 0; i < 12; i++) {
      if (service.status.value == ConnectionStatus.restored) break;
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Back online'), findsOneWidget);
    expect(_height(tester), kOfflineBarHeight);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(_height(tester), 0);

    service.dispose();
  });

  testWidgets('speaks the app language', (tester) async {
    final service = ConnectionService(probe: () async => false);
    await tester.pumpWidget(
      _app(OfflineBar(service: service), locale: const Locale('ru')),
    );
    service.start(observeLifecycle: false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Вы не в сети'), findsOneWidget);
    service.dispose();
  });

  testWidgets('the nav bar shows the footer under its tabs', (tester) async {
    await tester.pumpWidget(
      _app(
        KustNavBar(
          selectedIndex: 0,
          onSelected: (_) {},
          items: const [
            KustNavItem(Icons.home_outlined, Icons.home, 'Home'),
            KustNavItem(Icons.search, Icons.search, 'Search'),
          ],
          footer: const Text('footer here'),
        ),
      ),
    );
    final tab = tester.getBottomLeft(find.text('Home')).dy;
    final footer = tester.getTopLeft(find.text('footer here')).dy;
    expect(footer, greaterThan(tab));
  });

  testWidgets('clearance grows by the strip height only while it shows', (
    tester,
  ) async {
    double? hidden;
    double? shown;
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            OfflineInset(
              visible: false,
              child: Builder(
                builder: (context) {
                  hidden = KustNavBar.clearance(context);
                  return const SizedBox();
                },
              ),
            ),
            OfflineInset(
              visible: true,
              child: Builder(
                builder: (context) {
                  shown = KustNavBar.clearance(context);
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
    expect(shown! - hidden!, kOfflineBarHeight);
  });
}
