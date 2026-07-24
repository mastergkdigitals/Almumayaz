import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('moves Enter through the party fields in the approved order',
      (tester) async {
    await _openParties(tester);

    final name = find.byKey(const Key('partyNameField'));
    final type = find.byKey(const Key('partyTypeField'));
    final workplace = find.byKey(const Key('partyWorkplaceField'));
    final branch = find.byKey(const Key('partyBranchField'));
    final phone = find.byKey(const Key('partyPhoneField'));
    final alternatePhone =
        find.byKey(const Key('partyAlternatePhoneField'));
    final city = find.byKey(const Key('partyCityField'));
    final address = find.byKey(const Key('partyAddressField'));
    final notes = find.byKey(const Key('partyNotesField'));

    await tester.tap(name);
    await tester.enterText(name, 'طرف اختبار');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    final typeButton = tester.widget<InkWell>(type);
    expect(typeButton.focusNode?.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNWidgets(4));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNWidgets(4));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    expect(_hasTextFocus(tester, workplace), isTrue);

    await _submitAutocomplete(tester);
    expect(_hasTextFocus(tester, branch), isTrue);

    await _submitAutocomplete(tester);
    expect(_hasTextFocus(tester, phone), isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_hasTextFocus(tester, alternatePhone), isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_hasTextFocus(tester, city), isTrue);

    await _submitAutocomplete(tester);
    expect(_hasTextFocus(tester, address), isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_hasTextFocus(tester, notes), isTrue);

    await tester.enterText(notes, 'ملاحظة');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(_hasTextFocus(tester, notes), isTrue);
  });

  testWidgets('keeps search Enter idle and binds Ctrl+S to save or update',
      (tester) async {
    await _openParties(tester);

    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('partiesScreen')),
    );
    expect(shell.onNew, isNull);
    expect(shell.onRefresh, isNull);
    expect(shell.onSave, isNotNull);

    final search = find.byKey(const Key('partiesSearchField'));
    await tester.tap(search);
    await tester.enterText(search, 'الرافدين');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(_hasTextFocus(tester, search), isTrue);
    expect(
      find.descendant(
        of: find.byKey(const Key('partiesTable')),
        matching: find.text('مجهز الرافدين'),
      ),
      findsOneWidget,
    );

    await tester.enterText(search, '');
    final name = find.byKey(const Key('partyNameField'));
    await tester.enterText(name, 'طرف لوحة المفاتيح');
    await _sendControlShortcut(tester, LogicalKeyboardKey.keyS);
    await tester.pump();

    final table = find.byKey(const Key('partiesTable'));
    expect(
      find.descendant(
        of: table,
        matching: find.text('طرف لوحة المفاتيح'),
      ),
      findsOneWidget,
    );

    await tester.enterText(name, 'طرف لوحة المفاتيح المحدّث');
    await _sendControlShortcut(tester, LogicalKeyboardKey.keyS);
    await tester.pump();

    expect(
      find.descendant(
        of: table,
        matching: find.text('طرف لوحة المفاتيح المحدّث'),
      ),
      findsOneWidget,
    );

    await _sendControlShortcut(tester, LogicalKeyboardKey.keyN);
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pump();
    expect(_text(tester, name), 'طرف لوحة المفاتيح المحدّث');
  });

  testWidgets('closes dropdown then dialog before leaving parties',
      (tester) async {
    await _openParties(tester);

    final name = find.byKey(const Key('partyNameField'));
    await tester.tap(name);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    expect(find.byType(MenuItemButton), findsNWidgets(4));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(MenuItemButton), findsNothing);
    expect(find.byKey(const Key('partiesScreen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('partyRow_party-003')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('partiesDeleteButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsNothing);
    expect(find.byKey(const Key('partiesScreen')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('partiesScreen')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_parties')), findsOneWidget);
  });
}

Future<void> _openParties(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const AlmumayazApp());
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('dashboardCard_parties')));
  await tester.pumpAndSettle();
}

Future<void> _submitAutocomplete(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pump();
}

Future<void> _sendControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

bool _hasTextFocus(WidgetTester tester, Finder field) {
  return tester
      .widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      )
      .focusNode
      .hasFocus;
}

String _text(WidgetTester tester, Finder field) {
  return tester
      .widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      )
      .controller
      .text;
}
