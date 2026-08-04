import 'package:erp/app/app.dart';
import 'package:erp/core/config/app_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('environment customer profile cannot expose the Design System', () {
    const requestedEdition = String.fromEnvironment(
      'APP_EDITION',
      defaultValue: 'internal',
    );
    final configuration = AppConfiguration.fromEnvironment();

    if (requestedEdition.toLowerCase() == 'customer') {
      expect(configuration.edition, AppEdition.customer);
      expect(configuration.showDesignSystem, isFalse);
    } else {
      expect(configuration.edition, AppEdition.internal);
    }
  });

  testWidgets('customer About screen does not contain developer guide',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      AlmumayazApp(
        configuration: AppConfiguration.customer(
          enabledModules: const {
            AppModuleId.sales,
            AppModuleId.company,
            AppModuleId.about,
          },
        ),
      ),
    );
    await _login(tester);

    expect(find.byKey(const Key('dashboardCard_sales')), findsOneWidget);
    expect(find.byKey(const Key('dashboardCard_purchases')), findsNothing);
    await tester.tap(find.byKey(const Key('dashboardCard_about')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('aboutScreen')), findsOneWidget);
    expect(find.byKey(const Key('openDesignSystemGallery')), findsNothing);
    expect(find.text('دليل نظام التصميم'), findsNothing);
  });
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
}
