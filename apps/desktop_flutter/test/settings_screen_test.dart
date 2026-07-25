import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/dashboard/presentation/dashboard_screen.dart';
import 'package:erp/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens purchase table templates from Settings', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const DashboardScreen(username: 'admin'),
      ),
    );

    await tester.tap(find.byKey(const Key('dashboardCard_settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('settingsScreen')), findsOneWidget);
    expect(
      find.text('مقارنة أربعة تصاميم جديدة لجدول المشتريات'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('appScreenBackButton')), findsOneWidget);
  });

  testWidgets('shows four distinct five-column purchase table templates',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const SettingsScreen(),
      ),
    );
    await tester.pump();

    for (var index = 1; index <= 4; index++) {
      expect(find.text('نموذج $index'), findsOneWidget);
      expect(
        find.byKey(Key('purchaseTableTemplate$index')),
        findsOneWidget,
      );
    }

    for (final label in const [
      'ت',
      'رمز المادة',
      'اسم المادة',
      'الكمية',
      'السعر',
    ]) {
      expect(find.text(label), findsNWidgets(4));
    }

    expect(find.byIcon(Icons.add_rounded), findsWidgets);
    expect(find.byIcon(Icons.close_rounded), findsWidgets);
    expect(find.byType(AppInvoiceItemsTable), findsNothing);
  });

  testWidgets('edits and adds or deletes rows in every template',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const SettingsScreen(),
      ),
    );
    await tester.pump();

    for (var template = 1; template <= 4; template++) {
      final field = find.byKey(
        Key('template${template}CodeField-t$template-r1'),
      );
      await tester.ensureVisible(field);
      await tester.pump();
      await tester.enterText(field, 'NEW-$template');
      await tester.pump();

      final editable = tester.widget<EditableText>(
        find.descendant(
          of: field,
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.controller.text, 'NEW-$template');
    }

    for (var template = 1; template <= 4; template++) {
      final addButton = find.byKey(Key('template${template}AddRow'));
      final newRow = find.byKey(
        Key('template${template}Row-t$template-r4'),
      );
      final deleteButton = find.byKey(
        Key('template${template}DeleteRow-t$template-r4'),
      );

      await tester.ensureVisible(addButton);
      await tester.pump();
      await tester.tap(addButton);
      await tester.pump();
      expect(newRow, findsOneWidget);

      await tester.ensureVisible(deleteButton);
      await tester.pump();
      await tester.tap(deleteButton);
      await tester.pump();
      expect(newRow, findsNothing);
    }
  });
}
