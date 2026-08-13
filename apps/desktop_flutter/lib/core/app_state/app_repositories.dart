import '../../features/cashbox/data/demo_cashbox_repository.dart';
import '../../features/cashbox/domain/cashbox_repository.dart';
import '../../features/cashbox/domain/cashbox_voucher.dart';
import '../../features/items/data/demo_item_repository.dart';
import '../../features/items/domain/item_repository.dart';
import '../../features/installments/application/installment_schedule_builder.dart';
import '../../features/installments/data/demo_installment_repository.dart';
import '../../features/installments/domain/installment_plan.dart';
import '../../features/installments/domain/installment_repository.dart';
import '../../features/parties/data/demo_party_repository.dart';
import '../../features/parties/domain/party_repository.dart';
import '../../features/purchases/data/demo_purchase_repository.dart';
import '../../features/purchases/domain/purchase_invoice.dart';
import '../../features/purchases/domain/purchase_repository.dart';
import '../../features/sales/data/demo_sales_repository.dart';
import '../../features/sales/domain/sales_invoice.dart';
import '../../features/sales/domain/sales_repository.dart';
import '../../features/settings/data/demo_operational_settings_repositories.dart';
import '../../features/settings/domain/operational_master_data.dart';
import '../../features/settings/domain/operational_master_data_repository.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/warehouses/data/demo_warehouse_repository.dart';
import '../../features/warehouses/data/demo_inventory_cost_repository.dart';
import '../../features/warehouses/domain/inventory_cost_repository.dart';
import '../../features/warehouses/domain/warehouse_repository.dart';
import '../data/demo_transaction_runner.dart';
import '../domain/business_values.dart';
import 'demo_invoice_effects_coordinator.dart';

/// One composition root for every repository used by the desktop app.
///
/// A single instance is kept above the navigator by the app-store provider, so
/// demo changes survive closing and reopening a feature screen. API-backed
/// adapters can later replace individual fields without changing widgets.
class AppRepositories {
  const AppRepositories({
    required this.parties,
    required this.items,
    required this.warehouses,
    required this.inventoryCosts,
    required this.cashbox,
    required this.sales,
    required this.purchases,
    required this.installments,
    required this.businessSettings,
    required this.deviceSettings,
    required this.operationalMasterData,
  });

  factory AppRepositories.demo() {
    final transactionRunner = DemoTransactionRunner();
    late DemoOperationalMasterDataRepository masterData;
    late DemoPartyRepository parties;
    late DemoItemRepository items;
    late DemoWarehouseRepository warehouses;
    late DemoInventoryCostRepository inventoryCosts;
    late DemoCashboxRepository cashbox;
    late DemoSalesRepository sales;
    late DemoPurchaseRepository purchases;
    late DemoInstallmentRepository installments;
    late DemoBusinessSettingsRepository businessSettings;
    final seededSales = demoSalesInvoices();
    final seededPurchases = demoPurchaseInvoices();
    final seededTransfers = demoInventoryTransfers();
    final seededManualCashbox = demoCashboxVouchers();

    masterData = DemoOperationalMasterDataRepository(
      transactionRunner: transactionRunner,
      isExternallyReferenced: (id) async {
        final record = await masterData.getById(id);
        if (record == null) return false;
        switch (record.kind) {
          case OperationalMasterDataKind.itemGroup:
            return (await items.getAll()).any(
              (item) => item.groupId == id.value,
            );
          case OperationalMasterDataKind.itemType:
            return (await items.getAll()).any(
              (item) => item.typeId == id.value,
            );
          case OperationalMasterDataKind.workplace:
          case OperationalMasterDataKind.branch:
            return parties.referencesMasterData(id);
          case OperationalMasterDataKind.cashboxMainAccount:
          case OperationalMasterDataKind.cashboxSubaccount:
            if (await cashbox.referencesMasterData(id)) return true;
            if (record.kind ==
                OperationalMasterDataKind.cashboxMainAccount) {
              final defaults =
                  await businessSettings.loadOperationalDefaults();
              return defaults.cashbox.mainAccountId == id;
            }
            return false;
        }
      },
    );

    parties = DemoPartyRepository(
      masterData: masterData,
      transactionRunner: transactionRunner,
      isReferenced: (partyId) async {
        if ((await sales.getAll()).any(
          (invoice) => invoice.customerId == partyId,
        )) {
          return true;
        }
        if ((await purchases.getAll()).any(
          (invoice) => invoice.supplierId == partyId,
        )) {
          return true;
        }
        return cashbox.referencesParty(partyId);
      },
    );

    items = DemoItemRepository(
      masterData: masterData,
      transactionRunner: transactionRunner,
      isReferenced: (itemId) async {
        if ((await sales.getAll()).any(
          (invoice) => invoice.lines.any((line) => line.itemId == itemId),
        )) {
          return true;
        }
        if ((await purchases.getAll()).any(
          (invoice) => invoice.lines.any((line) => line.itemId == itemId),
        )) {
          return true;
        }
        return warehouses.referencesItem(itemId);
      },
    );

    inventoryCosts = DemoInventoryCostRepository(
      purchases: seededPurchases,
      sales: seededSales,
      transfers: seededTransfers,
    );
    warehouses = DemoWarehouseRepository(
      initialTransfers: seededTransfers,
      transactionRunner: transactionRunner,
      inventoryCostEffects: inventoryCosts,
      itemExists: (itemId) async => await items.getById(itemId) != null,
      isExternallyReferenced: (warehouseId) async {
        return (await sales.getAll()).any(
              (invoice) =>
                  invoice.defaultWarehouseId == warehouseId ||
                  invoice.lines.any(
                    (line) => line.warehouseId == warehouseId,
                  ),
            ) ||
            (await purchases.getAll()).any(
              (invoice) =>
                  invoice.defaultWarehouseId == warehouseId ||
                  invoice.lines.any(
                    (line) => line.warehouseId == warehouseId,
                  ),
            ) ||
            (await businessSettings.loadOperationalDefaults())
                    .purchases
                    .warehouseId ==
                warehouseId ||
            (await businessSettings.loadOperationalDefaults())
                    .sales
                    .warehouseId ==
                warehouseId;
      },
    );
    cashbox = DemoCashboxRepository(
      initialValues: [
        ...seededManualCashbox,
        ..._demoInvoiceCashboxPostings(
          sales: seededSales,
          purchases: seededPurchases,
          existingVouchers: seededManualCashbox,
          firstNumber: _highestCashboxNumber(seededManualCashbox) + 1,
        ),
      ],
      masterData: masterData,
      parties: parties,
      transactionRunner: transactionRunner,
    );

    Future<bool> partyExists(EntityId id) async =>
        await parties.getById(id) != null;
    Future<bool> itemExists(EntityId id) async =>
        await items.getById(id) != null;
    Future<bool> warehouseExists(EntityId id) async =>
        await warehouses.getById(id) != null;

    businessSettings = DemoBusinessSettingsRepository(
      warehouseExists: warehouseExists,
      cashboxMainAccountExists: (id) async => (await cashbox.getMainAccounts())
          .any((account) => account.entityId == id),
    );

    final invoiceEffects = DemoInvoiceEffectsCoordinator(
      transactionRunner: transactionRunner,
      parties: parties,
      warehouses: warehouses,
      cashbox: cashbox,
      businessSettings: businessSettings,
      inventoryCosts: inventoryCosts,
      sales: () => sales,
      installments: () => installments,
    );

    sales = DemoSalesRepository(
      initialValues: seededSales,
      partyExists: partyExists,
      itemExists: itemExists,
      warehouseExists: warehouseExists,
      mutationEffects: invoiceEffects,
      partyLabelOf: (id) async => (await parties.getById(id))?.name,
      itemLabelOf: (id) async => (await items.getById(id))?.name,
    );
    purchases = DemoPurchaseRepository(
      initialValues: seededPurchases,
      partyExists: partyExists,
      itemExists: itemExists,
      warehouseExists: warehouseExists,
      mutationEffects: invoiceEffects,
      partyLabelOf: (id) async => (await parties.getById(id))?.name,
      itemLabelOf: (id) async => (await items.getById(id))?.name,
    );
    installments = DemoInstallmentRepository(
      initialValues: _demoInstallmentPlans(seededSales),
      mutationEffects: invoiceEffects,
      salesInvoiceLoader: sales.getById,
    );

    return AppRepositories(
      parties: parties,
      items: items,
      warehouses: warehouses,
      inventoryCosts: inventoryCosts,
      cashbox: cashbox,
      sales: sales,
      purchases: purchases,
      installments: installments,
      businessSettings: businessSettings,
      deviceSettings: DemoDeviceSettingsRepository(),
      operationalMasterData: masterData,
    );
  }

  final PartyRepository parties;
  final ItemRepository items;
  final WarehouseRepository warehouses;
  final InventoryCostRepository inventoryCosts;
  final CashboxRepository cashbox;
  final SalesRepository sales;
  final PurchaseRepository purchases;
  final InstallmentRepository installments;
  final BusinessSettingsRepository businessSettings;
  final DeviceSettingsRepository deviceSettings;
  final OperationalMasterDataRepository operationalMasterData;
}

List<InstallmentPlan> _demoInstallmentPlans(
  Iterable<SalesInvoice> invoices,
) {
  return List.unmodifiable([
    for (final invoice in invoices)
      if (invoice.settlementKind == SalesSettlementKind.installments)
        InstallmentScheduleBuilder.build(
          planId: EntityId('installment-plan-${invoice.id.value}'),
          salesInvoiceId: invoice.id,
          customerId: invoice.customerId,
          remaining: invoice.total - invoice.receivedAtSale,
          invoiceDate: invoice.date,
        ),
  ]);
}

List<CashboxVoucher> _demoInvoiceCashboxPostings({
  required Iterable<SalesInvoice> sales,
  required Iterable<PurchaseInvoice> purchases,
  required Iterable<CashboxVoucher> existingVouchers,
  required int firstNumber,
}) {
  final postings = <_SeededInvoicePosting>[
    for (final invoice in sales)
      if (!invoice.receivedAtSale.isZero)
        _SeededInvoicePosting(
          source: CashboxVoucherSource(
            kind: CashboxVoucherSourceKind.salesInvoice,
            sourceId: invoice.id,
            partyId: invoice.customerId,
          ),
          createdTimestamp: _invoiceTimestamp(
            invoice.date,
            invoice.minuteOfDay,
          ),
          type: CashboxVoucherType.receipt,
          exchangeRate: invoice.exchangeRate,
          amount: invoice.receivedAtSale,
          notes: 'قيد آلي لفاتورة بيع رقم ${invoice.documentNumber}',
        ),
    for (final invoice in purchases)
      if (!invoice.paid.isZero)
        _SeededInvoicePosting(
          source: CashboxVoucherSource(
            kind: CashboxVoucherSourceKind.purchaseInvoice,
            sourceId: invoice.id,
            partyId: invoice.supplierId,
          ),
          createdTimestamp: _invoiceTimestamp(
            invoice.date,
            invoice.minuteOfDay,
          ),
          type: invoice.purchaseKind ==
                  PurchaseTransactionKind.returnPurchase
              ? CashboxVoucherType.receipt
              : CashboxVoucherType.payment,
          exchangeRate: invoice.exchangeRate,
          amount: invoice.paid,
          notes: 'قيد آلي لفاتورة شراء رقم ${invoice.documentNumber}',
        ),
  ]
    ..sort((first, second) {
      final byTimestamp = first.createdTimestamp.compareTo(
        second.createdTimestamp,
      );
      return byTimestamp != 0
          ? byTimestamp
          : first.source.sourceId.value.compareTo(
              second.source.sourceId.value,
            );
    });
  final chronologicalExisting = [...existingVouchers]
    ..sort((first, second) {
      final byTimestamp = first.createdTimestamp.compareTo(
        second.createdTimestamp,
      );
      return byTimestamp != 0
          ? byTimestamp
          : first.number.compareTo(second.number);
    });
  final balances = <EntityId, ({Money iqd, Money usd})>{};
  for (final voucher in chronologicalExisting) {
    balances[voucher.subaccountEntityId] = (
      iqd: voucher.iqdBalanceAfter,
      usd: voucher.usdBalanceAfter,
    );
  }
  final result = <CashboxVoucher>[];
  for (var index = 0; index < postings.length; index++) {
    final posting = postings[index];
    final account = _seededPostingAccount();
    final zeroIqd = Money.zero(AppCurrency.iqd);
    final zeroUsd = Money.zero(AppCurrency.usd);
    final before = balances[account.subaccountId] ??
        (iqd: zeroIqd, usd: zeroUsd);
    final iqdAmount = posting.amount.currency == AppCurrency.iqd
        ? posting.amount
        : zeroIqd;
    final usdAmount = posting.amount.currency == AppCurrency.usd
        ? posting.amount
        : zeroUsd;
    final direction = posting.type == CashboxVoucherType.receipt ? -1 : 1;
    final nextIqdBalance = before.iqd + iqdAmount * direction;
    final nextUsdBalance = before.usd + usdAmount * direction;
    result.add(
      CashboxVoucher.typed(
        entityId: EntityId(
          'cashbox-system-${posting.source.kind.name}-'
          '${posting.source.sourceId.value}',
        ),
        number: firstNumber + index,
        createdTimestamp: posting.createdTimestamp,
        type: posting.type,
        mainAccountEntityId: account.mainAccountId,
        mainAccountLabel: account.mainAccountLabel,
        subaccountEntityId: account.subaccountId,
        subaccountLabel: account.subaccountLabel,
        exchangeRateValue: posting.exchangeRate,
        iqdAmount: iqdAmount,
        usdAmount: usdAmount,
        iqdBalanceBefore: before.iqd,
        iqdBalanceAfter: nextIqdBalance,
        usdBalanceBefore: before.usd,
        usdBalanceAfter: nextUsdBalance,
        notes: posting.notes,
        source: posting.source,
      ),
    );
    balances[account.subaccountId] = (
      iqd: nextIqdBalance,
      usd: nextUsdBalance,
    );
  }
  return List.unmodifiable(result);
}

_SeededCashboxAccount _seededPostingAccount() {
  return _SeededCashboxAccount(
    mainAccountId: EntityId.demo('cashbox-main-account', 1),
    mainAccountLabel: 'الصندوق الرئيسي',
    subaccountId: EntityId.demo('cashbox-subaccount', 1),
    subaccountLabel: '1 - النقدية اليومية',
  );
}

int _highestCashboxNumber(Iterable<CashboxVoucher> vouchers) {
  var highest = 0;
  for (final voucher in vouchers) {
    if (voucher.number > highest) highest = voucher.number;
  }
  return highest;
}

AuditTimestamp _invoiceTimestamp(BusinessDate date, int minuteOfDay) {
  return AuditTimestamp(
    date.atTime(
      hour: minuteOfDay ~/ Duration.minutesPerHour,
      minute: minuteOfDay % Duration.minutesPerHour,
    ),
  );
}

class _SeededInvoicePosting {
  const _SeededInvoicePosting({
    required this.source,
    required this.createdTimestamp,
    required this.type,
    required this.exchangeRate,
    required this.amount,
    required this.notes,
  });

  final CashboxVoucherSource source;
  final AuditTimestamp createdTimestamp;
  final CashboxVoucherType type;
  final ExchangeRate exchangeRate;
  final Money amount;
  final String notes;
}

class _SeededCashboxAccount {
  const _SeededCashboxAccount({
    required this.mainAccountId,
    required this.mainAccountLabel,
    required this.subaccountId,
    required this.subaccountLabel,
  });

  final EntityId mainAccountId;
  final String mainAccountLabel;
  final EntityId subaccountId;
  final String subaccountLabel;
}
