import 'package:erp/core/design/app_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'design_system_test_harness.dart';

void main() {
  test('identifies complete and fully empty invoice rows', () {
    expect(const AppSalesInvoiceTableRowData().isEmpty, isTrue);
    expect(
      const AppSalesInvoiceTableRowData(
        code: 'S-001',
        name: 'مادة تجريبية',
        quantity: '1',
      ).hasRequiredValues,
      isTrue,
    );
    expect(const AppPurchaseInvoiceTableRowData().isEmpty, isTrue);
    expect(
      const AppPurchaseInvoiceTableRowData(
        code: 'P-001',
        name: 'مادة تجريبية',
        quantity: '1',
      ).hasRequiredValues,
      isTrue,
    );
  });

  testWidgets('keeps the list table header fixed while rows scroll',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    expect(find.text('جداول التطبيق'), findsOneWidget);
    expect(find.text('جداول القوائم والسجلات'), findsOneWidget);

    final table = find.byKey(const Key('designMaterialsTable'));
    await reveal(tester, table);
    final tableWidget = tester.widget<AppDataTable>(table);
    expect(tableWidget.accentColor, AppModuleColors.parties);

    final tableSurface = tester
        .widgetList<Container>(
          find.descendant(
            of: table,
            matching: find.byType(Container),
          ),
        )
        .firstWhere(
          (container) =>
              container.foregroundDecoration is BoxDecoration &&
              (container.foregroundDecoration! as BoxDecoration)
                  .border is Border,
        );
    final tableBorder =
        (tableSurface.foregroundDecoration! as BoxDecoration).border!
            as Border;
    expect(
      tableBorder.top.color,
      Color.lerp(
        AppModuleColors.parties,
        AppColors.surface,
        0.62,
      ),
    );
    expect(tableBorder.top.width, 1.4);

    final materialCodeHeader = find.descendant(
      of: table,
      matching: find.text('رمز المادة'),
    );
    expect(materialCodeHeader, findsOneWidget);
    expect(
      find.descendant(of: table, matching: find.text('P-001')),
      findsOneWidget,
    );
    expect(find.byTooltip('كشف'), findsWidgets);

    final headerY = tester.getTopLeft(materialCodeHeader).dy;
    final rows = find.descendant(of: table, matching: find.byType(ListView));
    expect(rows, findsOneWidget);

    await tester.drag(rows, const Offset(0, -500));
    await tester.pump();

    expect(find.text('P-012'), findsOneWidget);
    expect(
      tester.getTopLeft(materialCodeHeader).dy,
      closeTo(headerY, 0.1),
    );
  });

  testWidgets(
      'applies column direction and theme selection with a visible scrollbar',
      (tester) async {
    const accentColor = AppModuleColors.warehouses;
    final expectedSelectedColor = Color.alphaBlend(
      accentColor.withAlpha(22),
      AppColors.surface,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: AppDataTable(
                key: const Key('directionalDataTable'),
                height: 180,
                minimumColumnWidth: 260,
                accentColor: accentColor,
                columns: const [
                  AppTableColumn(
                    label: 'Code',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                  ),
                  AppTableColumn(label: 'الاسم'),
                ],
                rows: const [
                  AppTableRow(
                    selected: true,
                    cells: [Text('ABC-1'), Text('مادة')],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final table = find.byKey(const Key('directionalDataTable'));
    final horizontalScrollbar = tester
        .widgetList<Scrollbar>(
          find.descendant(of: table, matching: find.byType(Scrollbar)),
        )
        .firstWhere(
          (scrollbar) =>
              scrollbar.scrollbarOrientation ==
              ScrollbarOrientation.bottom,
        );
    final horizontalView = tester
        .widgetList<SingleChildScrollView>(
          find.descendant(
            of: table,
            matching: find.byType(SingleChildScrollView),
          ),
        )
        .firstWhere((view) => view.scrollDirection == Axis.horizontal);
    expect(horizontalScrollbar.thumbVisibility, isTrue);
    expect(horizontalScrollbar.controller, isNotNull);
    expect(
      identical(horizontalScrollbar.controller, horizontalView.controller),
      isTrue,
    );

    final codeHeader = find.text('Code');
    expect(tester.widget<Text>(codeHeader).textAlign, TextAlign.left);
    expect(
      tester
          .widgetList<Directionality>(
            find.ancestor(
              of: codeHeader,
              matching: find.byType(Directionality),
            ),
          )
          .any(
            (directionality) =>
                directionality.textDirection == TextDirection.ltr,
          ),
      isTrue,
    );
    expect(
      tester
          .widgetList<DefaultTextStyle>(
            find.ancestor(
              of: find.text('ABC-1'),
              matching: find.byType(DefaultTextStyle),
            ),
          )
          .any((style) => style.textAlign == TextAlign.left),
      isTrue,
    );
    expect(
      tester
          .widgetList<Material>(
            find.ancestor(
              of: find.text('ABC-1'),
              matching: find.byType(Material),
            ),
          )
          .any((material) => material.color == expectedSelectedColor),
      isTrue,
    );
  });

  testWidgets(
      'selects and activates table rows by keyboard while retaining focus',
      (tester) async {
    int? activatedIndex;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AppDataTable(
                key: const Key('keyboardDataTable'),
                height: 220,
                columns: const [AppTableColumn(label: 'الاسم')],
                rows: [
                  for (var index = 0; index < 3; index++)
                    AppTableRow(
                      rowKey: Key('keyboardRow_$index'),
                      selected: activatedIndex == index,
                      onTap: () {
                        setState(() => activatedIndex = index);
                      },
                      cells: [Text('الصف ${index + 1}')],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('keyboardRow_0')));
    await tester.pump();
    expect(activatedIndex, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    final highlightedSecondRow = find.ancestor(
      of: find.text('الصف 2'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.selected == true,
      ),
    );
    expect(highlightedSecondRow, findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activatedIndex, 1);

    final table = find.byKey(const Key('keyboardDataTable'));
    expect(
      tester
          .widgetList<Focus>(
            find.descendant(of: table, matching: find.byType(Focus)),
          )
          .any((focus) => focus.focusNode?.hasFocus ?? false),
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activatedIndex, 0);
  });

  testWidgets(
      'invoice columns apply direction and keep a visible horizontal scrollbar',
      (tester) async {
    final verticalController = ScrollController();
    addTearDown(verticalController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 220,
              child: AppInvoiceFieldTable(
                key: const Key('directionalInvoiceTable'),
                columns: const [
                  AppInvoiceFieldColumn(
                    'Code',
                    240,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                  ),
                  AppInvoiceFieldColumn('الاسم', 240),
                ],
                rowCount: 1,
                rowCellsBuilder: (_, _) => const [
                  Text('ABC-2'),
                  Text('مادة'),
                ],
                summaryCells: const [Text('Total'), Text('1')],
                accentColor: AppModuleColors.sales,
                lightAccentColor: AppModulePalettes.sales.light,
                verticalScrollController: verticalController,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final table = find.byKey(const Key('directionalInvoiceTable'));
    final horizontalScrollbar = tester
        .widgetList<Scrollbar>(
          find.descendant(of: table, matching: find.byType(Scrollbar)),
        )
        .firstWhere(
          (scrollbar) =>
              scrollbar.scrollbarOrientation ==
              ScrollbarOrientation.bottom,
        );
    final horizontalView = tester
        .widgetList<SingleChildScrollView>(
          find.descendant(
            of: table,
            matching: find.byType(SingleChildScrollView),
          ),
        )
        .firstWhere((view) => view.scrollDirection == Axis.horizontal);
    expect(horizontalScrollbar.thumbVisibility, isTrue);
    expect(horizontalScrollbar.controller, isNotNull);
    expect(
      identical(horizontalScrollbar.controller, horizontalView.controller),
      isTrue,
    );

    final codeHeader = find.text('Code');
    expect(tester.widget<Text>(codeHeader).textAlign, TextAlign.left);
    expect(
      tester
          .widgetList<Directionality>(
            find.ancestor(
              of: find.text('ABC-2'),
              matching: find.byType(Directionality),
            ),
          )
          .any(
            (directionality) =>
                directionality.textDirection == TextDirection.ltr,
          ),
      isTrue,
    );
    expect(
      tester
          .widgetList<DefaultTextStyle>(
            find.ancestor(
              of: find.text('ABC-2'),
              matching: find.byType(DefaultTextStyle),
            ),
          )
          .any((style) => style.textAlign == TextAlign.left),
      isTrue,
    );
  });

  testWidgets('shows sales and purchase tables on one shared foundation',
      (tester) async {
    await pumpDesignSystemGallery(tester);

    expect(find.text('جداول إدخال القوائم'), findsOneWidget);
    expect(find.text('جدول المبيعات'), findsOneWidget);
    expect(find.text('جدول المشتريات'), findsOneWidget);

    final salesReference =
        find.byKey(const Key('designSalesInvoiceTable'));
    await reveal(tester, salesReference);

    expect(
      find.byKey(const Key('appSalesInvoiceTableTemplate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appSalesInvoiceTableHeader')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appSalesInvoiceTableRow-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appSalesInvoiceTableSummary')),
      findsOneWidget,
    );

    final salesFoundation = tester.widget<AppInvoiceFieldTable>(
      find.descendant(
        of: salesReference,
        matching: find.byType(AppInvoiceFieldTable),
      ),
    );
    expect(salesFoundation.accentColor, AppModulePalettes.sales.middle);

    const salesFieldKeys = [
      'appSalesInvoiceTemplateCodeField-r1',
      'appSalesInvoiceTemplateNameField-r1',
      'appSalesInvoiceTemplateWarehouseDropdown-r1',
      'appSalesInvoiceTemplateQuantityField-r1',
      'appSalesInvoiceTemplateSalePriceField-r1',
      'appSalesInvoiceTemplateDiscountField-r1',
      'appSalesInvoiceTemplatePriceAfterDiscountField-r1',
      'appSalesInvoiceTemplateTotalField-r1',
    ];
    for (final key in salesFieldKeys) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }

    final salesTable = tester.widget<Container>(
      find.byKey(const Key('appSalesInvoiceTableTemplate')),
    );
    final decoration = salesTable.decoration! as BoxDecoration;
    final foreground = salesTable.foregroundDecoration! as BoxDecoration;
    expect(salesTable.clipBehavior, Clip.antiAlias);
    expect(decoration.border, isNull);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(AppRadii.lg),
    );
    expect(foreground.border, isA<Border>());
    expect(
      foreground.borderRadius,
      BorderRadius.circular(AppRadii.lg),
    );

    final warehouseDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(
          const Key(
            'appSalesInvoiceTemplateWarehouseDropdown-r1',
          ),
        ),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(warehouseDropdown.useIntrinsicHeight, isTrue);
    expect(
      warehouseDropdown.minimumHeight,
      AppControlHeights.invoiceField,
    );
    expect(warehouseDropdown.showLabel, isFalse);
    expect(warehouseDropdown.borderRadius, AppRadii.sm);

    final codeFieldOutline = find.descendant(
      of: find.byKey(
        const Key('appSalesInvoiceTemplateCodeField-r1'),
      ),
      matching: find.byType(InputDecorator),
    );
    final warehouseDropdownOutline = find.descendant(
      of: find.byKey(
        const Key(
          'appSalesInvoiceTemplateWarehouseDropdown-r1',
        ),
      ),
      matching: find.byType(InputDecorator),
    );
    final codeRect = tester.getRect(codeFieldOutline);
    final dropdownRect = tester.getRect(warehouseDropdownOutline);
    expect(codeRect.height, AppControlHeights.invoiceField);
    expect(dropdownRect.height, closeTo(codeRect.height, 0.1));
    expect(dropdownRect.top, closeTo(codeRect.top, 0.1));
    expect(dropdownRect.bottom, closeTo(codeRect.bottom, 0.1));

    final salesAddButton =
        find.byKey(const Key('appSalesInvoiceTemplateAddButton'));
    await reveal(tester, salesAddButton);
    expect(
      tester.widget<AppTableActionButton>(salesAddButton).onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(
        const Key('appSalesInvoiceTemplateCodeField-r1'),
      ),
      'S-001',
    );
    await tester.enterText(
      find.byKey(
        const Key('appSalesInvoiceTemplateNameField-r1'),
      ),
      'مادة تجريبية',
    );
    await tester.enterText(
      find.byKey(
        const Key('appSalesInvoiceTemplateQuantityField-r1'),
      ),
      '1',
    );
    await tester.pump();
    expect(
      tester.widget<AppTableActionButton>(salesAddButton).onPressed,
      isNotNull,
    );

    await tester.tap(salesAddButton);
    await tester.pump();

    expect(
      find.byKey(const Key('appSalesInvoiceTableRow-r2')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('appSalesInvoiceTemplateDeleteButton-r1'),
      ),
      findsOneWidget,
    );

    final purchaseReference =
        find.byKey(const Key('designPurchaseInvoiceTable'));
    await reveal(tester, purchaseReference);

    expect(
      find.byKey(const Key('appPurchaseInvoiceTableTemplate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appPurchaseInvoiceTableHeader')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appPurchaseInvoiceTableRow-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('appPurchaseInvoiceTableSummary')),
      findsOneWidget,
    );

    final purchaseFoundation = tester.widget<AppInvoiceFieldTable>(
      find.descendant(
        of: purchaseReference,
        matching: find.byType(AppInvoiceFieldTable),
      ),
    );
    expect(
      purchaseFoundation.accentColor,
      AppModulePalettes.purchases.middle,
    );

    for (final label in const [
      'الحاوية',
      'سعر الشراء',
      'الكلفة',
      'إجمالي الكلفة',
      'سعر البيع',
    ]) {
      expect(
        find.descendant(
          of: purchaseReference,
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }

    const purchaseFieldKeys = [
      'appPurchaseInvoiceTemplateCodeField-r1',
      'appPurchaseInvoiceTemplateNameField-r1',
      'appPurchaseInvoiceTemplateWarehouseDropdown-r1',
      'appPurchaseInvoiceTemplateQuantityField-r1',
      'appPurchaseInvoiceTemplateContainerField-r1',
      'appPurchaseInvoiceTemplatePurchasePriceField-r1',
      'appPurchaseInvoiceTemplateDiscountField-r1',
      'appPurchaseInvoiceTemplatePriceAfterDiscountField-r1',
      'appPurchaseInvoiceTemplateTotalField-r1',
      'appPurchaseInvoiceTemplateCostField-r1',
      'appPurchaseInvoiceTemplateTotalCostField-r1',
      'appPurchaseInvoiceTemplateSalePriceField-r1',
    ];
    for (final key in purchaseFieldKeys) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }

    final purchaseWarehouseDropdown = tester.widget<AppDropdownField<String>>(
      find.ancestor(
        of: find.byKey(
          const Key(
            'appPurchaseInvoiceTemplateWarehouseDropdown-r1',
          ),
        ),
        matching: find.byType(AppDropdownField<String>),
      ),
    );
    expect(
      purchaseWarehouseDropdown.minimumHeight,
      AppControlHeights.invoiceField,
    );

    final purchaseCodeFieldOutline = find.descendant(
      of: find.byKey(
        const Key('appPurchaseInvoiceTemplateCodeField-r1'),
      ),
      matching: find.byType(InputDecorator),
    );
    final purchaseWarehouseDropdownOutline = find.descendant(
      of: find.byKey(
        const Key(
          'appPurchaseInvoiceTemplateWarehouseDropdown-r1',
        ),
      ),
      matching: find.byType(InputDecorator),
    );
    expect(
      tester.getRect(purchaseWarehouseDropdownOutline).height,
      closeTo(tester.getRect(purchaseCodeFieldOutline).height, 0.1),
    );

    final purchaseAddButton =
        find.byKey(const Key('appPurchaseInvoiceTemplateAddButton'));
    await reveal(tester, purchaseAddButton);
    expect(
      tester.widget<AppTableActionButton>(purchaseAddButton).onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(
        const Key('appPurchaseInvoiceTemplateCodeField-r1'),
      ),
      'P-001',
    );
    await tester.enterText(
      find.byKey(
        const Key('appPurchaseInvoiceTemplateNameField-r1'),
      ),
      'مادة تجريبية',
    );
    await tester.enterText(
      find.byKey(
        const Key('appPurchaseInvoiceTemplateQuantityField-r1'),
      ),
      '1',
    );
    await tester.pump();
    final enabledPurchaseAddButton =
        tester.widget<AppTableActionButton>(purchaseAddButton);
    expect(enabledPurchaseAddButton.onPressed, isNotNull);

    enabledPurchaseAddButton.onPressed!();
    await tester.pump();

    expect(
      find.byKey(const Key('appPurchaseInvoiceTableRow-r2')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('appPurchaseInvoiceTemplateDeleteButton-r1'),
      ),
      findsOneWidget,
    );
  });
}
