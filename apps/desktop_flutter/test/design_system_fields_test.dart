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

    final readOnly = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('designReadOnlyField')),
        matching: find.byType(EditableText),
      ),
    );
    final disabled = tester.widget<TextFormField>(
      find.byKey(const Key('designDisabledField')),
    );
    final notes = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('designNotesField')),
        matching: find.byType(EditableText),
      ),
    );

    expect(readOnly.readOnly, isTrue);
    expect(disabled.enabled, isFalse);
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
    await tester.tap(dropdown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final dollar = find.text('دولار');
    expect(dollar, findsOneWidget);
    final label = tester.widget<Text>(dollar);
    expect(label.style?.fontSize, 18);
    expect(label.style?.fontWeight, FontWeight.w600);

    await tester.tap(dollar);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
