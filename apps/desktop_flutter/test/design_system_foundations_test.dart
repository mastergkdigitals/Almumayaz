import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats business values consistently', () {
    expect(AppFormatters.date(DateTime(2026, 7, 4)), '2026-07-04');
    expect(
      AppFormatters.time(const TimeOfDay(hour: 9, minute: 5)),
      '09:05',
    );
    expect(AppFormatters.quantity(1000), '1,000');
    expect(AppFormatters.money(12345.5, decimalPlaces: 2), '12,345.50');
    expect(AppFormatters.currency('IQD'), 'دينار');
    expect(AppFormatters.currency('USD'), 'دولار');
  });

  test('uses a black text caret globally', () {
    expect(AppTheme.light().textSelectionTheme.cursorColor, Colors.black);
  });

  testWidgets('handles the global keyboard shortcuts', (tester) async {
    var searches = 0;
    var saves = 0;
    var creates = 0;
    var refreshes = 0;
    var escapes = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppShortcutScope(
          onSearch: () => searches++,
          onSave: () => saves++,
          onNew: () => creates++,
          onRefresh: () => refreshes++,
          onEscape: () => escapes++,
          child: const Scaffold(body: Text('اختبار')),
        ),
      ),
    );
    await tester.pump();

    await _sendControlShortcut(tester, LogicalKeyboardKey.keyF);
    await _sendControlShortcut(tester, LogicalKeyboardKey.keyS);
    await _sendControlShortcut(tester, LogicalKeyboardKey.keyN);
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(searches, 1);
    expect(saves, 1);
    expect(creates, 1);
    expect(refreshes, 1);
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
}

Future<void> _sendControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}
