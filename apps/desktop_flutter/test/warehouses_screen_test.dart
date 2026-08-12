import 'dart:async';

import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/warehouses/domain/warehouse.dart';
import 'package:erp/features/warehouses/presentation/warehouses_controller.dart';
import 'package:erp/features/warehouses/presentation/widgets/inventory_transfer_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filters and navigates the repository warehouse list', () async {
    final repositories = AppRepositories.demo();
    final controller = WarehousesController(
      repository: repositories.warehouses,
      itemRepository: repositories.items,
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.state.warehouses, hasLength(4));
    expect(
      controller.state.warehouses.first.entityId,
      EntityId('warehouse-001'),
    );
    expect(
      controller.inventoryFor('warehouse-001').first.stockQuantity,
      const StockQuantity(18),
    );
    expect(
      controller.inventoryFor('warehouse-001').first.itemEntityId,
      EntityId('item-001'),
    );
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

  test('persists whole item transfers and immutable reversals', () async {
    final repositories = AppRepositories.demo();
    final controller = WarehousesController(
      repository: repositories.warehouses,
      itemRepository: repositories.items,
    );
    addTearDown(controller.dispose);
    await controller.load();

    final transferred = await controller.transferInventory(
      fromWarehouseId: 'warehouse-001',
      toWarehouseId: 'warehouse-002',
      quantitiesByItemId: {
        'item-001': 3,
        'item-002': 4,
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
      await controller.transferInventory(
        fromWarehouseId: 'warehouse-001',
        toWarehouseId: 'warehouse-002',
        quantitiesByItemId: {'item-001': 999},
      ),
      isFalse,
    );
    expect(
      await controller.transferInventory(
        fromWarehouseId: 'warehouse-001',
        toWarehouseId: 'warehouse-002',
        quantitiesByItemId: {'P-1001': 1},
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
    expect(controller.state.transferRecords.first.number, 105);
    expect(
      controller.state.transferRecords.first.lines,
      hasLength(2),
    );
    expect(
      controller.state.transferRecords.first.lines
          .map((line) => line.itemId),
      ['item-001', 'item-002'],
    );

    final originalId = controller.state.transferRecords.first.id;
    expect(
      await controller.reverseTransfer(
        originalId,
        createdAt: DateTime(2026, 7, 28),
      ),
      isTrue,
    );
    expect(controller.state.transferRecords.first.reversalOfId, originalId);
    expect(
      controller
          .inventoryFor('warehouse-001')
          .firstWhere((item) => item.productCode == 'P-1001')
          .quantity,
      18,
    );
    expect(await controller.reverseTransfer(originalId), isFalse);

    final reopened = WarehousesController(
      repository: repositories.warehouses,
      itemRepository: repositories.items,
    );
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.state.transferRecords.first.number, 106);
    expect(reopened.state.transferRecords.first.reversalOfId, originalId);
  });

  test('blocks real references and persists deletions', () async {
    final repositories = AppRepositories.demo();
    final controller = WarehousesController(
      repository: repositories.warehouses,
      itemRepository: repositories.items,
    );
    addTearDown(controller.dispose);
    await controller.load();

    controller.select('warehouse-002');
    expect(controller.isWarehouseReferenced('warehouse-002'), isTrue);
    expect((await controller.canDeleteSelected()).isAllowed, isFalse);
    expect(await controller.deleteSelected(), isNull);
    expect(controller.state.warehouses, hasLength(4));

    final temporary = Warehouse(
      id: 'warehouse-empty',
      number: 5,
      name: 'مخزن فارغ',
      location: '',
      notes: '',
    );
    await controller.add(temporary);
    expect(controller.isWarehouseReferenced(temporary.id), isFalse);
    expect(await controller.deleteSelected(), temporary);

    final reopened = WarehousesController(
      repository: repositories.warehouses,
      itemRepository: repositories.items,
    );
    addTearDown(reopened.dispose);
    await reopened.load();
    expect(reopened.state.warehouses, hasLength(4));
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
    expect(
      find.byKey(const Key('warehouseGroupsTypesButton')),
      findsNothing,
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
      tester.widget<AppRegularButton>(
        find.byKey(const Key('warehouseTransferButton')),
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

  testWidgets('creates one atomic multi-item transfer at 1280 by 720',
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
    expect(transferDialog.icon, Icons.compare_arrows_rounded);
    expect(
      find.byKey(const Key('inventoryTransferCloseButton')),
      findsNothing,
    );
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
      find.byKey(const Key('inventoryTransferLinesSection')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferLinesTable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferLinesHorizontalScroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferLinesHeader')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferLinesSummary')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('inventoryTransferLineRow-0')), findsOneWidget);
    expect(
      find.byKey(const Key('inventoryTransferLineItemField-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferLineAvailableField-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferLineQuantityField-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferSourceStockTable')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('inventoryTransferDestinationStockTable')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('inventoryTransferCreateTab')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferHistoryTab')),
      findsOneWidget,
    );
    final createTab = tester.widget<AppButton>(
      find.byKey(const Key('inventoryTransferCreateTab')),
    );
    expect(createTab.width, isNull);
    expect(createTab.minWidth, 180);
    final historyTab = tester.widget<AppButton>(
      find.byKey(const Key('inventoryTransferHistoryTab')),
    );
    expect(historyTab.width, isNull);
    expect(historyTab.minWidth, 210);

    final source = tester.widget<AppDropdownField<String>>(
      find.byKey(const Key('inventoryTransferFromDropdown')),
    );
    expect(source.value, 'warehouse-001');

    final destination = tester.widget<AppDropdownField<String>>(
      find.byKey(const Key('inventoryTransferToDropdown')),
    );
    expect(destination.value, 'warehouse-002');
    expect(destination.options, hasLength(4));

    final linesTable = tester.widget<AppInvoiceFieldTable>(
      find.ancestor(
        of: find.byKey(const Key('inventoryTransferLinesTable')),
        matching: find.byType(AppInvoiceFieldTable),
      ),
    );
    expect(
      linesTable.columns.map((column) => column.label),
      ['ت', 'المادة', 'المتوفر', 'كمية النقل', ''],
    );
    expect(linesTable.rowCount, 1);
    expect(linesTable.rowHeight, 80);
    final executeButton = tester.widget<AppButton>(
      find.byKey(const Key('inventoryTransferExecuteButton')),
    );
    expect(executeButton.width, 200);
    expect(executeButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const Key('inventoryTransferExecuteButton')),
    );
    await tester.pump();
    expect(find.text('أضف مادة واحدة مكتملة على الأقل'), findsOneWidget);

    await _selectTransferItem(tester, rowId: 0, itemId: 'item-001');
    await tester.enterText(
      find.byKey(const Key('inventoryTransferLineQuantityField-0')),
      '999',
    );
    await tester.pump();
    expect(
      _fieldText(
        tester,
        find.byKey(const Key('inventoryTransferLineAvailableField-0')),
      ),
      '18',
    );
    await tester.tap(
      find.byKey(const Key('inventoryTransferExecuteButton')),
    );
    await tester.pump();
    expect(
      find.text(
        'لا يمكن نقل طابعة ليزر لعدم كفاية الرصيد المخزني',
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('inventoryTransferLineQuantityField-0')),
      '3',
    );
    await tester.pump();

    // Deleting the only meaningful row must clear it instead of doing nothing.
    await tester.tap(
      find.byKey(const Key('inventoryTransferLineDeleteButton-0')),
    );
    await tester.pump();
    expect(find.byKey(const Key('inventoryTransferLineRow-0')), findsNothing);
    expect(find.byKey(const Key('inventoryTransferLineRow-1')), findsOneWidget);

    // A source change invalidates all drafted rows and starts from one blank row.
    await _selectTransferItem(tester, rowId: 1, itemId: 'item-001');
    await tester.enterText(
      find.byKey(const Key('inventoryTransferLineQuantityField-1')),
      '2',
    );
    tester
        .widget<AppDropdownField<String>>(
          find.byKey(const Key('inventoryTransferFromDropdown')),
        )
        .onChanged('warehouse-002');
    await tester.pump();
    expect(find.byKey(const Key('inventoryTransferLineRow-1')), findsNothing);
    expect(find.byKey(const Key('inventoryTransferLineRow-2')), findsOneWidget);
    expect(
      _fieldText(
        tester,
        find.byKey(const Key('inventoryTransferLineItemField-2')),
      ),
      isEmpty,
    );
    tester
        .widget<AppDropdownField<String>>(
          find.byKey(const Key('inventoryTransferFromDropdown')),
        )
        .onChanged('warehouse-001');
    await tester.pump();

    await _selectTransferItem(tester, rowId: 3, itemId: 'item-001');
    await tester.enterText(
      find.byKey(const Key('inventoryTransferLineQuantityField-3')),
      '3',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('inventoryTransferLineAddButton')),
    );
    await tester.pump();
    expect(find.byKey(const Key('inventoryTransferLineRow-4')), findsOneWidget);
    expect(
      _transferItemField(tester, 4).options.map((item) => item.itemId),
      isNot(contains('item-001')),
    );

    await _selectTransferItem(tester, rowId: 4, itemId: 'item-002');
    await tester.enterText(
      find.byKey(const Key('inventoryTransferLineQuantityField-4')),
      '4',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('inventoryTransferLineDeleteButton-4')),
    );
    await tester.pump();
    expect(find.byKey(const Key('inventoryTransferLineRow-4')), findsNothing);
    await tester.tap(
      find.byKey(const Key('inventoryTransferLineAddButton')),
    );
    await tester.pump();
    await _selectTransferItem(tester, rowId: 5, itemId: 'item-002');
    await tester.enterText(
      find.byKey(const Key('inventoryTransferLineQuantityField-5')),
      '4',
    );
    await tester.pump();
    expect(find.text('2 مادة'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const Key('inventoryTransferExecuteButton')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('inventoryTransferHistorySearchField')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferHistoryCloseButton')),
      findsNothing,
    );
    expect(
      tester
          .widget<AppModuleDialog>(
            find.byKey(const Key('inventoryTransferDialog')),
          )
          .icon,
      Icons.history_rounded,
    );
    final refreshButton = tester.widget<AppButton>(
      find.byKey(const Key('inventoryTransferHistoryRefreshButton')),
    );
    expect(refreshButton.variant, AppButtonVariant.success);
    expect(refreshButton.width, isNull);
    expect(refreshButton.minWidth, 160);
    expect(
      find.byKey(const Key('inventoryTransferReverseButton')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('inventoryTransferHistoryRefreshButton')),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<SnackBar>(
        find.byKey(const Key('appToast')),
      ).backgroundColor,
      AppColors.green,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('inventoryTransferToastHost')),
        matching: find.byKey(const Key('appToast')),
      ),
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

    expect(
      find.byKey(const Key('inventoryTransferHistory_105')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferHistory_106')),
      findsNothing,
    );
    expect(
      find.text(
        'P-1001 - طابعة ليزر (3)، P-1002 - حبر طابعة أسود (4)',
      ),
      findsOneWidget,
    );
    final reverseButton = tester.widget<AppButton>(
      find.byKey(const Key('inventoryTransferReverseButton')),
    );
    expect(reverseButton.onPressed, isNotNull);
    reverseButton.onPressed!();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('inventoryTransferHistory_106')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('appModuleDialogClose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('warehouseTransferButton')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('inventoryTransferHistoryTab')),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('inventoryTransferHistory_105')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('inventoryTransferHistory_106')),
      findsOneWidget,
    );
  });

  testWidgets('cannot close the transfer dialog while a transfer is pending',
      (tester) async {
    final pendingTransfer = Completer<bool>();
    Map<String, int>? submittedQuantities;
    bool? dialogResult;
    final warehouses = [
      Warehouse(
        id: 'source',
        number: 1,
        name: 'المخزن الرئيسي',
        location: 'بغداد',
        notes: '',
      ),
      Warehouse(
        id: 'destination',
        number: 2,
        name: 'المخزن الفرعي',
        location: 'بغداد',
        notes: '',
      ),
    ];
    final sourceItem = WarehouseInventoryItem(
      id: 'balance-item-a',
      itemId: 'item-a',
      productCode: 'P-A',
      productName: 'مادة الاختبار',
      quantity: 10,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            key: const Key('openPendingTransferDialog'),
            onPressed: () async {
              dialogResult = await InventoryTransferDialog.show(
                context,
                warehouses: warehouses,
                initialFromWarehouseId: 'source',
                inventoryFor: (warehouseId) =>
                    warehouseId == 'source' ? [sourceItem] : const [],
                onTransfer: ({
                  required String fromWarehouseId,
                  required String toWarehouseId,
                  required Map<String, int> quantitiesByItemId,
                }) {
                  submittedQuantities = Map.of(quantitiesByItemId);
                  return pendingTransfer.future;
                },
              );
            },
            child: const Text('فتح النقل'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('openPendingTransferDialog')));
    await tester.pumpAndSettle();
    await _selectTransferItem(tester, rowId: 0, itemId: 'item-a');
    await tester.enterText(
      find.byKey(const Key('inventoryTransferLineQuantityField-0')),
      '2',
    );
    await tester.tap(
      find.byKey(const Key('inventoryTransferExecuteButton')),
    );
    await tester.pump();

    expect(submittedQuantities, {'item-a': 2});
    expect(find.byKey(const Key('appModuleDialogClose')), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const Key('inventoryTransferDialog')), findsOneWidget);
    expect(dialogResult, isNull);

    pendingTransfer.complete(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appModuleDialogClose')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appModuleDialogClose')));
    await tester.pumpAndSettle();
    expect(dialogResult, isTrue);
  });

  testWidgets('guards unsaved warehouse data from system back',
      (tester) async {
    await _openWarehouses(tester);
    await tester.enterText(
      find.byKey(const Key('warehouseNameField')),
      'مخزن غير محفوظ',
    );
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appConfirmDialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('appDialogCancelButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('warehousesScreen')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appDialogConfirmButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('warehousesScreen')), findsNothing);
    expect(
      find.byKey(const Key('dashboardCard_warehouses')),
      findsOneWidget,
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

AppAutocompleteField<WarehouseInventoryItem> _transferItemField(
  WidgetTester tester,
  int rowId,
) {
  final field = find.byKey(Key('inventoryTransferLineItemField-$rowId'));
  return tester.widget<AppAutocompleteField<WarehouseInventoryItem>>(
    find.ancestor(
      of: field,
      matching: find.byType(
        AppAutocompleteField<WarehouseInventoryItem>,
      ),
    ),
  );
}

Future<void> _selectTransferItem(
  WidgetTester tester, {
  required int rowId,
  required String itemId,
}) async {
  final field = _transferItemField(tester, rowId);
  final item = field.options.singleWhere(
    (candidate) => candidate.itemId == itemId,
  );
  field.onSelected(item);
  await tester.pump();
}

String _fieldText(WidgetTester tester, Finder field) {
  return tester
      .widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      )
      .controller
      .text;
}
