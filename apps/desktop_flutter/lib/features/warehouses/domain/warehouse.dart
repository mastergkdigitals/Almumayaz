import 'package:flutter/foundation.dart';

@immutable
class Warehouse {
  const Warehouse({
    required this.id,
    required this.number,
    required this.name,
    required this.location,
    required this.notes,
    this.isMain = false,
  });

  final String id;
  final int number;
  final String name;
  final String location;
  final String notes;
  final bool isMain;

  Warehouse copyWith({
    String? name,
    String? location,
    String? notes,
  }) {
    return Warehouse(
      id: id,
      number: number,
      name: name ?? this.name,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isMain: isMain,
    );
  }

  String get searchText =>
      '$number $name $location $notes'.toLowerCase();
}

@immutable
class WarehouseInventoryItem {
  const WarehouseInventoryItem({
    required this.id,
    required this.productCode,
    required this.productName,
    required this.quantity,
  });

  final String id;
  final String productCode;
  final String productName;
  final int quantity;

  String get searchText =>
      '$productCode $productName $quantity'.toLowerCase();
}

@immutable
class WarehouseTransferLine {
  const WarehouseTransferLine({
    required this.productCode,
    required this.productName,
    required this.quantity,
  });

  final String productCode;
  final String productName;
  final int quantity;

  String get summary => '$productCode - $productName ($quantity)';
}

/// An inventory transfer is immutable. Corrections are represented by a new
/// record whose [reversalOfId] points to the original transfer.
@immutable
class WarehouseTransferRecord {
  const WarehouseTransferRecord({
    required this.id,
    required this.number,
    required this.createdAt,
    required this.fromWarehouseId,
    required this.fromWarehouseName,
    required this.toWarehouseId,
    required this.toWarehouseName,
    required this.lines,
    this.reversalOfId,
  });

  final String id;
  final int number;
  final DateTime createdAt;
  final String fromWarehouseId;
  final String fromWarehouseName;
  final String toWarehouseId;
  final String toWarehouseName;
  final List<WarehouseTransferLine> lines;
  final String? reversalOfId;

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
        if (reversalOfId != null) 'عكس تصحيح',
      ].join(' ').toLowerCase();
}
