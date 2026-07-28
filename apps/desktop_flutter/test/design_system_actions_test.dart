import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  testWidgets('shows the shared navigation and action buttons',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    expect(find.text('الأزرار'), findsOneWidget);
    expect(find.text('أزرار التنقل'), findsOneWidget);
    expect(find.text('أزرار الإجراءات'), findsOneWidget);
    expect(find.byKey(const Key('designSecondaryButton')), findsNothing);
    expect(find.byKey(const Key('designGhostButton')), findsNothing);

    const navigation = <String, IconData>{
      'designNavigationFirst': Icons.first_page_rounded,
      'designNavigationPrevious': Icons.chevron_left_rounded,
      'designNavigationNext': Icons.chevron_right_rounded,
      'designNavigationLast': Icons.last_page_rounded,
    };
    for (final entry in navigation.entries) {
      final finder = find.byKey(Key(entry.key));
      final button = tester.widget<AppButton>(finder);
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(104));
      expect(size.height, 52);
      expect(button.icon, entry.value);
      expect(button.variant, AppButtonVariant.navigation);
      expect(button.minWidth, 104);
      expect(button.height, 52);
    }

    const actions =
        <String, (IconData, AppButtonVariant, Color)>{
      'designActionSave': (
        Icons.save_rounded,
        AppButtonVariant.primary,
        AppColors.blue,
      ),
      'designActionUpdate': (
        Icons.update_rounded,
        AppButtonVariant.success,
        AppColors.green,
      ),
      'designActionUndo': (
        Icons.undo_rounded,
        AppButtonVariant.warning,
        AppColors.orange,
      ),
      'designActionDelete': (
        Icons.delete_rounded,
        AppButtonVariant.danger,
        AppColors.red,
      ),
    };
    for (final entry in actions.entries) {
      final finder = find.byKey(Key(entry.key));
      final button = tester.widget<AppButton>(finder);
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(108));
      expect(size.height, 52);
      expect(button.icon, entry.value.$1);
      expect(button.variant, entry.value.$2);
      expect(button.iconSize, 18);
      expect(button.minWidth, 108);
      expect(button.textStyle?.fontSize, 16);
      expect(button.textStyle?.fontWeight, FontWeight.w700);

      final renderedButton = tester.widget<ElevatedButton>(
        find.descendant(
          of: finder,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(
        renderedButton.style?.backgroundColor?.resolve(<WidgetState>{}),
        entry.value.$3,
      );
    }
  });

  testWidgets('matches regular gallery buttons to navigation buttons',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    const regularButtonKeys = [
      'designDeleteDialogButton',
      'designUnsavedDialogButton',
      'designRecordSearchDialogButton',
      'designStatementDialogButton',
      'designTransferDialogButton',
      'designGroupsTypesDialogButton',
      'designWorkplacesDialogButton',
      'designCashboxTabsDialogButton',
      'designQuickPartyButton',
      'designQuickItemButton',
      'designQuickWorkplaceButton',
      'designQuickWorkplaceBranchButton',
      'designQuickItemGroupButton',
      'designQuickItemTypeButton',
      'designQuickCashboxMainButton',
      'designQuickCashboxSubButton',
      'designSaveToastButton',
      'designUpdateToastButton',
      'designUndoToastButton',
      'designDeleteToastButton',
    ];

    final navigation = tester.widget<AppButton>(
      find.byKey(const Key('designNavigationFirst')),
    );
    final navigationControl = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const Key('designNavigationFirst')),
        matching: find.byType(OutlinedButton),
      ),
    );

    for (final key in regularButtonKeys) {
      final finder = find.byKey(Key(key));
      final regularButton = tester.widget<AppRegularButton>(finder);
      final button = tester.widget<AppButton>(
        find.descendant(
          of: finder,
          matching: find.byType(AppButton),
        ),
      );
      final control = tester.widget<OutlinedButton>(
        find.descendant(
          of: finder,
          matching: find.byType(OutlinedButton),
        ),
      );

      expect(regularButton.onPressed, isNotNull);
      expect(button.variant, navigation.variant);
      expect(button.minWidth, navigation.minWidth);
      expect(button.height, navigation.height);
      expect(button.padding, navigation.padding);
      expect(button.iconSize, navigation.iconSize);
      expect(button.iconSpacing, navigation.iconSpacing);
      expect(button.textStyle, navigation.textStyle);

      for (final states in <Set<WidgetState>>[
        <WidgetState>{},
        <WidgetState>{WidgetState.hovered},
        <WidgetState>{WidgetState.pressed},
      ]) {
        expect(
          control.style?.backgroundColor?.resolve(states),
          navigationControl.style?.backgroundColor?.resolve(states),
        );
        expect(
          control.style?.foregroundColor?.resolve(states),
          navigationControl.style?.foregroundColor?.resolve(states),
        );
        expect(
          control.style?.side?.resolve(states),
          navigationControl.style?.side?.resolve(states),
        );
      }
    }
  });

  testWidgets('changes the theme preview icon and tooltip', (tester) async {
    await pumpDesignSystemGallery(tester);

    final themeButton = find.byKey(const Key('designHeaderThemeButton'));
    await reveal(tester, themeButton);

    Tooltip tooltip() => tester.widget<Tooltip>(
          find.descendant(
            of: themeButton,
            matching: find.byType(Tooltip),
          ),
        );

    expect(tooltip().message, 'داكن');
    expect(tooltip().verticalOffset, 32);
    expect(
      tooltip().padding,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    );
    expect(
      tooltip().textStyle,
      const TextStyle(
        color: AppTooltipColors.text,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    );
    final tooltipDecoration = tooltip().decoration! as BoxDecoration;
    expect(tooltipDecoration.color, AppTooltipColors.background);
    expect(
      (tooltipDecoration.border! as Border).top.color,
      AppTooltipColors.border,
    );
    expect(
      tooltipDecoration.borderRadius,
      BorderRadius.circular(12),
    );
    expect(tooltipDecoration.boxShadow, hasLength(1));
    expect(tooltipDecoration.boxShadow!.single.blurRadius, 14);
    expect(
      tooltipDecoration.boxShadow!.single.offset,
      const Offset(0, 7),
    );
    expect(
      tester.widget<Icon>(
        find.descendant(of: themeButton, matching: find.byType(Icon)),
      ).icon,
      Icons.dark_mode_rounded,
    );

    await tester.tap(themeButton);
    await tester.pump();

    expect(tooltip().message, 'فاتح');
    expect(
      tester.widget<Icon>(
        find.descendant(of: themeButton, matching: find.byType(Icon)),
      ).icon,
      Icons.light_mode_rounded,
    );
  });

  testWidgets('documents the invoice header buttons and tooltips',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    expect(find.text('أزرار الفواتير والتلميحات'), findsOneWidget);

    const buttons = <String, (IconData, String)>{
      'designInvoicePrintButton': (Icons.print_rounded, 'طباعة'),
      'designInvoicePrintWithoutPriceButton': (
        Icons.print_disabled_rounded,
        'طباعة بدون سعر',
      ),
      'designInvoiceSearchButton': (Icons.search_rounded, 'بحث'),
      'designInvoiceInstallmentsButton': (
        Icons.table_chart_rounded,
        'جدول الأقساط',
      ),
      'designInvoiceStatementButton': (
        Icons.receipt_long_rounded,
        'كشف حساب',
      ),
    };

    for (final entry in buttons.entries) {
      final finder = find.byKey(Key(entry.key));
      await reveal(tester, finder);

      final button = tester.widget<AppHeaderIconButton>(finder);
      expect(button.icon, entry.value.$1);
      expect(button.tooltip, entry.value.$2);
      expect(tester.getSize(finder), const Size.square(52));

      final tooltip = tester.widget<Tooltip>(
        find.descendant(of: finder, matching: find.byType(Tooltip)),
      );
      expect(tooltip.message, entry.value.$2);
    }
  });

  testWidgets('matches the shared screen back button to its reference',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final screenBack = find.byKey(const Key('appScreenBackButton'));
    final referenceBack = find.byKey(const Key('designHeaderBackButton'));
    await reveal(tester, referenceBack);

    final screenIcon = tester.widget<Icon>(
      find.descendant(of: screenBack, matching: find.byType(Icon)),
    );
    final referenceIcon = tester.widget<Icon>(
      find.descendant(of: referenceBack, matching: find.byType(Icon)),
    );

    expect(screenIcon.icon, Icons.arrow_back_rounded);
    expect(referenceIcon.icon, screenIcon.icon);
    expect(tester.getSize(screenBack), tester.getSize(referenceBack));

    final button = tester.widget<OutlinedButton>(
      find.descendant(
        of: referenceBack,
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      Colors.white,
    );
    expect(
      button.style?.backgroundColor?.resolve(
        <WidgetState>{WidgetState.pressed},
      ),
      const Color(0xFFF8FAFC),
    );
    expect(
      button.style?.side?.resolve(<WidgetState>{})?.color,
      const Color(0xFFD1D5DB),
    );
    expect(
      button.style?.side?.resolve(
        <WidgetState>{WidgetState.hovered},
      )?.color,
      const Color(0xFF111827),
    );
    expect(
      button.style?.side?.resolve(
        <WidgetState>{WidgetState.pressed},
      )?.color,
      const Color(0xFF111827),
    );
    final shape = button.style?.shape?.resolve(<WidgetState>{})
        as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(14));
  });

  testWidgets('uses real action states and consistent colors',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final actionBar = find.byKey(const Key('designActionBar'));
    await reveal(tester, actionBar);

    final buttonKeys = const [
      Key('designActionBarFirst'),
      Key('designActionBarPrevious'),
      Key('designActionBarNext'),
      Key('designActionBarLast'),
      Key('designActionBarSave'),
      Key('designActionBarUpdate'),
      Key('designActionBarUndo'),
      Key('designActionBarDelete'),
    ];
    for (final key in buttonKeys.take(4)) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(104));
      expect(size.height, 52);
    }
    for (final key in buttonKeys.skip(4)) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(108));
      expect(size.height, 52);
    }

    AppButton appButton(String key) =>
        tester.widget<AppButton>(find.byKey(Key(key)));

    expect(appButton('designActionBarFirst').minWidth, 104);
    expect(appButton('designActionBarFirst').width, isNull);
    expect(appButton('designActionBarSave').minWidth, 108);
    expect(appButton('designActionBarSave').width, isNull);
    expect(
      appButton('designActionBarSave').variant,
      AppButtonVariant.primary,
    );
    expect(
      appButton('designActionBarUpdate').variant,
      AppButtonVariant.success,
    );
    expect(
      appButton('designActionBarUndo').variant,
      AppButtonVariant.warning,
    );
    expect(
      appButton('designActionBarDelete').variant,
      AppButtonVariant.danger,
    );
    expect(appButton('designActionBarSave').onPressed, isNotNull);
    expect(appButton('designActionBarUpdate').onPressed, isNull);
    expect(appButton('designActionBarUndo').onPressed, isNull);
    expect(appButton('designActionBarDelete').onPressed, isNull);

    final disabledNavigation = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const Key('designActionBarNext')),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(
      disabledNavigation.style?.side?.resolve(
        {WidgetState.disabled},
      )?.color,
      const Color(0xFFD1D5DB).withValues(alpha: 0.55),
    );

    final stateDropdown =
        find.byKey(const Key('designActionBarStateDropdown'));
    await reveal(tester, stateDropdown);
    await tester.tap(stateDropdown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(
      find.widgetWithText(MenuItemButton, 'محفوظ مع تعديلات'),
    );
    await tester.pump();
    await reveal(tester, actionBar);

    expect(appButton('designActionBarSave').onPressed, isNull);
    expect(appButton('designActionBarUpdate').onPressed, isNotNull);
    expect(appButton('designActionBarUndo').onPressed, isNotNull);
    expect(appButton('designActionBarDelete').onPressed, isNotNull);

    final updateButton = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(const Key('designActionBarUpdate')),
        matching: find.byType(ElevatedButton),
      ),
    );
    final undoButton = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(const Key('designActionBarUndo')),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(
      updateButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.green,
    );
    expect(
      undoButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.orange,
    );

    await tester.tap(find.byKey(const Key('designActionBarDelete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final dialog = find.byKey(const Key('appConfirmDialog'));
    final cancel = find.byKey(const Key('appDialogCancelButton'));
    final confirm = find.byKey(const Key('appDialogConfirmButton'));
    expect(tester.widget<Dialog>(dialog).backgroundColor, AppColors.surface);
    expect(
      tester.getCenter(confirm).dx,
      greaterThan(tester.getCenter(cancel).dx),
    );

    final confirmButton = tester.widget<ElevatedButton>(
      find.descendant(of: confirm, matching: find.byType(ElevatedButton)),
    );
    expect(
      confirmButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.red,
    );

    await tester.tap(cancel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('documents the unsaved changes confirmation',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final button = find.byKey(const Key('designUnsavedDialogButton'));
    await reveal(tester, button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('تغييرات غير محفوظة'), findsWidgets);
    expect(find.text('تجاهل'), findsOneWidget);
    expect(find.text('البقاء'), findsOneWidget);

    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('keeps fixed-width icon buttons free of overflow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: AppButton(
              label: 'إضافة',
              icon: Icons.add_rounded,
              width: 112,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(AppButton)),
      const Size(112, AppControlHeights.standard),
    );
  });

}
