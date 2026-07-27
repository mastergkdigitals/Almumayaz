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
      find.byKey(const Key('settingsFieldTableRow')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsFieldTableSummary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateCodeField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateNameField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateWarehouseDropdown')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateQuantityField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateSalePriceField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateDiscountField')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('settingsTemplatePriceAfterDiscountField'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateTotalField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settingsTemplateAddButton')),
      findsOneWidget,
    );

    final codeTextField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('settingsTemplateCodeField')),
        matching: find.byType(TextField),
      ),
    );
    final enabledBorder =
        codeTextField.decoration!.enabledBorder! as OutlineInputBorder;
    expect(
      enabledBorder.borderRadius,
      BorderRadius.circular(AppRadii.md),
    );

    final readOnlyTextField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(
          const Key('settingsTemplatePriceAfterDiscountField'),
        ),
        matching: find.byType(TextField),
      ),
    );
    expect(readOnlyTextField.enabled, isFalse);
    expect(
      readOnlyTextField.decoration?.fillColor,
      AppColors.neutralSurface,
    );

    final warehouseDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(
          const Key('settingsTemplateWarehouseDropdown'),
        ),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(
      warehouseDropdown.visualStyle,
      AppDropdownVisualStyle.standard,
    );
    expect(warehouseDropdown.accentColor, AppModuleColors.sales);

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settingsScreen')), findsNothing);
    expect(
      find.byKey(const Key('dashboardCard_settings')),
      findsOneWidget,
    );
  });
}
