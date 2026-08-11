import 'dart:async';

import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/data/app_repository.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/parties/application/party_statement_service.dart';
import 'package:erp/features/parties/data/demo_party_repository.dart';
import 'package:erp/features/parties/domain/party.dart';
import 'package:erp/features/parties/domain/party_repository.dart';
import 'package:erp/features/parties/presentation/parties_controller.dart';
import 'package:erp/features/parties/presentation/parties_screen.dart';
import 'package:erp/features/parties/presentation/widgets/party_form.dart';
import 'package:erp/features/permissions/domain/permission_models.dart';
import 'package:erp/features/settings/data/demo_operational_settings_repositories.dart';
import 'package:erp/features/settings/domain/operational_master_data.dart';
import 'package:erp/features/settings/domain/operational_master_data_repository.dart';
import 'package:erp/features/users/domain/user_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters and navigates the repository-backed parties list', () async {
    final repositories = AppRepositories.demo();
    final controller = PartiesController(
      repository: repositories.parties,
      masterData: repositories.operationalMasterData,
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.state.parties, hasLength(13));
    expect(controller.state.parties.first.entityId, EntityId('party-001'));
    expect(
      controller.state.parties.first.iqdBalance,
      Money.fromMajor(500000, AppCurrency.iqd),
    );
    expect(
      controller.state.parties.first.usdBalance,
      Money.fromMajor(850, AppCurrency.usd),
    );

    controller.search('مجهز الرافدين');
    expect(controller.visibleParties, hasLength(1));

    controller.first();
    expect(controller.selectedParty?.name, 'مجهز الرافدين');

    controller.search('');
    controller.first();
    expect(controller.selectedParty?.name, 'شركة النخيل للتجارة');

    controller.next();
    expect(controller.selectedParty?.name, 'أحمد كريم');

    controller.last();
    expect(controller.selectedParty?.name, 'مجهز الكرادة');

    controller.next();
    expect(controller.selectedParty, isNull);

    controller.previous();
    expect(controller.selectedParty?.name, 'مجهز الكرادة');

    controller.last();
    expect(controller.selectedParty, isNull);
  });

  test('deletes only parties without known demo relationships', () async {
    final repositories = AppRepositories.demo();
    final controller = PartiesController(
      repository: repositories.parties,
      masterData: repositories.operationalMasterData,
    );
    addTearDown(controller.dispose);
    await controller.load();

    controller.select('party-001');
    expect((await controller.canDeleteSelected()).isAllowed, isFalse);
    expect(await controller.deleteSelected(), isNull);

    controller.select('party-004');
    expect((await controller.canDeleteSelected()).isAllowed, isTrue);
    expect((await controller.deleteSelected())?.id, 'party-004');
    expect(controller.state.parties, hasLength(12));
  });

  test('persists parties across controllers and reports missing references',
      () async {
    final repositories = AppRepositories.demo();
    final first = PartiesController(
      repository: repositories.parties,
      masterData: repositories.operationalMasterData,
    );
    addTearDown(first.dispose);
    await first.load();
    final submitted = Party(
      id: 'party-persistence-test',
      number: first.nextNumber,
      createdAt: DateTime(2026, 8, 5),
      name: 'طرف مستمر',
      type: PartyType.customer,
      workplace: '',
      branch: '',
      phone: '',
      alternatePhone: '',
      city: '',
      address: '',
      notes: '',
      balanceIqd: 0,
      balanceUsd: 0,
    );
    final added = await first.add(submitted);
    expect(added.entityId, isNot(submitted.entityId));

    final reopened = PartiesController(
      repository: repositories.parties,
      masterData: repositories.operationalMasterData,
    );
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(
      reopened.state.parties.any(
        (party) => party.entityId == added.entityId,
      ),
      isTrue,
    );

    final masterData = DemoOperationalMasterDataRepository();
    final brokenRepository = DemoPartyRepository(
      masterData: masterData,
      initialValues: [demoParties().first],
      initialMasterDataReferences: {
        EntityId('party-001'): PartyMasterDataReferences(
          workplaceId: EntityId('missing-workplace'),
          branchId: EntityId('missing-branch'),
        ),
      },
    );
    final broken = PartiesController(
      repository: brokenRepository,
      masterData: masterData,
    );
    addTearDown(broken.dispose);
    await broken.load();
    expect(broken.state.dataState.status, AppDataStatus.missingReference);
  });

  test('enforces canonical names and complete master-data references',
      () async {
    final repositories = AppRepositories.demo();
    final duplicate = Party(
      id: 'party-normalized-duplicate',
      number: 99,
      createdAt: DateTime(2026, 8, 5),
      name: '  أَحمد   كريم  ',
      type: PartyType.customer,
      workplace: '',
      branch: '',
      phone: '',
      alternatePhone: '',
      city: '',
      address: '',
      notes: '',
      balanceIqd: 0,
      balanceUsd: 0,
    );
    await expectLater(
      repositories.parties.saveWithMasterData(
        duplicate,
        const PartyMasterDataReferences(),
      ),
      throwsStateError,
    );

    final workplace = (await repositories.operationalMasterData.getByKind(
      OperationalMasterDataKind.workplace,
    ))
        .first;
    await expectLater(
      repositories.parties.saveWithMasterData(
        duplicate.copyWith(name: 'طرف بمرجع ناقص'),
        PartyMasterDataReferences(workplaceId: workplace.id),
      ),
      throwsStateError,
    );
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
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('partiesTable')),
          )
          .accentColor,
      AppModuleColors.parties,
    );
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
    expect(
      find.ancestor(
        of: find.byKey(const Key('partyTimeField')),
        matching: find.byType(AppTimeField),
      ),
      findsOneWidget,
    );

    final readOnlyDecoration = _fieldDecoration(
      tester,
      find.byKey(const Key('partyNumberField')),
    );
    expect(readOnlyDecoration.fillColor, AppColors.neutralSurface);
    expect(
      (readOnlyDecoration.disabledBorder as OutlineInputBorder)
          .borderSide
          .color,
      AppColors.border,
    );

    final nameDecoration = _fieldDecoration(
      tester,
      find.byKey(const Key('partyNameField')),
    );
    expect(nameDecoration.fillColor, AppColors.surface);
    expect(
      (nameDecoration.enabledBorder as OutlineInputBorder)
          .borderSide
          .color,
      AppColors.border,
    );
    final focusedNameBorder =
        nameDecoration.focusedBorder as OutlineInputBorder;
    expect(focusedNameBorder.borderSide.color, AppColors.blue);
    expect(focusedNameBorder.borderSide.width, 1.6);
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(const Key('partyNameField')),
              matching: find.byIcon(Icons.person_rounded),
            ),
          )
          .color,
      AppColors.blue,
    );
    expect(
      tester
          .widget<AppTableActionButton>(
            find.byKey(const Key('partyStatement_party-001')),
          )
          .foregroundColor,
      Colors.black,
    );

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

  testWidgets('guards system back and opens only one discard confirmation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('partyNameField')),
      'طرف غير محفوظ',
    );
    await tester.pump();

    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('partiesScreen')),
    );
    shell.onBack!();
    shell.onBack!();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('partiesScreen')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('partiesScreen')), findsNothing);
    expect(find.byKey(const Key('dashboardCard_parties')), findsOneWidget);
  });

  testWidgets('prevents duplicate party names when saving',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('partyNameField')),
      '  أحمد   كريم  ',
    );
    await tester.tap(find.byKey(const Key('partiesSaveButton')));
    await tester.pump();

    final toast = find.byKey(const Key('appToast'));
    expect(toast, findsOneWidget);
    expect(tester.widget<SnackBar>(toast).backgroundColor, AppColors.orange);
    expect(
      find.descendant(
        of: toast,
        matching: find.text('يوجد طرف مسجل بهذا الاسم'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('partiesTable')),
          )
          .rows,
      hasLength(13),
    );
  });

  testWidgets('shows and filters workplace and branch suggestions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();

    final wholesaleCount =
        find.text('تجارة الجملة').evaluate().length;
    await tester.tap(find.byKey(const Key('partyWorkplaceField')));
    await tester.pump();
    expect(
      find.text('تجارة الجملة'),
      findsNWidgets(wholesaleCount + 1),
    );

    await tester.enterText(
      find.byKey(const Key('partyWorkplaceField')),
      'الأجه',
    );
    await tester.pump();
    expect(find.text('تجارة الجملة'), findsNWidgets(wholesaleCount));

    final mosulCount = find.text('الموصل').evaluate().length;
    final erbilCount = find.text('أربيل').evaluate().length;
    await tester.tap(find.text('الأجهزة المكتبية').last);
    await tester.pump();
    // The workplace selection rebuilds the form first, then refreshes the
    // newly focused branch overlay with the stable-ID-filtered options.
    await tester.pump();
    expect(
      _fieldText(tester, find.byKey(const Key('partyWorkplaceField'))),
      'الأجهزة المكتبية',
    );
    expect(find.text('الموصل'), findsNWidgets(mosulCount + 1));
    expect(find.text('أربيل'), findsNWidgets(erbilCount));
  });

  testWidgets('opens statement options and report from a party row',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('partyStatement_party-001')),
    );
    await tester.pumpAndSettle();

    final optionsDialog =
        find.byKey(const Key('appStatementOptionsDialog'));
    expect(optionsDialog, findsOneWidget);
    expect(
      tester.widget<AppModuleDialog>(optionsDialog).accentColor,
      AppModuleColors.parties,
    );
    expect(
      _fieldText(tester, find.byKey(const Key('appStatementParty'))),
      'شركة النخيل للتجارة',
    );
    expect(
      _fieldDecoration(
        tester,
        find.byKey(const Key('appStatementParty')),
      ).labelText,
      'اسم الطرف',
    );

    await tester.tap(find.byKey(const Key('appStatementConfirm')));
    await tester.pumpAndSettle();

    final report = find.byKey(const Key('appStatementReportDialog'));
    expect(report, findsOneWidget);
    expect(
      tester.widget<AppModuleDialog>(report).accentColor,
      AppModuleColors.parties,
    );
    expect(
      find.descendant(
        of: report,
        matching: find.text('شركة النخيل للتجارة'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('appStatementReportTable')), findsOneWidget);
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('appStatementReportTable')),
          )
          .rows,
      hasLength(2),
    );
    expect(find.text('قائمة بيع رقم 101 — تضاف إلى حساب الزبون'), findsOneWidget);
    expect(find.text('سند قبض رقم 1 — دفعة على الحساب'), findsOneWidget);
    expect(
      find.descendant(
        of: report,
        matching: find.text('500,000'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows loading and an error when party statement loading fails',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = AppStore.demo();
    addTearDown(store.dispose);
    final service = _ControlledPartyStatementService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AppStoreScope(
            store: store,
            child: PartiesScreen(statementService: service),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('partyStatement_party-001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appStatementConfirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.byKey(const Key('partyStatementLoadingDialog')), findsOneWidget);
    expect(find.byKey(const Key('partyStatementLoadingState')), findsOneWidget);

    service.completeWithError();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.byKey(const Key('partyStatementLoadingDialog')), findsNothing);
    expect(find.byKey(const Key('appStatementReportDialog')), findsNothing);
    expect(
      find.text('تعذر تحميل كشف الحساب. حاول مرة أخرى.'),
      findsOneWidget,
    );
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
    expect(_fieldText(tester, name), 'مجهز الكرادة');

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
    expect(_fieldText(tester, name), 'مجهز الكرادة');
  });

  testWidgets('quick-creates a workplace and a constrained branch',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore.demo();
    addTearDown(store.dispose);

    await tester.pumpWidget(AlmumayazApp(store: store));
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();

    const workplaceName = 'جهة عمل المرحلة الثانية';
    await tester.enterText(
      find.byKey(const Key('partyWorkplaceField')),
      workplaceName,
    );
    await tester.pump();
    await tester.tap(find.text('إضافة جهة عمل جديدة'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('partyQuickWorkplaceDialog')),
        findsOneWidget);
    expect(
      _fieldText(
        tester,
        find.byKey(const Key('partyQuickWorkplaceNameField')),
      ),
      workplaceName,
    );
    await tester.tap(find.byKey(const Key('partyQuickWorkplaceConfirm')));
    await tester.pumpAndSettle();
    expect(
      _fieldText(tester, find.byKey(const Key('partyWorkplaceField'))),
      workplaceName,
    );

    final workplaces = await store.repositories.operationalMasterData
        .getByKind(OperationalMasterDataKind.workplace);
    final workplace =
        workplaces.singleWhere((record) => record.name == workplaceName);

    const branchName = 'فرع المرحلة الثانية';
    await tester.enterText(
      find.byKey(const Key('partyBranchField')),
      branchName,
    );
    await tester.pump();
    await tester.tap(find.text('إضافة فرع جديد'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('partyQuickBranchDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('partyQuickBranchConfirm')));
    await tester.pumpAndSettle();
    expect(
      _fieldText(tester, find.byKey(const Key('partyBranchField'))),
      branchName,
    );

    final branches = await store.repositories.operationalMasterData.getByKind(
      OperationalMasterDataKind.branch,
      parentId: workplace.id,
    );
    final branch =
        branches.singleWhere((record) => record.name == branchName);
    expect(branch.parentId, workplace.id);
    expect(branch.id.value, isNotEmpty);
  });

  testWidgets('normal party creation never reuses a deleted issued identity',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore.demo();
    addTearDown(store.dispose);

    await tester.pumpWidget(AlmumayazApp(store: store));
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();

    const firstName = 'طرف إصدار عادي أول';
    await tester.enterText(
      find.byKey(const Key('partyNameField')),
      firstName,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('partiesSaveButton')));
    await tester.pumpAndSettle();
    final first = (await store.repositories.parties.getAll())
        .singleWhere((party) => party.name == firstName);

    await tester.tap(find.byKey(const Key('partiesDeleteButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();
    expect(await store.repositories.parties.getById(first.entityId), isNull);

    const secondName = 'طرف إصدار عادي ثان';
    await tester.enterText(
      find.byKey(const Key('partyNameField')),
      secondName,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('partiesSaveButton')));
    await tester.pumpAndSettle();
    final second = (await store.repositories.parties.getAll())
        .singleWhere((party) => party.name == secondName);

    expect(second.number, greaterThan(first.number));
    expect(second.entityId, isNot(first.entityId));
    expect(_fieldText(tester, find.byKey(const Key('partyNumberField'))),
        second.number.toString());
  });

  testWidgets('party form retains stable master IDs after master renames',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore.demo();
    addTearDown(store.dispose);
    final masterData = store.repositories.operationalMasterData;
    final workplace = await masterData.createNamedRecord(
      const CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.workplace,
        name: 'جهة شاشة قبل التعديل',
      ),
    );
    final branch = await masterData.createNamedRecord(
      CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.branch,
        name: 'فرع شاشة قبل التعديل',
        parentId: workplace.id,
      ),
    );
    final party = await store.repositories.parties.quickCreate(
      PartyQuickCreateRequest(
        name: 'طرف شاشة بمرجع ثابت',
        type: PartyType.customer,
        workplaceId: workplace.id,
        branchId: branch.id,
      ),
    );
    await masterData.save(
      OperationalMasterDataRecord(
        id: workplace.id,
        kind: workplace.kind,
        number: workplace.number,
        name: 'جهة شاشة بعد التعديل',
      ),
    );
    await masterData.save(
      OperationalMasterDataRecord(
        id: branch.id,
        kind: branch.kind,
        number: branch.number,
        name: 'فرع شاشة بعد التعديل',
        parentId: workplace.id,
      ),
    );

    await tester.pumpWidget(AlmumayazApp(store: store));
    await _login(tester);
    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('partiesSearchField')),
      party.name,
    );
    await tester.pump();
    await tester.tap(find.byKey(Key('partyRow_${party.id}')));
    await tester.pumpAndSettle();

    final form = tester.widget<PartyForm>(find.byType(PartyForm));
    expect(form.workplaceId, workplace.id);
    expect(form.branchId, branch.id);
    expect(
      _fieldText(tester, find.byKey(const Key('partyWorkplaceField'))),
      'جهة شاشة بعد التعديل',
    );
    expect(
      _fieldText(tester, find.byKey(const Key('partyBranchField'))),
      'فرع شاشة بعد التعديل',
    );
  });

  testWidgets('hides master-data quick-create without Settings manage',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore.demo();
    addTearDown(store.dispose);
    await store.signIn(
      SignInCredentials(username: 'admin', password: 'password'),
    );
    final role = await store.services.administration.saveRole(
      RoleSaveRequest(
        name: 'إضافة الأطراف فقط',
        permissions: {
          PermissionCode(
            module: 'parties',
            action: PermissionAction.view,
          ),
          PermissionCode(
            module: 'parties',
            action: PermissionAction.create,
          ),
        },
      ),
    );
    await store.services.administration.createUser(
      UserCreateRequest(
        fullName: 'مستخدم إضافة الأطراف',
        username: 'parties.creator',
        roleIds: {role.id},
        initialPassword: 'parties-password',
      ),
    );
    await store.signOut();

    await tester.pumpWidget(AlmumayazApp(store: store));
    await _login(
      tester,
      username: 'parties.creator',
      password: 'parties-password',
    );
    await tester.tap(find.byKey(const Key('dashboardCard_parties')));
    await tester.pumpAndSettle();

    final workplaceAutocomplete = tester.widget<
        AppAutocompleteField<OperationalMasterDataRecord>>(
      find.ancestor(
        of: find.byKey(const Key('partyWorkplaceField')),
        matching: find.byType(
          AppAutocompleteField<OperationalMasterDataRecord>,
        ),
      ),
    );
    expect(workplaceAutocomplete.onCreateRequested, isNull);

    await tester.enterText(
      find.byKey(const Key('partyWorkplaceField')),
      'جهة غير موجودة',
    );
    await tester.pump();
    expect(find.text('إضافة جهة عمل جديدة'), findsNothing);
  });
}

class _ControlledPartyStatementService implements PartyStatementService {
  final Completer<PartyStatementResult> _completer = Completer();

  @override
  Future<PartyStatementResult> load(PartyStatementQuery query) {
    return _completer.future;
  }

  void completeWithError() {
    _completer.completeError(StateError('statement unavailable'));
  }
}

Future<void> _login(
  WidgetTester tester, {
  String username = 'admin',
  String password = 'password',
}) async {
  await tester.enterText(find.byKey(const Key('usernameField')), username);
  await tester.enterText(find.byKey(const Key('passwordField')), password);
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

InputDecoration _fieldDecoration(WidgetTester tester, Finder field) {
  return tester
      .widget<InputDecorator>(
        find.descendant(of: field, matching: find.byType(InputDecorator)),
      )
      .decoration;
}
