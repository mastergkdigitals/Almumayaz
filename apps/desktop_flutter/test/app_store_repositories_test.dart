import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/cashbox/domain/cashbox_repository.dart';
import 'package:erp/features/parties/domain/party.dart';
import 'package:erp/features/purchases/domain/purchase_invoice.dart';
import 'package:erp/features/sales/domain/sales_invoice.dart';
import 'package:erp/features/settings/domain/operational_master_data.dart';
import 'package:erp/features/settings/domain/settings_models.dart';
import 'package:erp/features/warehouses/domain/inventory_records.dart';
import 'package:erp/features/warehouses/domain/warehouse.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo repositories expose resolvable cross-module references', () async {
    final repositories = AppRepositories.demo();
    final sale = (await repositories.sales.getAll()).first;
    final purchase = (await repositories.purchases.getAll()).first;

    expect((await repositories.sales.getAll()).map((entry) => entry.documentNumber),
        [101, 102, 103]);
    expect(
      (await repositories.purchases.getAll())
          .map((entry) => entry.documentNumber),
      [101, 102, 103],
    );

    expect(await repositories.parties.getById(sale.customerId), isNotNull);
    expect(await repositories.parties.getById(purchase.supplierId), isNotNull);
    expect(
      await repositories.warehouses.getById(sale.defaultWarehouseId),
      isNotNull,
    );
    for (final line in sale.lines) {
      expect(await repositories.items.getById(line.itemId), isNotNull);
      expect(
        await repositories.warehouses.getById(line.warehouseId),
        isNotNull,
      );
    }
    for (final line in purchase.lines) {
      expect(await repositories.items.getById(line.itemId), isNotNull);
      expect(
        await repositories.warehouses.getById(line.warehouseId),
        isNotNull,
      );
    }

    expect(sale.id.value, isNot(sale.documentNumber.toString()));
    expect(purchase.id.value, isNot(purchase.documentNumber.toString()));

    final defaults = await repositories.businessSettings
        .loadOperationalDefaults();
    expect(
      await repositories.warehouses.getById(defaults.sales.warehouseId),
      isNotNull,
    );
    expect(
      (await repositories.cashbox.getMainAccounts()).any(
        (account) => account.entityId == defaults.cashbox.mainAccountId,
      ),
      isTrue,
    );

    final masterGroups = await repositories.operationalMasterData.getByKind(
      OperationalMasterDataKind.itemGroup,
    );
    final itemGroups = await repositories.items.getGroups();
    expect(
      itemGroups.any((group) => EntityId(group.id) == masterGroups.first.id),
      isTrue,
    );
  });

  test('shared repository instances retain demo mutations', () async {
    final store = AppStore.demo();
    final firstHandle = store.repositories.parties;
    final secondHandle = store.repositories.parties;
    final added = Party(
      id: EntityId.demo('party', 99).value,
      number: 99,
      createdAt: DateTime(2026, 8, 5),
      name: 'طرف اختبار مشترك',
      type: PartyType.customer,
      workplace: 'اختبار',
      branch: 'الرئيسي',
      phone: '',
      alternatePhone: '',
      city: 'بغداد',
      address: '',
      notes: '',
      balanceIqd: 0,
      balanceUsd: 0,
    );

    expect(identical(firstHandle, secondHandle), isTrue);
    await firstHandle.save(added);
    expect(
      (await secondHandle.getById(EntityId(added.id)))?.id,
      added.id,
    );
  });

  test('store exposes one cross-module invalidation signal', () {
    final store = AppStore.demo();
    var notifications = 0;
    store.addListener(() => notifications++);

    store.markDataChanged();

    expect(store.revision, 1);
    expect(notifications, 1);
  });

  testWidgets('AppStoreProvider keeps its store while child screens reopen', (
    tester,
  ) async {
    Object? firstRepository;
    Object? reopenedRepository;

    Widget buildChild(String label, ValueChanged<Object> capture) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (context) {
            capture(
              AppStoreScope.of(
                context,
                listen: false,
              ).repositories.parties,
            );
            return Text(label);
          },
        ),
      );
    }

    await tester.pumpWidget(
      AppStoreProvider(
        key: const ValueKey('appStoreProvider'),
        child: buildChild('الشاشة الأولى', (value) => firstRepository = value),
      ),
    );
    await tester.pumpWidget(
      AppStoreProvider(
        key: const ValueKey('appStoreProvider'),
        child: buildChild(
          'إعادة فتح الشاشة',
          (value) => reopenedRepository = value,
        ),
      ),
    );

    expect(reopenedRepository, same(firstRepository));
  });

  test('reference guards see relationships owned by other repositories', () async {
    final repositories = AppRepositories.demo();

    final partyDecision = await repositories.parties.canDelete(
      EntityId('party-001'),
    );
    final itemDecision = await repositories.items.canDelete(
      EntityId('item-001'),
    );
    final warehouseDecision = await repositories.warehouses.canDelete(
      EntityId('warehouse-001'),
    );

    expect(partyDecision.isAllowed, isFalse);
    expect(itemDecision.isAllowed, isFalse);
    expect(warehouseDecision.isAllowed, isFalse);
  });

  test('cashbox balance uses the persisted chronological snapshot', () async {
    final cashbox = AppRepositories.demo().cashbox;
    final balance = await cashbox.getBalance(
      EntityId.demo('cashbox-subaccount', 4),
    );
    final mainAccounts = await cashbox.getMainAccounts();
    final partiesAccount = mainAccounts.firstWhere(
      (account) =>
          account.id == EntityId.demo('cashbox-main-account', 4).value,
    );
    final customerAccount = partiesAccount.subaccounts.firstWhere(
      (account) =>
          account.id == EntityId.demo('cashbox-subaccount', 4).value,
    );

    expect(balance.iqd.toPlainString(), '500000');
    expect(balance.usd.toPlainString(), '850.00');
    expect(partiesAccount.label, 'الأطراف');
    expect(customerAccount.balanceIqd, 500000);
    expect(customerAccount.balanceUsd, 850);
  });

  test('cashbox recalculates snapshots after update and delete', () async {
    final cashbox = AppRepositories.demo().cashbox;
    final voucher = (await cashbox.getAll()).first;
    await cashbox.save(voucher.copyWith(amountIqd: 500000));

    var balance = await cashbox.getBalance(
      EntityId.demo('cashbox-subaccount', 4),
    );
    expect(balance.iqd.toPlainString(), '750000');

    await cashbox.delete(EntityId(voucher.id));
    balance = await cashbox.getBalance(
      EntityId.demo('cashbox-subaccount', 4),
    );
    expect(balance.iqd.toPlainString(), '1250000');
  });

  test('settings master-data parents remain protected while children exist', () async {
    final repository = AppRepositories.demo().operationalMasterData;
    final groups = await repository.getByKind(
      OperationalMasterDataKind.itemGroup,
    );

    expect(groups, isNotEmpty);
    expect((await repository.canDelete(groups.first.id)).isAllowed, isFalse);
    expect(
      (await repository.canDelete(EntityId.demo('item-type', 1))).isAllowed,
      isFalse,
    );
    expect(
      (await repository.canDelete(EntityId.demo('branch', 1))).isAllowed,
      isFalse,
    );
    expect(
      (await repository.canDelete(
        EntityId.demo('cashbox-subaccount', 1),
      )).isAllowed,
      isFalse,
    );
  });

  test('settings master-data enforces parent kinds', () async {
    final repository = AppRepositories.demo().operationalMasterData;
    final invalid = OperationalMasterDataRecord(
      id: EntityId.demo('item-type', 99),
      kind: OperationalMasterDataKind.itemType,
      number: 99,
      name: 'نوع غير صالح',
      parentId: EntityId.demo('workplace', 1),
    );

    expect(() => repository.save(invalid), throwsStateError);

    final existing = await repository.getById(
      EntityId.demo('item-group', 1),
    );
    expect(existing, isNotNull);
    final existingRecord = existing!;
    expect(
      () => repository.save(
        OperationalMasterDataRecord(
          id: existingRecord.id,
          kind: OperationalMasterDataKind.workplace,
          number: existingRecord.number,
          name: existingRecord.name,
        ),
      ),
      throwsStateError,
    );
  });

  test('operational defaults protect referenced warehouses and accounts', () async {
    final repositories = AppRepositories.demo();
    final warehouse = Warehouse(
      id: EntityId.demo('warehouse', 99).value,
      number: 99,
      name: 'مخزن اختبار الإعدادات',
      location: '',
      notes: '',
    );
    final account = OperationalMasterDataRecord(
      id: EntityId.demo('cashbox-main-account', 99),
      kind: OperationalMasterDataKind.cashboxMainAccount,
      number: 99,
      name: 'حساب اختبار الإعدادات',
    );
    await repositories.warehouses.save(warehouse);
    await repositories.operationalMasterData.save(account);
    final current = await repositories.businessSettings
        .loadOperationalDefaults();
    await repositories.businessSettings.saveOperationalDefaults(
      OperationalDefaults(
        purchases: current.purchases,
        sales: SalesDefaults(
          warehouseId: EntityId(warehouse.id),
          saleKind: current.sales.saleKind,
          currency: current.sales.currency,
        ),
        cashbox: CashboxDefaults(
          movementKind: current.cashbox.movementKind,
          mainAccountId: account.id,
        ),
      ),
    );

    expect(
      (await repositories.warehouses.canDelete(EntityId(warehouse.id)))
          .isAllowed,
      isFalse,
    );
    expect(
      (await repositories.operationalMasterData.canDelete(account.id))
          .isAllowed,
      isFalse,
    );
  });

  test('Sales and Purchase keep their different line discount rules', () {
    final salesLine = SalesInvoiceLine(
      id: EntityId.demo('sale-line', 90),
      itemId: EntityId.demo('item', 1),
      warehouseId: EntityId.demo('warehouse', 1),
      quantity: WholeQuantity(2),
      unitPrice: Money.fromMajor(100, AppCurrency.iqd),
      discountPerUnit: Money.fromMajor(10, AppCurrency.iqd),
    );
    final purchaseLine = PurchaseInvoiceLine(
      id: EntityId.demo('purchase-line', 90),
      itemId: EntityId.demo('item', 1),
      warehouseId: EntityId.demo('warehouse', 1),
      quantity: WholeQuantity(2),
      containerQuantity: WholeQuantity(0),
      purchasePrice: Money.fromMajor(100, AppCurrency.iqd),
      lineDiscount: Money.fromMajor(10, AppCurrency.iqd),
      salePrice: Money.fromMajor(120, AppCurrency.iqd),
    );

    expect(salesLine.total.toPlainString(), '180');
    expect(purchaseLine.netTotal.toPlainString(), '190');
  });

  test('Purchase model preserves a legitimate negative result', () {
    final line = PurchaseInvoiceLine(
      id: EntityId.demo('purchase-line', 91),
      itemId: EntityId.demo('item', 1),
      warehouseId: EntityId.demo('warehouse', 1),
      quantity: WholeQuantity(1),
      containerQuantity: WholeQuantity(0),
      purchasePrice: Money.fromMajor(100, AppCurrency.iqd),
      lineDiscount: Money.fromMajor(150, AppCurrency.iqd),
      salePrice: Money.fromMajor(120, AppCurrency.iqd),
    );
    final invoice = PurchaseInvoice(
      id: EntityId.demo('purchase', 91),
      documentNumber: 2091,
      date: BusinessDate(2026, 8, 5),
      minuteOfDay: 9 * 60,
      supplierId: EntityId.demo('party', 3),
      defaultWarehouseId: EntityId.demo('warehouse', 1),
      currency: AppCurrency.iqd,
      exchangeRate: ExchangeRate.parse('1310'),
      purchaseKind: PurchaseTransactionKind.local,
      settlementKind: PurchaseSettlementKind.cash,
      lines: [line],
      expenses: Money.zero(AppCurrency.iqd),
      invoiceDiscount: Money.zero(AppCurrency.iqd),
      paid: Money.fromMajor(-50, AppCurrency.iqd),
    );

    expect(invoice.total.toPlainString(), '-50');
    expect(invoice.paid, invoice.total);
  });

  test('invoice numbers remain reserved after permanent deletion', () async {
    final repositories = AppRepositories.demo();
    final sale = (await repositories.sales.getAll()).first;
    final purchase = (await repositories.purchases.getAll()).first;

    await repositories.sales.deleteInvoicePermanently(sale.id);
    await repositories.purchases.deleteInvoicePermanently(purchase.id);

    expect(await repositories.sales.nextDocumentNumber(), 104);
    expect(await repositories.purchases.nextDocumentNumber(), 104);
    expect(
      () => repositories.sales.createInvoice(
        _copySale(sale, id: EntityId.demo('sale', 99)),
      ),
      throwsStateError,
    );
    expect(
      () => repositories.purchases.createInvoice(
        _copyPurchase(purchase, id: EntityId.demo('purchase', 99)),
      ),
      throwsStateError,
    );
  });

  test('invoice repositories search resolved and historical labels', () async {
    final repositories = AppRepositories.demo();

    expect(
      (await repositories.sales.search('شركة النخيل')).single.documentNumber,
      101,
    );
    expect(
      (await repositories.sales.search('ورق تصوير A4'))
          .map((invoice) => invoice.documentNumber),
      contains(101),
    );
    expect(
      (await repositories.purchases.search('شركة التجارة العالمية'))
          .single
          .documentNumber,
      102,
    );
    expect(
      (await repositories.purchases.search('طابعة حرارية'))
          .map((invoice) => invoice.documentNumber),
      contains(102),
    );
  });

  test('invoice repository changes persist through shared handles', () async {
    final repositories = AppRepositories.demo();
    final salesHandle = repositories.sales;
    final purchaseHandle = repositories.purchases;
    final sale = (await salesHandle.getAll()).first;
    final purchase = (await purchaseHandle.getAll()).first;

    await salesHandle.replaceInvoice(_copySale(sale, notes: 'بيع محفوظ'));
    await purchaseHandle.replaceInvoice(
      _copyPurchase(purchase, notes: 'شراء محفوظ'),
    );

    expect((await repositories.sales.getById(sale.id))?.notes, 'بيع محفوظ');
    expect(
      (await repositories.purchases.getById(purchase.id))?.notes,
      'شراء محفوظ',
    );
  });

  test('invalid warehouse transfer leaves all balances unchanged', () async {
    final repositories = AppRepositories.demo();
    final warehouseId = EntityId('warehouse-001');
    final before = await repositories.warehouses.getInventory(warehouseId);

    expect(
      () => repositories.warehouses.transfer(
        InventoryTransferDraft(
          fromWarehouseId: warehouseId,
          toWarehouseId: EntityId('warehouse-002'),
          lines: [
            InventoryTransferLine(
              itemId: EntityId('item-001'),
              quantity: WholeQuantity(9999),
            ),
          ],
        ),
      ),
      throwsStateError,
    );
    final after = await repositories.warehouses.getInventory(warehouseId);
    expect(
      after.map((balance) => balance.quantity.value),
      before.map((balance) => balance.quantity.value),
    );
  });
}

SalesInvoice _copySale(
  SalesInvoice source, {
  EntityId? id,
  String? notes,
}) {
  return SalesInvoice(
    id: id ?? source.id,
    documentNumber: source.documentNumber,
    date: source.date,
    minuteOfDay: source.minuteOfDay,
    customerId: source.customerId,
    defaultWarehouseId: source.defaultWarehouseId,
    currency: source.currency,
    exchangeRate: source.exchangeRate,
    settlementKind: source.settlementKind,
    lines: source.lines,
    invoiceDiscount: source.invoiceDiscount,
    received: source.received,
    customerNameSnapshot: source.customerNameSnapshot,
    searchDetailsSnapshot: source.searchDetailsSnapshot,
    balanceAfterInvoice: source.balanceAfterInvoice,
    driverName: source.driverName,
    notes: notes ?? source.notes,
  );
}

PurchaseInvoice _copyPurchase(
  PurchaseInvoice source, {
  EntityId? id,
  String? notes,
}) {
  return PurchaseInvoice(
    id: id ?? source.id,
    documentNumber: source.documentNumber,
    date: source.date,
    minuteOfDay: source.minuteOfDay,
    supplierId: source.supplierId,
    defaultWarehouseId: source.defaultWarehouseId,
    currency: source.currency,
    exchangeRate: source.exchangeRate,
    purchaseKind: source.purchaseKind,
    settlementKind: source.settlementKind,
    lines: source.lines,
    expenses: source.expenses,
    invoiceDiscount: source.invoiceDiscount,
    paid: source.paid,
    supplierNameSnapshot: source.supplierNameSnapshot,
    searchDetailsSnapshot: source.searchDetailsSnapshot,
    balanceAfterInvoice: source.balanceAfterInvoice,
    notes: notes ?? source.notes,
  );
}
