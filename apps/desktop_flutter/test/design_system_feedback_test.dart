import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  testWidgets('keeps the table header fixed while rows scroll', (tester) async {
    await pumpDesignSystemGallery(tester);

    final table = find.byKey(const Key('designMaterialsTable'));
    await reveal(tester, table);

    expect(find.text('مواد تجريبية'), findsNothing);
    expect(find.text('رمز المادة'), findsOneWidget);
    expect(
      find.descendant(of: table, matching: find.text('P-001')),
      findsOneWidget,
    );
    expect(find.byTooltip('كشف'), findsWidgets);

    final headerY = tester.getTopLeft(find.text('رمز المادة')).dy;
    final rows = find.descendant(of: table, matching: find.byType(ListView));
    expect(rows, findsOneWidget);

    await tester.drag(rows, const Offset(0, -500));
    await tester.pump();

    expect(find.text('P-012'), findsOneWidget);
    expect(tester.getTopLeft(find.text('رمز المادة')).dy, closeTo(headerY, 0.1));
  });

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

  testWidgets('shows non-dismissible messages for two seconds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: AppButton(
              label: 'حفظ',
              onPressed: () => AppToast.showSuccess(context, 'تم الحفظ بنجاح'),
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
