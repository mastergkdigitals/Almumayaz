import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/parties/presentation/parties_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters and navigates the temporary parties list', () {
    final controller = PartiesController();
    addTearDown(controller.dispose);

    expect(controller.state.parties, hasLength(10));

    controller.search('الرافدين');
    expect(controller.visibleParties, hasLength(1));

    controller.first();
    expect(controller.selectedParty?.name, 'مجهز الرافدين');

    controller.search('');
    controller.first();
    expect(controller.selectedParty?.name, 'شركة النخيل للتجارة');

    controller.next();
    expect(controller.selectedParty?.name, 'أحمد كريم');

    controller.last();
    expect(controller.selectedParty?.name, 'نور فاضل');
  });

  testWidgets('opens the parties screen with the approved shared controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);

    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('partiesScreen')), findsOneWidget);
    expect(find.text('الأطراف'), findsWidgets);
    expect(find.byKey(const Key('partyForm')), findsOneWidget);
    expect(find.byKey(const Key('partiesActionBar')), findsOneWidget);
    expect(find.byKey(const Key('partiesTable')), findsOneWidget);
    expect(find.byKey(const Key('appScreenBackButton')), findsOneWidget);
    expect(find.text('بيانات الطرف'), findsNothing);
    expect(find.text('نوع الطرف مخصص للتقارير فقط'), findsNothing);
    expect(find.text('نوع الطرف (للتقارير)'), findsNothing);
    expect(find.text('نوع الطرف'), findsOneWidget);
    expect(find.text('شركة النخيل للتجارة'), findsOneWidget);
    expect(AppColors.headerBackground, Colors.white);

    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesSaveButton')),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesUpdateButton')),
      ).onPressed,
      isNull,
    );

    for (final fieldKey in [
      'partyNumberField',
      'partyDateField',
      'partyTimeField',
      'partyBalanceIqdField',
      'partyBalanceUsdField',
    ]) {
      expect(
        tester.widget<TextFormField>(
          find.byKey(Key(fieldKey)),
        ).enabled,
        isFalse,
      );
    }

    final notesInput = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('partyNotesField')),
        matching: find.byType(EditableText),
      ),
    );
    expect(notesInput.maxLines, 1);

    final headerSubtitle = tester.widget<Text>(
      find.text('إدارة بيانات الزبائن والمجهزين والموظفين'),
    );
    expect(headerSubtitle.style?.fontWeight, FontWeight.w500);

    for (final fieldKey in [
      'partyPhoneField',
      'partyAlternatePhoneField',
      'partyBalanceIqdField',
      'partyBalanceUsdField',
    ]) {
      final input = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(Key(fieldKey)),
          matching: find.byType(EditableText),
        ),
      );
      expect(input.textDirection, TextDirection.rtl);
      expect(input.textAlign, TextAlign.right);
    }

    await tester.tap(find.byKey(const Key('partyRow_party-003')));
    await tester.pump();

    final nameInput = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('partyNameField')),
        matching: find.byType(EditableText),
      ),
    );
    expect(nameInput.controller.text, 'مجهز الرافدين');
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesSaveButton')),
      ).onPressed,
      isNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesUpdateButton')),
      ).onPressed,
      isNotNull,
    );

    await tester.enterText(
      find.byKey(const Key('partiesSearchField')),
      'أسواق دجلة',
    );
    await tester.pump();

    final table = find.byKey(const Key('partiesTable'));
    expect(
      find.descendant(of: table, matching: find.text('أسواق دجلة')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: table, matching: find.text('أحمد كريم')),
      findsNothing,
    );
  });
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
}
