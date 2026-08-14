import '../../../core/domain/business_values.dart';

enum InventoryCostAvailability { available, unavailable }

enum InventoryCostMethod { movingAverage, unavailable }

extension InventoryCostAvailabilityLabel on InventoryCostAvailability {
  String get arabicLabel => switch (this) {
        InventoryCostAvailability.available => 'متوفرة',
        InventoryCostAvailability.unavailable => 'غير متوفرة',
      };
}

extension InventoryCostMethodLabel on InventoryCostMethod {
  String get arabicLabel => switch (this) {
        InventoryCostMethod.movingAverage => 'متوسط متحرك',
        InventoryCostMethod.unavailable => '-',
      };
}

/// Authoritative base-currency value for one warehouse/item stock position.
///
/// Quantity can be negative only when the explicit sales policy permits it.
/// A null [totalCostIqd] is deliberate: it prevents an unknown or negative
/// inventory origin from being presented as a fabricated cost.
class InventoryCostBalance {
  InventoryCostBalance({
    required this.id,
    required this.warehouseId,
    required this.itemId,
    required this.quantity,
    required this.totalCostIqd,
  }) {
    final cost = totalCostIqd;
    if (quantity.isZero) {
      throw ArgumentError.value(quantity, 'quantity', 'Must not be zero');
    }
    if (cost != null &&
        (cost.currency != AppCurrency.iqd || cost.isNegative)) {
      throw ArgumentError.value(
        cost,
        'totalCostIqd',
        'Must be a non-negative IQD value',
      );
    }
    if (quantity.isNegative && cost != null) {
      throw ArgumentError.value(
        cost,
        'totalCostIqd',
        'Negative inventory cannot have an authoritative cost',
      );
    }
  }

  final EntityId id;
  final EntityId warehouseId;
  final EntityId itemId;
  final StockQuantity quantity;
  final Money? totalCostIqd;

  InventoryCostAvailability get availability => totalCostIqd == null
      ? InventoryCostAvailability.unavailable
      : InventoryCostAvailability.available;
}

/// Immutable cost-of-goods snapshot for a saved sales line.
///
/// [allocatedRevenue] includes the line's share of the invoice-level discount.
/// Cost is retained both in base IQD and in the sale currency using the sale's
/// saved exchange rate. Unavailable records keep both cost values null.
class SalesLineCostRecord {
  SalesLineCostRecord({
    required this.id,
    required this.salesInvoiceId,
    required this.salesLineId,
    required this.warehouseId,
    required this.itemId,
    required this.quantity,
    required this.allocatedRevenue,
    required this.totalCostIqd,
    required this.totalCost,
    required this.availability,
    required this.method,
  }) {
    if (quantity.isZero) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive');
    }
    final hasCost = totalCostIqd != null && totalCost != null;
    if (availability == InventoryCostAvailability.available && !hasCost) {
      throw ArgumentError('Available sales costs must contain both values');
    }
    if (availability == InventoryCostAvailability.unavailable && hasCost) {
      throw ArgumentError('Unavailable sales costs must not contain values');
    }
    if ((totalCostIqd == null) != (totalCost == null)) {
      throw ArgumentError('Sales cost values must be both present or absent');
    }
    if (totalCostIqd != null &&
        (totalCostIqd!.currency != AppCurrency.iqd ||
            totalCostIqd!.isNegative)) {
      throw ArgumentError.value(totalCostIqd, 'totalCostIqd');
    }
    if (totalCost != null &&
        (totalCost!.currency != allocatedRevenue.currency ||
            totalCost!.isNegative)) {
      throw ArgumentError.value(totalCost, 'totalCost');
    }
    if (availability == InventoryCostAvailability.available &&
        method != InventoryCostMethod.movingAverage) {
      throw ArgumentError('Available costs must use moving average');
    }
    if (availability == InventoryCostAvailability.unavailable &&
        method != InventoryCostMethod.unavailable) {
      throw ArgumentError('Unavailable costs must use the unavailable method');
    }
  }

  final EntityId id;
  final EntityId salesInvoiceId;
  final EntityId salesLineId;
  final EntityId warehouseId;
  final EntityId itemId;
  final WholeQuantity quantity;
  final Money allocatedRevenue;
  final Money? totalCostIqd;
  final Money? totalCost;
  final InventoryCostAvailability availability;
  final InventoryCostMethod method;

  Money? get profit =>
      totalCost == null ? null : allocatedRevenue - totalCost!;
}

/// Cost restored to stock by one persisted sales-return line.
///
/// Both values are positive magnitudes. Report projections apply the negative
/// sign when presenting the reversal of revenue, cost of goods and profit.
class SalesReturnLineCostRecord {
  SalesReturnLineCostRecord({
    required this.id,
    required this.salesReturnId,
    required this.salesReturnLineId,
    required this.originalSalesInvoiceId,
    required this.originalSalesLineId,
    required this.warehouseId,
    required this.itemId,
    required this.quantity,
    required this.allocatedRefund,
    required this.restoredCostIqd,
    required this.restoredCost,
    required this.availability,
    required this.method,
  }) {
    if (quantity.isZero) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive');
    }
    final hasCost = restoredCostIqd != null && restoredCost != null;
    if (availability == InventoryCostAvailability.available && !hasCost) {
      throw ArgumentError('Available return costs must contain both values');
    }
    if (availability == InventoryCostAvailability.unavailable && hasCost) {
      throw ArgumentError('Unavailable return costs must not contain values');
    }
    if ((restoredCostIqd == null) != (restoredCost == null)) {
      throw ArgumentError('Return cost values must be both present or absent');
    }
    if (restoredCostIqd != null &&
        (restoredCostIqd!.currency != AppCurrency.iqd ||
            restoredCostIqd!.isNegative)) {
      throw ArgumentError.value(restoredCostIqd, 'restoredCostIqd');
    }
    if (restoredCost != null &&
        (restoredCost!.currency != allocatedRefund.currency ||
            restoredCost!.isNegative)) {
      throw ArgumentError.value(restoredCost, 'restoredCost');
    }
    if (availability == InventoryCostAvailability.available &&
        method != InventoryCostMethod.movingAverage) {
      throw ArgumentError('Available return costs must use moving average');
    }
    if (availability == InventoryCostAvailability.unavailable &&
        method != InventoryCostMethod.unavailable) {
      throw ArgumentError('Unavailable return costs need unavailable method');
    }
  }

  final EntityId id;
  final EntityId salesReturnId;
  final EntityId salesReturnLineId;
  final EntityId originalSalesInvoiceId;
  final EntityId originalSalesLineId;
  final EntityId warehouseId;
  final EntityId itemId;
  final WholeQuantity quantity;
  final Money allocatedRefund;
  final Money? restoredCostIqd;
  final Money? restoredCost;
  final InventoryCostAvailability availability;
  final InventoryCostMethod method;

  Money? get reversedProfit =>
      restoredCost == null ? null : allocatedRefund - restoredCost!;
}
