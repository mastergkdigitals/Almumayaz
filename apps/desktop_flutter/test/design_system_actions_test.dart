import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  testWidgets('shows unduplicated black secondary button variants',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    expect(find.text('الأزرار'), findsOneWidget);
    expect(find.text('حفظ'), findsOneWidget);
    expect(find.text('حذف'), findsOneWidget);
    expect(find.text('الأول'), findsOneWidget);
    expect(find.byKey(const Key('designNavigationFirst')), findsNothing);

    final secondaryButton = tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byKey(const Key('designSecondaryButton')),
        matching: find.byType(OutlinedButton),
      ),
    );
    final ghostButton = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const Key('designGhostButton')),
        matching: find.byType(TextButton),
      ),
    );

    expect(
      secondaryButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColors.navigation,
    );
    expect(
      ghostButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColors.navigation,
    );
    expect(
      secondaryButton.style?.mouseCursor?.resolve(<WidgetState>{}),
      SystemMouseCursors.click,
    );
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
    for (final key in buttonKeys) {
      expect(
        tester.getSize(find.byKey(key)),
        const Size(108, AppControlHeights.standard),
      );
    }

    AppButton appButton(String key) =>
        tester.widget<AppButton>(find.byKey(Key(key)));

    expect(appButton('designActionBarSave').onPressed, isNotNull);
    expect(appButton('designActionBarUpdate').onPressed, isNull);
    expect(appButton('designActionBarUndo').onPressed, isNull);
    expect(appButton('designActionBarDelete').onPressed, isNull);

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
      AppColors.success,
    );
    expect(
      undoButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.warning,
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
      AppColors.danger,
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
}
