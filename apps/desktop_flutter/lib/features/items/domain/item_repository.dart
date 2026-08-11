import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'item.dart';

class ItemQuickCreateRequest {
  const ItemQuickCreateRequest({
    required this.code,
    required this.name,
    required this.groupId,
    required this.typeId,
    this.barcode = '',
    this.iqdSalePrice =
        const Money.fromMinorUnits(0, AppCurrency.iqd),
    this.usdSalePrice =
        const Money.fromMinorUnits(0, AppCurrency.usd),
    this.notes = '',
  });

  final String code;
  final String name;
  final EntityId groupId;
  final EntityId typeId;
  final String barcode;
  final Money iqdSalePrice;
  final Money usdSalePrice;
  final String notes;
}

abstract interface class ItemRepository implements AppRepository<Item> {
  Future<List<Item>> search(String query);

  Future<List<ItemGroup>> getGroups();

  Future<List<ItemType>> getTypes({EntityId? groupId});

  /// Atomically validates the selected group/type and issues a stable ID.
  Future<Item> quickCreate(ItemQuickCreateRequest request);
}
