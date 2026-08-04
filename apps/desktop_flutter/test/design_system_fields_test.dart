import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  testWidgets('documents standard field states', (tester) async {
    await pumpDesignSystemGallery(tester);

    final nameField = find.byKey(const Key('designNameField'));
    await reveal(tester, nameField);

    expect(
      AppTypography.fieldText.fontSize,
      18 * AppDensity.scale,
    );
    expect(AppTypography.fieldText.fontWeight, FontWeight.w600);
    expect(find.byKey(const Key('designCityField')), findsOneWidget);
    expect(find.byKey(const Key('designDateField')), findsOneWidget);
    expect(find.byKey(const Key('designTimeField')), findsOneWidget);
    expect(find.byKey(const Key('designNotesField')), findsOneWidget);
    expect(find.byKey(const Key('designPhoneField')), findsOneWidget);

    final timeField = find.byKey(const Key('designTimeField'));
    expect(
      find.ancestor(
        of: timeField,
        matching: find.byType(AppTimeField),
      ),
      findsOneWidget,
    );
    expect(tester.widget<TextFormField>(timeField).enabled, isFalse);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: timeField,
              matching: find.byType(EditableText),
            ),
          )
          .readOnly,
      isTrue,
    );
    expect(
      _fieldDecoration(tester, timeField).fillColor,
      AppColors.neutralSurface,
    );
    expect(tester.widget<TextFormField>(timeField).controller?.text, '09:30 ص');

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
    final errorText = find.text('هذا الحقل مطلوب');
    expect(errorText, findsOneWidget);
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
    expect(dropdownWidget.accentColor, AppModuleColors.purchases);
    expect(dropdownWidget.textDirection, isNull);
    expect(dropdownWidget.textAlign, TextAlign.start);
    expect(dropdownWidget.menuTextDirection, isNull);

    final decorator = tester.widget<InputDecorator>(
      find.descendant(
        of: dropdown,
        matching: find.byType(InputDecorator),
      ),
    );
    expect(decorator.decoration.labelText, 'العملة');
    expect(decorator.decoration.contentPadding, isNull);
    expect(decorator.decoration.labelStyle, isNull);
    final enabledBorder =
        decorator.decoration.enabledBorder! as OutlineInputBorder;
    expect(
      enabledBorder.borderRadius,
      BorderRadius.circular(AppRadii.md),
    );
    expect(enabledBorder.borderSide.color, AppColors.border);
    final focusedBorder =
        decorator.decoration.focusedBorder! as OutlineInputBorder;
    expect(
      focusedBorder.borderRadius,
      BorderRadius.circular(AppRadii.md),
    );
    expect(focusedBorder.borderSide.color, AppModuleColors.purchases);
    expect(focusedBorder.borderSide.width, 1.5);
    final prefixIcon = decorator.decoration.prefixIcon! as Icon;
    expect(prefixIcon.icon, Icons.currency_exchange_rounded);
    expect(prefixIcon.color, AppModuleColors.purchases);
    final suffixIcon = decorator.decoration.suffixIcon!;
    expect(suffixIcon, isA<AnimatedRotation>());
    expect(
      find.descendant(
        of: dropdown,
        matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
      ),
      findsOneWidget,
    );
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
    expect(selectedValue.textDirection, isNull);
    expect(selectedValue.textAlign, TextAlign.start);
    expect(selectedValue.style?.color, AppColors.textPrimary);
    expect(
      selectedValue.style?.fontSize,
      18 * AppDensity.scale,
    );
    expect(selectedValue.style?.fontWeight, FontWeight.w600);

    final menuAnchor = tester.widget<MenuAnchor>(
      find.ancestor(
        of: dropdown,
        matching: find.byType(MenuAnchor),
      ),
    );
    final menuStyle = menuAnchor.style!;
    expect(
      menuStyle.shadowColor?.resolve(<WidgetState>{}),
      AppColors.menuShadow,
    );
    expect(menuStyle.elevation?.resolve(<WidgetState>{}), 4);
    final menuShape = menuStyle.shape?.resolve(<WidgetState>{})
        as RoundedRectangleBorder;
    expect(menuShape.borderRadius, BorderRadius.circular(AppRadii.md));
    expect(menuShape.side.color, AppColors.border);

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
    expect(label.style?.fontSize, 18 * AppDensity.scale);
    expect(label.style?.fontWeight, FontWeight.w600);
    expect(label.style?.color, AppColors.textPrimary);

    final selectedOption = find.widgetWithText(MenuItemButton, 'دينار');
    final selectedButton = tester.widget<MenuItemButton>(selectedOption);
    expect(
      selectedButton.style?.minimumSize?.resolve(<WidgetState>{}),
      const Size(0, 44 * AppDensity.scale),
    );
    expect(
      selectedButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      Color.alphaBlend(
        AppModuleColors.purchases.withAlpha(22),
        AppColors.surface,
      ),
    );
    final selectedOptionLabel = tester.widget<Text>(
      find.descendant(
        of: selectedOption,
        matching: find.text('دينار'),
      ),
    );
    expect(selectedOptionLabel.style?.fontWeight, FontWeight.w700);
    expect(
      selectedOptionLabel.style?.color,
      AppModuleColors.purchases,
    );
    expect(
      find.descendant(
        of: selectedOption,
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );

    final dollarButton = tester.widget<MenuItemButton>(dollarOption);
    expect(
      dollarButton.style?.backgroundColor?.resolve(
        <WidgetState>{WidgetState.hovered},
      ),
      AppColors.controlHoverSurface,
    );

    await tester.tap(dollarOption);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}

InputDecoration _fieldDecoration(WidgetTester tester, Finder field) {
  return tester
      .widget<InputDecorator>(
        find.descendant(of: field, matching: find.byType(InputDecorator)),
      )
      .decoration;
}
