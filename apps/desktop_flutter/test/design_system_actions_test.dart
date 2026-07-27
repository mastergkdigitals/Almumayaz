import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  testWidgets('shows the exact old Parties navigation and action buttons',
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
      final button = find.byKey(Key(entry.key));
      expect(tester.getSize(button), const Size(104, 52));
      expect(
        tester.widget<Icon>(
          find.descendant(of: button, matching: find.byType(Icon)),
        ).icon,
        entry.value,
      );
      final decoration = tester
          .widget<AnimatedContainer>(
            find.descendant(
              of: button,
              matching: find.byType(AnimatedContainer),
            ),
          )
          .decoration! as BoxDecoration;
      expect(decoration.color, Colors.white);
      expect((decoration.border! as Border).top.color,
          const Color(0xFFD1D5DB));
      expect(decoration.boxShadow, isEmpty);
    }

    const actions = <String, (IconData, Color)>{
      'designActionSave': (Icons.add_rounded, AppColors.green),
      'designActionUndo': (Icons.close_rounded, AppColors.grey),
      'designActionUpdate': (Icons.save_rounded, AppColors.blue),
      'designActionDelete': (Icons.delete_rounded, AppColors.red),
    };
    for (final entry in actions.entries) {
      final button = find.byKey(Key(entry.key));
      expect(tester.getSize(button), const Size(108, 52));
      final icon = tester.widget<Icon>(
        find.descendant(of: button, matching: find.byType(Icon)),
      );
      expect(icon.icon, entry.value.$1);
      expect(icon.size, 20);
      final decoration = tester
          .widget<AnimatedContainer>(
            find.descendant(
              of: button,
              matching: find.byType(AnimatedContainer),
            ),
          )
          .decoration! as BoxDecoration;
      expect(decoration.color, entry.value.$2);
      final text = tester.widget<Text>(
        find.descendant(of: button, matching: find.byType(Text)),
      );
      expect(text.style?.fontSize, 16);
      expect(text.style?.fontWeight, FontWeight.w800);
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
      AppButtonVariant.success,
    );
    expect(
      appButton('designActionBarUpdate').variant,
      AppButtonVariant.primary,
    );
    expect(
      appButton('designActionBarUndo').variant,
      AppButtonVariant.neutral,
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
      AppColors.disabled,
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
      AppColors.blue,
    );
    expect(
      undoButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.grey,
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
