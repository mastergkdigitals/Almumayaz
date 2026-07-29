import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/dashboard/presentation/dashboard_card.dart';
import 'package:erp/features/settings/presentation/widgets/settings_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the six-section Settings hub with approved gradients',
      (tester) async {
    await _openSettings(tester);

    expect(find.byKey(const Key('settingsScreen')), findsOneWidget);
    expect(find.byKey(const Key('settingsHub')), findsOneWidget);

    const sections = [
      ('businessPolicies', 'سياسات العمل'),
      ('defaultSettings', 'الإعدادات الافتراضية'),
      ('masterData', 'إدارة البيانات الأساسية'),
      ('backup', 'النسخ الاحتياطي والبيانات'),
      ('usersSecurity', 'المستخدمون والأمان'),
      ('archive', 'الأرشيف الإلكتروني'),
    ];
    for (final section in sections) {
      expect(
        find.byKey(Key('settingsSectionCard_${section.$1}')),
        findsOneWidget,
      );
      expect(find.text(section.$2), findsOneWidget);
    }

    final firstRowY = tester
        .getTopLeft(
          find.byKey(
            const Key('settingsSectionCard_businessPolicies'),
          ),
        )
        .dy;
    expect(
      tester
          .getTopLeft(
            find.byKey(
              const Key('settingsSectionCard_defaultSettings'),
            ),
          )
          .dy,
      moreOrLessEquals(firstRowY),
    );
    expect(
      find.byKey(const Key('settingsSectionCard_printing')),
      findsNothing,
    );

    final secondRowY = tester
        .getTopLeft(
          find.byKey(const Key('settingsSectionCard_masterData')),
        )
        .dy;
    expect(
      tester
          .getTopLeft(
            find.byKey(const Key('settingsSectionCard_backup')),
          )
          .dy,
      moreOrLessEquals(secondRowY),
    );
    expect(secondRowY, greaterThan(firstRowY));

    final thirdRowY = tester
        .getTopLeft(
          find.byKey(const Key('settingsSectionCard_usersSecurity')),
        )
        .dy;
    expect(
      tester
          .getTopLeft(
            find.byKey(const Key('settingsSectionCard_archive')),
          )
          .dy,
      moreOrLessEquals(thirdRowY),
    );
    expect(thirdRowY, greaterThan(secondRowY));

    DashboardCard card(String id) => tester.widget<DashboardCard>(
          find.byKey(Key('settingsSectionCard_$id')),
        );

    expect(
      card('defaultSettings').colors,
      const [
        Color(0xFF312E81),
        Color(0xFF4F46E5),
        Color(0xFFA5B4FC),
      ],
    );
    expect(
      card('defaultSettings').shadowColor,
      const Color(0xFF4F46E5),
    );
    expect(
      card('usersSecurity').colors,
      const [
        Color(0xFF7F1D1D),
        Color(0xFFDC2626),
        Color(0xFFFCA5A5),
      ],
    );
    expect(
      card('usersSecurity').shadowColor,
      const Color(0xFFB91C1C),
    );
    expect(card('archive').colors, AppModulePalettes.sales.gradient);
    expect(
      card('archive').shadowColor,
      AppModulePalettes.sales.shadow,
    );
    expect(card('backup').colors, AppModulePalettes.reports.gradient);
    expect(card('backup').shadowColor, AppModulePalettes.reports.shadow);

    final expectedTint = Color.alphaBlend(
      AppModuleColors.settings.withAlpha(12),
      AppColors.surface,
    );
    final shell = tester.widget<AppScreenShell>(
      find.byKey(const Key('settingsScreen')),
    );
    expect(shell.title, 'الإعدادات');
    expect(shell.backgroundColor, expectedTint);
    expect(
      tester
          .widget<ColoredBox>(
            find.byKey(const Key('settingsTintBackground')),
          )
          .color,
      expectedTint,
    );

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settingsScreen')), findsNothing);
    expect(
      find.byKey(const Key('dashboardCard_settings')),
      findsOneWidget,
    );
  });

  testWidgets('keeps printing inside Business Policies and rounds panels',
      (tester) async {
    await _openSettings(tester);

    await _openSection(tester, 'businessPolicies');
    expect(
      find.byKey(const Key('businessPoliciesSettingsContent')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsDefaultExchangeRateField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsAllowInsufficientStockSale')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsDefaultCustomerDebtLimitField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsOverdueDebtAlerts')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<SettingsTemplatePanel>(
            find.byKey(const Key('settingsPricingInventoryPanel')),
          )
          .accentColor,
      AppModulePalettes.settings.middle,
    );
    expect(
      tester
          .widget<AppSwitchField>(
            find.byKey(
              const Key('settingsAllowInsufficientStockSale'),
            ),
          )
          .accentColor,
      AppModulePalettes.settings.middle,
    );
    expect(
      tester
          .getSize(
            find.byKey(const Key('settingsPricingInventoryPanel')),
          )
          .height,
      moreOrLessEquals(
        tester
            .getSize(
              find.byKey(const Key('settingsDebtInstallmentsPanel')),
            )
            .height,
      ),
    );
    final switchSurface = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(
              const Key('settingsAllowInsufficientStockSale'),
            ),
            matching: find.byType(Container),
          ),
        )
        .firstWhere(
          (container) =>
              container.decoration is BoxDecoration &&
              (container.decoration! as BoxDecoration).border is Border,
        );
    final switchBorder =
        (switchSurface.decoration! as BoxDecoration).border! as Border;
    expect(
      switchBorder.top.color,
      Color.lerp(
        AppModulePalettes.settings.middle,
        AppColors.surface,
        0.62,
      ),
    );

    final policiesList = tester.widget<ListView>(
      find.byKey(const Key('businessPoliciesSettingsContent')),
    );
    expect(policiesList.padding, const EdgeInsets.all(AppSpacing.md));

    final panelClip = tester.widget<ClipRRect>(
      find
          .descendant(
            of: find.byKey(const Key('settingsPricingInventoryPanel')),
            matching: find.byType(ClipRRect),
          )
          .first,
    );
    expect(
      panelClip.borderRadius,
      BorderRadius.circular(AppRadii.lg),
    );
    final panelSurface = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(
              const Key('settingsPricingInventoryPanel'),
            ),
            matching: find.byType(Container),
          ),
        )
        .firstWhere(
          (container) =>
              container.foregroundDecoration is BoxDecoration &&
              (container.foregroundDecoration! as BoxDecoration)
                  .border is Border,
        );
    final panelBorder =
        (panelSurface.foregroundDecoration! as BoxDecoration).border!
            as Border;
    expect(
      panelBorder.top.color,
      Color.lerp(
        AppModulePalettes.settings.middle,
        AppColors.surface,
        0.62,
      ),
    );
    expect(panelBorder.top.width, 1.4);

    await tester.drag(
      find.byKey(const Key('businessPoliciesSettingsContent')),
      const Offset(0, -420),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('settingsPrintingPanel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsDefaultPrinterField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsPaperSizeField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsPrintCopiesField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsPrintPreviewSwitch')),
      findsOneWidget,
    );

    await _returnToSettingsHub(tester);

    await _openSection(tester, 'defaultSettings');
    expect(
      find.byKey(const Key('operationalDefaultsSettingsContent')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsPurchaseDefaultWarehouse')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsPurchaseDefaultPayment')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsSalesDefaultType')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsCashboxDefaultAccount')),
      findsOneWidget,
    );
    const defaultsAccent = Color(0xFF4F46E5);
    expect(
      tester
          .widget<SettingsTemplatePanel>(
            find.byKey(const Key('settingsPurchaseDefaultsPanel')),
          )
          .accentColor,
      defaultsAccent,
    );
    expect(
      tester
          .widget<AppScreenShell>(
            find.byKey(const Key('settingsScreen')),
          )
          .backgroundColor,
      Color.alphaBlend(
        defaultsAccent.withAlpha(12),
        AppColors.surface,
      ),
    );
    final defaultsPanelHeight = tester
        .getSize(find.byKey(const Key('settingsPurchaseDefaultsPanel')))
        .height;
    expect(
      tester
          .getSize(find.byKey(const Key('settingsSalesDefaultsPanel')))
          .height,
      moreOrLessEquals(defaultsPanelHeight),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('settingsCashboxDefaultsPanel')))
          .height,
      moreOrLessEquals(defaultsPanelHeight),
    );
  });

  testWidgets('preserves Settings edits and guards unsaved exit',
      (tester) async {
    await _openSettings(tester);
    await _openSection(tester, 'businessPolicies');

    const exchangeRateKey = Key('settingsDefaultExchangeRateField');
    await tester.enterText(find.byKey(exchangeRateKey), '1,400');
    await tester.pump();

    await _returnToSettingsHub(tester);
    expect(
      _hasTextFocus(
        tester,
        find.byKey(exchangeRateKey, skipOffstage: false),
        skipOffstage: false,
      ),
      isFalse,
    );
    await _openSection(tester, 'businessPolicies');
    expect(
      _fieldText(tester, find.byKey(exchangeRateKey)),
      '1,400',
    );

    await _returnToSettingsHub(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    expect(find.text('مغادرة الإعدادات'), findsOneWidget);

    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pump();
    expect(find.byKey(const Key('settingsHub')), findsOneWidget);

    await _openSection(tester, 'businessPolicies');
    final saveButton =
        find.byKey(const Key('settingsSaveBusinessPolicies'));
    await Scrollable.ensureVisible(
      tester.element(saveButton),
      duration: Duration.zero,
    );
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pump();

    await _returnToSettingsHub(tester);
    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsNothing);
    expect(find.byKey(const Key('settingsScreen')), findsNothing);
  });

  testWidgets('shows master data and backup testing controls',
      (tester) async {
    await _openSettings(tester);

    await _openSection(tester, 'masterData');
    expect(
      find.byKey(const Key('masterDataSettingsContent')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsGroupsTypesTemplate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsItemGroupsTable')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('settingsItemGroupsTable')),
          )
          .accentColor,
      AppModulePalettes.parties.middle,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('settingsItemGroupsPanel')))
          .height,
      moreOrLessEquals(
        tester
            .getSize(find.byKey(const Key('settingsItemTypesPanel')))
            .height,
      ),
    );

    final itemTypesTable = tester.widget<AppDataTable>(
      find.byKey(const Key('settingsItemTypesTable')),
    );
    expect(
      itemTypesTable.columns.map((column) => column.label),
      ['ت', 'الاسم', 'المجموعة', 'الحالة', 'الإجراءات'],
    );
    expect(
      (itemTypesTable.rows.first.cells[2] as Text).data,
      'المواد الغذائية',
    );

    await tester.enterText(
      find.byKey(const Key('settingsItemGroupsNameField')),
      'مجموعة اختبار',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('settingsItemGroupsClearButton')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(
      find.byKey(const Key('settingsItemGroupsAddButton')),
    );
    await tester.pump();
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('settingsItemGroupsTable')),
          )
          .rows
          .any(
            (row) =>
                (row.cells[1] as Text).data == 'مجموعة اختبار',
          ),
      isTrue,
    );
    final itemTypeParent = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(const Key('settingsItemTypesParentField')),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(
      itemTypeParent.options.map((option) => option.label),
      contains('مجموعة اختبار'),
    );

    tester
        .widget<AppDataTable>(
          find.byKey(const Key('settingsItemTypesTable')),
        )
        .rows
        .first
        .onTap!();
    await tester.pump();
    tester
        .widget<AppDropdownField<String>>(
          find.ancestor(
            of: find.byKey(const Key('settingsItemTypesParentField')),
            matching: find.byType(AppDropdownField<String>),
          ),
        )
        .onChanged('مجموعة اختبار');
    await tester.pump();
    tester
        .widget<AppButton>(
          find.byKey(const Key('settingsItemTypesUpdateButton')),
        )
        .onPressed!();
    await tester.pump();
    expect(
      (tester
                  .widget<AppDataTable>(
                    find.byKey(const Key('settingsItemTypesTable')),
                  )
                  .rows
                  .first
                  .cells[2]
              as Text)
          .data,
      'مجموعة اختبار',
    );

    tester
        .widget<AppDataTable>(
          find.byKey(const Key('settingsItemGroupsTable')),
        )
        .rows
        .last
        .onTap!();
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('settingsItemGroupsNameField')),
      'مجموعة اختبار معدلة',
    );
    tester
        .widget<AppButton>(
          find.byKey(const Key('settingsItemGroupsUpdateButton')),
        )
        .onPressed!();
    await tester.pump();
    expect(
      (tester
                  .widget<AppDataTable>(
                    find.byKey(const Key('settingsItemTypesTable')),
                  )
                  .rows
                  .first
                  .cells[2]
              as Text)
          .data,
      'مجموعة اختبار معدلة',
    );

    await tester.tap(
      find.byKey(
        const Key('masterDataTab_workplacesBranches'),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('settingsWorkplacesBranchesTemplate')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('masterDataTab_groupsTypes')),
    );
    await tester.pump();
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('settingsItemGroupsTable')),
          )
          .rows
          .any(
            (row) =>
                (row.cells[1] as Text).data == 'مجموعة اختبار معدلة',
          ),
      isTrue,
    );

    await tester.tap(
      find.byKey(const Key('masterDataTab_cashboxAccounts')),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('settingsCashboxAccountsTemplate')),
      findsOneWidget,
    );
    await _returnToSettingsHub(tester);

    await _openSection(tester, 'backup');
    expect(
      find.byKey(const Key('backupDataSettingsContent')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsLocalBackupPathField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsAutomaticBackupSwitch')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsToggleDriveConnectionButton')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const Key('settingsLocalBackupPanel')))
          .height,
      moreOrLessEquals(
        tester
            .getSize(find.byKey(const Key('settingsDriveBackupPanel')))
            .height,
      ),
    );

    await tester.tap(
      find.byKey(const Key('settingsToggleDriveConnectionButton')),
    );
    await tester.pump();
    expect(find.text('الحساب مرتبط وجاهز للنسخ'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('backupDataSettingsContent')),
      const Offset(0, -700),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('settingsSaveBackupConfigurationButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsBackupHistoryTable')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('settingsBackupHistoryTable')),
          )
          .accentColor,
      AppModulePalettes.reports.middle,
    );
  });

  testWidgets('shows users security logs and archive interactions',
      (tester) async {
    await _openSettings(tester);

    await _openSection(tester, 'usersSecurity');
    expect(
      find.byKey(const Key('usersSecuritySettingsContent')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsUsersTable')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('settingsUsersTable')),
          )
          .accentColor,
      const Color(0xFFDC2626),
    );

    await _sendControlShortcut(tester, LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(
      find.byKey(const Key('settingsSecurityLogsTable')),
      findsOneWidget,
    );
    expect(
      _hasTextFocus(
        tester,
        find.byKey(const Key('settingsSecurityLogSearchField')),
      ),
      isTrue,
    );

    await tester.tap(
      find.byKey(const Key('usersSecurityTab_security')),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('settingsCurrentPasswordField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsIdleLockSwitch')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('usersSecurityTab_logs')));
    await tester.pump();
    expect(
      find.byKey(const Key('settingsSecurityLogSearchField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsSecurityLogsTable')),
      findsOneWidget,
    );
    expect(find.text('استعادة'), findsWidgets);
    await _returnToSettingsHub(tester);

    await _openSection(tester, 'archive');
    expect(
      find.byKey(const Key('electronicArchiveSettingsContent')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsArchiveSearchField')),
      findsOneWidget,
    );
    await _sendControlShortcut(tester, LogicalKeyboardKey.keyF);
    await tester.pump();
    expect(
      _hasTextFocus(
        tester,
        find.byKey(const Key('settingsArchiveSearchField')),
      ),
      isTrue,
    );
    expect(
      find.byKey(const Key('settingsArchiveTable')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('settingsArchiveTable')),
          )
          .accentColor,
      AppModulePalettes.sales.middle,
    );

    await tester.tap(
      find.byKey(const Key('settingsArchiveUploadButton')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('settingsArchiveUploadDialog')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('settingsArchiveDocumentNameField')),
      'مستند اختبار',
    );
    await tester.tap(
      find.byKey(const Key('settingsArchiveChooseFileButton')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('settingsArchiveUploadConfirmButton')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('settingsArchiveUploadDialog')),
      findsNothing,
    );
    expect(find.text('مستند اختبار'), findsOneWidget);
  });

  testWidgets('keeps user status separate and edits roles and passwords',
      (tester) async {
    await _openSettings(tester);
    await _openSection(tester, 'usersSecurity');

    AppStatusBadge userStatus(int userId) =>
        tester.widget<AppStatusBadge>(
          find.descendant(
            of: find.byKey(Key('settingsUserStatus_$userId')),
            matching: find.byType(AppStatusBadge),
          ),
        );

    void pressUserAction(String key) {
      tester
          .widget<AppTableActionButton>(find.byKey(Key(key)))
          .onPressed!();
    }

    expect(userStatus(2).label, 'نشط');
    pressUserAction('settingsUserEnable_2');
    await tester.pump();
    expect(userStatus(2).label, 'معطل');

    pressUserAction('settingsUserLock_2');
    await tester.pump();
    expect(userStatus(2).label, 'معطل ومقفل');

    pressUserAction('settingsUserLock_2');
    await tester.pump();
    expect(userStatus(2).label, 'معطل');

    pressUserAction('settingsUserPassword_2');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('settingsUserPasswordDialog_2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsUserPasswordConfirm_2')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('settingsUserPasswordNewField_2')),
      'password-2',
    );
    await tester.enterText(
      find.byKey(const Key('settingsUserPasswordConfirmField_2')),
      'password-2',
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('settingsUserPasswordConfirm_2')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(
      find.byKey(const Key('settingsUserPasswordConfirm_2')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('settingsUserPasswordDialog_2')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const Key('usersSecurityTab_roles')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('settingsAddRoleButton')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('settingsRoleDialog_new')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsRolePermissionMatrix')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('settingsRoleNameField')),
      'دور اختبار',
    );
    await tester.tap(
      find.byKey(const Key('settingsRoleSelectAllButton')),
    );
    await tester.pump();
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('settingsRoleDialogConfirmButton')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(
      find.byKey(const Key('settingsRoleDialogConfirmButton')),
    );
    await tester.pumpAndSettle();

    final rolesTable = tester.widget<AppDataTable>(
      find.byKey(const Key('settingsRolesTable')),
    );
    expect(
      rolesTable.rows.any(
        (row) => (row.cells[1] as Text).data == 'دور اختبار',
      ),
      isTrue,
    );
  });
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const AlmumayazApp());
  await tester.enterText(
    find.byKey(const Key('usernameField')),
    'admin',
  );
  await tester.enterText(
    find.byKey(const Key('passwordField')),
    'password',
  );
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byKey(const Key('dashboardCard_settings')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _openSection(
  WidgetTester tester,
  String sectionId,
) async {
  await tester.tap(
    find.byKey(Key('settingsSectionCard_$sectionId')),
  );
  await tester.pump();
  expect(
    find.byKey(Key('settingsSection_$sectionId')),
    findsOneWidget,
  );
}

Future<void> _returnToSettingsHub(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('appScreenBackButton')));
  await tester.pump();
  expect(find.byKey(const Key('settingsHub')), findsOneWidget);
}

String _fieldText(WidgetTester tester, Finder field) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: field,
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;
}

bool _hasTextFocus(
  WidgetTester tester,
  Finder field, {
  bool skipOffstage = true,
}) {
  return tester
      .widget<EditableText>(
        find.descendant(
          of: field,
          matching: find.byType(
            EditableText,
            skipOffstage: skipOffstage,
          ),
          skipOffstage: skipOffstage,
        ),
      )
      .focusNode
      .hasFocus;
}

Future<void> _sendControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}
