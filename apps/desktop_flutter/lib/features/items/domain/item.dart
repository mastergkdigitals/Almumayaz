import 'package:flutter/foundation.dart';

@immutable
class ItemGroup {
  const ItemGroup({
    required this.id,
    required this.number,
    required this.name,
  });

  final String id;
  final int number;
  final String name;

  String get label => '$number - $name';
}

@immutable
class ItemType {
  const ItemType({
    required this.id,
    required this.groupId,
    required this.number,
    required this.name,
  });

  final String id;
  final String groupId;
  final int number;
  final String name;

  String get label => '$number - $name';
}

@immutable
class Item {
  const Item({
    required this.id,
    required this.code,
    required this.name,
    required this.barcode,
    required this.groupId,
    required this.groupName,
    required this.typeId,
    required this.typeName,
    required this.salePriceIqd,
    required this.salePriceUsd,
    required this.notes,
  });

  final String id;
  final String code;
  final String name;
  final String barcode;
  final String groupId;
  final String groupName;
  final String typeId;
  final String typeName;
  final num salePriceIqd;
  final num salePriceUsd;
  final String notes;

  Item copyWith({
    String? code,
    String? name,
    String? barcode,
    String? groupId,
    String? groupName,
    String? typeId,
    String? typeName,
    num? salePriceIqd,
    num? salePriceUsd,
    String? notes,
  }) {
    return Item(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      typeId: typeId ?? this.typeId,
      typeName: typeName ?? this.typeName,
      salePriceIqd: salePriceIqd ?? this.salePriceIqd,
      salePriceUsd: salePriceUsd ?? this.salePriceUsd,
      notes: notes ?? this.notes,
    );
  }

  String get searchText =>
      '$code $name $barcode $groupName $typeName $notes'.toLowerCase();
}
