import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/reports/presentation/reports_demo_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps saved Sales and Purchase lists status-free', () {
    for (final reportId in ['salesInvoices', 'purchaseInvoices']) {
      final report = reportDefinitions.singleWhere(
        (candidate) => candidate.id == reportId,
      );
      final variant = report.variants.single;

      expect(
        variant.filters.map((filter) => filter.id),
        isNot(contains('status')),
      );
      expect(
        variant.columns.map((column) => column.label),
        isNot(contains('الحالة')),
      );
      for (final row in variant.rows) {
        expect(row.filterValues.containsKey('status'), isFalse);
        expect(row.cells, hasLength(variant.columns.length));
      }
    }
  });

  testWidgets('opens the seven-section Reports hub', (tester) async {
    await _openReports(tester);

    expect(find.byKey(const Key('reportsScreen')), findsOneWidget);
    expect(find.byKey(const Key('reportsHub')), findsOneWidget);

    final firstRow = find.byKey(const Key('reportsHubRow_0'));
    final secondRow = find.byKey(const Key('reportsHubRow_1'));
    final lastRow = find.byKey(const Key('reportsHubRow_2'));
    expect(firstRow, findsOneWidget);
    expect(secondRow, findsOneWidget);
    expect(lastRow, findsOneWidget);
    for (final report in reportDefinitions.take(3)) {
      expect(
        find.descendant(
          of: firstRow,
          matching: find.byKey(Key('reportSectionCard_${report.id}')),
        ),
        findsOneWidget,
      );
    }
    for (final report in reportDefinitions.skip(3).take(3)) {
      expect(
        find.descendant(
          of: secondRow,
          matching: find.byKey(Key('reportSectionCard_${report.id}')),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: lastRow,
        matching: find.byKey(
          Key('reportSectionCard_${reportDefinitions.last.id}'),
        ),
      ),
      findsOneWidget,
    );

    for (final report in reportDefinitions) {
      expect(
        find.byKey(Key('reportSectionCard_${report.id}')),
        findsOneWidget,
      );
      expect(find.text(report.title), findsOneWidget);
    }

    final expectedTint = Color.alphaBlend(
      AppModuleColors.reports.withAlpha(12),
      AppColors.surface,
    );
    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('reportsScreen')),
    );
    expect(shell.title, 'التقارير');
    expect(shell.backgroundColor, expectedTint);
    expect(
      tester
          .widget<ColoredBox>(
            find.byKey(const Key('reportsTintBackground')),
          )
          .color,
      expectedTint,
    );

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reportsScreen')), findsNothing);
    expect(
      find.byKey(const Key('dashboardCard_reports')),
      findsOneWidget,
    );
  });

  testWidgets('opens every report with shared controls and themed table',
      (tester) async {
    await _openReports(tester);

    for (final report in reportDefinitions) {
      await _openReport(tester, report.id);

      expect(
        find.byKey(Key('reportContent_${report.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('reportFiltersPanel_${report.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('reportSelector_${report.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('reportSummaryPanel_${report.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('reportSearch_${report.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('reportShowButton_${report.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('reportResetButton_${report.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('reportPrintButton_${report.id}')),
        findsOneWidget,
      );

      final variant = report.variants.first;
      final table = tester.widget<AppDataTable>(
        find.byKey(Key('reportTable_${report.id}_${variant.id}')),
      );
      expect(table.accentColor, report.palette.middle);
      expect(
        table.columns.map((column) => column.label),
        variant.columns.map((column) => column.label),
      );
      expect(table.rows, isNotEmpty);

      await _returnToReportsHub(tester);
      expect(
        find.byKey(
          Key('reportContent_${report.id}'),
          skipOffstage: false,
        ),
        findsNothing,
      );
    }
  });

  testWidgets('filters, resets and prints Sales demo report',
      (tester) async {
    await _openReports(tester);
    await _openReport(tester, 'salesInvoices');

    final searchField =
        find.byKey(const Key('reportSearch_salesInvoices'));
    await tester.enterText(searchField, 'أحمد');
    await tester.pump();

    AppDataTable salesTable() => tester.widget<AppDataTable>(
          find.byKey(
            const Key('reportTable_salesInvoices_main'),
          ),
        );

    expect(salesTable().rows, hasLength(1));
    expect(
      (salesTable().rows.single.cells[3] as Text).data,
      'أحمد كريم',
    );

    final currencyField =
        find.byKey(const Key('reportFilter_salesInvoices_currency'));
    tester
        .widget<AppDropdownField<String>>(
          find.ancestor(
            of: currencyField,
            matching: find.byType(AppDropdownField<String>),
          ),
        )
        .onChanged('USD');
    await tester.pump();
    expect(salesTable().rows, hasLength(1));

    await tester.tap(
      find.byKey(const Key('reportResetButton_salesInvoices')),
    );
    await tester.pump();
    expect(_fieldText(tester, searchField), isEmpty);
    expect(salesTable().rows, hasLength(3));
    expect(
      _dropdown(tester, currencyField).value,
      'all',
    );
    await _finishToast(tester);

    await tester.tap(
      find.byKey(const Key('reportPrintButton_salesInvoices')),
    );
    await tester.pump();
    expect(find.byKey(const Key('appToast')), findsOneWidget);
    expect(
      find.text('تم تجهيز معاينة طباعة تقرير قوائم المبيعات'),
      findsOneWidget,
    );
    await _finishToast(tester);
  });

  testWidgets('switches Inventory report between stock and transfers',
      (tester) async {
    await _openReports(tester);
    await _openReport(tester, 'inventory');

    expect(
      find.byKey(
        const Key('reportTable_inventory_currentStock'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('reportVariantTab_inventory_transfers'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(
              const Key('reportVariantTab_inventory_transfers'),
            ),
          )
          .padding,
      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );

    await tester.tap(
      find.byKey(
        const Key('reportVariantTab_inventory_transfers'),
      ),
    );
    await tester.pump();

    final transfersTable = tester.widget<AppDataTable>(
      find.byKey(const Key('reportTable_inventory_transfers')),
    );
    expect(
      transfersTable.columns.map((column) => column.label),
      [
        'ت',
        'رقم النقل',
        'التاريخ',
        'من مخزن',
        'إلى مخزن',
        'المواد',
      ],
    );
    expect(transfersTable.rows, hasLength(2));
  });

  testWidgets('focuses report search and resets demo state on reopen',
      (tester) async {
    await _openReports(tester);
    await _openReport(tester, 'partyBalances');

    const searchKey = Key('reportSearch_partyBalances');
    await _sendControlF(tester);
    expect(_hasTextFocus(tester, find.byKey(searchKey)), isTrue);

    final partyTypeField =
        find.byKey(const Key('reportFilter_partyBalances_partyType'));
    _dropdown(tester, partyTypeField).onChanged('supplier');
    await tester.pump();
    expect(_dropdown(tester, partyTypeField).value, 'supplier');

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const Key('reportsHub')), findsOneWidget);
    expect(find.byKey(const Key('appConfirmDialog')), findsNothing);

    await _openReport(tester, 'partyBalances');
    expect(
      _dropdown(
        tester,
        find.byKey(
          const Key('reportFilter_partyBalances_partyType'),
        ),
      ).value,
      'all',
    );

    await _returnToReportsHub(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsNothing);
    expect(find.byKey(const Key('reportsScreen')), findsNothing);
  });
}

Future<void> _openReports(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const AlmumayazApp());
  await tester.enterText(
    find.byKey(const Key('usernameField')),
    'admin',
  );
  await tester.enterText(
    find.byKey(const Key('passwordField')),
    'password',
  );
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byKey(const Key('dashboardCard_reports')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _openReport(
  WidgetTester tester,
  String reportId,
) async {
  await tester.tap(
    find.byKey(Key('reportSectionCard_$reportId')),
  );
  await tester.pump();
  expect(
    find.byKey(Key('reportSection_$reportId')),
    findsOneWidget,
  );
}

Future<void> _returnToReportsHub(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('appScreenBackButton')));
  await tester.pump();
  expect(find.byKey(const Key('reportsHub')), findsOneWidget);
}

AppDropdownField<String> _dropdown(
  WidgetTester tester,
  Finder field,
) {
  return tester.widget<AppDropdownField<String>>(
    find.ancestor(
      of: field,
      matching: find.byType(AppDropdownField<String>),
    ),
  );
}

String _fieldText(WidgetTester tester, Finder field) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: field,
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}

bool _hasTextFocus(WidgetTester tester, Finder field) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: field,
          matching: find.byType(EditableText),
        ),
      )
      .focusNode
      .hasFocus;
}

Future<void> _sendControlF(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

Future<void> _finishToast(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(AppToast.duration);
  await tester.pump(const Duration(milliseconds: 300));
}
