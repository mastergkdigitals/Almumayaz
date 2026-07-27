import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds the clipped sales grid directly on its tinted page',
      (tester) async {
    await _openSalesScreen(tester);

    expect(find.byKey(const Key('salesScreen')), findsOneWidget);
    expect(find.byKey(const Key('salesTintBackground')), findsOneWidget);
    expect(find.byKey(const Key('salesItemsTable')), findsOneWidget);
    expect(find.byKey(const Key('salesTableSurface')), findsOneWidget);
    expect(find.byKey(const Key('salesTableHeader')), findsOneWidget);
    expect(find.byKey(const Key('salesTableSummary')), findsOneWidget);
    expect(find.byKey(const Key('appInvoiceTableHeader')), findsNothing);
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
    expect(find.byKey(const Key('salesCodeCell-r1')), findsOneWidget);
    expect(find.byKey(const Key('salesNameCell-r1')), findsOneWidget);
    expect(find.byKey(const Key('salesWarehouseCell-r1')), findsOneWidget);

    final codeField = tester.widget<TextField>(
      find.byKey(const Key('salesCode-r1')),
    );
    expect(codeField.decoration?.filled, isFalse);
    expect(codeField.decoration?.fillColor, Colors.transparent);
    final codeCell = tester.widget<Container>(
      find.byKey(const Key('salesCodeCell-r1')),
    );
    expect(codeCell.clipBehavior, Clip.antiAlias);
    expect(codeCell.foregroundDecoration, isA<BoxDecoration>());

    final tableRect =
        tester.getRect(find.byKey(const Key('salesTableSurface')));
    final addButtonRect =
        tester.getRect(find.byKey(const Key('salesAdd-r1')));
    expect(addButtonRect.left, greaterThanOrEqualTo(tableRect.left - 0.5));
    expect(addButtonRect.right, lessThanOrEqualTo(tableRect.right + 0.5));
    await tester.tap(find.byKey(const Key('salesCode-r1')));
    await tester.pump();
    final codeRect =
        tester.getRect(find.byKey(const Key('salesCodeCell-r1')));
    final nameRect =
        tester.getRect(find.byKey(const Key('salesNameCell-r1')));
    final warehouseRect =
        tester.getRect(find.byKey(const Key('salesWarehouseCell-r1')));
    expect(codeRect.overlaps(nameRect), isFalse);
    expect(nameRect.overlaps(warehouseRect), isFalse);
    final focusedCell = tester.widget<Container>(
      find.byKey(const Key('salesCodeCell-r1')),
    );
    final focusedDecoration =
        focusedCell.foregroundDecoration! as BoxDecoration;
    final focusedBorder = focusedDecoration.border! as Border;
    expect(focusedBorder.top.color, AppModuleColors.sales);
    expect(focusedBorder.top.width, 1.5);

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
    final tintBackground = tester.widget<ColoredBox>(
      find.byKey(const Key('salesTintBackground')),
    );
    expect(tintBackground.color, expectedTint);

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
