import 'package:flutter/foundation.dart';

import '../../../core/domain/business_values.dart';

@immutable
class ItemGroup {
  factory ItemGroup({
    required String id,
    required int number,
    required String name,
  }) {
    return ItemGroup.typed(
      entityId: EntityId(id),
      number: number,
      name: name,
    );
  }

  const ItemGroup.typed({
    required this.entityId,
    required this.number,
    required this.name,
  });

  final EntityId entityId;
  final int number;
  final String name;

  String get id => entityId.value;
  String get label => '$number - $name';
}

@immutable
class ItemType {
  factory ItemType({
    required String id,
    required String groupId,
    required int number,
    required String name,
  }) {
    return ItemType.typed(
      entityId: EntityId(id),
      groupEntityId: EntityId(groupId),
      number: number,
      name: name,
    );
  }

  const ItemType.typed({
    required this.entityId,
    required this.groupEntityId,
    required this.number,
    required this.name,
  });

  final EntityId entityId;
  final EntityId groupEntityId;
  final int number;
  final String name;

  String get id => entityId.value;
  String get groupId => groupEntityId.value;
  String get label => '$number - $name';
}

@immutable
class Item {
  factory Item({
    required String id,
    required String code,
    required String name,
    required String barcode,
    required String groupId,
    required String groupName,
    required String typeId,
    required String typeName,
    required num salePriceIqd,
    required num salePriceUsd,
    required String notes,
  }) {
    return Item.typed(
      entityId: EntityId(id),
      code: code,
      name: name,
      barcode: barcode,
      groupEntityId: EntityId(groupId),
      groupName: groupName,
      typeEntityId: EntityId(typeId),
      typeName: typeName,
      iqdSalePrice: Money.fromMajor(salePriceIqd, AppCurrency.iqd),
      usdSalePrice: Money.fromMajor(salePriceUsd, AppCurrency.usd),
      notes: notes,
    );
  }

  Item.typed({
    required this.entityId,
    required this.code,
    required this.name,
    required this.barcode,
    required this.groupEntityId,
    required this.groupName,
    required this.typeEntityId,
    required this.typeName,
    required this.iqdSalePrice,
    required this.usdSalePrice,
    required this.notes,
  }) {
    _requireCurrency(iqdSalePrice, AppCurrency.iqd, 'iqdSalePrice');
    _requireCurrency(usdSalePrice, AppCurrency.usd, 'usdSalePrice');
  }

  final EntityId entityId;
  final String code;
  final String name;
  final String barcode;
  final EntityId groupEntityId;
  final String groupName;
  final EntityId typeEntityId;
  final String typeName;
  final Money iqdSalePrice;
  final Money usdSalePrice;
  final String notes;

  String get id => entityId.value;
  String get groupId => groupEntityId.value;
  String get typeId => typeEntityId.value;
  num get salePriceIqd => iqdSalePrice.majorUnits;
  num get salePriceUsd => usdSalePrice.majorUnits;

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
    return Item.typed(
      entityId: entityId,
      code: code ?? this.code,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      groupEntityId:
          groupId == null ? groupEntityId : EntityId(groupId),
      groupName: groupName ?? this.groupName,
      typeEntityId: typeId == null ? typeEntityId : EntityId(typeId),
      typeName: typeName ?? this.typeName,
      iqdSalePrice: salePriceIqd == null
          ? iqdSalePrice
          : Money.fromMajor(salePriceIqd, AppCurrency.iqd),
      usdSalePrice: salePriceUsd == null
          ? usdSalePrice
          : Money.fromMajor(salePriceUsd, AppCurrency.usd),
      notes: notes ?? this.notes,
    );
  }

  Item copyWithTyped({
    String? code,
    String? name,
    String? barcode,
    EntityId? groupEntityId,
    String? groupName,
    EntityId? typeEntityId,
    String? typeName,
    Money? iqdSalePrice,
    Money? usdSalePrice,
    String? notes,
  }) {
    return Item.typed(
      entityId: entityId,
      code: code ?? this.code,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      groupEntityId: groupEntityId ?? this.groupEntityId,
      groupName: groupName ?? this.groupName,
      typeEntityId: typeEntityId ?? this.typeEntityId,
      typeName: typeName ?? this.typeName,
      iqdSalePrice: iqdSalePrice ?? this.iqdSalePrice,
      usdSalePrice: usdSalePrice ?? this.usdSalePrice,
      notes: notes ?? this.notes,
    );
  }

  String get searchText => [
        code,
        name,
        barcode,
        groupName,
        typeName,
        notes,
        iqdSalePrice.toPlainString(),
        usdSalePrice.toPlainString(),
      ].join(' ').toLowerCase();
}

void _requireCurrency(Money value, AppCurrency currency, String name) {
  if (value.currency != currency) {
    throw ArgumentError.value(value, name, 'Must use ${currency.code}');
  }
}
