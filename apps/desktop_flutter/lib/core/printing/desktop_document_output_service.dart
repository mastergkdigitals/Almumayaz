import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/service_failure.dart';
import 'document_output_service.dart';

abstract interface class DocumentBinaryComposer {
  Future<Uint8List> composePdf(
    DocumentOutputRequest request, {
    required bool includePrices,
    required DocumentOutputSettings settings,
  });

  Future<Uint8List> composeExcel(DocumentOutputRequest request);
}

abstract interface class DocumentPlatformGateway {
  Future<bool> printPdf({
    required Uint8List bytes,
    required String name,
    required DocumentOutputSettings settings,
  });

  Future<String?> saveFile({
    required Uint8List bytes,
    required String suggestedName,
    required String extension,
    required String mimeType,
  });
}

class NativeDocumentPlatformGateway implements DocumentPlatformGateway {
  const NativeDocumentPlatformGateway();

  @override
  Future<bool> printPdf({
    required Uint8List bytes,
    required String name,
    required DocumentOutputSettings settings,
  }) {
    final baseFormat = switch (settings.paperSize) {
      DocumentPaperSize.a4 => PdfPageFormat.a4,
      DocumentPaperSize.a5 => PdfPageFormat.a5,
    };
    final format = settings.landscape ? baseFormat.landscape : baseFormat;
    if (!settings.previewEnabled) {
      return _directPrintOrFallback(
        bytes: bytes,
        name: name,
        format: format,
        settings: settings,
      );
    }
    return _layoutPdf(bytes: bytes, name: name, format: format);
  }

  Future<bool> _directPrintOrFallback({
    required Uint8List bytes,
    required String name,
    required PdfPageFormat format,
    required DocumentOutputSettings settings,
  }) async {
    List<Printer> printers;
    try {
      printers = await Printing.listPrinters();
    } catch (_) {
      return _layoutPdf(bytes: bytes, name: name, format: format);
    }
    final configuredName = settings.defaultPrinterName?.trim().toLowerCase();
    Printer? selected;
    if (configuredName != null && configuredName.isNotEmpty) {
      for (final printer in printers) {
        if (printer.name.trim().toLowerCase() == configuredName &&
            printer.isAvailable) {
          selected = printer;
          break;
        }
      }
    } else {
      for (final printer in printers) {
        if (printer.isDefault && printer.isAvailable) {
          selected = printer;
          break;
        }
      }
    }
    if (selected == null) {
      return _layoutPdf(bytes: bytes, name: name, format: format);
    }
    return Printing.directPrintPdf(
      printer: selected,
      name: name,
      format: format,
      dynamicLayout: false,
      onLayout: (_) async => bytes,
    );
  }

  Future<bool> _layoutPdf({
    required Uint8List bytes,
    required String name,
    required PdfPageFormat format,
  }) {
    return Printing.layoutPdf(
      name: name,
      format: format,
      dynamicLayout: false,
      onLayout: (_) async => bytes,
    );
  }

  @override
  Future<String?> saveFile({
    required Uint8List bytes,
    required String suggestedName,
    required String extension,
    required String mimeType,
  }) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        XTypeGroup(
          label: extension.toUpperCase(),
          extensions: [extension],
        ),
      ],
    );
    if (location == null) return null;

    final file = XFile.fromData(
      bytes,
      mimeType: mimeType,
      name: suggestedName,
    );
    final selectedPath = location.path;
    final outputPath = selectedPath.toLowerCase().endsWith('.$extension')
        ? selectedPath
        : '$selectedPath.$extension';
    await file.saveTo(outputPath);
    return outputPath;
  }
}

class PackageDocumentBinaryComposer implements DocumentBinaryComposer {
  Future<_PdfFonts>? _fonts;

  @override
  Future<Uint8List> composePdf(
    DocumentOutputRequest request, {
    required bool includePrices,
    required DocumentOutputSettings settings,
  }) async {
    final fonts = await (_fonts ??= _loadFonts());
    final visibleColumns = _visibleColumnIndexes(
      request,
      includePrices: includePrices,
    );
    final visibleFields = request.fields
        .where((field) => includePrices || !field.isPrice)
        .toList(growable: false);
    final baseFormat = switch (settings.paperSize) {
      DocumentPaperSize.a4 => PdfPageFormat.a4,
      DocumentPaperSize.a5 => PdfPageFormat.a5,
    };
    final pageFormat = settings.landscape ? baseFormat.landscape : baseFormat;
    final document = pw.Document(
      title: request.title,
      creator: 'Almumayaz ERP',
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
      ),
    );

    for (var copy = 0; copy < settings.copies; copy++) {
      document.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          maxPages: 500,
          margin: const pw.EdgeInsets.all(24),
          textDirection: pw.TextDirection.rtl,
          build: (_) => [
            pw.Text(
              request.title,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 18,
              ),
              textAlign: pw.TextAlign.center,
            ),
            if (request.subtitle?.trim().isNotEmpty ?? false) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                request.subtitle!.trim(),
                style: pw.TextStyle(font: fonts.bold, fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
            ],
            if (settings.copies > 1) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                'نسخة ${copy + 1} من ${settings.copies}',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
            if (visibleFields.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  for (final field in visibleFields)
                    pw.Text(
                      '${field.label}: ${field.value}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                ],
              ),
            ],
            pw.SizedBox(height: 14),
            if (request.rows.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Text(
                  'لا توجد بيانات ضمن الخيارات المحددة',
                  textAlign: pw.TextAlign.center,
                ),
              )
            else
              _buildTable(
                request,
                visibleColumns,
                fonts,
              ),
          ],
          footer: (context) => pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(
                color: PdfColors.grey700,
                fontSize: 8,
              ),
            ),
          ),
        ),
      );
    }

    return document.save();
  }

  pw.Widget _buildTable(
    DocumentOutputRequest request,
    List<int> visibleColumns,
    _PdfFonts fonts,
  ) {
    final fontSize = visibleColumns.length > 8 ? 6.5 : 8.5;
    pw.Widget cell(String value, {required bool header}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 6,
        ),
        child: pw.Text(
          value,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: header ? fonts.bold : fonts.regular,
            fontSize: fontSize,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey400,
        width: 0.5,
      ),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            for (final index in visibleColumns)
              cell(request.columns[index].label, header: true),
          ],
        ),
        for (final row in request.rows)
          pw.TableRow(
            children: [
              for (final index in visibleColumns)
                cell(row[index], header: false),
            ],
          ),
      ],
    );
  }

  @override
  Future<Uint8List> composeExcel(DocumentOutputRequest request) async {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'التقرير');
    final sheet = workbook['التقرير']..isRTL = true;

    sheet.appendRow([TextCellValue(request.title)]);
    if (request.subtitle?.trim().isNotEmpty ?? false) {
      sheet.appendRow([TextCellValue(request.subtitle!.trim())]);
    }
    if (request.fields.isNotEmpty) {
      sheet.appendRow(const <CellValue?>[]);
      for (final field in request.fields) {
        sheet.appendRow([
          TextCellValue(field.label),
          TextCellValue(field.value),
        ]);
      }
    }
    sheet.appendRow(const <CellValue?>[]);
    sheet.appendRow([
      for (final column in request.columns) TextCellValue(column.label),
    ]);
    for (final row in request.rows) {
      sheet.appendRow([for (final value in row) TextCellValue(value)]);
    }
    for (var index = 0; index < request.columns.length; index++) {
      sheet.setColumnAutoFit(index);
    }

    final bytes = workbook.save();
    if (bytes == null) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.unavailable,
        message: 'تعذر إنشاء ملف Excel',
        code: 'excel_generation_failed',
      );
    }
    return Uint8List.fromList(bytes);
  }

  Future<_PdfFonts> _loadFonts() async {
    final regular =
        await rootBundle.load('assets/fonts/Tajawal/Tajawal-Regular.ttf');
    final bold =
        await rootBundle.load('assets/fonts/Tajawal/Tajawal-Bold.ttf');
    return _PdfFonts(
      regular: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    );
  }
}

class DesktopDocumentOutputService implements DocumentOutputService {
  DesktopDocumentOutputService({
    DocumentBinaryComposer? composer,
    DocumentPlatformGateway? platform,
    DocumentOutputSettingsLoader? settingsLoader,
  })  : _composer = composer ?? PackageDocumentBinaryComposer(),
        _platform = platform ?? const NativeDocumentPlatformGateway(),
        _settingsLoader = settingsLoader;

  final DocumentBinaryComposer _composer;
  final DocumentPlatformGateway _platform;
  final DocumentOutputSettingsLoader? _settingsLoader;

  @override
  Future<DocumentOutputResult> createPreview(
    DocumentOutputRequest request, {
    bool includePrices = true,
  }) async {
    _validate(request);
    final loadedSettings = await _loadSettings();
    final settings = _settingsForRequest(
      loadedSettings,
      request,
      includePrices: includePrices,
    );
    try {
      final bytes = await _composer.composePdf(
        request,
        includePrices: includePrices,
        settings: settings,
      );
      final printed = await _platform.printPdf(
        bytes: bytes,
        name: request.title,
        settings: settings,
      );
      if (!printed) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.cancelled,
          message: 'تم إلغاء الطباعة',
          code: 'print_cancelled',
        );
      }
      return DocumentOutputResult(
        action: includePrices
            ? DocumentOutputAction.print
            : DocumentOutputAction.printWithoutPrices,
        title: includePrices
            ? 'تم إرسال المستند للطباعة'
            : 'تمت الطباعة بدون أسعار',
        documentTitle: request.title,
        content: _buildContent(request, includePrices: includePrices),
        rowCount: request.rows.length,
        isDemo: false,
      );
    } on ServiceFailure {
      rethrow;
    } catch (error) {
      throw ServiceFailure(
        kind: ServiceFailureKind.unavailable,
        message: 'تعذر إرسال المستند إلى الطابعة',
        code: 'native_print_failed',
        cause: error,
      );
    }
  }

  @override
  Future<DocumentOutputResult> export(
    DocumentOutputRequest request,
    DocumentExportFormat format,
  ) async {
    _validate(request);
    final loadedSettings = await _loadSettings();
    final extension = switch (format) {
      DocumentExportFormat.pdf => 'pdf',
      DocumentExportFormat.excel => 'xlsx',
    };
    final mimeType = switch (format) {
      DocumentExportFormat.pdf => 'application/pdf',
      DocumentExportFormat.excel =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
    final fileName = '${_safeFileName(request.fileNameBase ?? request.title)}.'
        '$extension';
    try {
      final bytes = switch (format) {
        DocumentExportFormat.pdf => await _composer.composePdf(
            request,
            includePrices: true,
            settings: _settingsForRequest(
              DocumentOutputSettings(paperSize: loadedSettings.paperSize),
              request,
              includePrices: true,
            ),
          ),
        DocumentExportFormat.excel => await _composer.composeExcel(request),
      };
      final path = await _platform.saveFile(
        bytes: bytes,
        suggestedName: fileName,
        extension: extension,
        mimeType: mimeType,
      );
      if (path == null) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.cancelled,
          message: 'تم إلغاء حفظ الملف',
          code: 'file_save_cancelled',
        );
      }
      return DocumentOutputResult(
        action: format == DocumentExportFormat.pdf
            ? DocumentOutputAction.pdf
            : DocumentOutputAction.excel,
        title: format == DocumentExportFormat.pdf
            ? 'تم حفظ ملف PDF'
            : 'تم حفظ ملف Excel',
        documentTitle: request.title,
        content: _buildContent(request, includePrices: true),
        rowCount: request.rows.length,
        fileName: _fileNameFromPath(path, fallback: fileName),
        filePath: path,
        isDemo: false,
      );
    } on ServiceFailure {
      rethrow;
    } catch (error) {
      throw ServiceFailure(
        kind: ServiceFailureKind.unavailable,
        message: 'تعذر حفظ الملف. تحقق من المسار والصلاحيات.',
        code: 'native_file_save_failed',
        cause: error,
      );
    }
  }

  Future<DocumentOutputSettings> _loadSettings() async {
    final loader = _settingsLoader;
    if (loader == null) return const DocumentOutputSettings();
    try {
      final settings = await loader();
      return settings.copies > 0 ? settings : const DocumentOutputSettings();
    } catch (_) {
      return const DocumentOutputSettings();
    }
  }

  DocumentOutputSettings _settingsForRequest(
    DocumentOutputSettings settings,
    DocumentOutputRequest request, {
    required bool includePrices,
  }) {
    final visibleColumnCount = _visibleColumnIndexes(
      request,
      includePrices: includePrices,
    ).length;
    return settings.copyWith(landscape: visibleColumnCount > 7);
  }
}

class _PdfFonts {
  const _PdfFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}

void _validate(DocumentOutputRequest request) {
  if (request.title.trim().isEmpty) {
    throw const ServiceFailure(
      kind: ServiceFailureKind.validation,
      message: 'عنوان المستند مطلوب',
      code: 'document_title_required',
    );
  }
  if (request.columns.isEmpty) {
    throw const ServiceFailure(
      kind: ServiceFailureKind.validation,
      message: 'يجب تعريف عمود واحد على الأقل للمستند',
      code: 'document_columns_required',
    );
  }
  if (request.rows.any((row) => row.length != request.columns.length)) {
    throw const ServiceFailure(
      kind: ServiceFailureKind.validation,
      message: 'تعذر تجهيز المستند بسبب عدم تطابق الأعمدة',
      code: 'document_columns_mismatch',
    );
  }
}

List<int> _visibleColumnIndexes(
  DocumentOutputRequest request, {
  required bool includePrices,
}) {
  return [
    for (var index = 0; index < request.columns.length; index++)
      if (includePrices || !request.columns[index].isPrice) index,
  ];
}

String _buildContent(
  DocumentOutputRequest request, {
  required bool includePrices,
}) {
  final visibleColumns = _visibleColumnIndexes(
    request,
    includePrices: includePrices,
  );
  final fields = request.fields.where(
    (field) => includePrices || !field.isPrice,
  );
  final buffer = StringBuffer()..writeln(request.title);
  if (request.subtitle?.trim().isNotEmpty ?? false) {
    buffer.writeln(request.subtitle!.trim());
  }
  if (fields.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln(
        fields
            .map((field) => '${field.label}: ${field.value}')
            .join(' | '),
      );
  }
  buffer
    ..writeln()
    ..writeln(
      visibleColumns.map((index) => request.columns[index].label).join(' | '),
    );
  if (request.rows.isEmpty) {
    buffer.writeln('لا توجد بيانات ضمن الخيارات المحددة');
  } else {
    for (final row in request.rows) {
      buffer.writeln(visibleColumns.map((index) => row[index]).join(' | '));
    }
  }
  return buffer.toString().trimRight();
}

String _safeFileName(String value) {
  final normalized = value
      .trim()
      .replaceAll(RegExp(r'[^\w\u0600-\u06FF]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return normalized.isEmpty ? 'document' : normalized;
}

String _fileNameFromPath(String path, {required String fallback}) {
  final segments = path.split(RegExp(r'[/\\]'));
  final name = segments.isEmpty ? '' : segments.last.trim();
  return name.isEmpty ? fallback : name;
}
