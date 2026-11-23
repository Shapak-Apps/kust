import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kust/core/net/connection_service.dart';
import 'package:kust/l10n/app_locale.dart';
import 'package:kust/theme.dart';
import 'package:kust/widgets/offline_bar.dart';

/// A screen that reports the top padding it is given.
class _Probe extends StatelessWidget {
  const _Probe();

  static double top = -1;

  @override
  Widget build(BuildContext context) {
    top = MediaQuery.paddingOf(context).top;
    return const SizedBox.expand();
  }
}

Widget _app(ConnectionService service, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      theme: appTheme,
      locale: locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: kLocalizationDelegates,
      builder: (context, child) =>
          OfflineInsetHost(service: service, child: child!),
      home: const _Probe(),
    );

void main() {
  testWidgets('offline shows at the top and pushes the screen down', (
    tester,
  ) async {
    var reachable = true;
    final service = ConnectionService(probe: () async => reachable);
    await tester.pumpWidget(_app(service));
    service.start(observeLifecycle: false);
    await tester.pump();
    await tester.pumpAndSettle();
    final base = _Probe.top;
    expect(find.text("You're offline"), findsNothing);

    reachable = false;
    await tester.pump(const Duration(seconds: 21));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(service.status.value, ConnectionStatus.offline);
    expect(find.text("You're offline"), findsOneWidget);
    expect(tester.getTopLeft(find.text("You're offline")).dy, lessThan(40));
    expect(_Probe.top, base + kOfflineBarHeight);

    reachable = true;
    await service.checkNow();
    await tester.pumpAndSettle();
    expect(find.text('Back online'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Back online'), findsNothing);
    expect(_Probe.top, base);
    service.dispose();
  });

  testWidgets('speaks the app language', (tester) async {
    final service = ConnectionService(probe: () async => false);
    await tester.pumpWidget(_app(service, locale: const Locale('ru')));
    service.start(observeLifecycle: false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Вы не в сети'), findsOneWidget);
    service.dispose();
  });
}
