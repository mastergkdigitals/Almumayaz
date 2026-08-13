import '../../features/cashbox/data/demo_cashbox_repository.dart';
import '../../features/cashbox/domain/cashbox_voucher.dart';
import '../../features/installments/application/installment_schedule_builder.dart';
import '../../features/installments/data/demo_installment_mutation_effects.dart';
import '../../features/installments/data/demo_installment_repository.dart';
import '../../features/installments/domain/installment_plan.dart';
import '../../features/parties/data/demo_party_repository.dart';
import '../../features/parties/domain/party.dart';
import '../../features/purchases/data/demo_purchase_mutation_effects.dart';
import '../../features/purchases/domain/purchase_invoice.dart';
import '../../features/sales/data/demo_sales_mutation_effects.dart';
import '../../features/sales/data/demo_sales_repository.dart';
import '../../features/sales/domain/sales_invoice.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/warehouses/data/demo_warehouse_repository.dart';
import '../../features/warehouses/data/demo_inventory_cost_repository.dart';
import '../data/demo_transaction_runner.dart';
import '../domain/business_values.dart';

/// Applies invoice, inventory, Cashbox, and Party demo projections atomically.
///
/// The Party adjustment remains the authoritative net invoice effect.
/// Source-linked Cashbox vouchers represent received/paid money but must not
/// be counted a second time by party statements.
class DemoInvoiceEffectsCoordinator
    implements
        DemoSalesMutationEffects,
        DemoPurchaseMutationEffects,
        DemoInstallmentMutationEffects {
  const DemoInvoiceEffectsCoordinator({
    required DemoTransactionRunner transactionRunner,
    required DemoPartyRepository parties,
    required DemoWarehouseRepository warehouses,
    required DemoCashboxRepository cashbox,
    required BusinessSettingsRepository businessSettings,
    required DemoInventoryCostRepository inventoryCosts,
    required DemoSalesRepository Function() sales,
    required DemoInstallmentRepository Function() installments,
  })  : _transactionRunner = transactionRunner,
        _parties = parties,
        _warehouses = warehouses,
        _cashbox = cashbox,
        _businessSettings = businessSettings,
        _inventoryCosts = inventoryCosts,
        _sales = sales,
        _installments = installments;

  final DemoTransactionRunner _transactionRunner;
  final DemoPartyRepository _parties;
  final DemoWarehouseRepository _warehouses;
  final DemoCashboxRepository _cashbox;
  final BusinessSettingsRepository _businessSettings;
  final DemoInventoryCostRepository _inventoryCosts;
  final DemoSalesRepository Function() _sales;
  final DemoInstallmentRepository Function() _installments;

  @override
  Future<SalesInvoice> applySale({
    required SalesInvoice candidate,
    required Future<SalesInvoice?> Function() preflightAndLoadPrevious,
    required void Function(SalesInvoice normalized) commit,
  }) {
    return _transactionRunner.run(() async {
      final previous = await preflightAndLoadPrevious();
      final installmentRepository = _installments();
      final previousPlan = installmentRepository.getDemoPlanForSalesInvoice(
        candidate.id,
      );
      final stagedInstallments = _stageInstallmentPlan(
        repository: installmentRepository,
        previous: previous,
        candidate: candidate,
        previousPlan: previousPlan,
      );
      final stagedCosts = _inventoryCosts.stageSale(
        _inventoryCosts.createSnapshot(),
        previous: previous,
        candidate: candidate,
      );
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
      final stagedCashbox = await _cashbox.stageInvoicePosting(
        _salesPosting(candidate),
      );
      final finalParty = stagedParties[candidate.customerId]!;
      final finalBalance = _partyBalance(finalParty, candidate.currency);
      final normalized = _salesWithBalance(candidate, finalBalance);

      commit(normalized);
      _warehouses.commitInventorySnapshot(stagedInventory);
      _cashbox.commitCashboxMutation(stagedCashbox);
      _parties.commitPartySnapshot(stagedParties);
      installmentRepository.commitInstallmentSnapshot(stagedInstallments);
      _inventoryCosts.commitSnapshot(stagedCosts);
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
      final installmentRepository = _installments();
      final previousPlan = installmentRepository.getDemoPlanForSalesInvoice(
        previous.id,
      );
      if (previous.settlementKind == SalesSettlementKind.installments &&
          previousPlan == null) {
        throw StateError('خطة الأقساط المرتبطة بقائمة البيع غير موجودة');
      }
      final stagedCosts = _inventoryCosts.stageSale(
        _inventoryCosts.createSnapshot(),
        previous: previous,
        candidate: null,
      );
      final stagedInventory = _warehouses.stageInventoryAdjustments(
        _salesInventoryAdjustments(previous, direction: -1),
        allowNegative: true,
      );
      final stagedParties = _parties.stageBalanceAdjustments([
        _salesPartyAdjustment(previous, direction: -1),
      ]);
      final stagedCashbox = _cashbox.stageRemoveSystemPostings(
        [
          _salesSource(previous),
          if (previousPlan != null)
            for (final entry in previousPlan.entries)
              _installmentSource(previousPlan, entry),
        ],
      );
      final stagedInstallments =
          installmentRepository.stageRemoveForSalesInvoice(previous.id);

      commit();
      _warehouses.commitInventorySnapshot(stagedInventory);
      _cashbox.commitCashboxMutation(stagedCashbox);
      _parties.commitPartySnapshot(stagedParties);
      installmentRepository.commitInstallmentSnapshot(stagedInstallments);
      _inventoryCosts.commitSnapshot(stagedCosts);
    });
  }

  @override
  Future<InstallmentPlan> settleInstallment({
    required EntityId entryId,
    required AuditTimestamp paidAt,
    required String notes,
    required Future<DemoInstallmentSettlement> Function()
        preflightAndBuildSettlement,
    required void Function(InstallmentPlan updated) commit,
  }) {
    return _transactionRunner.run(() async {
      final settlement = await preflightAndBuildSettlement();
      final invoice = settlement.salesInvoice;
      final plan = settlement.previous;
      final entry = settlement.paidEntry;
      if (plan.salesInvoiceId != invoice.id ||
          plan.customerId != invoice.customerId ||
          plan.currency != invoice.currency ||
          invoice.settlementKind != SalesSettlementKind.installments) {
        throw StateError('بيانات خطة الأقساط لا تطابق قائمة البيع');
      }
      final stagedParties = _parties.stageBalanceAdjustments([
        DemoPartyBalanceAdjustment(
          partyId: plan.customerId,
          delta: -entry.amount,
        ),
      ]);
      final finalParty = stagedParties[plan.customerId]!;
      final finalBalance = _partyBalance(finalParty, plan.currency);
      final stagedSales = _sales().stageInstallmentReceipt(
        salesInvoiceId: invoice.id,
        amount: entry.amount,
        paidAt: paidAt,
        balanceAfterPayment: finalBalance,
      );
      final stagedCashbox = await _cashbox.stageSystemPosting(
        DemoSystemCashboxPosting(
          source: _installmentSource(plan, entry),
          createdTimestamp: paidAt,
          type: CashboxVoucherType.receipt,
          exchangeRate: invoice.exchangeRate,
          amount: entry.amount,
          notes: notes.isEmpty
              ? 'تسديد القسط رقم ${entry.number} من قائمة بيع رقم '
                  '${invoice.documentNumber}'
              : notes,
        ),
      );

      commit(settlement.updated);
      _sales().commitSalesMutation(stagedSales);
      _cashbox.commitCashboxMutation(stagedCashbox);
      _parties.commitPartySnapshot(stagedParties);
      return settlement.updated;
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
      final stagedCosts = _inventoryCosts.stagePurchase(
        _inventoryCosts.createSnapshot(),
        previous: previous,
        candidate: candidate,
      );
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
      final stagedCashbox = await _cashbox.stageInvoicePosting(
        _purchasePosting(candidate),
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
      _cashbox.commitCashboxMutation(stagedCashbox);
      _parties.commitPartySnapshot(stagedParties);
      _inventoryCosts.commitSnapshot(stagedCosts);
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
      final stagedCosts = _inventoryCosts.stagePurchase(
        _inventoryCosts.createSnapshot(),
        previous: previous,
        candidate: null,
      );
      final stagedInventory = _warehouses.stageInventoryAdjustments(
        _purchaseInventoryAdjustments(previous, direction: -1),
        allowNegative: false,
      );
      final stagedParties = _parties.stageBalanceAdjustments([
        _purchasePartyAdjustment(previous, direction: -1),
      ]);
      final stagedCashbox = _cashbox.stageRemoveInvoicePosting(
        _purchaseSource(previous),
      );

      commit();
      _warehouses.commitInventorySnapshot(stagedInventory);
      _cashbox.commitCashboxMutation(stagedCashbox);
      _parties.commitPartySnapshot(stagedParties);
      _inventoryCosts.commitSnapshot(stagedCosts);
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

  DemoInvoiceCashboxPosting _salesPosting(SalesInvoice invoice) {
    return DemoInvoiceCashboxPosting(
      source: _salesSource(invoice),
      createdTimestamp: _invoiceTimestamp(invoice.date, invoice.minuteOfDay),
      type: CashboxVoucherType.receipt,
      exchangeRate: invoice.exchangeRate,
      amount: invoice.receivedAtSale,
      notes: 'قيد آلي لفاتورة بيع رقم ${invoice.documentNumber}',
    );
  }

  CashboxVoucherSource _salesSource(SalesInvoice invoice) {
    return CashboxVoucherSource(
      kind: CashboxVoucherSourceKind.salesInvoice,
      sourceId: invoice.id,
      partyId: invoice.customerId,
    );
  }

  CashboxVoucherSource _installmentSource(
    InstallmentPlan plan,
    InstallmentEntry entry,
  ) {
    return CashboxVoucherSource(
      kind: CashboxVoucherSourceKind.installmentPayment,
      sourceId: entry.id,
      partyId: plan.customerId,
    );
  }

  Map<EntityId, InstallmentPlan> _stageInstallmentPlan({
    required DemoInstallmentRepository repository,
    required SalesInvoice? previous,
    required SalesInvoice candidate,
    required InstallmentPlan? previousPlan,
  }) {
    if (previous == null && previousPlan != null) {
      throw StateError('توجد خطة أقساط بلا قائمة بيع مرتبطة');
    }
    if (previous?.settlementKind == SalesSettlementKind.installments &&
        previousPlan == null) {
      throw StateError('خطة الأقساط المرتبطة بقائمة البيع غير موجودة');
    }
    if (candidate.settlementKind != SalesSettlementKind.installments) {
      if (previousPlan?.hasPaidEntries ?? false) {
        throw StateError('لا يمكن تغيير نوع قائمة بيع بعد تسديد قسط منها');
      }
      return repository.stageRemoveForSalesInvoice(candidate.id);
    }
    if (previousPlan?.hasPaidEntries ?? false) {
      _validatePaidPlanUpdate(
        previous: previous!,
        candidate: candidate,
        plan: previousPlan!,
      );
      return repository.stageUpsertPlan(previousPlan);
    }
    if (!candidate.installmentReceived.isZero) {
      throw StateError('إجمالي الأقساط المسددة لا يطابق خطة الأقساط');
    }
    final remaining = candidate.total - candidate.receivedAtSale;
    if (!remaining.isPositive) {
      throw StateError('يجب أن تحتوي قائمة الأقساط على مبلغ متبقٍ');
    }
    final planId = previousPlan?.id ??
        EntityId('installment-plan-${candidate.id.value}');
    final rebuilt = InstallmentScheduleBuilder.build(
      planId: planId,
      salesInvoiceId: candidate.id,
      customerId: candidate.customerId,
      remaining: remaining,
      invoiceDate: candidate.date,
    );
    return repository.stageUpsertPlan(rebuilt);
  }

  void _validatePaidPlanUpdate({
    required SalesInvoice previous,
    required SalesInvoice candidate,
    required InstallmentPlan plan,
  }) {
    final changesTerms = candidate.customerId != previous.customerId ||
        candidate.currency != previous.currency ||
        candidate.exchangeRate != previous.exchangeRate ||
        candidate.date != previous.date ||
        candidate.settlementKind != SalesSettlementKind.installments ||
        candidate.total != previous.total ||
        candidate.receivedAtSale != previous.receivedAtSale ||
        candidate.installmentReceived != previous.installmentReceived;
    final planMismatch = plan.customerId != candidate.customerId ||
        plan.currency != candidate.currency ||
        plan.paid != candidate.installmentReceived;
    if (changesTerms || planMismatch) {
      throw StateError(
        'لا يمكن تغيير بيانات الاستحقاق بعد تسديد قسط من القائمة',
      );
    }
  }

  DemoInvoiceCashboxPosting _purchasePosting(PurchaseInvoice invoice) {
    return DemoInvoiceCashboxPosting(
      source: _purchaseSource(invoice),
      createdTimestamp: _invoiceTimestamp(invoice.date, invoice.minuteOfDay),
      type: invoice.purchaseKind ==
              PurchaseTransactionKind.returnPurchase
          ? CashboxVoucherType.receipt
          : CashboxVoucherType.payment,
      exchangeRate: invoice.exchangeRate,
      amount: invoice.paid,
      notes: 'قيد آلي لفاتورة شراء رقم ${invoice.documentNumber}',
    );
  }

  CashboxVoucherSource _purchaseSource(PurchaseInvoice invoice) {
    return CashboxVoucherSource(
      kind: CashboxVoucherSourceKind.purchaseInvoice,
      sourceId: invoice.id,
      partyId: invoice.supplierId,
    );
  }

  Money _partyBalance(Party party, AppCurrency currency) {
    return currency == AppCurrency.iqd
        ? party.iqdBalance
        : party.usdBalance;
  }
}

AuditTimestamp _invoiceTimestamp(BusinessDate date, int minuteOfDay) {
  return AuditTimestamp(
    date.atTime(
      hour: minuteOfDay ~/ Duration.minutesPerHour,
      minute: minuteOfDay % Duration.minutesPerHour,
    ),
  );
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
    receivedAtSale: source.receivedAtSale,
    installmentReceived: source.installmentReceived,
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
