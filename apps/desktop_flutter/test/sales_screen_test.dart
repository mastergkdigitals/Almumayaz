import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('places the old sales table directly on its tinted page',
      (tester) async {
    await _openSalesScreen(tester);

    expect(find.byKey(const Key('salesScreen')), findsOneWidget);
    expect(find.byKey(const Key('salesTintBackground')), findsOneWidget);
    expect(find.byKey(const Key('salesItemsTable')), findsOneWidget);
    expect(find.byKey(const Key('salesTableSurface')), findsOneWidget);
    expect(find.byKey(const Key('salesCode-r1')), findsOneWidget);
    expect(find.byKey(const Key('salesName-r1')), findsOneWidget);
    expect(find.byKey(const Key('salesWarehouse-r1')), findsOneWidget);
    expect(find.byKey(const Key('salesQuantity-r1')), findsOneWidget);
    expect(find.byKey(const Key('salesSalePrice-r1')), findsOneWidget);
    expect(find.byKey(const Key('salesDiscount-r1')), findsOneWidget);
    expect(find.byKey(const Key('salesPriceAfterDiscount-r1')), findsOneWidget);
    expect(find.byKey(const Key('salesTotal-r1')), findsOneWidget);
    expect(find.byKey(const Key('salesAdd-r1')), findsOneWidget);
    expect(find.byKey(const Key('salesQuantityTotal')), findsOneWidget);
    expect(find.byKey(const Key('salesDiscountTotal')), findsOneWidget);
    expect(find.byKey(const Key('salesTotal')), findsOneWidget);

    final expectedTint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );
    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('salesScreen')),
    );
    expect(shell.subtitle, isNull);
    expect(shell.backgroundColor, expectedTint);

    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byKey(const Key('salesScreen')),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, expectedTint);

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('salesScreen')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_sales')), findsOneWidget);
  });
}

Future<void> _openSalesScreen(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const AlmumayazApp());
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byKey(const Key('dashboardCard_sales')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
