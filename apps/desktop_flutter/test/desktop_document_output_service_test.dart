import 'dart:convert';
import 'dart:typed_data';

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
