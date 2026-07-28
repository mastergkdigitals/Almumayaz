import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens Settings with the field-style sales table template',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const AlmumayazApp());
    await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
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

    expect(find.byKey(const Key('settingsScreen')), findsOneWidget);
    expect(
      find.byKey(const Key('settingsTintBackground')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsFieldTableTemplate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsFieldTableHeader')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsFieldTableRow-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsFieldTableRows')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsFieldTableSummary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateCodeField-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateNameField-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateWarehouseDropdown-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateQuantityField-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateSalePriceField-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateDiscountField-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('settingsTemplatePriceAfterDiscountField-r1'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateTotalField-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateAddButton')),
      findsOneWidget,
    );

    final table = tester.widget<Container>(
      find.byKey(const Key('settingsFieldTableTemplate')),
    );
    final tableDecoration = table.decoration! as BoxDecoration;
    final tableForeground =
        table.foregroundDecoration! as BoxDecoration;
    expect(table.clipBehavior, Clip.antiAlias);
    expect(tableDecoration.border, isNull);
    expect(
      tableDecoration.borderRadius,
      BorderRadius.circular(AppRadii.lg),
    );
    expect(tableForeground.border, isA<Border>());
    expect(
      tableForeground.borderRadius,
      BorderRadius.circular(AppRadii.lg),
    );

    final codeTextField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('settingsTemplateCodeField-r1')),
        matching: find.byType(TextField),
      ),
    );
    final enabledBorder =
        codeTextField.decoration!.enabledBorder! as OutlineInputBorder;
    expect(codeTextField.decoration?.labelText, isNull);
    expect(
      enabledBorder.borderRadius,
      BorderRadius.circular(AppRadii.sm),
    );

    final readOnlyTextField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(
          const Key('settingsTemplatePriceAfterDiscountField-r1'),
        ),
        matching: find.byType(TextField),
      ),
    );
    expect(readOnlyTextField.enabled, isFalse);
    expect(readOnlyTextField.decoration?.labelText, isNull);
    expect(
      readOnlyTextField.decoration?.fillColor,
      AppColors.neutralSurface,
    );

    final warehouseDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(
          const Key('settingsTemplateWarehouseDropdown-r1'),
        ),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(
      warehouseDropdown.visualStyle,
      AppDropdownVisualStyle.standard,
    );
    expect(warehouseDropdown.accentColor, AppModuleColors.sales);
    expect(warehouseDropdown.useIntrinsicHeight, isTrue);
    expect(warehouseDropdown.showLabel, isFalse);
    expect(warehouseDropdown.borderRadius, AppRadii.sm);

    final codeFieldOutline = find.descendant(
      of: find.byKey(const Key('settingsTemplateCodeField-r1')),
      matching: find.byType(InputDecorator),
    );
    final warehouseDropdownOutline = find.descendant(
      of: find.byKey(
        const Key('settingsTemplateWarehouseDropdown-r1'),
      ),
      matching: find.byType(InputDecorator),
    );
    final codeFieldRect = tester.getRect(codeFieldOutline);
    final warehouseDropdownRect = tester.getRect(
      warehouseDropdownOutline,
    );
    expect(
      warehouseDropdownRect.height,
      closeTo(codeFieldRect.height, 0.1),
    );
    expect(
      warehouseDropdownRect.top,
      closeTo(codeFieldRect.top, 0.1),
    );
    expect(
      warehouseDropdownRect.bottom,
      closeTo(codeFieldRect.bottom, 0.1),
    );

    await tester.tap(find.byKey(const Key('settingsTemplateAddButton')));
    await tester.pump();

    expect(
      find.byKey(const Key('settingsFieldTableRow-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsFieldTableRow-r2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateCodeField-r2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateWarehouseDropdown-r2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateDeleteButton-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateAddButton')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('settingsTemplateDeleteButton-r1')),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('settingsFieldTableRow-r1')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('settingsFieldTableRow-r2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateAddButton')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settingsScreen')), findsNothing);
    expect(
      find.byKey(const Key('dashboardCard_settings')),
      findsOneWidget,
    );
  });
}
