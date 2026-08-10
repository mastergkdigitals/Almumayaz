import '../../features/parties/data/demo_party_repository.dart';
import '../../features/parties/domain/party.dart';
import '../../features/purchases/data/demo_purchase_mutation_effects.dart';
import '../../features/purchases/domain/purchase_invoice.dart';
import '../../features/sales/data/demo_sales_mutation_effects.dart';
import '../../features/sales/domain/sales_invoice.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/warehouses/data/demo_warehouse_repository.dart';
import '../data/demo_transaction_runner.dart';
import '../domain/business_values.dart';

/// Applies the cross-feature projections of demo invoices atomically.
///
/// Cashbox posting deliberately remains outside this coordinator. Invoice
/// received/paid amounts are already represented by statement movements, and
/// the current cashbox model has no immutable source-document identity with
/// which to prevent a duplicate posting.
class DemoInvoiceEffectsCoordinator
    implements DemoSalesMutationEffects, DemoPurchaseMutationEffects {
  const DemoInvoiceEffectsCoordinator({
    required DemoTransactionRunner transactionRunner,
    required DemoPartyRepository parties,
    required DemoWarehouseRepository warehouses,
    required BusinessSettingsRepository businessSettings,
  })  : _transactionRunner = transactionRunner,
        _parties = parties,
        _warehouses = warehouses,
        _businessSettings = businessSettings;

  final DemoTransactionRunner _transactionRunner;
  final DemoPartyRepository _parties;
  final DemoWarehouseRepository _warehouses;
  final BusinessSettingsRepository _businessSettings;

  @override
  Future<SalesInvoice> applySale({
    required SalesInvoice candidate,
    required Future<SalesInvoice?> Function() preflightAndLoadPrevious,
    required void Function(SalesInvoice normalized) commit,
  }) {
    return _transactionRunner.run(() async {
      final previous = await preflightAndLoadPrevious();
      final inventoryAdjustments = <DemoInventoryAdjustment>[
        if (previous != null)
          ..._salesInventoryAdjustments(previous, direction: -1),
        ..._salesInventoryAdjustments(candidate, direction: 1),
      ];
      final partyAdjustments = <DemoPartyBalanceAdjustment>[
        if (previous != null)
          _salesPartyAdjustment(previous, direction: -1),
        _salesPartyAdjustment(candidate, direction: 1),
      ];
      final policies = await _businessSettings.loadBusinessPolicies();
      final stagedInventory = _warehouses.stageInventoryAdjustments(
        inventoryAdjustments,
        allowNegative: policies.allowSaleWithInsufficientStock,
      );
      final stagedParties = _parties.stageBalanceAdjustments(
        partyAdjustments,
      );
      final finalParty = stagedParties[candidate.customerId]!;
      final finalBalance = _partyBalance(finalParty, candidate.currency);
      final normalized = _salesWithBalance(candidate, finalBalance);

      commit(normalized);
      _warehouses.commitInventorySnapshot(stagedInventory);
      _parties.commitPartySnapshot(stagedParties);
      return normalized;
    });
  }

  @override
  Future<void> deleteSale({
    required EntityId id,
    required Future<SalesInvoice> Function() preflightAndLoadPrevious,
    required void Function() commit,
  }) {
    return _transactionRunner.run(() async {
      final previous = await preflightAndLoadPrevious();
      final stagedInventory = _warehouses.stageInventoryAdjustments(
        _salesInventoryAdjustments(previous, direction: -1),
        allowNegative: true,
      );
      final stagedParties = _parties.stageBalanceAdjustments([
        _salesPartyAdjustment(previous, direction: -1),
      ]);

      commit();
      _warehouses.commitInventorySnapshot(stagedInventory);
      _parties.commitPartySnapshot(stagedParties);
    });
  }

  @override
  Future<PurchaseInvoice> applyPurchase({
    required PurchaseInvoice candidate,
    required Future<PurchaseInvoice?> Function() preflightAndLoadPrevious,
    required void Function(PurchaseInvoice normalized) commit,
  }) {
    return _transactionRunner.run(() async {
      final previous = await preflightAndLoadPrevious();
      final inventoryAdjustments = <DemoInventoryAdjustment>[
        if (previous != null)
          ..._purchaseInventoryAdjustments(previous, direction: -1),
        ..._purchaseInventoryAdjustments(candidate, direction: 1),
      ];
      final partyAdjustments = <DemoPartyBalanceAdjustment>[
        if (previous != null)
          _purchasePartyAdjustment(previous, direction: -1),
        _purchasePartyAdjustment(candidate, direction: 1),
      ];
      final stagedInventory = _warehouses.stageInventoryAdjustments(
        inventoryAdjustments,
        allowNegative: false,
      );
      final stagedParties = _parties.stageBalanceAdjustments(
        partyAdjustments,
      );
      final finalParty = stagedParties[candidate.supplierId]!;
      final signedBalance = _partyBalance(finalParty, candidate.currency);

      // Purchase screens display the payable magnitude while Party remains
      // the authoritative signed projection (supplier credit is negative).
      final normalized = _purchaseWithBalance(
        candidate,
        signedBalance.absolute,
      );

      commit(normalized);
      _warehouses.commitInventorySnapshot(stagedInventory);
      _parties.commitPartySnapshot(stagedParties);
      return normalized;
    });
  }

  @override
  Future<void> deletePurchase({
    required EntityId id,
    required Future<PurchaseInvoice> Function() preflightAndLoadPrevious,
    required void Function() commit,
  }) {
    return _transactionRunner.run(() async {
      final previous = await preflightAndLoadPrevious();
      final stagedInventory = _warehouses.stageInventoryAdjustments(
        _purchaseInventoryAdjustments(previous, direction: -1),
        allowNegative: false,
      );
      final stagedParties = _parties.stageBalanceAdjustments([
        _purchasePartyAdjustment(previous, direction: -1),
      ]);

      commit();
      _warehouses.commitInventorySnapshot(stagedInventory);
      _parties.commitPartySnapshot(stagedParties);
    });
  }

  Iterable<DemoInventoryAdjustment> _salesInventoryAdjustments(
    SalesInvoice invoice, {
    required int direction,
  }) sync* {
    for (final line in invoice.lines) {
      yield DemoInventoryAdjustment(
        warehouseId: line.warehouseId,
        itemId: line.itemId,
        quantityDelta: -line.quantity.value * direction,
      );
    }
  }

  DemoPartyBalanceAdjustment _salesPartyAdjustment(
    SalesInvoice invoice, {
    required int direction,
  }) {
    final remaining = invoice.total - invoice.received;
    return DemoPartyBalanceAdjustment(
      partyId: invoice.customerId,
      delta: remaining * direction,
    );
  }

  Iterable<DemoInventoryAdjustment> _purchaseInventoryAdjustments(
    PurchaseInvoice invoice, {
    required int direction,
  }) sync* {
    final purchaseDirection =
        invoice.purchaseKind == PurchaseTransactionKind.returnPurchase
            ? -1
            : 1;
    for (final line in invoice.lines) {
      yield DemoInventoryAdjustment(
        warehouseId: line.warehouseId,
        itemId: line.itemId,
        quantityDelta:
            line.quantity.value * purchaseDirection * direction,
      );
    }
  }

  DemoPartyBalanceAdjustment _purchasePartyAdjustment(
    PurchaseInvoice invoice, {
    required int direction,
  }) {
    final purchaseDirection =
        invoice.purchaseKind == PurchaseTransactionKind.returnPurchase
            ? -1
            : 1;
    final remaining = invoice.total - invoice.paid;
    return DemoPartyBalanceAdjustment(
      partyId: invoice.supplierId,
      delta: remaining * (-purchaseDirection * direction),
    );
  }

  Money _partyBalance(Party party, AppCurrency currency) {
    return currency == AppCurrency.iqd
        ? party.iqdBalance
        : party.usdBalance;
  }
}

SalesInvoice _salesWithBalance(SalesInvoice source, Money balance) {
  return SalesInvoice(
    id: source.id,
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
    balanceAfterInvoice: balance,
    driverName: source.driverName,
    notes: source.notes,
  );
}

PurchaseInvoice _purchaseWithBalance(PurchaseInvoice source, Money balance) {
  return PurchaseInvoice(
    id: source.id,
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
    balanceAfterInvoice: balance,
    notes: source.notes,
  );
}
