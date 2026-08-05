import 'package:erp/core/data/app_repository.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  testWidgets('blocks interaction while the loading overlay is visible',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final overlay = find.byType(AppLoadingOverlay);
    expect(overlay, findsOneWidget);
    expect(
      find.descendant(of: overlay, matching: find.byType(AbsorbPointer)),
      findsOneWidget,
    );
    expect(find.text('جاري حفظ البيانات'), findsOneWidget);
  });

  testWidgets('documents save update undo and delete toast colors',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    expect(find.text('رسائل التنبيه'), findsOneWidget);

    const toastButtons = <String, Color>{
      'designSaveToastButton': AppColors.blue,
      'designUpdateToastButton': AppColors.green,
      'designUndoToastButton': AppColors.orange,
      'designDeleteToastButton': AppColors.red,
    };

    await reveal(
      tester,
      find.byKey(const Key('designSaveToastButton')),
    );

    for (final entry in toastButtons.entries) {
      final button = find.byKey(Key(entry.key));
      expect(
        tester.widget<AppRegularButton>(button).onPressed,
        isNotNull,
      );

      await tester.tap(button);
      await tester.pump();

      final toast = tester.widget<SnackBar>(
        find.byKey(const Key('appToast')),
      );
      expect(toast.backgroundColor, entry.value);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(AppToast.duration);
      await tester.pump(const Duration(milliseconds: 300));
    }
  });

  testWidgets('uses the regular button for state panel actions',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final errorPanel = find.byType(AppStatePanel).at(1);
    expect(
      find.descendant(
        of: errorPanel,
        matching: find.byType(AppRegularButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('documents the missing-reference state in orange',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final missingReferenceState = find.byKey(
      const Key('designMissingReferenceState'),
    );
    expect(missingReferenceState, findsOneWidget);
    expect(
      tester.widget<AppStatePanel>(missingReferenceState).type,
      AppStateType.missingReference,
    );

    final icon = tester.widget<Icon>(
      find.descendant(
        of: missingReferenceState,
        matching: find.byIcon(Icons.link_off_rounded),
      ),
    );
    expect(icon.color, AppColors.orange);

    final panelContainer = tester.widget<Container>(
      find.descendant(
        of: missingReferenceState,
        matching: find.byType(Container),
      ).first,
    );
    final decoration = panelContainer.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.warningSurface);
    expect(decoration.border!.top.color, AppColors.orange.withAlpha(72));
  });

  testWidgets('maps repository data states to shared state panels',
      (tester) async {
    Future<void> pumpState(AppDataState<String> state) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: AppDataStateView<String>(
            state: state,
            dataBuilder: (context, data) => Text('جاهز: $data'),
          ),
        ),
      );
    }

    await pumpState(const AppDataState<String>.loading());
    expect(
      tester.widget<AppStatePanel>(find.byType(AppStatePanel)).type,
      AppStateType.loading,
    );

    await pumpState(const AppDataState<String>.empty(message: 'القائمة فارغة'));
    expect(find.text('القائمة فارغة'), findsOneWidget);
    expect(
      tester.widget<AppStatePanel>(find.byType(AppStatePanel)).type,
      AppStateType.empty,
    );

    await pumpState(
      const AppDataState<String>.missingReference('مرجع مفقود'),
    );
    expect(find.text('مرجع مفقود'), findsOneWidget);
    expect(
      tester.widget<AppStatePanel>(find.byType(AppStatePanel)).type,
      AppStateType.missingReference,
    );

    await pumpState(
      const AppDataState<String>.error('تعذر الطلب', message: 'فشل التحميل'),
    );
    expect(find.text('فشل التحميل'), findsOneWidget);
    expect(
      tester.widget<AppStatePanel>(find.byType(AppStatePanel)).type,
      AppStateType.error,
    );

    await pumpState(const AppDataState<String>.ready('بيانات'));
    expect(find.text('جاهز: بيانات'), findsOneWidget);
    expect(find.byType(AppStatePanel), findsNothing);
  });

  testWidgets('shows non-dismissible messages for two seconds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: AppButton(
              label: 'حفظ',
              onPressed: () =>
                  AppToast.showInfo(context, 'تم الحفظ بنجاح'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('حفظ'));
    await tester.pump();

    final toast = tester.widget<SnackBar>(find.byKey(const Key('appToast')));
    expect(toast.duration, const Duration(seconds: 2));
    expect(toast.dismissDirection, DismissDirection.none);
    expect(find.byKey(const Key('appToastContent')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(AppToast.duration);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('appToast')), findsNothing);
  });
}
