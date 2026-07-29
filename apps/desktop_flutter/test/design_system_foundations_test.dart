import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  test('formats business values consistently', () {
    expect(AppFormatters.date(DateTime(2026, 12, 31)), '2026/12/31');
    expect(
      AppFormatters.time(const TimeOfDay(hour: 1, minute: 1)),
      '01:01 ص',
    );
    expect(
      AppFormatters.time(const TimeOfDay(hour: 13, minute: 1)),
      '01:01 م',
    );
    expect(AppFormatters.quantity(1000000), '1,000,000');
    expect(AppFormatters.iqd(1000000), '1,000,000');
    expect(AppFormatters.usd(100000), '100,000.00');
    expect(AppFormatters.moneyByCurrency(15300.12135, 'IQD'), '15,300');
    expect(
      AppFormatters.moneyByCurrency(15.300012135, 'USD'),
      '15.30',
    );
    expect(AppFormatters.parseInteger('1,000,000'), 1000000);
    expect(AppFormatters.parseNumber('1,000,000.25'), 1000000.25);
    expect(AppFormatters.money(12345.5, decimalPlaces: 2), '12,345.50');
    expect(AppFormatters.currency('IQD'), 'دينار');
    expect(AppFormatters.currency('USD'), 'دولار');
  });

  test('uses a black text caret globally', () {
    expect(
      AppTheme.light().textSelectionTheme.cursorColor,
      AppColors.cursor,
    );
  });

  test('uses the approved system colors', () {
    expect(AppColors.blue, const Color(0xFF2563EB));
    expect(AppColors.green, const Color(0xFF16A34A));
    expect(AppColors.orange, const Color(0xFFF97316));
    expect(AppColors.grey, const Color(0xFF64748B));
    expect(AppColors.red, const Color(0xFFDC2626));

    expect(AppColors.primary, AppColors.blue);
    expect(AppColors.success, AppColors.green);
    expect(AppColors.warning, AppColors.orange);
    expect(AppColors.danger, AppColors.red);
    expect(AppColors.info, AppColors.blue);
  });

  testWidgets('documents the responsive visual foundations',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    expect(find.text('القياسات وأساسيات الواجهة'), findsOneWidget);
    expect(
      find.byKey(const Key('designFoundationsSection')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designFoundationCanvas')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designFoundationMinimumWindow')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designFoundationAspectRatio')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designFoundationRegularButtonHeight')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designFoundationInvoiceFieldHeight')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designFoundationSpacing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designFoundationTypography')),
      findsOneWidget,
    );

    expect(find.text('2000 px'), findsOneWidget);
    expect(find.text('1280 × 720'), findsOneWidget);
    expect(find.text('16:9'), findsOneWidget);
    expect(
      AppRegularButton.defaultHeight,
      52,
    );
    expect(AppControlHeights.invoiceField, 55);
  });

  testWidgets('handles the global keyboard shortcuts', (tester) async {
    var searches = 0;
    var saves = 0;
    var escapes = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppShortcutScope(
          onSearch: () => searches++,
          onSave: () => saves++,
          onEscape: () => escapes++,
          child: const Scaffold(body: Text('اختبار')),
        ),
      ),
    );
    await tester.pump();

    await _sendControlShortcut(tester, LogicalKeyboardKey.keyF);
    await _sendControlShortcut(tester, LogicalKeyboardKey.keyS);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(searches, 1);
    expect(saves, 1);
    expect(escapes, 1);
  });

  testWidgets('moves focus through the shared traversal helper',
      (tester) async {
    final firstFocus = FocusNode();
    final secondFocus = FocusNode();
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                key: const Key('firstFocusField'),
                focusNode: firstFocus,
              ),
              TextField(
                key: const Key('secondFocusField'),
                focusNode: secondFocus,
              ),
            ],
          ),
        ),
      ),
    );

    firstFocus.requestFocus();
    await tester.pump();
    AppFocusTraversal.next(
      tester.element(find.byKey(const Key('firstFocusField'))),
    );
    await tester.pump();

    expect(secondFocus.hasFocus, isTrue);
  });

  testWidgets('does not use arrow keys to move between app controls',
      (tester) async {
    final firstFocus = FocusNode();
    final secondFocus = FocusNode();
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppKeyboardScope(
          child: Scaffold(
            body: Row(
              children: [
                TextButton(
                  focusNode: firstFocus,
                  onPressed: () {},
                  child: const Text('الأول'),
                ),
                TextButton(
                  focusNode: secondFocus,
                  onPressed: () {},
                  child: const Text('الثاني'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    firstFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(firstFocus.hasFocus, isTrue);
    expect(secondFocus.hasFocus, isFalse);
  });
}

Future<void> _sendControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}
