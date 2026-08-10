import 'dart:async';

import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/data/app_repository.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/printing/document_output_service.dart';
import 'package:erp/core/responsive/responsive_shell.dart';
import 'package:erp/features/purchases/domain/purchase_invoice.dart';
import 'package:erp/features/purchases/domain/purchase_repository.dart';
import 'package:erp/features/purchases/presentation/purchase_screen.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:erp/features/sales/domain/sales_repository.dart';
import 'package:erp/features/sales/presentation/sales_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('actual output result identifies the saved Windows path',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => AppDocumentOutputDialog.show(
              context,
              result: const DocumentOutputResult(
                action: DocumentOutputAction.pdf,
                title: 'تم حفظ ملف PDF',
                documentTitle: 'مستند فعلي',
                content: 'المحتوى',
                rowCount: 1,
                fileName: 'مستند.pdf',
                filePath: r'C:\Exports\مستند.pdf',
                isDemo: false,
              ),
              accentColor: AppColors.blue,
            ),
            child: const Text('فتح'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();

    expect(
      find.text('تم إنشاء ملف PDF وحفظه في المسار المختار.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appDocumentOutputFilePath')),
      findsOneWidget,
    );
  });

  testWidgets('sales print and installment actions show useful results',
      (tester) async {
    await _openModule(tester, 'sales', size: const Size(1280, 720));

    await tester.tap(find.byKey(const Key('salesPrintButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appDocumentOutputDialog')), findsOneWidget);
    expect(
      _documentContent(tester),
      allOf(contains('قائمة بيع رقم 101'), contains('ورق طباعة')),
    );

    await tester.tap(find.byKey(const Key('appDocumentOutputClose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesInstallmentsButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('appInstallmentScheduleDialog')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('appInstallmentScheduleTable')),
          )
          .rows,
      hasLength(4),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('appInstallmentScheduleDialog')),
        matching: find.text('250.00'),
      ),
      findsNWidgets(4),
    );
  });

  testWidgets('sales output actions require a clean saved invoice',
      (tester) async {
    final output = _RecordingDocumentOutputService();
    await _openDocumentScreen(
      tester,
      SalesScreen(printService: output, exportService: output),
    );

    await tester.tap(find.byKey(const Key('salesNextButton')));
    await tester.pumpAndSettle();
    expect(_headerAction(tester, 'salesInstallmentsButton'), isNotNull);

    await tester.enterText(
      find.byKey(const Key('salesNotesField')),
      'تعديل غير محفوظ',
    );
    await tester.pump();
    _expectHeaderActionsDisabled(tester, const [
      'salesPrintButton',
      'salesPrintWithoutPricesButton',
      'salesPdfButton',
      'salesExcelButton',
      'salesInstallmentsButton',
      'salesStatementButton',
    ]);

    await tester.tap(find.byKey(const Key('salesUndoButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesLastButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesLastButton')));
    await tester.pumpAndSettle();
    _expectHeaderActionsDisabled(tester, const [
      'salesPrintButton',
      'salesPrintWithoutPricesButton',
      'salesPdfButton',
      'salesExcelButton',
      'salesInstallmentsButton',
      'salesStatementButton',
    ]);
  });

  testWidgets('purchase output actions require a clean saved invoice',
      (tester) async {
    final output = _RecordingDocumentOutputService();
    await _openDocumentScreen(
      tester,
      PurchaseScreen(printService: output, exportService: output),
    );

    await tester.enterText(
      find.byKey(const Key('purchaseNotesField')),
      'تعديل غير محفوظ',
    );
    await tester.pump();
    _expectHeaderActionsDisabled(tester, const [
      'purchasePrintButton',
      'purchasePrintWithoutPricesButton',
      'purchasePdfButton',
      'purchaseExcelButton',
      'purchaseStatementButton',
    ]);

    await tester.tap(find.byKey(const Key('purchaseUndoButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('purchaseLastButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('purchaseLastButton')));
    await tester.pumpAndSettle();
    _expectHeaderActionsDisabled(tester, const [
      'purchasePrintButton',
      'purchasePrintWithoutPricesButton',
      'purchasePdfButton',
      'purchaseExcelButton',
      'purchaseStatementButton',
    ]);
  });

  testWidgets(
      'sales invoice output routes without-prices PDF and Excel correctly',
      (tester) async {
    final output = _RecordingDocumentOutputService();
    await _openDocumentScreen(
      tester,
      SalesScreen(printService: output, exportService: output),
    );

    await tester.tap(
      find.byKey(const Key('salesPrintWithoutPricesButton')),
    );
    await tester.pumpAndSettle();

    expect(output.lastPreviewRequest?.title, 'قائمة بيع رقم 101');
    expect(output.lastIncludePrices, isFalse);
    expect(
      _documentContent(tester),
      allOf(
        contains('ورق طباعة'),
        isNot(contains('سعر البيع')),
        isNot(contains('المجموع:')),
      ),
    );

    await tester.tap(find.byKey(const Key('appDocumentOutputClose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesPdfButton')));
    await tester.pumpAndSettle();

    expect(output.exports.last.format, DocumentExportFormat.pdf);
    expect(output.exports.last.request.title, 'قائمة بيع رقم 101');
    expect(_outputFileName(tester), 'قائمة_بيع_101.pdf');

    await tester.tap(find.byKey(const Key('appDocumentOutputClose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesExcelButton')));
    await tester.pumpAndSettle();

    expect(output.exports.last.format, DocumentExportFormat.excel);
    expect(output.exports.last.request.fileNameBase, 'قائمة بيع 101');
    expect(_outputFileName(tester), 'قائمة_بيع_101.xlsx');
  });

  testWidgets('purchase invoice PDF and Excel use the injected export service',
      (tester) async {
    final output = _RecordingDocumentOutputService();
    await _openDocumentScreen(
      tester,
      PurchaseScreen(printService: output, exportService: output),
    );

    await tester.tap(find.byKey(const Key('purchasePrintButton')));
    await tester.pumpAndSettle();

    expect(output.lastPreviewRequest?.title, 'قائمة شراء رقم 101');
    expect(output.lastIncludePrices, isTrue);

    await tester.tap(find.byKey(const Key('appDocumentOutputClose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('purchasePdfButton')));
    await tester.pumpAndSettle();

    expect(output.exports.last.format, DocumentExportFormat.pdf);
    expect(output.exports.last.request.title, 'قائمة شراء رقم 101');
    expect(_outputFileName(tester), 'قائمة_شراء_101.pdf');

    await tester.tap(find.byKey(const Key('appDocumentOutputClose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('purchaseExcelButton')));
    await tester.pumpAndSettle();

    expect(output.exports.last.format, DocumentExportFormat.excel);
    expect(output.exports.last.request.fileNameBase, 'قائمة شراء 101');
    expect(_outputFileName(tester), 'قائمة_شراء_101.xlsx');
  });

  testWidgets('sales output reloads the latest selected saved invoice',
      (tester) async {
    final store = AppStore.demo();
    final output = _RecordingDocumentOutputService();
    await _openDocumentScreen(
      tester,
      SalesScreen(printService: output, exportService: output),
      store: store,
    );

    final saved = (await store.repositories.sales.getAll()).first;
    await store.repositories.sales.replaceInvoice(
      _salesWithCustomerName(saved, 'زبون محدث'),
    );
    await tester.tap(find.byKey(const Key('salesPdfButton')));
    await tester.pumpAndSettle();

    expect(output.exports.last.request.subtitle, 'زبون محدث');
    expect(_outputFileName(tester), 'قائمة_بيع_101.pdf');
  });

  testWidgets('purchase output reloads the latest selected saved invoice',
      (tester) async {
    final store = AppStore.demo();
    final output = _RecordingDocumentOutputService();
    await _openDocumentScreen(
      tester,
      PurchaseScreen(printService: output, exportService: output),
      store: store,
    );

    final saved = (await store.repositories.purchases.getAll()).first;
    await store.repositories.purchases.replaceInvoice(
      _purchaseWithSupplierName(saved, 'مجهز محدث'),
    );
    await tester.tap(find.byKey(const Key('purchasePdfButton')));
    await tester.pumpAndSettle();

    expect(output.exports.last.request.subtitle, 'مجهز محدث');
    expect(_outputFileName(tester), 'قائمة_شراء_101.pdf');
  });

  testWidgets('sales output stops when the selected invoice disappeared',
      (tester) async {
    final store = AppStore.demo();
    final output = _RecordingDocumentOutputService();
    await _openDocumentScreen(
      tester,
      SalesScreen(printService: output, exportService: output),
      store: store,
    );

    final selected = (await store.repositories.sales.getAll()).first;
    await store.repositories.sales.deleteInvoicePermanently(selected.id);
    await tester.tap(find.byKey(const Key('salesPdfButton')));
    await tester.pumpAndSettle();

    expect(output.exports, isEmpty);
    expect(find.byKey(const Key('salesMissingReferenceState')), findsOneWidget);
    await tester.pump(AppToast.duration);
    await tester.pumpAndSettle();
  });

  testWidgets('purchase output stops when the selected invoice disappeared',
      (tester) async {
    final store = AppStore.demo();
    final output = _RecordingDocumentOutputService();
    await _openDocumentScreen(
      tester,
      PurchaseScreen(printService: output, exportService: output),
      store: store,
    );

    final selected = (await store.repositories.purchases.getAll()).first;
    await store.repositories.purchases.deleteInvoicePermanently(selected.id);
    await tester.tap(find.byKey(const Key('purchasePdfButton')));
    await tester.pumpAndSettle();

    expect(output.exports, isEmpty);
    expect(
      find.byKey(const Key('purchaseMissingReferenceState')),
      findsOneWidget,
    );
    await tester.pump(AppToast.duration);
    await tester.pumpAndSettle();
  });

  testWidgets('sales output preserves edits made while repository reloads',
      (tester) async {
    final repositories = AppRepositories.demo();
    final delayedSales = _DelayedSalesRepository(repositories.sales);
    final store = AppStore(
      repositories: _repositoriesWithSales(repositories, delayedSales),
    );
    final output = _RecordingDocumentOutputService();
    await _openDocumentScreen(
      tester,
      SalesScreen(printService: output, exportService: output),
      store: store,
    );

    delayedSales.delayNextLoad();
    await tester.tap(find.byKey(const Key('salesPdfButton')));
    await tester.pump();
    await delayedSales.loadStarted;
    _setFieldValue(
      tester,
      'salesNotesField',
      'تعديل أثناء التحديث',
    );
    await tester.pump();
    delayedSales.releaseLoad();
    await tester.pumpAndSettle();

    expect(output.exports, isEmpty);
    expect(find.byKey(const Key('appDocumentOutputDialog')), findsNothing);
    expect(
      _fieldValue(tester, 'salesNotesField'),
      'تعديل أثناء التحديث',
    );
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '101');
  });

  testWidgets('purchase output preserves edits made while repository reloads',
      (tester) async {
    final repositories = AppRepositories.demo();
    final delayedPurchases = _DelayedPurchaseRepository(
      repositories.purchases,
    );
    final store = AppStore(
      repositories: _repositoriesWithPurchases(
        repositories,
        delayedPurchases,
      ),
    );
    final output = _RecordingDocumentOutputService();
    await _openDocumentScreen(
      tester,
      PurchaseScreen(printService: output, exportService: output),
      store: store,
    );

    delayedPurchases.delayNextLoad();
    await tester.tap(find.byKey(const Key('purchasePdfButton')));
    await tester.pump();
    await delayedPurchases.loadStarted;
    _setFieldValue(
      tester,
      'purchaseNotesField',
      'تعديل أثناء التحديث',
    );
    await tester.pump();
    delayedPurchases.releaseLoad();
    await tester.pumpAndSettle();

    expect(output.exports, isEmpty);
    expect(find.byKey(const Key('appDocumentOutputDialog')), findsNothing);
    expect(
      _fieldValue(tester, 'purchaseNotesField'),
      'تعديل أثناء التحديث',
    );
    expect(_fieldValue(tester, 'purchaseInvoiceNumberField'), '101');
  });

  testWidgets('sales editor stays gated while the output service is pending',
      (tester) async {
    final output = _RecordingDocumentOutputService()..delayNextExport();
    await _openDocumentScreen(
      tester,
      SalesScreen(printService: output, exportService: output),
    );

    await tester.tap(find.byKey(const Key('salesPdfButton')));
    await tester.pump();
    await output.exportStarted;

    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('salesScreen')),
    );
    expect(shell.onBack, isNull);
    expect(shell.onSearch, isNull);
    expect(
      tester
          .widget<AbsorbPointer>(
            find.byKey(const Key('salesDocumentActionAbsorber')),
          )
          .absorbing,
      isTrue,
    );
    final notesField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('salesNotesField')),
        matching: find.byType(EditableText),
      ),
    );
    expect(notesField.focusNode.canRequestFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(notesField.focusNode.hasFocus, isFalse);
    expect(_fieldValue(tester, 'salesInvoiceNumberField'), '101');

    _setFieldValue(
      tester,
      'salesNotesField',
      'تعديل أثناء الإخراج',
    );
    await tester.pump();
    output.releaseExport();
    await tester.pumpAndSettle();

    expect(output.exports, hasLength(1));
    expect(find.byKey(const Key('appDocumentOutputDialog')), findsNothing);
    expect(
      _fieldValue(tester, 'salesNotesField'),
      'تعديل أثناء الإخراج',
    );
  });

  testWidgets('purchase without-prices preview omits every priced field',
      (tester) async {
    await _openModule(tester, 'purchases', size: const Size(1280, 720));

    await tester.tap(
      find.byKey(const Key('purchasePrintWithoutPricesButton')),
    );
    await tester.pumpAndSettle();

    expect(find.text('معاينة الطباعة بدون أسعار'), findsOneWidget);
    final content = _documentContent(tester);
    expect(content, contains('ورق طباعة A4'));
    expect(content, contains('الكمية'));
    expect(content, isNot(contains('سعر الشراء')));
    expect(content, isNot(contains('إجمالي الكلفة')));
    expect(content, isNot(contains('المجموع: 150,000')));
  });

  testWidgets('statement PDF and Excel buttons show named output results',
      (tester) async {
    await _openModule(tester, 'sales', size: const Size(1280, 720));

    await tester.tap(find.byKey(const Key('salesStatementButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appStatementConfirm')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('appStatementReportTable')),
          )
          .rows,
      hasLength(2),
    );

    await tester.tap(find.byKey(const Key('appStatementPdf')));
    await tester.pumpAndSettle();
    expect(_outputFileName(tester), endsWith('.pdf'));
    expect(
      _documentContent(tester),
      allOf(
        contains('قائمة بيع رقم 101'),
        contains('سند قبض رقم 1'),
      ),
    );

    await tester.tap(find.byKey(const Key('appDocumentOutputClose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appStatementExcel')));
    await tester.pumpAndSettle();
    expect(_outputFileName(tester), endsWith('.xlsx'));
  });

  testWidgets('party statement output contains repository-backed movements',
      (tester) async {
    await _openModule(tester, 'parties', size: const Size(1440, 900));

    await tester.tap(find.byKey(const Key('partyStatement_party-001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appStatementConfirm')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('appStatementReportTable')),
          )
          .rows,
      hasLength(2),
    );

    await tester.tap(find.byKey(const Key('appStatementPdf')));
    await tester.pumpAndSettle();

    expect(_outputFileName(tester), endsWith('.pdf'));
    expect(
      _documentContent(tester),
      allOf(
        contains('قائمة بيع رقم 101'),
        contains('سند قبض رقم 1'),
        contains('500,000'),
      ),
    );
  });

  testWidgets('cashbox print keeps its toast and opens a voucher preview',
      (tester) async {
    await _openModule(tester, 'cashbox', size: const Size(1440, 900));

    await tester.tap(find.byKey(const Key('cashboxPrintButton')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('appToast')), findsOneWidget);
    expect(find.byKey(const Key('appDocumentOutputDialog')), findsOneWidget);
    expect(
      _documentContent(tester),
      allOf(contains('سند قبض رقم 11'), contains('النقدية اليومية')),
    );
  });
}

String _documentContent(WidgetTester tester) {
  return tester
      .widget<SelectableText>(
        find.byKey(const Key('appDocumentOutputContent')),
      )
      .data!;
}

String _outputFileName(WidgetTester tester) {
  return tester
      .widget<AppStatusBadge>(
        find.byKey(const Key('appDocumentOutputFileName')),
      )
      .label;
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

void _setFieldValue(
  WidgetTester tester,
  String key,
  String value,
) {
  tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text = value;
}

VoidCallback? _headerAction(WidgetTester tester, String key) {
  return tester
      .widget<AppHeaderIconButton>(find.byKey(Key(key)))
      .onPressed;
}

void _expectHeaderActionsDisabled(
  WidgetTester tester,
  List<String> keys,
) {
  for (final key in keys) {
    expect(
      _headerAction(tester, key),
      isNull,
      reason: '$key must require a clean saved invoice.',
    );
  }
}

Future<void> _openModule(
  WidgetTester tester,
  String moduleId, {
  required Size size,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const AlmumayazApp());
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('dashboardCard_$moduleId')));
  await tester.pumpAndSettle();
}

Future<void> _openDocumentScreen(
  WidgetTester tester,
  Widget screen, {
  AppStore? store,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final effectiveStore = store ?? AppStore.demo();
  addTearDown(effectiveStore.dispose);

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
      home: AppStoreProvider(store: effectiveStore, child: screen),
    ),
  );
  await tester.pumpAndSettle();
}

class _RecordingDocumentOutputService implements DocumentOutputService {
  final _delegate = const DemoDocumentOutputService();
  final _exportGate = _LoadGate();
  DocumentOutputRequest? lastPreviewRequest;
  bool? lastIncludePrices;
  final List<({
    DocumentOutputRequest request,
    DocumentExportFormat format,
  })> exports = [];

  void delayNextExport() => _exportGate.delayNextLoad();

  Future<void> get exportStarted => _exportGate.loadStarted;

  void releaseExport() => _exportGate.releaseLoad();

  @override
  Future<DocumentOutputResult> createPreview(
    DocumentOutputRequest request, {
    bool includePrices = true,
  }) {
    lastPreviewRequest = request;
    lastIncludePrices = includePrices;
    return _delegate.createPreview(
      request,
      includePrices: includePrices,
    );
  }

  @override
  Future<DocumentOutputResult> export(
    DocumentOutputRequest request,
    DocumentExportFormat format,
  ) async {
    exports.add((request: request, format: format));
    await _exportGate.waitIfNeeded();
    return _delegate.export(request, format);
  }
}

SalesInvoice _salesWithCustomerName(
  SalesInvoice invoice,
  String customerName,
) {
  return SalesInvoice(
    id: invoice.id,
    documentNumber: invoice.documentNumber,
    date: invoice.date,
    minuteOfDay: invoice.minuteOfDay,
    customerId: invoice.customerId,
    defaultWarehouseId: invoice.defaultWarehouseId,
    currency: invoice.currency,
    exchangeRate: invoice.exchangeRate,
    settlementKind: invoice.settlementKind,
    lines: invoice.lines,
    invoiceDiscount: invoice.invoiceDiscount,
    received: invoice.received,
    customerNameSnapshot: customerName,
    searchDetailsSnapshot: invoice.searchDetailsSnapshot,
    balanceAfterInvoice: invoice.balanceAfterInvoice,
    driverName: invoice.driverName,
    notes: invoice.notes,
  );
}

PurchaseInvoice _purchaseWithSupplierName(
  PurchaseInvoice invoice,
  String supplierName,
) {
  return PurchaseInvoice(
    id: invoice.id,
    documentNumber: invoice.documentNumber,
    date: invoice.date,
    minuteOfDay: invoice.minuteOfDay,
    supplierId: invoice.supplierId,
    defaultWarehouseId: invoice.defaultWarehouseId,
    currency: invoice.currency,
    exchangeRate: invoice.exchangeRate,
    purchaseKind: invoice.purchaseKind,
    settlementKind: invoice.settlementKind,
    lines: invoice.lines,
    expenses: invoice.expenses,
    invoiceDiscount: invoice.invoiceDiscount,
    paid: invoice.paid,
    supplierNameSnapshot: supplierName,
    searchDetailsSnapshot: invoice.searchDetailsSnapshot,
    balanceAfterInvoice: invoice.balanceAfterInvoice,
    notes: invoice.notes,
  );
}

AppRepositories _repositoriesWithSales(
  AppRepositories repositories,
  SalesRepository sales,
) {
  return AppRepositories(
    parties: repositories.parties,
    items: repositories.items,
    warehouses: repositories.warehouses,
    cashbox: repositories.cashbox,
    sales: sales,
    purchases: repositories.purchases,
    businessSettings: repositories.businessSettings,
    deviceSettings: repositories.deviceSettings,
    operationalMasterData: repositories.operationalMasterData,
  );
}

AppRepositories _repositoriesWithPurchases(
  AppRepositories repositories,
  PurchaseRepository purchases,
) {
  return AppRepositories(
    parties: repositories.parties,
    items: repositories.items,
    warehouses: repositories.warehouses,
    cashbox: repositories.cashbox,
    sales: repositories.sales,
    purchases: purchases,
    businessSettings: repositories.businessSettings,
    deviceSettings: repositories.deviceSettings,
    operationalMasterData: repositories.operationalMasterData,
  );
}

class _LoadGate {
  Completer<void>? _gate;
  Completer<void>? _started;

  void delayNextLoad() {
    assert(_gate == null, 'A delayed load is already pending.');
    _gate = Completer<void>();
    _started = Completer<void>();
  }

  Future<void> get loadStarted => _started!.future;

  void releaseLoad() {
    final gate = _gate;
    if (gate == null) {
      throw StateError('No delayed load is pending.');
    }
    if (!gate.isCompleted) gate.complete();
  }

  Future<void> waitIfNeeded() async {
    final gate = _gate;
    if (gate == null) return;
    final started = _started!;
    if (!started.isCompleted) started.complete();
    await gate.future;
    if (identical(_gate, gate)) {
      _gate = null;
      _started = null;
    }
  }
}

class _DelayedSalesRepository implements SalesRepository {
  _DelayedSalesRepository(this._delegate);

  final SalesRepository _delegate;
  final _loadGate = _LoadGate();

  void delayNextLoad() => _loadGate.delayNextLoad();

  Future<void> get loadStarted => _loadGate.loadStarted;

  void releaseLoad() => _loadGate.releaseLoad();

  @override
  Future<List<SalesInvoice>> getAll() async {
    await _loadGate.waitIfNeeded();
    return _delegate.getAll();
  }

  @override
  Future<SalesInvoice?> getById(EntityId id) => _delegate.getById(id);

  @override
  Future<SalesInvoice> save(SalesInvoice value) => _delegate.save(value);

  @override
  Future<DeleteDecision> canDelete(EntityId id) =>
      _delegate.canDelete(id);

  @override
  Future<void> delete(EntityId id) => _delegate.delete(id);

  @override
  Future<List<SalesInvoice>> search(String query) =>
      _delegate.search(query);

  @override
  Future<int> nextDocumentNumber() => _delegate.nextDocumentNumber();

  @override
  Future<SalesInvoice> createInvoice(SalesInvoice invoice) =>
      _delegate.createInvoice(invoice);

  @override
  Future<SalesInvoice> replaceInvoice(SalesInvoice invoice) =>
      _delegate.replaceInvoice(invoice);

  @override
  Future<void> deleteInvoicePermanently(EntityId id) =>
      _delegate.deleteInvoicePermanently(id);
}

class _DelayedPurchaseRepository implements PurchaseRepository {
  _DelayedPurchaseRepository(this._delegate);

  final PurchaseRepository _delegate;
  final _loadGate = _LoadGate();

  void delayNextLoad() => _loadGate.delayNextLoad();

  Future<void> get loadStarted => _loadGate.loadStarted;

  void releaseLoad() => _loadGate.releaseLoad();

  @override
  Future<List<PurchaseInvoice>> getAll() async {
    await _loadGate.waitIfNeeded();
    return _delegate.getAll();
  }

  @override
  Future<PurchaseInvoice?> getById(EntityId id) => _delegate.getById(id);

  @override
  Future<PurchaseInvoice> save(PurchaseInvoice value) =>
      _delegate.save(value);

  @override
  Future<DeleteDecision> canDelete(EntityId id) =>
      _delegate.canDelete(id);

  @override
  Future<void> delete(EntityId id) => _delegate.delete(id);

  @override
  Future<List<PurchaseInvoice>> search(String query) =>
      _delegate.search(query);

  @override
  Future<int> nextDocumentNumber() => _delegate.nextDocumentNumber();

  @override
  Future<PurchaseInvoice> createInvoice(PurchaseInvoice invoice) =>
      _delegate.createInvoice(invoice);

  @override
  Future<PurchaseInvoice> replaceInvoice(PurchaseInvoice invoice) =>
      _delegate.replaceInvoice(invoice);

  @override
  Future<void> deleteInvoicePermanently(EntityId id) =>
      _delegate.deleteInvoicePermanently(id);
}
