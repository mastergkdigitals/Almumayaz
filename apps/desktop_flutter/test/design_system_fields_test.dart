import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  testWidgets('documents standard field states', (tester) async {
    await pumpDesignSystemGallery(tester);

    final nameField = find.byKey(const Key('designNameField'));
    await reveal(tester, nameField);

    expect(AppTypography.fieldText.fontSize, 18);
    expect(AppTypography.fieldText.fontWeight, FontWeight.w600);
    expect(find.byKey(const Key('designCityField')), findsOneWidget);
    expect(find.byKey(const Key('designDateField')), findsOneWidget);
    expect(find.byKey(const Key('designTimeField')), findsOneWidget);
    expect(find.byKey(const Key('designNotesField')), findsOneWidget);
    expect(find.byKey(const Key('designPhoneField')), findsOneWidget);

    final readOnly = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('designReadOnlyField')),
        matching: find.byType(EditableText),
      ),
    );
    final readOnlyField = tester.widget<TextFormField>(
      find.byKey(const Key('designReadOnlyField')),
    );
    final readOnlyDecoration = _fieldDecoration(
      tester,
      find.byKey(const Key('designReadOnlyField')),
    );
    final disabled = tester.widget<TextFormField>(
      find.byKey(const Key('designDisabledField')),
    );
    final phone = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('designPhoneField')),
        matching: find.byType(EditableText),
      ),
    );
    final notes = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('designNotesField')),
        matching: find.byType(EditableText),
      ),
    );

    expect(readOnly.readOnly, isTrue);
    expect(readOnlyField.enabled, isFalse);
    expect(
      readOnlyDecoration.fillColor,
      AppColors.neutralSurface,
    );
    expect(
      (readOnlyDecoration.disabledBorder as OutlineInputBorder)
          .borderSide
          .color,
      AppColors.border,
    );
    expect(disabled.enabled, isFalse);
    expect(phone.textDirection, TextDirection.rtl);
    expect(phone.textAlign, TextAlign.right);
    expect(phone.keyboardType, TextInputType.phone);

    for (final key in const [
      'designNameField',
      'designSearchField',
      'designQuantityField',
      'designMoneyField',
      'designPhoneField',
      'designCityField',
      'designDateField',
      'designTimeField',
      'designDisabledField',
      'designNotesField',
    ]) {
      expect(
        tester.getSize(find.byKey(Key(key))).height,
        AppControlHeights.large,
      );
    }

    final errorText = find.text('هذا الحقل مطلوب');
    expect(errorText, findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('designErrorField'))).height,
      greaterThan(AppControlHeights.large),
    );
    expect(
      tester.getSize(find.byKey(const Key('designReadOnlyField'))).height,
      greaterThan(AppControlHeights.large),
    );
    expect(
      Theme.of(tester.element(errorText))
          .inputDecorationTheme
          .errorStyle
          ?.fontWeight,
      FontWeight.w600,
    );
    expect(notes.maxLines, 1);
  });

  testWidgets('groups quantity and money while typing', (tester) async {
    await pumpDesignSystemGallery(tester);

    final quantity = find.byKey(const Key('designQuantityField'));
    await reveal(tester, quantity);
    await tester.enterText(quantity, '1000000');
    await tester.pump();

    expect(
      tester.widget<TextFormField>(quantity).controller?.text,
      '1,000,000',
    );

    final money = find.byKey(const Key('designMoneyField'));
    await tester.enterText(money, '1000000.25');
    await tester.pump();

    expect(
      tester.widget<TextFormField>(money).controller?.text,
      '1,000,000.25',
    );
  });

  testWidgets('clears search text without leaving the field', (tester) async {
    await pumpDesignSystemGallery(tester);

    final search = find.byKey(const Key('designSearchField'));
    await reveal(tester, search);

    expect(find.byKey(const Key('designSearchClearButton')), findsNothing);
    await tester.enterText(search, 'مادة');
    await tester.pump();

    final clear = find.byKey(const Key('designSearchClearButton'));
    expect(clear, findsOneWidget);
    expect(tester.widget<IconButton>(clear).onPressed, isNotNull);

    await tester.tap(clear);
    await tester.pump();

    expect(tester.widget<TextFormField>(search).controller?.text, isEmpty);
    expect(find.byKey(const Key('designSearchClearButton')), findsNothing);
  });

  testWidgets('opens the custom currency dropdown', (tester) async {
    await pumpDesignSystemGallery(tester);

    final dropdown = find.byKey(const Key('designCurrencyDropdown'));
    await reveal(tester, dropdown);

    final dropdownWidget = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: dropdown,
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(
      dropdownWidget.visualStyle,
      AppDropdownVisualStyle.oldPurchase,
    );
    expect(dropdownWidget.accentColor, AppModuleColors.purchases);
    expect(dropdownWidget.textDirection, TextDirection.ltr);
    expect(dropdownWidget.textAlign, TextAlign.center);
    expect(dropdownWidget.menuTextDirection, TextDirection.ltr);

    final decorator = tester.widget<InputDecorator>(
      find.descendant(
        of: dropdown,
        matching: find.byType(InputDecorator),
      ),
    );
    expect(decorator.decoration.labelText, 'العملة');
    expect(
      decorator.decoration.contentPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
    expect(
      decorator.decoration.labelStyle,
      const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
    final enabledBorder =
        decorator.decoration.enabledBorder! as OutlineInputBorder;
    expect(
      enabledBorder.borderRadius,
      BorderRadius.circular(14),
    );
    expect(enabledBorder.borderSide.color, const Color(0xFFE5E7EB));
    final focusedBorder =
        decorator.decoration.focusedBorder! as OutlineInputBorder;
    expect(
      focusedBorder.borderRadius,
      BorderRadius.circular(14),
    );
    expect(focusedBorder.borderSide.color, AppModuleColors.purchases);
    expect(focusedBorder.borderSide.width, 1.6);
    final prefixIcon = decorator.decoration.prefixIcon! as Icon;
    expect(prefixIcon.icon, Icons.currency_exchange_rounded);
    expect(prefixIcon.color, AppModuleColors.purchases);
    expect(prefixIcon.size, 20);
    final suffixIcon = decorator.decoration.suffixIcon! as Icon;
    expect(suffixIcon.icon, Icons.keyboard_arrow_down_rounded);
    expect(suffixIcon.color, AppModuleColors.purchases);
    expect(suffixIcon.size, 20);
    expect(decorator.baseStyle, isNull);
    expect(decorator.textAlign, isNull);
    expect(decorator.textAlignVertical, isNull);
    expect(decorator.expands, isFalse);
    expect(decorator.isEmpty, isFalse);
    final dropdownSize = tester.getSize(dropdown);
    final textFieldSize = tester.getSize(
      find.byKey(const Key('designNameField')),
    );
    expect(dropdownSize.width, textFieldSize.width);
    expect(dropdownSize.height, closeTo(textFieldSize.height, 2));
    expect(
      find.descendant(of: dropdown, matching: find.text('دينار')),
      findsOneWidget,
    );
    final selectedValue = tester.widget<Text>(
      find.descendant(of: dropdown, matching: find.text('دينار')),
    );
    expect(selectedValue.textDirection, TextDirection.ltr);
    expect(selectedValue.textAlign, TextAlign.center);
    expect(selectedValue.style?.color, const Color(0xFF111827));
    expect(selectedValue.style?.fontSize, 20);
    expect(selectedValue.style?.fontWeight, FontWeight.w700);

    final menuAnchor = tester.widget<MenuAnchor>(
      find.ancestor(
        of: dropdown,
        matching: find.byType(MenuAnchor),
      ),
    );
    final menuStyle = menuAnchor.style!;
    expect(
      menuStyle.shadowColor?.resolve(<WidgetState>{}),
      Colors.black.withAlpha(36),
    );
    expect(menuStyle.elevation?.resolve(<WidgetState>{}), 8);
    final menuShape = menuStyle.shape?.resolve(<WidgetState>{})
        as RoundedRectangleBorder;
    expect(menuShape.borderRadius, BorderRadius.circular(16));
    expect(menuShape.side.color, AppModuleColors.purchases);

    await tester.tap(dropdown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final dollarOption = find.widgetWithText(MenuItemButton, 'دولار');
    expect(dollarOption, findsOneWidget);
    final dollar = find.descendant(
      of: dollarOption,
      matching: find.text('دولار'),
    );
    expect(dollar, findsOneWidget);
    final label = tester.widget<Text>(dollar);
    expect(label.style?.fontSize, 18);
    expect(label.style?.fontWeight, FontWeight.w700);
    expect(label.style?.color, const Color(0xFF111827));
    expect(label.textDirection, TextDirection.ltr);

    final selectedOption = find.widgetWithText(MenuItemButton, 'دينار');
    final selectedButton = tester.widget<MenuItemButton>(selectedOption);
    expect(
      selectedButton.style?.minimumSize?.resolve(<WidgetState>{}),
      const Size(0, 48),
    );
    expect(
      selectedButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      Color.lerp(
        AppModulePalettes.purchases.light,
        Colors.white,
        0.58,
      ),
    );
    final selectedOptionLabel = tester.widget<Text>(
      find.descendant(
        of: selectedOption,
        matching: find.text('دينار'),
      ),
    );
    expect(selectedOptionLabel.style?.fontWeight, FontWeight.w800);
    expect(
      selectedOptionLabel.style?.color,
      AppModulePalettes.purchases.dark,
    );
    expect(
      find.descendant(
        of: selectedOption,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNothing,
    );

    final dollarButton = tester.widget<MenuItemButton>(dollarOption);
    expect(
      dollarButton.style?.backgroundColor?.resolve(
        <WidgetState>{WidgetState.hovered},
      ),
      Color.lerp(
        AppModulePalettes.purchases.light,
        Colors.white,
        0.78,
      ),
    );

    await tester.tap(dollarOption);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('compares old and current purchase fields in matching rows',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    final oldRow =
        find.byKey(const Key('designOldPurchaseFieldsRow'));
    final currentRow =
        find.byKey(const Key('designCurrentPurchaseFieldsRow'));
    await reveal(tester, currentRow);

    expect(
      find.text('مقارنة حقول وقوائم المشتريات'),
      findsOneWidget,
    );
    expect(oldRow, findsOneWidget);
    expect(currentRow, findsOneWidget);
    expect(tester.widget<Row>(oldRow).children, hasLength(15));
    expect(tester.widget<Row>(currentRow).children, hasLength(15));
    expect(tester.getSize(oldRow).width, tester.getSize(currentRow).width);

    for (final key in const [
      'designOldPurchaseInvoiceField',
      'designOldPurchaseDateField',
      'designOldPurchaseTimeField',
      'designOldPurchaseWarehouseDropdown',
      'designOldPurchaseTypeDropdown',
      'designOldPaymentTypeDropdown',
      'designOldPurchaseCurrencyDropdown',
      'designOldPurchaseExchangeRateField',
      'designCurrentPurchaseInvoiceField',
      'designCurrentPurchaseDateField',
      'designCurrentPurchaseTimeField',
      'designCurrentPurchaseWarehouseDropdown',
      'designCurrentPurchaseTypeDropdown',
      'designCurrentPaymentTypeDropdown',
      'designCurrentPurchaseCurrencyDropdown',
      'designCurrentPurchaseExchangeRateField',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }

    final oldFieldFinder = find.byKey(
      const Key('designOldPurchaseInvoiceField'),
    );
    final oldField = _editableText(tester, oldFieldFinder);
    final oldFieldDecoration = _fieldDecoration(tester, oldFieldFinder);
    expect(oldField.style.fontSize, 20);
    expect(oldField.style.fontWeight, FontWeight.w700);
    expect(
      oldFieldDecoration.labelStyle,
      const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
    final oldBorder =
        oldFieldDecoration.enabledBorder! as OutlineInputBorder;
    expect(oldBorder.borderRadius, BorderRadius.circular(14));
    expect(oldBorder.borderSide.color, const Color(0xFFE5E7EB));

    final oldTime = tester.widget<InputDecorator>(
      find.byKey(const Key('designOldPurchaseTimeField')),
    );
    expect(oldTime.decoration.fillColor, const Color(0xFFF1F5F9));
    final oldTimeBorder =
        oldTime.decoration.enabledBorder! as OutlineInputBorder;
    expect(oldTimeBorder.borderRadius, BorderRadius.circular(16));
    expect(oldTimeBorder.borderSide.color, const Color(0xFFDDE3EA));

    AppDropdownField<String> dropdown(String key) {
      return tester.widget<AppDropdownField<String>>(
        find.ancestor(
          of: find.byKey(Key(key)),
          matching: find.byType(AppDropdownField<String>),
        ),
      );
    }

    expect(
      dropdown('designOldPurchaseWarehouseDropdown').visualStyle,
      AppDropdownVisualStyle.oldPurchase,
    );
    expect(
      dropdown('designOldPurchaseWarehouseDropdown').contentPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
    expect(
      dropdown('designOldPurchaseWarehouseDropdown').textAlign,
      TextAlign.center,
    );
    expect(
      dropdown('designOldPurchaseTypeDropdown').visualStyle,
      AppDropdownVisualStyle.oldPurchase,
    );
    expect(
      dropdown('designOldPaymentTypeDropdown').visualStyle,
      AppDropdownVisualStyle.oldPurchase,
    );
    expect(
      dropdown('designOldPurchaseCurrencyDropdown').visualStyle,
      AppDropdownVisualStyle.oldPurchase,
    );
    expect(
      dropdown('designCurrentPurchaseWarehouseDropdown').visualStyle,
      AppDropdownVisualStyle.standard,
    );
    expect(
      dropdown('designCurrentPurchaseTypeDropdown').visualStyle,
      AppDropdownVisualStyle.standard,
    );
    expect(
      dropdown('designCurrentPaymentTypeDropdown').visualStyle,
      AppDropdownVisualStyle.standard,
    );
    expect(
      dropdown('designCurrentPurchaseCurrencyDropdown').visualStyle,
      AppDropdownVisualStyle.standard,
    );
  });
}

EditableText _editableText(WidgetTester tester, Finder field) {
  return tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
}

InputDecoration _fieldDecoration(WidgetTester tester, Finder field) {
  return tester
      .widget<InputDecorator>(
        find.descendant(of: field, matching: find.byType(InputDecorator)),
      )
      .decoration;
}
