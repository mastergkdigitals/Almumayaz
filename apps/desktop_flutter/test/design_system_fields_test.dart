import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(
      tester
          .widget<AppIntegerField>(
            find.ancestor(
              of: quantity,
              matching: find.byType(AppIntegerField),
            ),
          )
          .accentColor,
      AppModuleColors.purchases,
    );
    await tester.enterText(quantity, '1000000');
    await tester.pump();

    expect(
      tester.widget<TextFormField>(quantity).controller?.text,
      '1,000,000',
    );

    final money = find.byKey(const Key('designMoneyField'));
    expect(
      tester
          .widget<AppMoneyField>(
            find.ancestor(
              of: money,
              matching: find.byType(AppMoneyField),
            ),
          )
          .accentColor,
      AppModuleColors.purchases,
    );
    await tester.enterText(money, '1000000.25');
    await tester.pump();

    expect(
      tester.widget<TextFormField>(money).controller?.text,
      '1,000,000.25',
    );
  });

  testWidgets(
      'autocomplete opens on focus without mutating text and supports keys',
      (tester) async {
    final controller = TextEditingController(text: 'بغداد');
    addTearDown(controller.dispose);
    final observedValues = <String>[];
    controller.addListener(() => observedValues.add(controller.text));
    String? selectedCity;
    var selectionCount = 0;
    var submissionCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AppAutocompleteField<String>(
                controller: controller,
                fieldKey: const Key('autocompleteRegressionField'),
                label: 'المدينة',
                accentColor: AppModuleColors.parties,
                options: const ['بغداد', 'البصرة', 'أربيل'],
                displayStringForOption: (city) => city,
                onSelected: (city) {
                  selectedCity = city;
                  selectionCount++;
                },
                onSubmitted: (_) => submissionCount++,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('autocompleteRegressionField')),
    );
    await tester.pump();

    expect(find.text('البصرة'), findsOneWidget);
    expect(controller.text, 'بغداد');
    expect(
      observedValues.every((value) => !value.contains('\u200B')),
      isTrue,
    );

    final expectedBorderColor = Color.lerp(
      AppModuleColors.parties,
      AppColors.surface,
      0.62,
    );
    final popup = tester
        .widgetList<Material>(
          find.ancestor(
            of: find.text('البصرة'),
            matching: find.byType(Material),
          ),
        )
        .firstWhere((material) {
      final shape = material.shape;
      return shape is RoundedRectangleBorder &&
          shape.side.color == expectedBorderColor;
    });
    expect(
      (popup.shape! as RoundedRectangleBorder).side.color,
      expectedBorderColor,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selectedCity, 'بغداد');
    expect(selectionCount, 1);
    expect(submissionCount, 0);
    expect(controller.text, 'بغداد');
    expect(find.text('البصرة'), findsNothing);
    expect(
      observedValues.every((value) => !value.contains('\u200B')),
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selectionCount, 1);
    expect(submissionCount, 1);
  });

  testWidgets('integer and money fields support read-only values and precision',
      (tester) async {
    final integerController = TextEditingController(text: '12');
    final moneyController = TextEditingController(text: '15.30');
    addTearDown(integerController.dispose);
    addTearDown(moneyController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              AppIntegerField(
                fieldKey: const Key('readOnlyIntegerField'),
                controller: integerController,
                label: 'الكمية',
                readOnly: true,
              ),
              AppMoneyField(
                fieldKey: const Key('readOnlyMoneyField'),
                controller: moneyController,
                label: 'المبلغ',
                readOnly: true,
                decimalPlaces: 2,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final integerEditable = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('readOnlyIntegerField')),
        matching: find.byType(EditableText),
      ),
    );
    final moneyEditable = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('readOnlyMoneyField')),
        matching: find.byType(EditableText),
      ),
    );
    expect(integerEditable.readOnly, isTrue);
    expect(moneyEditable.readOnly, isTrue);

    final formatter = moneyEditable.inputFormatters!
        .whereType<AppMoneyInputFormatter>()
        .single;
    expect(formatter.decimalPlaces, 2);
    const accepted = TextEditingValue(
      text: '15.30',
      selection: TextSelection.collapsed(offset: 5),
    );
    const rejected = TextEditingValue(
      text: '15.300',
      selection: TextSelection.collapsed(offset: 6),
    );
    expect(formatter.formatEditUpdate(accepted, rejected), accepted);
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
    expect(focusedBorder.borderSide.width, 1.6);
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
    expect(selectedValue.style?.fontSize, 18);
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
    expect(label.style?.fontSize, 18);
    expect(label.style?.fontWeight, FontWeight.w600);
    expect(label.style?.color, AppColors.textPrimary);

    final selectedOption = find.widgetWithText(MenuItemButton, 'دينار');
    final selectedButton = tester.widget<MenuItemButton>(selectedOption);
    expect(
      selectedButton.style?.minimumSize?.resolve(<WidgetState>{}),
      const Size(0, 44),
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
