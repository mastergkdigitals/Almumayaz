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
      expect(dropdown.textDirection, TextDirection.rtl);
      expect(dropdown.textAlign, TextAlign.right);
      expect(dropdown.menuTextDirection, TextDirection.rtl);
    }

    final saleTypeDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(const Key('salesTypeField')),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(
      saleTypeDropdown.options.map((option) => option.label),
      containsAllInOrder(['نقدي', 'آجل', 'أقساط']),
    );

    for (final key in [
      'salesInvoiceNumberField',
      'salesDateField',
      'salesTimeField',
      'salesExchangeRateField',
      ...secondRowKeys,
      ...totalsRowKeys,
    ]) {
      final textField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(TextField),
        ),
      );
      expect(
        textField.textDirection,
        TextDirection.rtl,
        reason: '$key must remain RTL outside the invoice table.',
      );
      expect(
        textField.textAlign,
        TextAlign.right,
        reason: '$key must align its value to the RTL side.',
      );
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
    expect(find.byKey(const Key('salesSearchField')), findsNothing);

    const invoiceButtons = <String, (IconData, String)>{
      'salesSearchButton': (Icons.search_rounded, 'بحث'),
      'salesPrintButton': (Icons.print_rounded, 'طباعة'),
      'salesInstallmentsButton': (
        Icons.table_chart_rounded,
        'جدول الأقساط',
      ),
      'salesStatementButton': (
        Icons.receipt_long_rounded,
        'كشف الحساب',
      ),
    };
    for (final entry in invoiceButtons.entries) {
      final finder = find.byKey(Key(entry.key));
      expect(finder, findsOneWidget);

      final button = tester.widget<AppHeaderIconButton>(finder);
      expect(button.icon, entry.value.$1);
      expect(button.tooltip, entry.value.$2);
      expect(tester.getSize(finder), const Size.square(52));
    }
    expect(
      tester
          .widget<AppHeaderIconButton>(
            find.byKey(const Key('salesInstallmentsButton')),
          )
          .onPressed,
      isNull,
    );
    _expectRightToLeftOrder(tester, invoiceButtons.keys.toList());

    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '103');
    expect(_fieldValue(tester, 'salesCustomerNameField'), 'أسواق دجلة');
    expect(
      _fieldValue(tester, 'appSalesInvoiceTemplateNameField-r1'),
      'دفتر ملاحظات',
    );

    for (final key in const [
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

  testWidgets('updates installments availability and total currency labels',
      (tester) async {
    await _openSalesScreen(tester);

    AppHeaderIconButton installmentsButton() {
      return tester.widget<AppHeaderIconButton>(
        find.byKey(const Key('salesInstallmentsButton')),
      );
    }

    expect(installmentsButton().onPressed, isNull);
    expect(_fieldLabel(tester, 'salesTotalIqdField'), 'المجموع دينار');
    expect(
      _fieldLabel(tester, 'salesRemainingIqdField'),
      'المتبقي دينار',
    );
    expect(
      _fieldLabel(tester, 'salesCurrentBalanceIqdField'),
      'الرصيد الحالي دينار',
    );

    final saleTypeDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(const Key('salesTypeField')),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    saleTypeDropdown.onChanged('أقساط');
    await tester.pump();
    expect(installmentsButton().onPressed, isNotNull);

    final currencyDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(const Key('salesCurrencyField')),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    currencyDropdown.onChanged('USD');
    await tester.pump();

    expect(_fieldLabel(tester, 'salesTotalIqdField'), 'المجموع دولار');
    expect(
      _fieldLabel(tester, 'salesRemainingIqdField'),
      'المتبقي دولار',
    );
    expect(
      _fieldLabel(tester, 'salesCurrentBalanceIqdField'),
      'الرصيد الحالي دولار',
    );

    tester
        .widget<AppDropdownField<String>>(
          find.ancestor(
            of: find.byKey(const Key('salesTypeField')),
            matching: find.byType(AppDropdownField<String>),
          ),
        )
        .onChanged('نقدي');
    await tester.pump();
    expect(installmentsButton().onPressed, isNull);
  });

  testWidgets('uses the Sales color in the shared date picker',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.tap(find.byKey(const Key('salesDateField')));
    await tester.pump();

    expect(find.byKey(const Key('appDatePickerDialog')), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appDatePickerConfirm')),
          )
          .backgroundColor,
      AppModuleColors.sales,
    );

    await tester.tap(find.byKey(const Key('appDatePickerCancel')));
    await tester.pump();
  });

  testWidgets('opens the sales-colored invoice search dialog',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.tap(find.byKey(const Key('salesSearchButton')));
    await tester.pumpAndSettle();

    final dialog = find.byKey(const Key('salesRecordSearchDialog'));
    expect(dialog, findsOneWidget);
    final moduleDialog = tester.widget<AppModuleDialog>(dialog);
    expect(moduleDialog.title, 'بحث قوائم البيع');
    expect(moduleDialog.subtitle, 'ابحث عن قائمة بيع محفوظة ثم اخترها');
    expect(moduleDialog.accentColor, AppModuleColors.sales);

    final searchDecoration = tester
        .widget<InputDecorator>(
          find.descendant(
            of: find.byKey(const Key('salesRecordSearchField')),
            matching: find.byType(InputDecorator),
          ),
        )
        .decoration;
    expect(searchDecoration.labelText, 'بحث في قوائم البيع');
    expect(
      searchDecoration.hintText,
      'رقم القائمة أو اسم الزبون أو اسم المادة',
    );
    expect(
      find.descendant(of: dialog, matching: find.text('أسواق دجلة')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('salesRecordSearchField')),
      'دجلة',
    );
    await tester.pump();

    expect(
      find.byKey(const Key('salesRecordSearchResult-0')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('أحمد كريم')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const Key('salesRecordSearchResult-0')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(dialog, findsNothing);
  });

  testWidgets('loads a complete demo invoice from Sales search',
      (tester) async {
    await _openSalesScreen(tester);

    await tester.tap(find.byKey(const Key('salesSearchButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('salesRecordSearchField')),
      '102',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('salesRecordSearchResult-0')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '102');
    expect(_fieldValue(tester, 'salesCustomerNameField'), 'أحمد كريم');
    expect(_fieldValue(tester, 'salesReceivedField'), '250');
    expect(_fieldLabel(tester, 'salesTotalIqdField'), 'المجموع دولار');
    expect(
      tester
          .widget<AppHeaderIconButton>(
            find.byKey(const Key('salesInstallmentsButton')),
          )
          .onPressed,
      isNotNull,
    );

    final tableValues = tester
        .widgetList<EditableText>(
          find.descendant(
            of: find.byKey(const Key('salesItemsTable')),
            matching: find.byType(EditableText),
          ),
        )
        .map((field) => field.controller.text);
    expect(tableValues, contains('طابعة حرارية'));
    expect(tableValues, contains('ماسح باركود'));
  });

  testWidgets('opens sales statement options and report', (tester) async {
    await _openSalesScreen(tester);

    await tester.enterText(
      find.byKey(const Key('salesCustomerNameField')),
      'أسواق دجلة',
    );
    await tester.tap(find.byKey(const Key('salesStatementButton')));
    await tester.pumpAndSettle();

    final optionsDialog =
        find.byKey(const Key('appStatementOptionsDialog'));
    expect(optionsDialog, findsOneWidget);
    expect(
      tester.widget<AppModuleDialog>(optionsDialog).accentColor,
      AppModuleColors.sales,
    );

    final partyField = find.byKey(const Key('appStatementParty'));
    final partyInput = tester.widget<EditableText>(
      find.descendant(of: partyField, matching: find.byType(EditableText)),
    );
    expect(partyInput.controller.text, 'أسواق دجلة');
    expect(
      tester
          .widget<InputDecorator>(
            find.descendant(
              of: partyField,
              matching: find.byType(InputDecorator),
            ),
          )
          .decoration
          .labelText,
      'اسم الزبون',
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('appStatementConfirm')),
          )
          .backgroundColor,
      AppModuleColors.sales,
    );

    await tester.tap(find.byKey(const Key('appStatementConfirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final report = find.byKey(const Key('appStatementReportDialog'));
    expect(report, findsOneWidget);
    expect(
      tester.widget<AppModuleDialog>(report).accentColor,
      AppModuleColors.sales,
    );
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('appStatementReportTable')),
          )
          .accentColor,
      AppModuleColors.sales,
    );
    expect(
      find.descendant(of: report, matching: find.text('أسواق دجلة')),
      findsOneWidget,
    );
  });
}

String _fieldValue(WidgetTester tester, String key) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}

String? _fieldLabel(WidgetTester tester, String key) {
  return tester
      .widget<TextField>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(TextField),
        ),
      )
      .decoration
      ?.labelText;
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
