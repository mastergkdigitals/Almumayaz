import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'opens the shared Sales-return workflow and saves from the keyboard',
    (tester) async {
      final store = AppStore.demo();
      addTearDown(store.dispose);
      await _openSalesReturns(tester, store);

      expect(find.byKey(const Key('salesReturnScreen')), findsOneWidget);
      expect(find.byKey(const Key('salesReturnEmptyState')), findsOneWidget);

      await tester.tap(find.text('مرتجع بيع جديد'));
      await tester.pump();

      expect(find.byKey(const Key('salesReturnNumberField')), findsOneWidget);
      expect(
        find.byKey(const Key('salesReturnSourceEmptyState')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('salesReturnSourceInvoiceField')),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('salesReturnLinesTable')), findsOneWidget);
      final quantityField = find.descendant(
        of: find.byKey(const Key('salesReturnLinesTable')),
        matching: find.byType(EditableText),
      ).first;
      await tester.enterText(quantityField, '1');
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final saved = await store.repositories.salesReturns.getAll();
      expect(saved, hasLength(1));
      expect(saved.single.lines.single.quantity.value, 1);

      final sourceSelector = tester.widget<AppAutocompleteField<SalesInvoice>>(
        find.ancestor(
          of: find.byKey(const Key('salesReturnSourceInvoiceField')),
          matching: find.byType(AppAutocompleteField<SalesInvoice>),
        ),
      );
      expect(sourceSelector.enabled, isFalse);
      expect(
        tester
            .widget<AppHeaderIconButton>(
              find.byKey(const Key('salesReturnPrintButton')),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _openSalesReturns(WidgetTester tester, AppStore store) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(AlmumayazApp(store: store));
  await tester.enterText(
    find.byKey(const Key('usernameField')),
    'admin',
  );
  await tester.enterText(
    find.byKey(const Key('passwordField')),
    'password',
  );
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('dashboardCard_sales')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('salesReturnsButton')));
  await tester.pumpAndSettle();
}
