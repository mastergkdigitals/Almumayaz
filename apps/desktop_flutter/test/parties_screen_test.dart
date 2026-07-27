import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/parties/domain/party.dart';
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

    controller.next();
    expect(controller.selectedParty, isNull);

    controller.previous();
    expect(controller.selectedParty?.name, 'نور فاضل');

    controller.last();
    expect(controller.selectedParty, isNull);
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
    expect(
      tester.widget(find.byKey(const Key('partyForm'))),
      isA<KeyedSubtree>(),
    );
    expect(find.byKey(const Key('partiesActionBar')), findsOneWidget);
    expect(find.byKey(const Key('partiesTable')), findsOneWidget);
    expect(find.byKey(const Key('appScreenBackButton')), findsOneWidget);
    expect(find.text('بيانات الطرف'), findsNothing);
    expect(find.text('نوع الطرف مخصص للتقارير فقط'), findsNothing);
    expect(find.text('نوع الطرف (للتقارير)'), findsNothing);
    expect(find.text('نوع الطرف'), findsOneWidget);
    expect(find.text('شركة النخيل للتجارة'), findsOneWidget);
    expect(AppColors.headerBackground, Colors.white);

    final partyTypeDecorator = tester.widget<InputDecorator>(
      find.descendant(
        of: find.byKey(const Key('partyTypeField')),
        matching: find.byType(InputDecorator),
      ),
    );
    expect(partyTypeDecorator.decoration.labelText, 'نوع الطرف');
    expect(partyTypeDecorator.isEmpty, isFalse);
    expect(
      tester
          .widget<AppDropdownField<PartyType>>(
            find.ancestor(
              of: find.byKey(const Key('partyTypeField')),
              matching: find.byType(AppDropdownField<PartyType>),
            ),
          )
          .useIntrinsicHeight,
      isTrue,
    );
    expect(
      tester.getSize(find.byKey(const Key('partyTypeField'))),
      tester.getSize(find.byKey(const Key('partyNameField'))),
    );

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
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesUndoButton')),
      ).onPressed,
      isNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesDeleteButton')),
      ).onPressed,
      isNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesFirstButton')),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesPreviousButton')),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesNextButton')),
      ).onPressed,
      isNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesLastButton')),
      ).onPressed,
      isNull,
    );

    final partiesFirstButton = tester.widget<AppButton>(
      find.byKey(const Key('partiesFirstButton')),
    );
    expect(partiesFirstButton.variant, AppButtonVariant.navigation);
    expect(
      partiesFirstButton.padding,
      const EdgeInsets.symmetric(horizontal: 14),
    );
    expect(partiesFirstButton.iconSize, 20);
    expect(partiesFirstButton.textStyle?.fontSize, 16);
    expect(partiesFirstButton.textStyle?.fontWeight, FontWeight.w800);
    final partiesFirstOutlinedButton = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const Key('partiesFirstButton')),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(
      partiesFirstOutlinedButton.style?.side
          ?.resolve(<WidgetState>{WidgetState.hovered})
          ?.color,
      const Color(0xFF111827),
    );
    expect(
      partiesFirstOutlinedButton.style?.backgroundColor
          ?.resolve(<WidgetState>{WidgetState.pressed}),
      const Color(0xFFF8FAFC),
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

    final readOnlyDecoration = tester
        .widget<TextFormField>(
          find.byKey(const Key('partyNumberField')),
        )
        .decoration;
    expect(readOnlyDecoration?.fillColor, AppColors.neutralSurface);
    expect(
      (readOnlyDecoration?.disabledBorder as OutlineInputBorder)
          .borderSide
          .color,
      AppColors.border,
    );

    final nameDecoration = tester
        .widget<TextFormField>(
          find.byKey(const Key('partyNameField')),
        )
        .decoration;
    expect(nameDecoration?.fillColor, AppColors.surface);
    expect(
      (nameDecoration?.enabledBorder as OutlineInputBorder)
          .borderSide
          .color,
      AppColors.border,
    );
    final focusedNameBorder =
        nameDecoration?.focusedBorder as OutlineInputBorder;
    expect(focusedNameBorder.borderSide.color, AppModuleColors.parties);
    expect(focusedNameBorder.borderSide.width, 1.6);

    final namePosition =
        tester.getTopLeft(find.byKey(const Key('partyNameField')));
    final typePosition =
        tester.getTopLeft(find.byKey(const Key('partyTypeField')));
    final workplacePosition =
        tester.getTopLeft(find.byKey(const Key('partyWorkplaceField')));
    final branchPosition =
        tester.getTopLeft(find.byKey(const Key('partyBranchField')));
    final phonePosition =
        tester.getTopLeft(find.byKey(const Key('partyPhoneField')));
    final alternatePhonePosition = tester.getTopLeft(
      find.byKey(const Key('partyAlternatePhoneField')),
    );
    final cityPosition =
        tester.getTopLeft(find.byKey(const Key('partyCityField')));
    final addressPosition =
        tester.getTopLeft(find.byKey(const Key('partyAddressField')));
    final notesPosition =
        tester.getTopLeft(find.byKey(const Key('partyNotesField')));

    expect(typePosition.dy, namePosition.dy);
    expect(branchPosition.dy, workplacePosition.dy);
    expect(alternatePhonePosition.dy, phonePosition.dy);
    expect(addressPosition.dy, cityPosition.dy);
    expect(workplacePosition.dy, greaterThan(namePosition.dy));
    expect(phonePosition.dy, greaterThan(workplacePosition.dy));
    expect(cityPosition.dy, greaterThan(phonePosition.dy));
    expect(notesPosition.dy, greaterThan(cityPosition.dy));

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
      isNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesUndoButton')),
      ).onPressed,
      isNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesDeleteButton')),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<AppScreenShell>(
        find.byKey(const Key('partiesScreen')),
      ).onSave,
      isNull,
    );
    for (final key in [
      'partiesFirstButton',
      'partiesPreviousButton',
      'partiesNextButton',
      'partiesLastButton',
    ]) {
      expect(
        tester.widget<AppButton>(find.byKey(Key(key))).onPressed,
        isNotNull,
      );
    }

    await tester.enterText(
      find.byKey(const Key('partyNameField')),
      'مجهز الرافدين المعدل',
    );
    await tester.pump();
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesUpdateButton')),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesUndoButton')),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<AppScreenShell>(
        find.byKey(const Key('partiesScreen')),
      ).onSave,
      isNotNull,
    );

    await tester.enterText(
      find.byKey(const Key('partyNameField')),
      'مجهز الرافدين',
    );
    await tester.pump();
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesUpdateButton')),
      ).onPressed,
      isNull,
    );
    expect(
      tester.widget<AppScreenShell>(
        find.byKey(const Key('partiesScreen')),
      ).onSave,
      isNull,
    );

    tester
        .widget<AppDropdownField<PartyType>>(
          find.ancestor(
            of: find.byKey(const Key('partyTypeField')),
            matching: find.byType(AppDropdownField<PartyType>),
          ),
        )
        .onChanged(PartyType.customer);
    await tester.pump();
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesUpdateButton')),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesUndoButton')),
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

  testWidgets('guards unsaved party data before leaving or changing records',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();

    final name = find.byKey(const Key('partyNameField'));
    await tester.enterText(name, 'طرف غير محفوظ');
    await tester.pump();

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('partiesScreen')), findsOneWidget);
    expect(_fieldText(tester, name), 'طرف غير محفوظ');

    await tester.tap(find.byKey(const Key('partiesFirstButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, name), 'شركة النخيل للتجارة');

    await tester.enterText(name, 'شركة معدلة');
    await tester.pump();
    await tester.tap(find.byKey(const Key('partyRow_party-002')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, name), 'أحمد كريم');
  });

  testWidgets('matches the old action-bar navigation boundaries',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();

    final name = find.byKey(const Key('partyNameField'));
    await tester.tap(find.byKey(const Key('partiesFirstButton')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, name), 'شركة النخيل للتجارة');

    await tester.tap(find.byKey(const Key('partiesLastButton')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, name), 'نور فاضل');

    await tester.tap(find.byKey(const Key('partiesNextButton')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, name), isEmpty);
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('partiesNextButton')),
      ).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('partiesPreviousButton')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, name), 'نور فاضل');
  });
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester, Finder field) {
  return tester
      .widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      )
      .controller
      .text;
}
