import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:erp/core/printing/desktop_document_output_service.dart';
import 'package:erp/core/printing/document_output_service.dart';
import 'package:erp/core/services/service_failure.dart';
import 'package:erp/features/reports/application/document_report_output_service.dart';
import 'package:erp/features/reports/application/report_output_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const request = DocumentOutputRequest(
    title: 'مستند تجريبي',
    fileNameBase: 'مستند تجريبي',
    fields: [DocumentField(label: 'العملة', value: 'دينار')],
    columns: [
      DocumentColumn(label: 'المادة'),
      DocumentColumn(label: 'السعر', isPrice: true),
    ],
    rows: [
      ['ورق طباعة', '12,000'],
    ],
  );

  const rtlTableRequest = DocumentOutputRequest(
    title: 'تقرير عربي',
    columns: [
      DocumentColumn(label: 'ت'),
      DocumentColumn(label: 'الزبون'),
      DocumentColumn(label: 'التاريخ'),
      DocumentColumn(label: 'الإجمالي', isPrice: true),
    ],
    rows: [
      ['1', 'شركة ABC 42', '2026/08/11', '1,250.00 USD'],
    ],
  );

  test('orders Arabic PDF columns RTL and keeps header cells aligned', () {
    final indexes = pdfTableVisualColumnIndexes(
      rtlTableRequest,
      includePrices: true,
    );

    expect(indexes, [3, 2, 1, 0]);
    expect(
      indexes.map((index) => rtlTableRequest.columns[index].label),
      ['الإجمالي', 'التاريخ', 'الزبون', 'ت'],
    );
    expect(
      indexes.map((index) => rtlTableRequest.rows.single[index]),
      ['1,250.00 USD', '2026/08/11', 'شركة ABC 42', '1'],
    );
  });

  test('removes PDF price columns before applying the RTL order', () {
    final indexes = pdfTableVisualColumnIndexes(
      rtlTableRequest,
      includePrices: false,
    );

    expect(indexes, [2, 1, 0]);
    expect(
      indexes.map((index) => rtlTableRequest.columns[index].label),
      ['التاريخ', 'الزبون', 'ت'],
    );
    expect(
      indexes.map((index) => rtlTableRequest.rows.single[index]),
      ['2026/08/11', 'شركة ABC 42', '1'],
    );
  });

  test('package composer produces real PDF and XLSX containers', () async {
    final composer = PackageDocumentBinaryComposer();

    final pdf = await composer.composePdf(
      request,
      includePrices: true,
      settings: const DocumentOutputSettings(),
    );
    final excel = await composer.composeExcel(request);

    expect(ascii.decode(pdf.take(4).toList()), '%PDF');
    expect(excel.take(2), orderedEquals([0x50, 0x4B]));
  });

  test('Excel preserves RTL, native value types, and safe text fallbacks',
      () async {
    const typedRequest = DocumentOutputRequest(
      title: 'تقرير الأنواع',
      fields: [
        DocumentField(
          label: 'هامش الربح',
          value: '28.57%',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.percentage,
          spreadsheetDecimalPlaces: 2,
        ),
      ],
      columns: [
        DocumentColumn(label: 'الزبون'),
        DocumentColumn(
          label: 'الكمية',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.integer,
        ),
        DocumentColumn(
          label: 'الإجمالي',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.decimal,
        ),
        DocumentColumn(
          label: 'التاريخ',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.date,
        ),
        DocumentColumn(
          label: 'الوقت',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.time,
        ),
        DocumentColumn(
          label: 'النسبة',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.percentage,
          spreadsheetDecimalPlaces: 2,
        ),
        DocumentColumn(
          label: 'رمز بصفر',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.integer,
        ),
        DocumentColumn(
          label: 'رقم طويل',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.integer,
        ),
        DocumentColumn(
          label: 'صيغة محمية',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.decimal,
        ),
        DocumentColumn(
          label: 'تاريخ غير صالح',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.date,
        ),
        DocumentColumn(
          label: 'قيمة مفقودة',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.decimal,
        ),
      ],
      rows: [
        [
          'شركة ABC 42',
          '12',
          '1,250.50',
          '2026/08/11',
          '02:35 م',
          '28.57%',
          '00123',
          '1234567890123456',
          '=2+2',
          '2026/02/30',
          '—',
        ],
      ],
    );
    final bytes = await PackageDocumentBinaryComposer().composeExcel(
      typedRequest,
    );
    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.tables['التقرير']!;

    expect(sheet.isRTL, isTrue);
    final headerIndex = sheet.rows.indexWhere(
      (row) => row.first?.value.toString() == 'الزبون',
    );
    expect(headerIndex, greaterThanOrEqualTo(0));
    expect(
      sheet.rows[headerIndex].map(_text),
      [
        'الزبون',
        'الكمية',
        'الإجمالي',
        'التاريخ',
        'الوقت',
        'النسبة',
        'رمز بصفر',
        'رقم طويل',
        'صيغة محمية',
        'تاريخ غير صالح',
        'قيمة مفقودة',
      ],
    );
    final fieldRow = sheet.rows.singleWhere(
      (row) => row.first?.value.toString() == 'هامش الربح',
    );
    final values = sheet.rows[headerIndex + 1];

    expect(fieldRow[1]!.value, isA<DoubleCellValue>());
    expect(
      (fieldRow[1]!.value! as DoubleCellValue).value,
      closeTo(0.2857, 1e-9),
    );
    expect(fieldRow[1]!.cellStyle!.numberFormat.formatCode, '0.00%');
    expect(_text(values[0]), 'شركة ABC 42');
    expect(values[0]!.value, isA<TextCellValue>());
    expect((values[1]!.value! as IntCellValue).value, 12);
    expect(values[1]!.cellStyle!.numberFormat.formatCode, '#,##0');
    expect((values[2]!.value! as DoubleCellValue).value, 1250.5);
    expect(values[2]!.cellStyle!.numberFormat.formatCode, '#,##0.00');
    expect(values[3]!.value, isA<DateCellValue>());
    final date = values[3]!.value! as DateCellValue;
    expect(date.year, 2026);
    expect(date.month, 8);
    expect(date.day, 11);
    expect(values[3]!.cellStyle!.numberFormat.formatCode, 'yyyy/mm/dd');
    expect(values[4]!.value, isA<TimeCellValue>());
    final time = values[4]!.value! as TimeCellValue;
    expect(time.hour, 14);
    expect(time.minute, 35);
    expect(values[4]!.cellStyle!.numberFormat.formatCode, 'hh:mm');
    expect(
      (values[5]!.value! as DoubleCellValue).value,
      closeTo(0.2857, 1e-9),
    );
    expect(values[5]!.cellStyle!.numberFormat.formatCode, '0.00%');
    expect(_text(values[6]), '00123');
    expect(values[6]!.value, isA<TextCellValue>());
    expect(_text(values[7]), '1234567890123456');
    expect(values[7]!.value, isA<TextCellValue>());
    expect(_text(values[8]), '=2+2');
    expect(values[8]!.value, isA<TextCellValue>());
    expect(_text(values[9]), '2026/02/30');
    expect(values[9]!.value, isA<TextCellValue>());
    expect(_text(values[10]), '—');
    expect(values[10]!.value, isA<TextCellValue>());
  });

  test('desktop adapter applies device settings to native printing', () async {
    final composer = _RecordingComposer();
    final platform = _RecordingPlatform();
    final service = DesktopDocumentOutputService(
      composer: composer,
      platform: platform,
      settingsLoader: () async => const DocumentOutputSettings(
        defaultPrinterName: 'Office Printer',
        paperSize: DocumentPaperSize.a5,
        copies: 2,
        previewEnabled: false,
      ),
    );

    final result = await service.createPreview(
      request,
      includePrices: false,
    );

    expect(result.isDemo, isFalse);
    expect(result.action, DocumentOutputAction.printWithoutPrices);
    expect(composer.lastIncludePrices, isFalse);
    expect(composer.lastSettings?.paperSize, DocumentPaperSize.a5);
    expect(composer.lastSettings?.copies, 2);
    expect(composer.lastSettings?.previewEnabled, isFalse);
    expect(platform.lastPrintSettings?.defaultPrinterName, 'Office Printer');
    expect(platform.printedBytes, orderedEquals([0x25, 0x50, 0x44, 0x46]));
  });

  test('desktop adapter saves files and reports native cancellation', () async {
    final composer = _RecordingComposer();
    final platform = _RecordingPlatform(
      savedPath: r'C:\Exports\مستند_تجريبي.xlsx',
    );
    final service = DesktopDocumentOutputService(
      composer: composer,
      platform: platform,
    );

    final result = await service.export(
      request,
      DocumentExportFormat.excel,
    );

    expect(result.isDemo, isFalse);
    expect(result.fileName, 'مستند_تجريبي.xlsx');
    expect(result.filePath, r'C:\Exports\مستند_تجريبي.xlsx');
    expect(platform.savedExtension, 'xlsx');
    expect(platform.savedBytes, orderedEquals([0x50, 0x4B, 0x03, 0x04]));

    platform.savedPath = null;
    await expectLater(
      service.export(request, DocumentExportFormat.pdf),
      throwsA(
        isA<ServiceFailure>().having(
          (failure) => failure.kind,
          'kind',
          ServiceFailureKind.cancelled,
        ),
      ),
    );
  });

  test('desktop adapter reports a cancelled printer dialog', () async {
    final service = DesktopDocumentOutputService(
      composer: _RecordingComposer(),
      platform: _RecordingPlatform(printResult: false),
    );

    await expectLater(
      service.createPreview(request),
      throwsA(
        isA<ServiceFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              ServiceFailureKind.cancelled,
            )
            .having(
              (failure) => failure.code,
              'code',
              'print_cancelled',
            ),
      ),
    );
  });

  test('report adapter delegates real output and preserves saved path', () async {
    final composer = _RecordingComposer();
    final platform = _RecordingPlatform(
      savedPath: r'C:\Exports\تقرير.xlsx',
    );
    final documents = DesktopDocumentOutputService(
      composer: composer,
      platform: platform,
    );
    final reports = DocumentBackedReportOutputService(
      printService: documents,
      exportService: documents,
    );

    final result = await reports.export(
      const ReportOutputRequest(
        reportTitle: 'تقرير المبيعات',
        variantLabel: 'قوائم المبيعات',
        columnLabels: ['الزبون'],
        rowValues: [
          ['أسواق دجلة'],
        ],
        metrics: {'الإجمالي': '10,000'},
      ),
      ReportExportFormat.excel,
    );

    expect(result.isDemo, isFalse);
    expect(result.filePath, r'C:\Exports\تقرير.xlsx');
    expect(result.content, contains('أسواق دجلة'));
  });
}

class _RecordingComposer implements DocumentBinaryComposer {
  bool? lastIncludePrices;
  DocumentOutputSettings? lastSettings;

  @override
  Future<Uint8List> composeExcel(DocumentOutputRequest request) async {
    return Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]);
  }

  @override
  Future<Uint8List> composePdf(
    DocumentOutputRequest request, {
    required bool includePrices,
    required DocumentOutputSettings settings,
  }) async {
    lastIncludePrices = includePrices;
    lastSettings = settings;
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
  }
}

class _RecordingPlatform implements DocumentPlatformGateway {
  _RecordingPlatform({this.savedPath, this.printResult = true});

  String? savedPath;
  final bool printResult;
  DocumentOutputSettings? lastPrintSettings;
  Uint8List? printedBytes;
  Uint8List? savedBytes;
  String? savedExtension;

  @override
  Future<bool> printPdf({
    required Uint8List bytes,
    required String name,
    required DocumentOutputSettings settings,
  }) async {
    printedBytes = bytes;
    lastPrintSettings = settings;
    return printResult;
  }

  @override
  Future<String?> saveFile({
    required Uint8List bytes,
    required String suggestedName,
    required String extension,
    required String mimeType,
  }) async {
    savedBytes = bytes;
    savedExtension = extension;
    return savedPath;
  }
}

String? _text(Data? cell) => cell?.value?.toString();
