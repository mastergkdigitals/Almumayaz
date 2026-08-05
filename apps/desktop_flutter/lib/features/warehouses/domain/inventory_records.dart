import '../../../core/domain/business_values.dart';

/// Canonical persistence identity for a warehouse/item balance.
///
/// The older `WarehouseInventoryItem` remains a presentation projection until
/// the Warehouses screen is migrated; adapters must resolve its product code
/// to this stable [itemId] rather than persisting that display-only model.
class InventoryBalance {
  InventoryBalance({
    required this.id,
    required this.warehouseId,
    required this.itemId,
    required this.quantity,
  });

  final EntityId id;
  final EntityId warehouseId;
  final EntityId itemId;
  final WholeQuantity quantity;

  InventoryBalance copyWith({WholeQuantity? quantity}) {
    return InventoryBalance(
      id: id,
      warehouseId: warehouseId,
      itemId: itemId,
      quantity: quantity ?? this.quantity,
    );
  }
}

class InventoryTransferLine {
  InventoryTransferLine({
    required this.itemId,
    required this.quantity,
  }) {
    if (quantity.isZero) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive');
    }
  }

  final EntityId itemId;
  final WholeQuantity quantity;
}

class InventoryTransferDraft {
  InventoryTransferDraft({
    required this.fromWarehouseId,
    required this.toWarehouseId,
    required Iterable<InventoryTransferLine> lines,
    this.createdAt,
  }) : lines = List.unmodifiable(lines) {
    if (fromWarehouseId == toWarehouseId) {
      throw ArgumentError('Source and destination warehouses must differ');
    }
    if (this.lines.isEmpty) {
      throw ArgumentError.value(lines, 'lines', 'Must not be empty');
    }
  }

  final EntityId fromWarehouseId;
  final EntityId toWarehouseId;
  final List<InventoryTransferLine> lines;
  final AuditTimestamp? createdAt;
}

class InventoryTransfer {
  InventoryTransfer({
    required this.id,
    required this.documentNumber,
    required this.createdAt,
    required this.fromWarehouseId,
    required this.toWarehouseId,
    required Iterable<InventoryTransferLine> lines,
    this.reversalOfId,
  }) : lines = List.unmodifiable(lines);

  final EntityId id;

  /// Visible sequence; corrections never reuse it or mutate an old transfer.
  final int documentNumber;
  final AuditTimestamp createdAt;
  final EntityId fromWarehouseId;
  final EntityId toWarehouseId;
  final List<InventoryTransferLine> lines;
  final EntityId? reversalOfId;
}
