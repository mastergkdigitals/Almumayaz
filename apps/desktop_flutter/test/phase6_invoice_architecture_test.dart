import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/application/invoice_editor_coordinator.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/settings/domain/settings_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared editor uses stable identity for selection and navigation',
      () async {
    final records = [
      _EditorRecord(EntityId('invoice-a'), 101),
      _EditorRecord(EntityId('invoice-b'), 101),
      _EditorRecord(EntityId('invoice-c'), 102),
    ];
    final coordinator = InvoiceEditorCoordinator<_EditorRecord>(
      loadRecords: () async => records,
      idOf: (record) => record.id,
    );

    await coordinator.load();
    expect(
      coordinator.selection.records.take(2).map(
            (record) => record.documentNumber,
          ).toList(),
      [101, 101],
    );
    expect(
      coordinator.selection.select(EntityId('invoice-b'))?.id,
      EntityId('invoice-b'),
    );
    expect(coordinator.selection.selectedIndex, 1);
    expect(
      coordinator.selection.navigate(InvoiceEditorNavigation.next)?.id,
      EntityId('invoice-c'),
    );
    expect(
      coordinator.selection.navigate(InvoiceEditorNavigation.next),
      isNull,
    );
    expect(coordinator.selection.selectedId, isNull);

    final dirty = InvoiceEditorDirtyTracker((notes: '', total: 10));
    expect(dirty.hasChanges((notes: '', total: 10)), isFalse);
    expect(dirty.hasChanges((notes: 'changed', total: 10)), isTrue);
    dirty.accept((notes: 'changed', total: 10));
    expect(dirty.hasChanges((notes: 'changed', total: 10)), isFalse);
  });

  testWidgets(
      'invoice edits keep party and warehouse IDs through rename and name reuse',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = AppStore.demo();
    final warehouse = await store.repositories.warehouses.getById(
      EntityId('warehouse-003'),
    );
    await store.repositories.warehouses.save(
      warehouse!.copyWith(name: 'مخزن الجنوب المشترك'),
    );
    final reusedWarehouse = await store.repositories.warehouses.getById(
      EntityId('warehouse-002'),
    );
    await store.repositories.warehouses.save(
      reusedWarehouse!.copyWith(name: 'الرصافة'),
    );
    final originalCustomer = await store.repositories.parties.getById(
      EntityId('party-001'),
    );
    await store.repositories.parties.save(
      originalCustomer!.copyWith(name: 'شركة النخيل الجديدة'),
    );
    final reusedCustomer = await store.repositories.parties.getById(
      EntityId('party-008'),
    );
    await store.repositories.parties.save(
      reusedCustomer!.copyWith(name: 'شركة النخيل للتجارة'),
    );
    final originalSupplier = await store.repositories.parties.getById(
      EntityId('party-011'),
    );
    await store.repositories.parties.save(
      originalSupplier!.copyWith(name: 'شركة الرافدين الجديدة'),
    );
    final reusedSupplier = await store.repositories.parties.getById(
      EntityId('party-009'),
    );
    await store.repositories.parties.save(
      reusedSupplier!.copyWith(name: 'شركة الرافدين للتجهيز'),
    );
    final defaults =
        await store.repositories.businessSettings.loadOperationalDefaults();
    await store.repositories.businessSettings.saveOperationalDefaults(
      OperationalDefaults(
        purchases: PurchaseDefaults(
          warehouseId: EntityId('warehouse-003'),
          purchaseKind: defaults.purchases.purchaseKind,
          paymentKind: defaults.purchases.paymentKind,
          currency: defaults.purchases.currency,
        ),
        sales: SalesDefaults(
          warehouseId: EntityId('warehouse-003'),
          saleKind: defaults.sales.saleKind,
          currency: defaults.sales.currency,
        ),
        cashbox: defaults.cashbox,
      ),
    );

    await tester.pumpWidget(AlmumayazApp(store: store));
    await tester.enterText(find.byKey(const Key('usernameField')), 'admin');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboardCard_sales')));
    await tester.pumpAndSettle();
    final salesWarehouse = _dropdown(tester, 'salesWarehouseField');
    expect(salesWarehouse.value, 'warehouse-003');
    expect(
      salesWarehouse.options.map((option) => option.label),
      [
        'المخزن الرئيسي',
        'الرصافة',
        'مخزن الجنوب المشترك',
        'مخزن أربيل',
      ],
    );
    expect(_historicalWarehouseSnapshot(), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('salesNotesField')),
      'تحديث هوية المبيعات',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('salesUpdateButton')));
    await tester.pumpAndSettle();
    final updatedSale = await store.repositories.sales.getById(
      EntityId('sales-invoice-101'),
    );
    expect(updatedSale!.notes, 'تحديث هوية المبيعات');
    expect(updatedSale.customerId, EntityId('party-001'));
    expect(updatedSale.defaultWarehouseId, EntityId('warehouse-003'));
    expect(
      updatedSale.lines.take(2).map((line) => line.warehouseId),
      [EntityId('warehouse-003'), EntityId('warehouse-003')],
    );
    await tester.tap(find.byKey(const Key('salesLastButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salesLastButton')));
    await tester.pumpAndSettle();
    expect(_dropdown(tester, 'salesWarehouseField').value, 'warehouse-003');
    expect(
      _invoiceWarehouseDropdown(tester, 'appSalesInvoiceTemplate').value,
      'warehouse-003',
    );

    await tester.tap(find.byKey(const Key('appScreenBackButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboardCard_purchases')));
    await tester.pumpAndSettle();
    final purchaseWarehouse = _dropdown(tester, 'purchaseWarehouseField');
    expect(purchaseWarehouse.value, 'warehouse-003');
    expect(
      purchaseWarehouse.options.map((option) => option.label),
      [
        'المخزن الرئيسي',
        'الرصافة',
        'مخزن الجنوب المشترك',
        'مخزن أربيل',
      ],
    );
    expect(_historicalWarehouseSnapshot(), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('purchaseNotesField')),
      'تحديث هوية المشتريات',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('purchaseUpdateButton')));
    await tester.pumpAndSettle();
    final updatedPurchase = await store.repositories.purchases.getById(
      EntityId('purchase-invoice-101'),
    );
    expect(updatedPurchase!.notes, 'تحديث هوية المشتريات');
    expect(updatedPurchase.supplierId, EntityId('party-011'));
    expect(updatedPurchase.defaultWarehouseId, EntityId('warehouse-003'));
    expect(
      updatedPurchase.lines.map((line) => line.warehouseId),
      [
        EntityId('warehouse-003'),
        EntityId('warehouse-003'),
        EntityId('warehouse-001'),
      ],
    );
    await tester.tap(find.byKey(const Key('purchaseLastButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('purchaseLastButton')));
    await tester.pumpAndSettle();
    expect(
      _dropdown(tester, 'purchaseWarehouseField').value,
      'warehouse-003',
    );
    expect(
      _invoiceWarehouseDropdown(tester, 'appPurchaseInvoiceTemplate').value,
      'warehouse-003',
    );
  });
}

class _EditorRecord {
  const _EditorRecord(this.id, this.documentNumber);

  final EntityId id;
  final int documentNumber;
}

AppDropdownField<String> _dropdown(WidgetTester tester, String fieldKey) {
  return tester.widget<AppDropdownField<String>>(
    find.ancestor(
      of: find.byKey(Key(fieldKey)),
      matching: find.byType(AppDropdownField<String>),
    ),
  );
}

Finder _historicalWarehouseSnapshot() {
  return find.byWidgetPredicate(
    (widget) {
      if (widget is! AppDropdownField<String>) return false;
      final key = widget.fieldKey;
      return key is ValueKey<String> &&
          key.value.contains('InvoiceTemplateWarehouseDropdown-') &&
          widget.value == 'warehouse-003' &&
          widget.options.first.label == 'الرصافة';
    },
  );
}

AppDropdownField<String> _invoiceWarehouseDropdown(
  WidgetTester tester,
  String keyPrefix,
) {
  return tester.widget<AppDropdownField<String>>(
    find.byWidgetPredicate((widget) {
      if (widget is! AppDropdownField<String>) return false;
      final key = widget.fieldKey;
      return key is ValueKey<String> &&
          key.value.startsWith('${keyPrefix}WarehouseDropdown-');
    }).first,
  );
}
