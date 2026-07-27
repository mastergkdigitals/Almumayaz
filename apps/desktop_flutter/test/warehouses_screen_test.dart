import 'package:erp/app/app.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/features/warehouses/presentation/warehouses_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters and navigates the temporary warehouse list', () {
    final controller = WarehousesController();
    addTearDown(controller.dispose);

    expect(controller.state.warehouses, hasLength(4));
    expect(controller.materialCountFor('warehouse-001'), 4);
    expect(controller.totalQuantityFor('warehouse-001'), 227);

    controller.search('البصرة');
    expect(controller.visibleWarehouses, hasLength(1));
    expect(controller.visibleWarehouses.first.number, 3);

    controller.first();
    expect(controller.selectedWarehouse?.name, 'مخزن البصرة');

    controller.search('');
    controller.first();
    expect(controller.selectedWarehouse?.name, 'المخزن الرئيسي');

    controller.next();
    expect(controller.selectedWarehouse?.name, 'مخزن الكرادة');

    controller.last();
    expect(controller.selectedWarehouse?.name, 'مخزن أربيل');

    controller.next();
    expect(controller.selectedWarehouse, isNull);
  });

  test('moves whole item quantities between temporary warehouses', () {
    final controller = WarehousesController();
    addTearDown(controller.dispose);

    final transferred = controller.transferInventory(
      fromWarehouseId: 'warehouse-001',
      toWarehouseId: 'warehouse-002',
      quantitiesByProductCode: {
        'P-1001': 3,
        'P-1002': 4,
      },
    );

    expect(transferred, isTrue);
    expect(
      controller
          .inventoryFor('warehouse-001')
          .firstWhere((item) => item.productCode == 'P-1001')
          .quantity,
      15,
    );
    expect(
      controller
          .inventoryFor('warehouse-002')
          .firstWhere((item) => item.productCode == 'P-1001')
          .quantity,
      10,
    );
    expect(
      controller
          .inventoryFor('warehouse-002')
          .firstWhere((item) => item.productCode == 'P-1002')
          .quantity,
      4,
    );

    expect(
      controller.transferInventory(
        fromWarehouseId: 'warehouse-001',
        toWarehouseId: 'warehouse-002',
        quantitiesByProductCode: {'P-1001': 999},
      ),
      isFalse,
    );
    expect(
      controller
          .inventoryFor('warehouse-001')
          .firstWhere((item) => item.productCode == 'P-1001')
          .quantity,
      15,
    );
  });

  testWidgets('opens Warehouses with old structure and shared controls',
      (tester) async {
    await _openWarehouses(tester);

    expect(find.byKey(const Key('warehousesScreen')), findsOneWidget);
    expect(find.byKey(const Key('warehouseForm')), findsOneWidget);
    expect(find.byKey(const Key('warehousesActionBar')), findsOneWidget);
    expect(find.byKey(const Key('warehousesTable')), findsOneWidget);
    expect(
      find.byKey(const Key('warehouseInventoryPanel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('warehouseInventoryTable')),
      findsOneWidget,
    );

    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byKey(const Key('warehousesScreen')),
        matching: find.byType(Scaffold),
      ),
    );
    expect(
      scaffold.backgroundColor,
      Color.alphaBlend(
        AppModuleColors.warehouses.withAlpha(12),
        AppColors.surface,
      ),
    );

    final numberField = tester.widget<TextFormField>(
      find.byKey(const Key('warehouseNumberField')),
    );
    expect(numberField.enabled, isFalse);
    expect(
      _fieldDecoration(
        tester,
        find.byKey(const Key('warehouseNumberField')),
      ).fillColor,
      AppColors.neutralSurface,
    );

    for (final fieldKey in [
      'warehouseNameField',
      'warehouseLocationField',
      'warehouseNotesField',
    ]) {
      final fieldFinder = find.byKey(Key(fieldKey));
      final field = tester.widget<TextFormField>(fieldFinder);
      final decoration = _fieldDecoration(tester, fieldFinder);
      expect(field.enabled, isTrue);
      expect(decoration.fillColor, AppColors.surface);
      expect(
        (decoration.focusedBorder as OutlineInputBorder)
            .borderSide
            .color,
        AppModuleColors.warehouses,
      );
    }

    final warehouseTable = tester.widget<AppDataTable>(
      find.byKey(const Key('warehousesTable')),
    );
    expect(warehouseTable.accentColor, AppModuleColors.warehouses);
    expect(warehouseTable.alternatingRowColor, isNull);
    expect(
      warehouseTable.columns.map((column) => column.label),
      ['الرقم', 'اسم المخزن', 'الموقع', 'عدد المواد', 'إجمالي الكمية'],
    );

    final inventoryTable = tester.widget<AppDataTable>(
      find.byKey(const Key('warehouseInventoryTable')),
    );
    expect(inventoryTable.accentColor, AppModuleColors.warehouses);
    expect(inventoryTable.alternatingRowColor, isNull);
    expect(
      inventoryTable.columns.map((column) => column.label),
      ['رمز المادة', 'اسم المادة', 'الكمية'],
    );

    await tester.tap(
      find.byKey(const Key('warehouseRow_warehouse-001')),
    );
    await tester.pumpAndSettle();

    expect(find.text('مخزون المخزن الرئيسي'), findsOneWidget);
    expect(inventoryTable.rows, isEmpty);
    expect(
      tester
          .widget<AppDataTable>(
            find.byKey(const Key('warehouseInventoryTable')),
          )
          .rows,
      hasLength(4),
    );
    expect(
      tester.widget<AppButton>(
        find.descendant(
          of: find.byKey(const Key('warehouseTransferButton')),
          matching: find.byType(AppButton),
        ),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<AppButton>(
        find.byKey(const Key('warehousesDeleteButton')),
      ).onPressed,
      isNull,
    );
  });

  testWidgets('opens the Warehouse Transfer dialog with old structure',
      (tester) async {
    await _openWarehouses(tester);
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('warehouseRow_warehouse-001')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('warehouseTransferButton')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('inventoryTransferDialog')),
      findsOneWidget,
    );
    final transferDialog = tester.widget<AppModuleDialog>(
      find.byKey(const Key('inventoryTransferDialog')),
    );
    expect(transferDialog.bodyScrollable, isFalse);
    expect(transferDialog.maxHeightFactor, 0.96);
    expect(
      find.ancestor(
        of: find.byKey(const Key('inventoryTransferCreateTab')),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('inventoryTransferDetails')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferProductField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferQuantityField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferAvailableQuantity')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferSourceStockTable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferDestinationStockTable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferCreateTab')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferHistoryTab')),
      findsOneWidget,
    );

    final source = tester.widget<AppDropdownField<String>>(
      find.byKey(const Key('inventoryTransferFromDropdown')),
    );
    expect(source.value, 'warehouse-001');

    final destination = tester.widget<AppDropdownField<String>>(
      find.byKey(const Key('inventoryTransferToDropdown')),
    );
    expect(destination.value, 'warehouse-002');
    expect(destination.options, hasLength(4));

    final sourceStockTable = tester.widget<AppDataTable>(
      find.byKey(const Key('inventoryTransferSourceStockTable')),
    );
    expect(sourceStockTable.accentColor, AppModuleColors.warehouses);
    expect(
      sourceStockTable.columns.map((column) => column.label),
      ['رمز المادة', 'اسم المادة', 'الكمية'],
    );
    expect(
      tester
          .widget<AppButton>(
            find.byKey(const Key('inventoryTransferExecuteButton')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(
      find.byKey(const Key('inventoryTransferHistoryTab')),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('inventoryTransferHistorySearchField')),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('inventoryTransferHistorySearchField')),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    final historyTable = tester.widget<AppDataTable>(
      find.byKey(const Key('inventoryTransferHistoryTable')),
    );
    expect(historyTable.accentColor, AppModuleColors.warehouses);
    expect(historyTable.rowHeight, 56);
    expect(historyTable.showColumnDividers, isFalse);
    expect(historyTable.showShadow, isTrue);
    expect(historyTable.alternatingRowColor, isNull);
    expect(historyTable.verticalScrollController, isNotNull);
    expect(
      historyTable.columns.map((column) => column.label),
      ['رقم النقل', 'التاريخ', 'من مخزن', 'إلى مخزن', 'المواد'],
    );
  });
}

Future<void> _openWarehouses(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const AlmumayazApp());
  await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
  await tester.enterText(find.byKey(const Key('passwordField')), 'password');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('dashboardCard_warehouses')));
  await tester.pumpAndSettle();
}

InputDecoration _fieldDecoration(WidgetTester tester, Finder field) {
  return tester
      .widget<InputDecorator>(
        find.descendant(of: field, matching: find.byType(InputDecorator)),
      )
      .decoration;
}
