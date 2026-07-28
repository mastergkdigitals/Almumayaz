import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds the shared sales invoice layout', (tester) async {
    await _openSalesScreen(tester);

    expect(find.byKey(const Key('salesScreen')), findsOneWidget);
    expect(find.byKey(const Key('salesTintBackground')), findsOneWidget);

    const firstRowKeys = [
      'salesInvoiceNumberField',
      'salesDateField',
      'salesTimeField',
      'salesWarehouseField',
      'salesTypeField',
      'salesCurrencyField',
      'salesExchangeRateField',
    ];
    const secondRowKeys = [
      'salesCustomerNameField',
      'salesNotesField',
    ];
    const totalsRowKeys = [
      'salesDriverNameField',
      'salesInvoiceDiscountField',
      'salesDiscountPercentageField',
      'salesReceivedField',
      'salesTotalIqdField',
      'salesRemainingIqdField',
      'salesCurrentBalanceIqdField',
    ];

    for (final key in [
      ...firstRowKeys,
      ...secondRowKeys,
      ...totalsRowKeys,
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }

    _expectRightToLeftOrder(tester, firstRowKeys);
    _expectRightToLeftOrder(tester, secondRowKeys);
    _expectRightToLeftOrder(tester, totalsRowKeys);

    for (final key in const [
      'salesWarehouseField',
      'salesTypeField',
      'salesCurrencyField',
    ]) {
      final dropdown = tester.widget<AppDropdownField<String>>(
        find.ancestor(
          of: find.byKey(Key(key)),
          matching: find.byType(AppDropdownField<String>),
        ),
      );
      expect(dropdown.useIntrinsicHeight, isTrue);
      expect(dropdown.accentColor, AppModuleColors.sales);
    }

    expect(find.byKey(const Key('salesItemsTable')), findsOneWidget);
    expect(
      find.byKey(const Key('appSalesInvoiceTableTemplate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appSalesInvoiceTableHeader')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appSalesInvoiceTableSummary')),
      findsOneWidget,
    );

    expect(find.byKey(const Key('salesActionBar')), findsOneWidget);
    for (final key in const [
      'salesSearchField',
      'salesFirstButton',
      'salesPreviousButton',
      'salesNextButton',
      'salesLastButton',
      'salesSaveButton',
      'salesUpdateButton',
      'salesUndoButton',
      'salesDeleteButton',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }

    final expectedTint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );
    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('salesScreen')),
    );
    expect(shell.subtitle, isNull);
    expect(shell.backgroundColor, expectedTint);

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

void _expectRightToLeftOrder(
  WidgetTester tester,
  List<String> keys,
) {
  for (var index = 1; index < keys.length; index++) {
    final previous = tester.getTopLeft(find.byKey(Key(keys[index - 1])));
    final current = tester.getTopLeft(find.byKey(Key(keys[index])));
    expect(previous.dx, greaterThan(current.dx));
    expect(previous.dy, closeTo(current.dy, 0.1));
  }
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
