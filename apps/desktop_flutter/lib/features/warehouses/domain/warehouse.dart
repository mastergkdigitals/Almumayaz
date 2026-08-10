import 'package:flutter/foundation.dart';

import '../../../core/domain/business_values.dart';

@immutable
class Warehouse {
  factory Warehouse({
    required String id,
    required int number,
    required String name,
    required String location,
    required String notes,
    bool isMain = false,
  }) {
    return Warehouse.typed(
      entityId: EntityId(id),
      number: number,
      name: name,
      location: location,
      notes: notes,
      isMain: isMain,
    );
  }

  const Warehouse.typed({
    required this.entityId,
    required this.number,
    required this.name,
    required this.location,
    required this.notes,
    this.isMain = false,
  });

  final EntityId entityId;
  final int number;
  final String name;
  final String location;
  final String notes;
  final bool isMain;

  String get id => entityId.value;

  Warehouse copyWith({
    String? name,
    String? location,
    String? notes,
  }) {
    return Warehouse.typed(
      entityId: entityId,
      number: number,
      name: name ?? this.name,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isMain: isMain,
    );
  }

  String get searchText => '$number $name $location $notes'.toLowerCase();
}

/// Read-only presentation projection resolved from an [InventoryBalance].
@immutable
class WarehouseInventoryItem {
  factory WarehouseInventoryItem({
    required String id,
    required String productCode,
    required String productName,
    required int quantity,
  }) {
    return WarehouseInventoryItem.typed(
      balanceId: EntityId(id),
      productCode: productCode,
      productName: productName,
      stockQuantity: StockQuantity(quantity),
    );
  }

  const WarehouseInventoryItem.typed({
    required this.balanceId,
    required this.productCode,
    required this.productName,
    required this.stockQuantity,
  });

  final EntityId balanceId;
  final String productCode;
  final String productName;
  final StockQuantity stockQuantity;

  String get id => balanceId.value;
  int get quantity => stockQuantity.value;
  String get searchText => '$productCode $productName $quantity'.toLowerCase();
}

/// Read-only presentation projection resolved from an InventoryTransferLine.
@immutable
class WarehouseTransferLine {
  factory WarehouseTransferLine({
    required String productCode,
    required String productName,
    required int quantity,
  }) {
    return WarehouseTransferLine.typed(
      productCode: productCode,
      productName: productName,
      wholeQuantity: WholeQuantity(quantity),
    );
  }

  const WarehouseTransferLine.typed({
    required this.productCode,
    required this.productName,
    required this.wholeQuantity,
  });

  final String productCode;
  final String productName;
  final WholeQuantity wholeQuantity;

  int get quantity => wholeQuantity.value;
  String get summary => '$productCode - $productName ($quantity)';
}

/// Read-only presentation projection of the immutable inventory transfer.
@immutable
class WarehouseTransferRecord {
  factory WarehouseTransferRecord({
    required String id,
    required int number,
    required DateTime createdAt,
    required String fromWarehouseId,
    required String fromWarehouseName,
    required String toWarehouseId,
    required String toWarehouseName,
    required List<WarehouseTransferLine> lines,
    String? reversalOfId,
  }) {
    return WarehouseTransferRecord.typed(
      entityId: EntityId(id),
      number: number,
      createdTimestamp: AuditTimestamp(createdAt),
      fromWarehouseEntityId: EntityId(fromWarehouseId),
      fromWarehouseName: fromWarehouseName,
      toWarehouseEntityId: EntityId(toWarehouseId),
      toWarehouseName: toWarehouseName,
      lines: lines,
      reversalOfEntityId:
          reversalOfId == null ? null : EntityId(reversalOfId),
    );
  }

  WarehouseTransferRecord.typed({
    required this.entityId,
    required this.number,
    required this.createdTimestamp,
    required this.fromWarehouseEntityId,
    required this.fromWarehouseName,
    required this.toWarehouseEntityId,
    required this.toWarehouseName,
    required Iterable<WarehouseTransferLine> lines,
    this.reversalOfEntityId,
  }) : lines = List.unmodifiable(lines);

  final EntityId entityId;
  final int number;
  final AuditTimestamp createdTimestamp;
  final EntityId fromWarehouseEntityId;
  final String fromWarehouseName;
  final EntityId toWarehouseEntityId;
  final String toWarehouseName;
  final List<WarehouseTransferLine> lines;
  final EntityId? reversalOfEntityId;

  String get id => entityId.value;
  DateTime get createdAt => createdTimestamp.value.toLocal();
  String get fromWarehouseId => fromWarehouseEntityId.value;
  String get toWarehouseId => toWarehouseEntityId.value;
  String? get reversalOfId => reversalOfEntityId?.value;

  String get formattedDate =>
      '${createdAt.year.toString().padLeft(4, '0')}/'
      '${createdAt.month.toString().padLeft(2, '0')}/'
      '${createdAt.day.toString().padLeft(2, '0')}';

  String get itemsSummary => lines.map((line) => line.summary).join('، ');

  String get searchText => [
        number,
        formattedDate,
        fromWarehouseName,
        toWarehouseName,
        itemsSummary,
        if (reversalOfEntityId != null) 'عكس تصحيح',
      ].join(' ').toLowerCase();
}
