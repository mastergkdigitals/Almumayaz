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
      await tester.tap(find.byKey(Key(entry.key)));
      await tester.pump();

      final toast = tester.widget<SnackBar>(
        find.byKey(const Key('appToast')),
      );
      expect(toast.backgroundColor, entry.value);

      await tester.pump(AppToast.duration);
      await tester.pump(const Duration(milliseconds: 300));
    }
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
