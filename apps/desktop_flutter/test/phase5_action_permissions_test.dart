import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/core/printing/document_output_service.dart';
import 'package:erp/core/responsive/responsive_shell.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/reports/presentation/reports_screen.dart';
import 'package:erp/features/sales/presentation/sales_screen.dart';
import 'package:erp/features/users/domain/user_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'sales.view-only session cannot save, update, delete, print, or export',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = await _signedInViewOnlyStore('sales.viewer');
      addTearDown(store.dispose);
      final output = _RecordingDocumentOutputService();
      final invoicesBefore = await store.repositories.sales.getAll();

      await tester.pumpWidget(
        _screenHarness(
          store,
          SalesScreen(printService: output, exportService: output),
        ),
      );
      await tester.pumpAndSettle();

      expect(invoicesBefore, isNotEmpty);
      _expectDisabledButton(tester, const Key('salesSaveButton'));
      _expectDisabledButton(tester, const Key('salesUpdateButton'));
      _expectDisabledButton(tester, const Key('salesDeleteButton'));
      _expectDisabledHeaderButton(tester, const Key('salesPrintButton'));
      _expectDisabledHeaderButton(
        tester,
        const Key('salesPrintWithoutPricesButton'),
      );
      _expectDisabledHeaderButton(tester, const Key('salesPdfButton'));
      _expectDisabledHeaderButton(tester, const Key('salesExcelButton'));

      await tester.enterText(
        find.byKey(const Key('salesNotesField')),
        'محاولة تعديل بلا صلاحية',
      );
      await tester.pump();
      _expectDisabledButton(tester, const Key('salesUpdateButton'));
      await _sendControlKey(tester, LogicalKeyboardKey.keyS);
      await tester.tap(find.byKey(const Key('salesDeleteButton')));
      await tester.tap(find.byKey(const Key('salesPrintButton')));
      await tester.tap(find.byKey(const Key('salesPdfButton')));
      await tester.tap(find.byKey(const Key('salesExcelButton')));
      await tester.pump();

      expect(output.previewCalls, 0);
      expect(output.exportCalls, 0);
      expect(find.byKey(const Key('appDocumentOutputDialog')), findsNothing);
      expect(find.text('حذف قائمة البيع'), findsNothing);
      final invoicesAfter = await store.repositories.sales.getAll();
      expect(
        invoicesAfter.map((invoice) => invoice.id),
        orderedEquals(invoicesBefore.map((invoice) => invoice.id)),
      );
      expect(
        invoicesAfter.map((invoice) => invoice.notes),
        orderedEquals(invoicesBefore.map((invoice) => invoice.notes)),
      );
    },
  );

  testWidgets('reports.view-only session cannot print or export',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await _signedInViewOnlyStore('reports.viewer');
    addTearDown(store.dispose);

    await tester.pumpWidget(_screenHarness(store, const ReportsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('reportSectionCard_salesInvoices')),
    );
    await tester.pumpAndSettle();

    _expectDisabledButton(
      tester,
      const Key('reportPrintButton_salesInvoices'),
    );
    _expectDisabledButton(
      tester,
      const Key('reportPdfButton_salesInvoices'),
    );
    _expectDisabledButton(
      tester,
      const Key('reportExcelButton_salesInvoices'),
    );

    await tester.tap(
      find.byKey(const Key('reportPrintButton_salesInvoices')),
    );
    await tester.tap(find.byKey(const Key('reportPdfButton_salesInvoices')));
    await tester.tap(
      find.byKey(const Key('reportExcelButton_salesInvoices')),
    );
    await _sendControlKey(tester, LogicalKeyboardKey.keyP);
    await _sendControlKey(tester, LogicalKeyboardKey.keyE);
    await tester.pump();

    expect(find.byKey(const Key('reportOutputPreviewDialog')), findsNothing);
    expect(
      tester
          .widget<AppLoadingOverlay>(
            find.byKey(const Key('reportOutputLoading_salesInvoices')),
          )
          .isLoading,
      isFalse,
    );
  });
}

Future<AppStore> _signedInViewOnlyStore(String username) async {
  final store = AppStore.demo()..suspendIdleMonitoring();
  await store.signIn(
    SignInCredentials(username: 'admin', password: 'password'),
  );
  await store.services.administration.createUser(
    UserCreateRequest(
      fullName: 'مستخدم عرض فقط',
      username: username,
      roleIds: {EntityId.demo('role', 4)},
      initialPassword: 'viewer-password',
    ),
  );
  await store.signOut();
  await store.signIn(
    SignInCredentials(username: username, password: 'viewer-password'),
  );
  store.suspendIdleMonitoring();
  return store;
}

Widget _screenHarness(AppStore store, Widget screen) {
  return MaterialApp(
    locale: const Locale('ar', 'IQ'),
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: AppKeyboardScope(
        child: ResponsiveDesktopShell(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
    home: AppStoreScope(store: store, child: screen),
  );
}

void _expectDisabledButton(WidgetTester tester, Key key) {
  expect(tester.widget<AppButton>(find.byKey(key)).onPressed, isNull);
}

void _expectDisabledHeaderButton(WidgetTester tester, Key key) {
  expect(
    tester.widget<AppHeaderIconButton>(find.byKey(key)).onPressed,
    isNull,
  );
}

Future<void> _sendControlKey(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

class _RecordingDocumentOutputService implements DocumentOutputService {
  int previewCalls = 0;
  int exportCalls = 0;

  @override
  Future<DocumentOutputResult> createPreview(
    DocumentOutputRequest request, {
    bool includePrices = true,
  }) {
    previewCalls++;
    return const DemoDocumentOutputService().createPreview(
      request,
      includePrices: includePrices,
    );
  }

  @override
  Future<DocumentOutputResult> export(
    DocumentOutputRequest request,
    DocumentExportFormat format,
  ) {
    exportCalls++;
    return const DemoDocumentOutputService().export(request, format);
  }
}
