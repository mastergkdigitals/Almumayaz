import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      hasLength(1),
    );

    await tester.tap(find.byKey(const Key('appStatementPdf')));
    await tester.pumpAndSettle();
    expect(_outputFileName(tester), endsWith('.pdf'));
    expect(_documentContent(tester), contains('قائمة بيع رقم 101'));

    await tester.tap(find.byKey(const Key('appDocumentOutputClose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appStatementExcel')));
    await tester.pumpAndSettle();
    expect(_outputFileName(tester), endsWith('.xlsx'));
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
      allOf(contains('سند قبض رقم 7'), contains('شركة النخيل للتجارة')),
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
