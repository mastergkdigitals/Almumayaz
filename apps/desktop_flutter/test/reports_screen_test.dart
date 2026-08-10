import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/reports/application/report_output_service.dart';
import 'package:erp/features/reports/application/report_rows_service.dart';
import 'package:erp/features/reports/application/report_summary_calculator.dart';
import 'package:erp/features/reports/data/report_demo_catalog.dart';
import 'package:erp/features/reports/presentation/report_definition.dart';
import 'package:erp/features/reports/presentation/widgets/report_section_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps report filters status-free and rows aligned', () {
    for (final report in reportDefinitions) {
      for (final variant in report.variants) {
        expect(
          variant.filters.map((filter) => filter.id),
          isNot(contains('status')),
        );
        for (final row in _demoRows(report, variant)) {
          expect(row.filterValues.containsKey('status'), isFalse);
          expect(row.cells, hasLength(variant.columns.length));
        }
      }
    }
  });

  test('loads demo rows through the report rows service', () async {
    const service = DemoReportRowsService(delay: Duration.zero);
    final report = reportDefinitions.first;
    final variant = report.variants.first;
    final request = ReportRowsRequest(
      reportId: report.id,
      variantId: variant.id,
    );

    expect(service.snapshot(request), _demoRows(report, variant));
    expect(await service.load(request), _demoRows(report, variant));
  });

  test('calculates report metrics from only the supplied rows', () {
    final report = reportDefinitions.singleWhere(
      (candidate) => candidate.id == 'salesInvoices',
    );
    final variant = report.variants.single;
    final usdRows = _demoRows(report, variant)
        .where((row) => row.filterValues['currency'] == 'USD')
        .toList(growable: false);

    final metrics = ReportSummaryCalculator.calculate(
      reportId: report.id,
      variantId: variant.id,
      rows: usdRows,
      fallbackMetrics: variant.metrics,
    );
    String value(String label) =>
        metrics.singleWhere((metric) => metric.label == label).value;

    expect(value('عدد القوائم - دينار'), '0');
    expect(value('الإجمالي - دينار'), '0');
    expect(value('عدد القوائم - دولار'), '1');
    expect(value('الإجمالي - دولار'), '1,250.00');
    expect(value('المقبوض - دولار'), '250.00');
    expect(value('المتبقي - دولار'), '1,000.00');
  });

  test('demo report output contains the filtered rows and summaries',
      () async {
    const service = DemoReportOutputService(delay: Duration.zero);
    final report = reportDefinitions.first;
    final variant = report.variants.first;
    final row = _demoRows(report, variant).first;
    final request = ReportOutputRequest(
      reportTitle: report.title,
      variantLabel: variant.label,
      columnLabels: [
        for (final column in variant.columns) column.label,
      ],
      rowValues: [row.cells],
      metrics: {
        for (final metric in ReportSummaryCalculator.calculate(
          reportId: report.id,
          variantId: variant.id,
          rows: [row],
          fallbackMetrics: variant.metrics,
        ))
          metric.label: metric.value,
      },
    );

    final preview = await service.createPreview(request);
    final excel = await service.export(request, ReportExportFormat.excel);

    expect(preview.rowCount, 1);
    expect(preview.content, contains('أسواق دجلة'));
    expect(excel.fileName, endsWith('.xlsx'));
    expect(excel.content, contains('\t'));
    await expectLater(
      service.createPreview(
        const ReportOutputRequest(
          reportTitle: 'فارغ',
          variantLabel: 'فارغ',
          columnLabels: ['العمود'],
          rowValues: [],
          metrics: {},
        ),
      ),
      throwsA(isA<ReportOutputException>()),
    );
  });

  test('currency filters also constrain multi-currency party summaries', () {
    final report = reportDefinitions.singleWhere(
      (candidate) => candidate.id == 'partyBalances',
    );
    final variant = report.variants.single;
    final rows = _demoRows(report, variant)
        .where(
          (row) =>
              (row.filterValues['currency'] ?? '').split('|').contains('IQD'),
        )
        .toList(growable: false);
    final metrics = ReportSummaryCalculator.calculate(
      reportId: report.id,
      variantId: variant.id,
      rows: rows,
      fallbackMetrics: variant.metrics,
      selectedFilters: const {'currency': 'IQD'},
    );
    String value(String label) =>
        metrics.singleWhere((metric) => metric.label == label).value;

    expect(value('ذمم لنا - دينار'), '2,775,000');
    expect(value('ذمم لنا - دولار'), '0.00');
    expect(value('ذمم علينا - دولار'), '0.00');
  });

  test('calculates cashbox balances and embedded transfer quantities', () {
    final cashbox = reportDefinitions.singleWhere(
      (candidate) => candidate.id == 'cashbox',
    );
    final cashboxVariant = cashbox.variants.single;
    final cashboxMetrics = ReportSummaryCalculator.calculate(
      reportId: cashbox.id,
      variantId: cashboxVariant.id,
      rows: _demoRows(cashbox, cashboxVariant),
      fallbackMetrics: cashboxVariant.metrics,
    );
    String cashboxValue(String label) => cashboxMetrics
        .singleWhere((metric) => metric.label == label)
        .value;
    expect(cashboxValue('الصافي - دينار'), '1,315,000');
    expect(cashboxValue('الرصيد - دينار'), '11,115,000');
    expect(cashboxValue('الصافي - دولار'), '-400.00');
    expect(cashboxValue('الرصيد - دولار'), '4,100.00');

    final inventory = reportDefinitions.singleWhere(
      (candidate) => candidate.id == 'inventory',
    );
    final transfers = inventory.variants.singleWhere(
      (variant) => variant.id == 'transfers',
    );
    final transferMetrics = ReportSummaryCalculator.calculate(
      reportId: inventory.id,
      variantId: transfers.id,
      rows: [_demoRows(inventory, transfers).last],
      fallbackMetrics: transfers.metrics,
    );
    String transferValue(String label) => transferMetrics
        .singleWhere((metric) => metric.label == label)
        .value;
    expect(transferValue('عدد عمليات النقل'), '1');
    expect(transferValue('عدد سطور المواد'), '2');
    expect(transferValue('مجموع الكميات'), '7');
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
      expect(
        find.byKey(Key('reportPdfButton_${report.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('reportExcelButton_${report.id}')),
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
    expect(
      find.descendant(
        of: find.byKey(
          const Key('reportMetric_salesInvoices_main_1'),
        ),
        matching: find.text('0'),
      ),
      findsOneWidget,
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
      find.descendant(
        of: find.byKey(
          const Key('reportMetric_salesInvoices_main_1'),
        ),
        matching: find.text('487,000'),
      ),
      findsOneWidget,
    );
    expect(
      _dropdown(tester, currencyField).value,
      'all',
    );
    await _finishToast(tester);

    tester
        .widget<AppDateRangeField>(find.byType(AppDateRangeField))
        .onChanged(
          DateTimeRange(
            start: DateTime(2026, 7, 26),
            end: DateTime(2026, 7, 26),
          ),
        );
    await tester.pump();
    expect(salesTable().rows, hasLength(1));
    expect(
      find.descendant(
        of: find.byKey(
          const Key('reportMetric_salesInvoices_main_5'),
        ),
        matching: find.text('1,250.00'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('reportResetButton_salesInvoices')),
    );
    await tester.pump();
    expect(salesTable().rows, hasLength(3));
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
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(
      find.byKey(const Key('reportOutputPreviewDialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('reportOutputPreviewContent')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('reportOutputPreviewClose')),
    );
    await tester.pump();
    await _finishToast(tester);

    await tester.tap(
      find.byKey(const Key('reportPdfButton_salesInvoices')),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(find.textContaining('.pdf'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('reportOutputPreviewClose')),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('reportExcelButton_salesInvoices')),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(find.textContaining('.xlsx'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('reportOutputPreviewClose')),
    );
    await tester.pump();
  });

  testWidgets('shows loading and error states', (tester) async {
    final definition = reportDefinitions.first;
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ReportSectionView(
                definition: definition,
                definitions: [definition],
                onDefinitionChanged: (_) {},
                rowsService: const _FailingReportRowsService(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('reportShowButton_salesInvoices')),
    );
    await tester.pump();
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('reportTable_salesInvoices_main')),
          )
          .isLoading,
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();
    expect(
      find.byKey(const Key('reportErrorState_salesInvoices')),
      findsOneWidget,
    );
    await _finishToast(tester);
  });

  testWidgets('shows a missing-reference state for stale filters',
      (tester) async {
    final definition = reportDefinitions.first;
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ReportSectionView(
                definition: definition,
                definitions: [definition],
                onDefinitionChanged: (_) {},
                initialDropdownValues: const {
                  'currency': 'removed-currency',
                },
              ),
            ),
          ),
        ),
      ),
    );

    final state = find.byKey(
      const Key('reportMissingReferenceState_salesInvoices'),
    );
    expect(state, findsOneWidget);
    expect(
      tester.widget<AppStatePanel>(state).type,
      AppStateType.missingReference,
    );
    expect(
      find.descendant(
        of: state,
        matching: find.byIcon(Icons.link_off_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: state,
        matching: find.text('مرجع التصفية غير متاح'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: state,
        matching: find.byType(AppRegularButton),
      ),
    );
    await tester.pump();
    expect(state, findsNothing);
    expect(
      find.byKey(const Key('reportTable_salesInvoices_main')),
      findsOneWidget,
    );
    await _finishToast(tester);
  });

  testWidgets('shows an empty state and blocks empty exports',
      (tester) async {
    await _openReports(tester);
    await _openReport(tester, 'salesInvoices');
    await tester.enterText(
      find.byKey(const Key('reportSearch_salesInvoices')),
      'نتيجة غير موجودة',
    );
    await tester.pump();

    expect(
      find.byKey(const Key('reportEmptyState_salesInvoices')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('reportExcelButton_salesInvoices')),
    );
    await tester.pump();
    final toast = find.byKey(const Key('appToast')).first;
    expect(toast, findsOneWidget);
    expect(
      find.descendant(
        of: toast,
        matching: find.text('لا توجد نتائج لتجهيزها'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('reportOutputPreviewDialog')),
      findsNothing,
    );
    await _finishToast(tester);
  });

  testWidgets('moves report row selection with the keyboard',
      (tester) async {
    await _openReports(tester);
    await _openReport(tester, 'salesInvoices');

    await tester.tap(
      find.byKey(const Key('reportShowButton_salesInvoices')),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    final table = tester.widget<AppDataTable>(
      find.byKey(const Key('reportTable_salesInvoices_main')),
    );
    expect(table.rows.first.selected, isTrue);
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

class _FailingReportRowsService implements ReportRowsService {
  const _FailingReportRowsService();

  @override
  Future<List<ReportRowDefinition>> load(ReportRowsRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    throw StateError('demo failure');
  }
}

List<ReportRowDefinition> _demoRows(
  ReportDefinition report,
  ReportVariantDefinition variant,
) {
  return reportDemoRowsFor(
    reportId: report.id,
    variantId: variant.id,
  );
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
