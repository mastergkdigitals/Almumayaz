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
