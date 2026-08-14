import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/printing/document_output_service.dart';
import 'package:erp/core/responsive/responsive_shell.dart';
import 'package:erp/features/purchases/presentation/purchase_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saved linked return renders its source and bounded line editor',
      (tester) async {
    await _openPurchaseScreen(tester);

    await tester.tap(find.byKey(const Key('purchaseLastButton')));
    await tester.pumpAndSettle();

    expect(_fieldValue(tester, 'purchaseInvoiceNumberField'), '103');
    expect(
      _fieldValue(tester, 'purchaseOriginalInvoiceField'),
      'قائمة شراء رقم 101',
    );
    expect(
      _fieldValue(tester, 'purchaseSupplierNameField'),
      'شركة الرافدين للتجهيز',
    );
    expect(find.byKey(const Key('purchaseReturnLinesTable')), findsOneWidget);
    expect(find.byKey(const Key('purchaseItemsTable')), findsNothing);
    expect(
      _fieldValue(
        tester,
        'purchaseReturnQuantity-purchase-line-1013',
      ),
      '5',
    );
    expect(_fieldValue(tester, 'purchaseTotalField'), '90,000');
    expect(_fieldValue(tester, 'purchasePaidField'), '90,000');
    expect(
      _dropdown(tester, 'purchaseTypeField').enabled,
      isFalse,
    );
    expect(
      _textField(tester, 'purchaseOriginalInvoiceField').enabled,
      isFalse,
    );
  });

  testWidgets('saved normal purchase keeps its document kind immutable',
      (tester) async {
    await _openPurchaseScreen(tester);

    expect(_fieldValue(tester, 'purchaseInvoiceNumberField'), '101');
    expect(_dropdown(tester, 'purchaseTypeField').enabled, isFalse);
  });

  testWidgets('return output identifies source and does not label refund as cost',
      (tester) async {
    final output = _RecordingDocumentOutputService();
    await _openPurchaseScreen(tester, output: output);

    await tester.tap(find.byKey(const Key('purchaseLastButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('purchasePrintButton')));
    await tester.pumpAndSettle();

    final request = output.lastPreviewRequest!;
    expect(request.title, 'مرتجع شراء رقم 103');
    expect(request.fileNameBase, 'مرتجع شراء 103');
    final sourceField = request.fields.singleWhere(
      (field) => field.label == 'قائمة الشراء الأصلية',
    );
    expect(sourceField.value, '101');
    expect(
      sourceField.spreadsheetCellKind,
      DocumentSpreadsheetCellKind.integer,
    );
    expect(
      request.fields.singleWhere(
        (field) => field.label == 'سياسة تكلفة المخزون',
      ).value,
      contains('متوسط الكلفة المتحرك'),
    );
    expect(
      request.columns.map((column) => column.label),
      containsAll(['سعر المصدر', 'خصم السطر', 'قيمة السطر']),
    );
    expect(
      request.columns.map((column) => column.label),
      isNot(contains('إجمالي الكلفة')),
    );
    expect(
      request.columns.singleWhere((column) => column.label == 'الكمية')
          .spreadsheetCellKind,
      DocumentSpreadsheetCellKind.integer,
    );
    for (final label in const ['سعر المصدر', 'خصم السطر', 'قيمة السطر']) {
      final column = request.columns.singleWhere(
        (candidate) => candidate.label == label,
      );
      expect(
        column.spreadsheetCellKind,
        DocumentSpreadsheetCellKind.decimal,
      );
      expect(column.spreadsheetDecimalPlaces, 0);
    }
    expect(request.rows, hasLength(1));
    expect(request.rows.single.last, '90,000');
  });
}

Future<void> _openPurchaseScreen(
  WidgetTester tester, {
  _RecordingDocumentOutputService? output,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final store = AppStore.demo();
  addTearDown(store.dispose);
  final documentOutput = output ?? _RecordingDocumentOutputService();

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: AppKeyboardScope(
          child: ResponsiveDesktopShell(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      home: AppStoreProvider(
        store: store,
        child: PurchaseScreen(
          printService: documentOutput,
          exportService: documentOutput,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

AppDropdownField<String> _dropdown(WidgetTester tester, String fieldKey) {
  return tester.widget<AppDropdownField<String>>(
    find.ancestor(
      of: find.byKey(Key(fieldKey)),
      matching: find.byType(AppDropdownField<String>),
    ),
  );
}

AppTextField _textField(WidgetTester tester, String fieldKey) {
  return tester.widget<AppTextField>(
    find.ancestor(
      of: find.byKey(Key(fieldKey)),
      matching: find.byType(AppTextField),
    ),
  );
}

class _RecordingDocumentOutputService implements DocumentOutputService {
  final _delegate = const DemoDocumentOutputService();
  DocumentOutputRequest? lastPreviewRequest;

  @override
  Future<DocumentOutputResult> createPreview(
    DocumentOutputRequest request, {
    bool includePrices = true,
  }) {
    lastPreviewRequest = request;
    return _delegate.createPreview(request, includePrices: includePrices);
  }

  @override
  Future<DocumentOutputResult> export(
    DocumentOutputRequest request,
    DocumentExportFormat format,
  ) {
    return _delegate.export(request, format);
  }
}
