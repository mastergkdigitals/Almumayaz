import 'package:erp/app/app.dart';
import 'package:erp/core/config/app_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supportedViewports = <Size>[
    Size(1280, 720),
    Size(1366, 768),
    Size(1920, 1080),
    Size(2560, 1440),
  ];

  for (final viewport in supportedViewports) {
    testWidgets(
      'dashboard remains usable at '
      '${viewport.width.toInt()}x${viewport.height.toInt()}',
      (tester) async {
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          AlmumayazApp(configuration: AppConfiguration.internal()),
        );
        await tester.enterText(
          find.byKey(const Key('usernameField')),
          'admin',
        );
        await tester.enterText(
          find.byKey(const Key('passwordField')),
          'password',
        );
        await tester.tap(find.byKey(const Key('loginButton')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dashboardCard_purchases')), findsOneWidget);
        expect(find.byKey(const Key('dashboardCard_sales')), findsOneWidget);
        expect(find.byKey(const Key('dashboardCard_about')), findsOneWidget);

        final viewportRect = Offset.zero & viewport;
        for (final module in AppModuleId.values) {
          final card = find.byKey(Key('dashboardCard_${module.name}'));
          expect(card, findsOneWidget);
          expect(
            tester.getRect(card).overlaps(viewportRect),
            isTrue,
            reason: '${module.name} must remain inside the visible dashboard',
          );
        }

        await tester.tap(find.byKey(const Key('dashboardCard_sales')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('salesScreen')), findsOneWidget);
        expect(find.byKey(const Key('salesItemsTable')), findsOneWidget);
        expect(find.byKey(const Key('salesActionBar')), findsOneWidget);
        expect(
          tester
              .getRect(find.byKey(const Key('salesActionBar')))
              .overlaps(viewportRect),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
