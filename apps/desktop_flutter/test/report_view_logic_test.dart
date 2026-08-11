import 'package:erp/features/reports/application/report_output_request_factory.dart';
import 'package:erp/features/reports/application/report_row_filter.dart';
import 'package:erp/features/reports/domain/report_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rows = [
    ReportRowDefinition(
      id: 'row-1',
      cells: ['Alpha', '10'],
      filterValues: {'warehouse': 'main'},
    ),
    ReportRowDefinition(
      id: 'row-2',
      cells: ['Beta', '20'],
      filterValues: {'warehouse': 'main|secondary'},
      searchTerms: ['matched note'],
    ),
    ReportRowDefinition(
      id: 'row-3',
      cells: ['Gamma', '30'],
      filterValues: {'warehouse': 'secondary'},
    ),
  ];

  test('filters rows by date, stable option values, and search text', () {
    final datedRows = [
      ReportRowDefinition(
        id: rows[0].id,
        cells: rows[0].cells,
        date: DateTime(2026, 8, 10, 23, 45),
        filterValues: rows[0].filterValues,
      ),
      ReportRowDefinition(
        id: rows[1].id,
        cells: rows[1].cells,
        date: DateTime(2026, 8, 11, 8),
        filterValues: rows[1].filterValues,
        searchTerms: rows[1].searchTerms,
      ),
      ReportRowDefinition(
        id: rows[2].id,
        cells: rows[2].cells,
        date: DateTime(2026, 8, 12),
        filterValues: rows[2].filterValues,
      ),
    ];

    final filtered = ReportRowFilter.apply(
      rows: datedRows,
      dropdownFilterIds: const ['warehouse'],
      selectedValues: const {'warehouse': 'main'},
      startDate: DateTime(2026, 8, 10),
      endDate: DateTime(2026, 8, 11, 23, 59),
      query: 'matched',
    );

    expect(filtered.map((row) => row.id), ['row-2']);
  });

  test('reports empty and stale filter references with existing messages', () {
    const filters = [
      ReportFilterAvailability(
        id: 'warehouse',
        label: 'المخزن',
        options: [ReportFilterOption('main', 'الرئيسي')],
      ),
    ];

    expect(
      ReportRowFilter.missingReferenceMessage(
        filters: filters,
        selectedValues: const {'warehouse': 'missing'},
      ),
      'القيمة المحددة في المخزن لم تعد متاحة. '
      'امسح التصفية ثم اختر قيمة أخرى.',
    );
    expect(
      ReportRowFilter.missingReferenceMessage(
        filters: const [
          ReportFilterAvailability(
            id: 'warehouse',
            label: 'المخزن',
            options: [],
          ),
        ],
        selectedValues: const {},
      ),
      'لا توجد قيم متاحة في المخزن. '
      'راجع البيانات المرجعية ثم أعد المحاولة.',
    );
  });

  test('builds output request from the filtered row snapshot', () {
    final request = ReportOutputRequestFactory.create(
      reportTitle: 'تقرير تجريبي',
      variantLabel: 'رئيسي',
      columnLabels: const ['الاسم', 'القيمة'],
      rows: rows.take(2),
      metrics: const [
        ReportMetricValue(label: 'المجموع', value: '30'),
      ],
    );

    expect(request.columnLabels, ['الاسم', 'القيمة']);
    expect(request.rowValues, [rows[0].cells, rows[1].cells]);
    expect(request.metrics, {'المجموع': '30'});
  });
}
