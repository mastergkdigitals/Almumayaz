import 'package:erp/app/app.dart';
import 'package:erp/core/config/app_configuration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('customer profile completes a backend-free desktop workflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1366, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      AlmumayazApp(
        configuration: AppConfiguration.customer(
          companyName: 'شركة الاختبار',
          enabledModules: const {
            AppModuleId.sales,
            AppModuleId.company,
            AppModuleId.about,
          },
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboardCard_sales')), findsOneWidget);
    expect(find.text('شركة الاختبار'), findsOneWidget);
    expect(find.byKey(const Key('dashboardCard_purchases')), findsNothing);

    await tester.tap(find.byKey(const Key('dashboardCard_sales')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('salesScreen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboardCard_about')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('aboutScreen')), findsOneWidget);
    expect(find.byKey(const Key('openDesignSystemGallery')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
