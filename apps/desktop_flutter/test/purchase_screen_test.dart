import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('places the old purchase table directly on its tinted page',
      (tester) async {
    await _openPurchaseScreen(tester);

    expect(find.byKey(const Key('purchaseScreen')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTintBackground')), findsOneWidget);
    expect(find.byKey(const Key('purchaseItemsTable')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTableFit')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTableSurface')), findsOneWidget);
    expect(find.byKey(const Key('purchaseCode-r1')), findsOneWidget);
    expect(find.byKey(const Key('purchaseName-r1')), findsOneWidget);
    expect(find.byKey(const Key('purchaseWarehouse-r1')), findsOneWidget);
    expect(find.byKey(const Key('purchaseQuantity-r1')), findsOneWidget);
    expect(find.byKey(const Key('purchaseContainer-r1')), findsOneWidget);
    expect(find.byKey(const Key('purchasePurchasePrice-r1')), findsOneWidget);
    expect(find.byKey(const Key('purchaseDiscount-r1')), findsOneWidget);
    expect(find.byKey(const Key('purchaseSalePrice-r1')), findsOneWidget);
    expect(find.byKey(const Key('purchaseAdd-r1')), findsOneWidget);
    expect(find.byKey(const Key('purchaseQuantityTotal')), findsOneWidget);
    expect(find.byKey(const Key('purchaseSubtotal')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTotalCost')), findsOneWidget);

    final tableRect =
        tester.getRect(find.byKey(const Key('purchaseTableSurface')));
    final addButtonRect =
        tester.getRect(find.byKey(const Key('purchaseAdd-r1')));
    expect(addButtonRect.left, greaterThanOrEqualTo(tableRect.left - 0.5));
    expect(addButtonRect.right, lessThanOrEqualTo(tableRect.right + 0.5));
    expect(
      find.descendant(
        of: find.byKey(const Key('purchaseScreen')),
        matching: find.text('المشتريات'),
      ),
      findsOneWidget,
    );

    for (final removedKey in const [
      'purchaseHeaderPanel',
      'purchaseTablePanel',
      'purchaseTotalsPanel',
      'purchaseActionBar',
    ]) {
      expect(find.byKey(Key(removedKey)), findsNothing);
    }

    final expectedTint = Color.alphaBlend(
      AppModuleColors.purchases.withAlpha(12),
      AppColors.surface,
    );
    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('purchaseScreen')),
    );
    expect(shell.subtitle, isNull);
    expect(shell.backgroundColor, expectedTint);

    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byKey(const Key('purchaseScreen')),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, expectedTint);

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('purchaseScreen')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_purchases')), findsOneWidget);
  });
}

Future<void> _openPurchaseScreen(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const AlmumayazApp());
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byKey(const Key('dashboardCard_purchases')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
