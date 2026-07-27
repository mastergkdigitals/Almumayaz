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
    await tester.pump();

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
