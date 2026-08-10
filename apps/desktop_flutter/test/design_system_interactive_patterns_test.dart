import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  testWidgets('management dialogs add update and delete demo data',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final groupsButton =
        find.byKey(const Key('designGroupsTypesDialogButton'));
    await reveal(tester, groupsButton);
    await tester.tap(groupsButton);
    await tester.pump();

    final groupsDialog =
        find.byKey(const Key('designGroupsTypesDialog'));
    final initialDialogHeight = tester.getSize(groupsDialog).height;
    expect(
      find.byKey(const Key('designGroupsTypesDialogPrimaryList')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designGroupsTypesDialogSecondaryList')),
      findsOneWidget,
    );

    final primaryField =
        find.byKey(const Key('designGroupsTypesDialogPrimaryField'));
    final primaryTable = find.byKey(
      const Key('designGroupsTypesDialogPrimaryList'),
    );
    final initialPrimaryCount =
        tester.widget<AppDataTable>(primaryTable).rows.length;
    await tester.enterText(primaryField, 'قرطاسية');
    await tester.tap(
      find.byKey(const Key('designGroupsTypesDialogPrimaryCommit')),
    );
    await tester.pump();
    expect(find.text('هذا الاسم مستخدم مسبقاً'), findsOneWidget);
    expect(
      tester.widget<AppDataTable>(primaryTable).rows.length,
      initialPrimaryCount,
    );

    tester
        .widget<AppTableActionButton>(
          find.byKey(
            const Key(
              'designGroupsTypesDialogPrimaryDelete-primary-0',
            ),
          ),
        )
        .onPressed!();
    await tester.pump();
    expect(find.text('لا يمكن حذف سجل نظام محمي'), findsOneWidget);
    expect(find.byKey(const Key('appConfirmDialog')), findsNothing);

    tester
        .widget<AppTableActionButton>(
          find.byKey(
            const Key(
              'designGroupsTypesDialogPrimaryDelete-primary-1',
            ),
          ),
        )
        .onPressed!();
    await tester.pump();
    expect(
      find.text('لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('appConfirmDialog')), findsNothing);

    await tester.enterText(primaryField, 'أثاث مكتبي');
    await tester.tap(
      find.byKey(const Key('designGroupsTypesDialogPrimaryCommit')),
    );
    await tester.pump();

    expect(tester.getSize(groupsDialog).height, initialDialogHeight);
    expect(
      tester
          .widget<AppDataTable>(primaryTable)
          .rows
          .where((row) => (row.cells[1] as Text).data == 'أثاث مكتبي'),
      hasLength(1),
    );
    tester
        .widget<AppDataTable>(
          find.byKey(const Key('designGroupsTypesDialogPrimaryList')),
        )
        .rows
        .singleWhere(
          (row) => (row.cells[1] as Text).data == 'أثاث مكتبي',
        )
        .onTap!();
    await tester.pump();

    await tester.enterText(primaryField, 'مفروشات مكتبية');
    tester
        .widget<AppButton>(
          find.byKey(const Key('designGroupsTypesDialogPrimaryUpdate')),
        )
        .onPressed!();
    await tester.pump();

    expect(find.text('أثاث مكتبي'), findsNothing);
    expect(
      tester
          .widget<AppDataTable>(primaryTable)
          .rows
          .where(
            (row) =>
                (row.cells[1] as Text).data == 'مفروشات مكتبية',
          ),
      hasLength(1),
    );

    tester
        .widget<AppTableActionButton>(
          find.byKey(
            const Key(
              'designGroupsTypesDialogPrimaryDelete-primary-100',
            ),
          ),
        )
        .onPressed
        ?.call();
    await tester.pump();

    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('مفروشات مكتبية'), findsNothing);

    await tester.enterText(
      find.byKey(
        const Key('designGroupsTypesDialogSecondaryField'),
      ),
      'دفاتر',
    );
    await tester.tap(
      find.byKey(const Key('designGroupsTypesDialogSecondaryCommit')),
    );
    await tester.pump();
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('designGroupsTypesDialogSecondaryList')),
          )
          .rows
          .where((row) => (row.cells[1] as Text).data == 'دفاتر'),
      hasLength(1),
    );

    expect(
      find.byType(AppManagementPanel),
      findsNWidgets(2),
    );

    await tester.tap(
      find.byKey(const Key('designGroupsTypesDialogCancel')),
    );
    await tester.pump();

    final workplacesButton =
        find.byKey(const Key('designWorkplacesDialogButton'));
    await reveal(tester, workplacesButton);
    await tester.tap(workplacesButton);
    await tester.pump();

    expect(
      find.byKey(const Key('designWorkplacesDialogPrimaryField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designWorkplacesDialogSecondaryField')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('designWorkplacesDialogCancel')),
    );
    await tester.pump();

    final cashboxButton =
        find.byKey(const Key('designCashboxTabsDialogButton'));
    await reveal(tester, cashboxButton);
    await tester.tap(cashboxButton);
    await tester.pump();

    expect(
      find.byKey(const Key('designCashboxTabsDialogPrimaryField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designCashboxTabsDialogSecondaryField')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('designCashboxTabsDialogCancel')),
    );
    await tester.pump();
  });

  testWidgets('quick-create references show essential themed fields',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final partyButton =
        find.byKey(const Key('designQuickPartyButton'));
    await reveal(tester, partyButton);
    await tester.tap(partyButton);
    await tester.pump();

    final partyDialog =
        find.byKey(const Key('designQuickPartyDialog'));
    expect(partyDialog, findsOneWidget);
    expect(
      find.descendant(
        of: partyDialog,
        matching: find.text(
          'هذا الطرف غير موجود، هل تود إضافته؟',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designQuickPartypartyName')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designQuickPartyType')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designQuickPartyPhone')),
      findsOneWidget,
    );
    final partyConfirm = find.byKey(
      const Key('designQuickPartyConfirm'),
    );
    expect(
      tester.widget<AppButton>(partyConfirm).backgroundColor,
      AppModuleColors.parties,
    );
    expect(tester.widget<AppButton>(partyConfirm).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('designQuickPartypartyName')),
      'طرف تجريبي',
    );
    await tester.pump();
    expect(
      tester.widget<AppButton>(partyConfirm).onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<Row>(
            find.byKey(const Key('designQuickPartyActions')),
          )
          .mainAxisAlignment,
      MainAxisAlignment.center,
    );
    await tester.tap(
      find.byKey(const Key('designQuickPartyCancel')),
    );
    await tester.pump();

    final itemButton = find.byKey(const Key('designQuickItemButton'));
    await reveal(tester, itemButton);
    await tester.tap(itemButton);
    await tester.pump();

    expect(
      find.byKey(const Key('designQuickItemitemCode')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('designQuickItemitemName')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('designQuickItemConfirm')),
          )
          .backgroundColor,
      AppModuleColors.warehouses,
    );
    await tester.tap(
      find.byKey(const Key('designQuickItemCancel')),
    );
    await tester.pump();

    final cashboxButton =
        find.byKey(const Key('designQuickCashboxSubButton'));
    await reveal(tester, cashboxButton);
    await tester.tap(cashboxButton);
    await tester.pump();

    expect(
      find.byKey(const Key('designQuickCashboxSubMainAccount')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('designQuickCashboxSubcashboxSubName'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('designQuickCashboxSubConfirm')),
          )
          .backgroundColor,
      AppModuleColors.cashbox,
    );
    await tester.tap(
      find.byKey(const Key('designQuickCashboxSubCancel')),
    );
    await tester.pump();
  });
}
