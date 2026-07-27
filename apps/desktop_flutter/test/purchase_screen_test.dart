import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds the clipped purchase grid on its tinted page',
      (tester) async {
    await _openPurchaseScreen(tester);

    expect(find.byKey(const Key('purchaseScreen')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTintBackground')), findsOneWidget);
    expect(find.byKey(const Key('purchaseItemsTable')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTableFit')), findsNothing);
    expect(find.byKey(const Key('purchaseTableSurface')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTableHeader')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTableSummary')), findsOneWidget);
    expect(find.byKey(const Key('purchaseHorizontalScroll')), findsOneWidget);
    expect(find.byKey(const Key('appInvoiceTableHeader')), findsNothing);
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
    expect(find.byKey(const Key('purchaseDiscountTotal')), findsOneWidget);
    expect(find.byKey(const Key('purchaseSubtotal')), findsOneWidget);
    expect(find.byKey(const Key('purchaseTotalCost')), findsOneWidget);
    expect(find.byKey(const Key('purchaseCodeCell-r1')), findsOneWidget);
    expect(find.byKey(const Key('purchaseNameCell-r1')), findsOneWidget);
    expect(
      find.byKey(const Key('purchaseWarehouseCell-r1')),
      findsOneWidget,
    );

    final horizontalScroll = tester.widget<SingleChildScrollView>(
      find.byKey(const Key('purchaseHorizontalScroll')),
    );
    expect(horizontalScroll.scrollDirection, Axis.horizontal);
    final codeField = tester.widget<TextField>(
      find.byKey(const Key('purchaseCode-r1')),
    );
    expect(codeField.decoration?.filled, isFalse);
    expect(codeField.decoration?.fillColor, Colors.transparent);
    expect(codeField.textAlignVertical, TextAlignVertical.center);
    expect(codeField.style?.height, kTextHeightNone);
    final codeCell = tester.widget<Container>(
      find.byKey(const Key('purchaseCodeCell-r1')),
    );
    expect(codeCell.clipBehavior, Clip.antiAlias);
    expect(codeCell.foregroundDecoration, isA<BoxDecoration>());

    await tester.tap(find.byKey(const Key('purchaseCode-r1')));
    await tester.pump();
    final codeRect =
        tester.getRect(find.byKey(const Key('purchaseCodeCell-r1')));
    final nameRect =
        tester.getRect(find.byKey(const Key('purchaseNameCell-r1')));
    final warehouseRect = tester.getRect(
      find.byKey(const Key('purchaseWarehouseCell-r1')),
    );
    expect(codeRect.overlaps(nameRect), isFalse);
    expect(nameRect.overlaps(warehouseRect), isFalse);
    final focusedCell = tester.widget<Container>(
      find.byKey(const Key('purchaseCodeCell-r1')),
    );
    final focusedDecoration =
        focusedCell.foregroundDecoration! as BoxDecoration;
    final focusedBorder = focusedDecoration.border! as Border;
    expect(focusedBorder.top.color, isNot(AppModuleColors.purchases));
    expect(focusedBorder.top.width, 1);

    await tester.tap(find.byKey(const Key('purchaseWarehouse-r1')));
    await tester.pump();
    final warehouseMenu = tester.widget<DecoratedBox>(
      find.byKey(const Key('purchaseWarehouseMenu')),
    );
    final warehouseMenuDecoration =
        warehouseMenu.decoration as BoxDecoration;
    expect(
      warehouseMenuDecoration.borderRadius,
      BorderRadius.circular(AppRadii.md),
    );
    expect(
      (warehouseMenuDecoration.border! as Border).top.color,
      AppColors.border,
    );
    await tester.tap(find.byKey(const Key('purchaseWarehouse-r1')));
    await tester.pump();

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
    final tintBackground = tester.widget<ColoredBox>(
      find.byKey(const Key('purchaseTintBackground')),
    );
    expect(tintBackground.color, expectedTint);

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
