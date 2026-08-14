import '../../../core/domain/business_values.dart';
import '../../../core/domain/invoice_value_allocator.dart';
import '../../purchases/domain/purchase_invoice.dart';
import '../../sales/domain/sales_invoice.dart';
import '../../sales_returns/domain/sales_return.dart';
import '../domain/inventory_cost.dart';
import '../domain/inventory_cost_repository.dart';
import '../domain/inventory_records.dart';

/// Transfer-facing boundary used by the demo warehouse repository.
///
/// Staging performs the complete replay and can fail before warehouse state is
/// mutated. Committing only replaces already validated in-memory snapshots.
abstract interface class DemoInventoryCostTransferEffects {
  DemoInventoryCostSnapshot stageTransferCost(InventoryTransfer transfer);

  void commitCostSnapshot(DemoInventoryCostSnapshot snapshot);
}

/// Isolated, replayed state used as the no-fail commit payload of a demo
/// transaction. Public lists are immutable views intended for focused tests.
class DemoInventoryCostSnapshot {
  DemoInventoryCostSnapshot._({
    required Map<EntityId, PurchaseInvoice> purchases,
    required Map<EntityId, SalesInvoice> sales,
    required Map<EntityId, SalesReturn> salesReturns,
    required Map<EntityId, InventoryTransfer> transfers,
    required Map<_InventoryCostKey, InventoryCostBalance> balances,
    required Map<EntityId, SalesLineCostRecord> salesLineCosts,
    required Map<EntityId, SalesReturnLineCostRecord> salesReturnLineCosts,
  })  : _purchases = Map.unmodifiable(purchases),
        _sales = Map.unmodifiable(sales),
        _salesReturns = Map.unmodifiable(salesReturns),
        _transfers = Map.unmodifiable(transfers),
        _balances = Map.unmodifiable(balances),
        _salesLineCosts = Map.unmodifiable(salesLineCosts),
        _salesReturnLineCosts = Map.unmodifiable(salesReturnLineCosts);

  final Map<EntityId, PurchaseInvoice> _purchases;
  final Map<EntityId, SalesInvoice> _sales;
  final Map<EntityId, SalesReturn> _salesReturns;
  final Map<EntityId, InventoryTransfer> _transfers;
  final Map<_InventoryCostKey, InventoryCostBalance> _balances;
  final Map<EntityId, SalesLineCostRecord> _salesLineCosts;
  final Map<EntityId, SalesReturnLineCostRecord> _salesReturnLineCosts;

  List<InventoryCostBalance> get balances =>
      List.unmodifiable(_balances.values);

  List<SalesLineCostRecord> get salesLineCosts =>
      List.unmodifiable(_salesLineCosts.values);

  List<SalesReturnLineCostRecord> get salesReturnLineCosts =>
      List.unmodifiable(_salesReturnLineCosts.values);
}

/// Demo perpetual moving-average ledger, maintained per warehouse and item.
///
/// Every staged mutation rebuilds from explicit opening balances and immutable
/// source documents. This is intentionally O(demo records): replacing or
/// deleting a backdated document restates every downstream cost
/// deterministically instead of attempting a mathematically incorrect local
/// inverse.
class DemoInventoryCostRepository
    implements InventoryCostRepository, DemoInventoryCostTransferEffects {
  DemoInventoryCostRepository({
    Iterable<InventoryCostBalance>? openingBalances,
    Iterable<PurchaseInvoice> purchases = const [],
    Iterable<SalesInvoice> sales = const [],
    Iterable<SalesReturn> salesReturns = const [],
    Iterable<InventoryTransfer> transfers = const [],
  })  : _openingBalances = List.unmodifiable(
          openingBalances ?? demoInventoryCostOpeningBalances(),
        ),
        _purchases = {for (final invoice in purchases) invoice.id: invoice},
        _sales = {for (final invoice in sales) invoice.id: invoice},
        _salesReturns = {
          for (final salesReturn in salesReturns) salesReturn.id: salesReturn,
        },
        _transfers = {for (final transfer in transfers) transfer.id: transfer} {
    final initial = _replay(
      purchases: _purchases,
      sales: _sales,
      salesReturns: _salesReturns,
      transfers: _transfers,
    );
    _balances = Map.of(initial._balances);
    _salesLineCosts = Map.of(initial._salesLineCosts);
    _salesReturnLineCosts = Map.of(initial._salesReturnLineCosts);
  }

  final List<InventoryCostBalance> _openingBalances;
  Map<EntityId, PurchaseInvoice> _purchases;
  Map<EntityId, SalesInvoice> _sales;
  Map<EntityId, SalesReturn> _salesReturns;
  Map<EntityId, InventoryTransfer> _transfers;
  late Map<_InventoryCostKey, InventoryCostBalance> _balances;
  late Map<EntityId, SalesLineCostRecord> _salesLineCosts;
  late Map<EntityId, SalesReturnLineCostRecord> _salesReturnLineCosts;

  DemoInventoryCostSnapshot createSnapshot() => DemoInventoryCostSnapshot._(
        purchases: _purchases,
        sales: _sales,
        salesReturns: _salesReturns,
        transfers: _transfers,
        balances: _balances,
        salesLineCosts: _salesLineCosts,
        salesReturnLineCosts: _salesReturnLineCosts,
      );

  DemoInventoryCostSnapshot stagePurchase(
    DemoInventoryCostSnapshot snapshot, {
    required PurchaseInvoice? previous,
    required PurchaseInvoice? candidate,
  }) {
    final purchases = Map<EntityId, PurchaseInvoice>.of(snapshot._purchases);
    if (previous != null) purchases.remove(previous.id);
    if (candidate != null) purchases[candidate.id] = candidate;
    return _replay(
      purchases: purchases,
      sales: snapshot._sales,
      salesReturns: snapshot._salesReturns,
      transfers: snapshot._transfers,
    );
  }

  DemoInventoryCostSnapshot stageSale(
    DemoInventoryCostSnapshot snapshot, {
    required SalesInvoice? previous,
    required SalesInvoice? candidate,
  }) {
    final sales = Map<EntityId, SalesInvoice>.of(snapshot._sales);
    if (previous != null) sales.remove(previous.id);
    if (candidate != null) sales[candidate.id] = candidate;
    return _replay(
      purchases: snapshot._purchases,
      sales: sales,
      salesReturns: snapshot._salesReturns,
      transfers: snapshot._transfers,
    );
  }

  DemoInventoryCostSnapshot stageSalesReturn(
    DemoInventoryCostSnapshot snapshot, {
    required SalesReturn? previous,
    required SalesReturn? candidate,
  }) {
    final salesReturns = Map<EntityId, SalesReturn>.of(
      snapshot._salesReturns,
    );
    if (previous != null) salesReturns.remove(previous.id);
    if (candidate != null) salesReturns[candidate.id] = candidate;
    return _replay(
      purchases: snapshot._purchases,
      sales: snapshot._sales,
      salesReturns: salesReturns,
      transfers: snapshot._transfers,
    );
  }

  DemoInventoryCostSnapshot stageTransfer(
    DemoInventoryCostSnapshot snapshot, {
    required InventoryTransfer transfer,
  }) {
    final transfers = Map<EntityId, InventoryTransfer>.of(snapshot._transfers);
    final existing = transfers[transfer.id];
    if (existing != null) {
      throw StateError('معرف النقل المخزني مستخدم في سجل تكلفة آخر');
    }
    final reversalOfId = transfer.reversalOfId;
    if (reversalOfId != null) {
      final original = transfers[reversalOfId];
      if (original == null ||
          !transfer.createdAt.value.isAfter(original.createdAt.value)) {
        throw StateError('يجب أن يتبع عكس النقل سجله الأصلي زمنياً');
      }
    }
    transfers[transfer.id] = transfer;
    return _replay(
      purchases: snapshot._purchases,
      sales: snapshot._sales,
      salesReturns: snapshot._salesReturns,
      transfers: transfers,
    );
  }

  @override
  DemoInventoryCostSnapshot stageTransferCost(InventoryTransfer transfer) {
    return stageTransfer(createSnapshot(), transfer: transfer);
  }

  void commitSnapshot(DemoInventoryCostSnapshot snapshot) {
    _purchases = Map.of(snapshot._purchases);
    _sales = Map.of(snapshot._sales);
    _salesReturns = Map.of(snapshot._salesReturns);
    _transfers = Map.of(snapshot._transfers);
    _balances = Map.of(snapshot._balances);
    _salesLineCosts = Map.of(snapshot._salesLineCosts);
    _salesReturnLineCosts = Map.of(snapshot._salesReturnLineCosts);
  }

  @override
  void commitCostSnapshot(DemoInventoryCostSnapshot snapshot) {
    commitSnapshot(snapshot);
  }

  @override
  Future<List<InventoryCostBalance>> getBalances() async {
    final result = [..._balances.values]
      ..sort((first, second) {
        final byWarehouse = first.warehouseId.value.compareTo(
          second.warehouseId.value,
        );
        return byWarehouse != 0
            ? byWarehouse
            : first.itemId.value.compareTo(second.itemId.value);
      });
    return List.unmodifiable(result);
  }

  @override
  Future<InventoryCostBalance?> getBalance({
    required EntityId warehouseId,
    required EntityId itemId,
  }) async {
    return _balances[(warehouseId, itemId)];
  }

  @override
  Future<List<SalesLineCostRecord>> getSalesLineCosts({
    EntityId? salesInvoiceId,
  }) async {
    final result = _salesLineCosts.values
        .where(
          (record) =>
              salesInvoiceId == null ||
              record.salesInvoiceId == salesInvoiceId,
        )
        .toList()
      ..sort((first, second) => first.id.value.compareTo(second.id.value));
    return List.unmodifiable(result);
  }

  @override
  Future<SalesLineCostRecord?> getSalesLineCost(EntityId salesLineId) async {
    return _salesLineCosts[salesLineId];
  }

  @override
  Future<List<SalesReturnLineCostRecord>> getSalesReturnLineCosts({
    EntityId? salesReturnId,
  }) async {
    final result = _salesReturnLineCosts.values
        .where(
          (record) =>
              salesReturnId == null ||
              record.salesReturnId == salesReturnId,
        )
        .toList()
      ..sort((first, second) => first.id.value.compareTo(second.id.value));
    return List.unmodifiable(result);
  }

  @override
  Future<SalesReturnLineCostRecord?> getSalesReturnLineCost(
    EntityId salesReturnLineId,
  ) async {
    return _salesReturnLineCosts[salesReturnLineId];
  }

  DemoInventoryCostSnapshot _replay({
    required Map<EntityId, PurchaseInvoice> purchases,
    required Map<EntityId, SalesInvoice> sales,
    required Map<EntityId, SalesReturn> salesReturns,
    required Map<EntityId, InventoryTransfer> transfers,
  }) {
    final balances = <_InventoryCostKey, InventoryCostBalance>{};
    for (final balance in _openingBalances) {
      final key = (balance.warehouseId, balance.itemId);
      if (balances.containsKey(key)) {
        throw StateError('رصيد تكلفة افتتاحي مكرر للمخزن والمادة');
      }
      balances[key] = balance;
    }
    final costs = <EntityId, SalesLineCostRecord>{};
    final returnCosts = <EntityId, SalesReturnLineCostRecord>{};
    final returnProgress = <EntityId, _SalesReturnCostProgress>{};
    final events = <_InventoryCostEvent>[
      for (final invoice in purchases.values)
        _InventoryCostEvent.purchase(invoice),
      for (final invoice in sales.values) _InventoryCostEvent.sale(invoice),
      for (final salesReturn in salesReturns.values)
        _InventoryCostEvent.salesReturn(salesReturn),
      for (final transfer in transfers.values)
        _InventoryCostEvent.transfer(transfer),
    ]
      ..sort(_compareEvents);

    for (final event in events) {
      switch (event.kind) {
        case _InventoryCostEventKind.purchase:
          _applyPurchase(balances, event.value as PurchaseInvoice);
          break;
        case _InventoryCostEventKind.transfer:
          _applyTransfer(balances, event.value as InventoryTransfer);
          break;
        case _InventoryCostEventKind.sale:
          _applySale(
            balances,
            costs,
            event.value as SalesInvoice,
          );
          break;
        case _InventoryCostEventKind.salesReturn:
          _applySalesReturn(
            balances,
            costs,
            returnCosts,
            returnProgress,
            sales,
            event.value as SalesReturn,
          );
          break;
      }
    }
    return DemoInventoryCostSnapshot._(
      purchases: purchases,
      sales: sales,
      salesReturns: salesReturns,
      transfers: transfers,
      balances: balances,
      salesLineCosts: costs,
      salesReturnLineCosts: returnCosts,
    );
  }

  void _applyPurchase(
    Map<_InventoryCostKey, InventoryCostBalance> balances,
    PurchaseInvoice invoice,
  ) {
    if (invoice.purchaseKind == PurchaseTransactionKind.returnPurchase) {
      for (final line in invoice.lines) {
        _issue(
          balances,
          warehouseId: line.warehouseId,
          itemId: line.itemId,
          quantity: line.quantity.value,
        );
      }
      return;
    }

    final totalCostIqd = _toIqdMinorUnits(invoice.total, invoice.exchangeRate);
    final allocations = allocateInvoiceTotalMinorUnits(
      totalMinorUnits: totalCostIqd,
      netLineMinorUnits: [
        for (final line in invoice.lines) line.netTotal.minorUnits,
      ],
      grossLineMinorUnits: [
        for (final line in invoice.lines) line.grossTotal.minorUnits,
      ],
      quantities: [for (final line in invoice.lines) line.quantity.value],
    );
    for (var index = 0; index < invoice.lines.length; index++) {
      final line = invoice.lines[index];
      _receiveKnown(
        balances,
        warehouseId: line.warehouseId,
        itemId: line.itemId,
        quantity: line.quantity.value,
        costIqdMinorUnits: allocations[index],
      );
    }
  }

  void _applySale(
    Map<_InventoryCostKey, InventoryCostBalance> balances,
    Map<EntityId, SalesLineCostRecord> costs,
    SalesInvoice invoice,
  ) {
    final revenueAllocations = allocateInvoiceTotalMinorUnits(
      totalMinorUnits: invoice.total.minorUnits,
      netLineMinorUnits: [
        for (final line in invoice.lines) line.total.minorUnits,
      ],
      grossLineMinorUnits: [
        for (final line in invoice.lines) line.total.minorUnits,
      ],
      quantities: [for (final line in invoice.lines) line.quantity.value],
    );
    for (var index = 0; index < invoice.lines.length; index++) {
      final line = invoice.lines[index];
      final issuedCost = _issue(
        balances,
        warehouseId: line.warehouseId,
        itemId: line.itemId,
        quantity: line.quantity.value,
      );
      final revenue = Money.fromMinorUnits(
        revenueAllocations[index],
        invoice.currency,
      );
      final costIqd = issuedCost == null
          ? null
          : Money.fromMinorUnits(issuedCost, AppCurrency.iqd);
      final cost = issuedCost == null
          ? null
          : Money.fromMinorUnits(
              _fromIqdMinorUnits(
                issuedCost,
                invoice.currency,
                invoice.exchangeRate,
              ),
              invoice.currency,
            );
      final available = issuedCost != null;
      final record = SalesLineCostRecord(
        id: EntityId(
          'sales-line-cost-${invoice.id.value}-${line.id.value}',
        ),
        salesInvoiceId: invoice.id,
        salesLineId: line.id,
        warehouseId: line.warehouseId,
        itemId: line.itemId,
        quantity: line.quantity,
        allocatedRevenue: revenue,
        totalCostIqd: costIqd,
        totalCost: cost,
        availability: available
            ? InventoryCostAvailability.available
            : InventoryCostAvailability.unavailable,
        method: available
            ? InventoryCostMethod.movingAverage
            : InventoryCostMethod.unavailable,
      );
      if (costs.containsKey(line.id)) {
        throw StateError('هوية تكلفة سطر البيع مكررة');
      }
      costs[line.id] = record;
    }
  }

  void _applySalesReturn(
    Map<_InventoryCostKey, InventoryCostBalance> balances,
    Map<EntityId, SalesLineCostRecord> salesCosts,
    Map<EntityId, SalesReturnLineCostRecord> returnCosts,
    Map<EntityId, _SalesReturnCostProgress> progress,
    Map<EntityId, SalesInvoice> sales,
    SalesReturn salesReturn,
  ) {
    final sourceInvoice = sales[salesReturn.originalSalesInvoiceId];
    if (sourceInvoice == null) {
      throw StateError('قائمة البيع الأصلية لمرتجع البيع غير موجودة');
    }
    final sourceLines = {
      for (final line in sourceInvoice.lines) line.id: line,
    };
    for (final line in salesReturn.lines) {
      final sourceLine = sourceLines[line.sourceSalesLineId];
      if (sourceLine == null ||
          sourceLine.itemId != line.itemId ||
          sourceLine.warehouseId != line.warehouseId) {
        throw StateError('سطر مرتجع البيع لا يطابق سطر القائمة الأصلية');
      }
      final sourceCost = salesCosts[sourceLine.id];
      if (sourceCost == null) {
        throw StateError('تكلفة سطر البيع الأصلي غير موجودة');
      }
      final previous = progress[sourceLine.id] ??
          const _SalesReturnCostProgress(
            quantity: 0,
            restoredCostIqdMinorUnits: 0,
          );
      final cumulativeQuantity = previous.quantity + line.quantity.value;
      if (cumulativeQuantity > sourceLine.quantity.value) {
        throw StateError('كمية مرتجع البيع تتجاوز كمية السطر الأصلي');
      }

      final originalCostIqd = sourceCost.totalCostIqd?.minorUnits;
      final int? restoredCostIqd;
      if (originalCostIqd == null) {
        restoredCostIqd = null;
        _receiveUnknown(
          balances,
          warehouseId: line.warehouseId,
          itemId: line.itemId,
          quantity: line.quantity.value,
        );
      } else {
        final cumulativeRestoredCost = multiplyDivideAndRoundHalfAwayFromZero(
          originalCostIqd,
          cumulativeQuantity,
          sourceLine.quantity.value,
        );
        restoredCostIqd =
            cumulativeRestoredCost - previous.restoredCostIqdMinorUnits;
        _receiveKnown(
          balances,
          warehouseId: line.warehouseId,
          itemId: line.itemId,
          quantity: line.quantity.value,
          costIqdMinorUnits: restoredCostIqd,
        );
      }

      final restoredCost = restoredCostIqd == null
          ? null
          : Money.fromMinorUnits(
              _fromIqdMinorUnits(
                restoredCostIqd,
                salesReturn.currency,
                salesReturn.exchangeRate,
              ),
              salesReturn.currency,
            );
      final available = restoredCostIqd != null;
      final record = SalesReturnLineCostRecord(
        id: EntityId(
          'sales-return-line-cost-${salesReturn.id.value}-${line.id.value}',
        ),
        salesReturnId: salesReturn.id,
        salesReturnLineId: line.id,
        originalSalesInvoiceId: sourceInvoice.id,
        originalSalesLineId: sourceLine.id,
        warehouseId: line.warehouseId,
        itemId: line.itemId,
        quantity: line.quantity,
        allocatedRefund: line.allocatedRefund,
        restoredCostIqd: restoredCostIqd == null
            ? null
            : Money.fromMinorUnits(restoredCostIqd, AppCurrency.iqd),
        restoredCost: restoredCost,
        availability: available
            ? InventoryCostAvailability.available
            : InventoryCostAvailability.unavailable,
        method: available
            ? InventoryCostMethod.movingAverage
            : InventoryCostMethod.unavailable,
      );
      if (returnCosts.containsKey(line.id)) {
        throw StateError('هوية تكلفة سطر مرتجع البيع مكررة');
      }
      returnCosts[line.id] = record;
      progress[sourceLine.id] = _SalesReturnCostProgress(
        quantity: cumulativeQuantity,
        restoredCostIqdMinorUnits: restoredCostIqd == null
            ? previous.restoredCostIqdMinorUnits
            : previous.restoredCostIqdMinorUnits + restoredCostIqd,
      );
    }
  }

  void _applyTransfer(
    Map<_InventoryCostKey, InventoryCostBalance> balances,
    InventoryTransfer transfer,
  ) {
    for (final line in transfer.lines) {
      final movedCost = _takeForTransfer(
        balances,
        warehouseId: transfer.fromWarehouseId,
        itemId: line.itemId,
        quantity: line.quantity.value,
      );
      if (movedCost == null) {
        _receiveUnknown(
          balances,
          warehouseId: transfer.toWarehouseId,
          itemId: line.itemId,
          quantity: line.quantity.value,
        );
      } else {
        _receiveKnown(
          balances,
          warehouseId: transfer.toWarehouseId,
          itemId: line.itemId,
          quantity: line.quantity.value,
          costIqdMinorUnits: movedCost,
        );
      }
    }
  }

  int? _issue(
    Map<_InventoryCostKey, InventoryCostBalance> balances, {
    required EntityId warehouseId,
    required EntityId itemId,
    required int quantity,
  }) {
    final key = (warehouseId, itemId);
    final current = balances[key];
    if (current == null ||
        current.quantity.value <= 0 ||
        current.quantity.value < quantity) {
      final finalQuantity = (current?.quantity.value ?? 0) - quantity;
      _writeBalance(
        balances,
        key: key,
        quantity: finalQuantity,
        totalCostIqdMinorUnits: null,
      );
      return null;
    }
    final total = current.totalCostIqd?.minorUnits;
    final issued = total == null
        ? null
        : multiplyDivideAndRoundHalfAwayFromZero(
            total,
            quantity,
            current.quantity.value,
          );
    final finalQuantity = current.quantity.value - quantity;
    _writeBalance(
      balances,
      key: key,
      quantity: finalQuantity,
      totalCostIqdMinorUnits: issued == null ? null : total! - issued,
    );
    return issued;
  }

  int? _takeForTransfer(
    Map<_InventoryCostKey, InventoryCostBalance> balances, {
    required EntityId warehouseId,
    required EntityId itemId,
    required int quantity,
  }) {
    final current = balances[(warehouseId, itemId)];
    if (current == null || current.quantity.value < quantity) {
      throw StateError('أرصدة تكلفة المخزون غير متزامنة مع الكميات');
    }
    return _issue(
      balances,
      warehouseId: warehouseId,
      itemId: itemId,
      quantity: quantity,
    );
  }

  void _receiveKnown(
    Map<_InventoryCostKey, InventoryCostBalance> balances, {
    required EntityId warehouseId,
    required EntityId itemId,
    required int quantity,
    required int costIqdMinorUnits,
  }) {
    final key = (warehouseId, itemId);
    final current = balances[key];
    if (current == null) {
      _writeBalance(
        balances,
        key: key,
        quantity: quantity,
        totalCostIqdMinorUnits: costIqdMinorUnits,
      );
      return;
    }
    final finalQuantity = current.quantity.value + quantity;
    if (current.quantity.isNegative) {
      if (finalQuantity <= 0) {
        _writeBalance(
          balances,
          key: key,
          quantity: finalQuantity,
          totalCostIqdMinorUnits: null,
        );
        return;
      }
      final knownRemainder = allocateIntegerByWeights(
        costIqdMinorUnits,
        [-current.quantity.value, finalQuantity],
      )[1];
      _writeBalance(
        balances,
        key: key,
        quantity: finalQuantity,
        totalCostIqdMinorUnits: knownRemainder,
      );
      return;
    }
    final currentCost = current.totalCostIqd?.minorUnits;
    _writeBalance(
      balances,
      key: key,
      quantity: finalQuantity,
      totalCostIqdMinorUnits:
          currentCost == null ? null : currentCost + costIqdMinorUnits,
    );
  }

  void _receiveUnknown(
    Map<_InventoryCostKey, InventoryCostBalance> balances, {
    required EntityId warehouseId,
    required EntityId itemId,
    required int quantity,
  }) {
    final key = (warehouseId, itemId);
    final current = balances[key];
    _writeBalance(
      balances,
      key: key,
      quantity: (current?.quantity.value ?? 0) + quantity,
      totalCostIqdMinorUnits: null,
    );
  }

  void _writeBalance(
    Map<_InventoryCostKey, InventoryCostBalance> balances, {
    required _InventoryCostKey key,
    required int quantity,
    required int? totalCostIqdMinorUnits,
  }) {
    if (quantity == 0) {
      balances.remove(key);
      return;
    }
    balances[key] = InventoryCostBalance(
      id: EntityId('inventory-cost-${key.$1.value}-${key.$2.value}'),
      warehouseId: key.$1,
      itemId: key.$2,
      quantity: StockQuantity(quantity),
      totalCostIqd: totalCostIqdMinorUnits == null
          ? null
          : Money.fromMinorUnits(
              totalCostIqdMinorUnits,
              AppCurrency.iqd,
            ),
    );
  }
}

typedef _InventoryCostKey = (EntityId warehouseId, EntityId itemId);

class _SalesReturnCostProgress {
  const _SalesReturnCostProgress({
    required this.quantity,
    required this.restoredCostIqdMinorUnits,
  });

  final int quantity;
  final int restoredCostIqdMinorUnits;
}

enum _InventoryCostEventKind { purchase, transfer, sale, salesReturn }

class _InventoryCostEvent {
  _InventoryCostEvent.purchase(PurchaseInvoice invoice)
      : kind = _InventoryCostEventKind.purchase,
        timestamp = invoice.date.atTime(
          hour: invoice.minuteOfDay ~/ Duration.minutesPerHour,
          minute: invoice.minuteOfDay % Duration.minutesPerHour,
        ),
        stableId = invoice.id.value,
        value = invoice;

  _InventoryCostEvent.sale(SalesInvoice invoice)
      : kind = _InventoryCostEventKind.sale,
        timestamp = invoice.date.atTime(
          hour: invoice.minuteOfDay ~/ Duration.minutesPerHour,
          minute: invoice.minuteOfDay % Duration.minutesPerHour,
        ),
        stableId = invoice.id.value,
        value = invoice;

  _InventoryCostEvent.salesReturn(SalesReturn salesReturn)
      : kind = _InventoryCostEventKind.salesReturn,
        timestamp = salesReturn.date.atTime(
          hour: salesReturn.minuteOfDay ~/ Duration.minutesPerHour,
          minute: salesReturn.minuteOfDay % Duration.minutesPerHour,
        ),
        stableId = salesReturn.id.value,
        value = salesReturn;

  _InventoryCostEvent.transfer(InventoryTransfer transfer)
      : kind = _InventoryCostEventKind.transfer,
        timestamp = transfer.createdAt.value.toLocal(),
        stableId = transfer.id.value,
        value = transfer;

  final _InventoryCostEventKind kind;
  final DateTime timestamp;
  final String stableId;
  final Object value;
}

int _compareEvents(_InventoryCostEvent first, _InventoryCostEvent second) {
  final byTime = first.timestamp.compareTo(second.timestamp);
  if (byTime != 0) return byTime;
  if (first.kind == _InventoryCostEventKind.purchase &&
      second.kind == _InventoryCostEventKind.purchase) {
    final firstInvoice = first.value as PurchaseInvoice;
    final secondInvoice = second.value as PurchaseInvoice;
    if (firstInvoice.isReturn != secondInvoice.isReturn) {
      return firstInvoice.isReturn ? 1 : -1;
    }
    final byDocumentNumber =
        firstInvoice.documentNumber.compareTo(secondInvoice.documentNumber);
    if (byDocumentNumber != 0) return byDocumentNumber;
  }
  if (first.kind == _InventoryCostEventKind.salesReturn &&
      second.kind == _InventoryCostEventKind.salesReturn) {
    final firstReturn = first.value as SalesReturn;
    final secondReturn = second.value as SalesReturn;
    final byDocumentNumber =
        firstReturn.documentNumber.compareTo(secondReturn.documentNumber);
    if (byDocumentNumber != 0) return byDocumentNumber;
  }
  final byKind = first.kind.index.compareTo(second.kind.index);
  return byKind != 0 ? byKind : first.stableId.compareTo(second.stableId);
}

int _toIqdMinorUnits(Money value, ExchangeRate rate) {
  if (value.currency == AppCurrency.iqd) return value.minorUnits;
  return multiplyDivideAndRoundHalfAwayFromZero(
    value.minorUnits,
    rate.tenThousandths,
    AppCurrency.usd.scale * 10000,
  );
}

int _fromIqdMinorUnits(
  int value,
  AppCurrency currency,
  ExchangeRate rate,
) {
  if (currency == AppCurrency.iqd) return value;
  return multiplyDivideAndRoundHalfAwayFromZero(
    value,
    AppCurrency.usd.scale * 10000,
    rate.tenThousandths,
  );
}

InventoryCostBalance _openingCost(
  String warehouseId,
  String itemId,
  int quantity,
  int unitCostIqd,
) {
  final warehouse = EntityId(warehouseId);
  final item = EntityId(itemId);
  return InventoryCostBalance(
    id: EntityId('inventory-cost-$warehouseId-$itemId'),
    warehouseId: warehouse,
    itemId: item,
    quantity: StockQuantity(quantity),
    totalCostIqd: Money.fromMajor(
      quantity * unitCostIqd,
      AppCurrency.iqd,
    ),
  );
}

/// Explicit stock-and-cost position immediately before the dated demo events.
/// Values are not inferred from sales prices. The quantities reconcile the
/// immutable transfer and invoice seeds with the warehouse demo projection.
List<InventoryCostBalance> demoInventoryCostOpeningBalances() => [
      _openingCost('warehouse-001', 'item-001', 18, 200000),
      _openingCost('warehouse-001', 'item-002', 59, 30000),
      _openingCost('warehouse-001', 'item-003', 140, 7000),
      _openingCost('warehouse-001', 'item-004', 23, 100000),
      _openingCost('warehouse-001', 'item-005', 10, 2000),
      _openingCost('warehouse-001', 'item-009', 3, 4000),
      _openingCost('warehouse-001', 'item-010', 4, 25000),
      _openingCost('warehouse-002', 'item-001', 7, 200000),
      _openingCost('warehouse-002', 'item-003', 25, 7000),
      _openingCost('warehouse-002', 'item-004', 1, 100000),
      _openingCost('warehouse-003', 'item-002', 27, 30000),
      _openingCost('warehouse-003', 'item-003', 10, 8000),
      _openingCost('warehouse-003', 'item-004', 13, 100000),
      _openingCost('warehouse-004', 'item-003', 32, 7000),
      _openingCost('warehouse-004', 'item-007', 4, 786000),
      _openingCost('warehouse-004', 'item-008', 6, 131000),
    ];
