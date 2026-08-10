import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'item.dart';

abstract interface class ItemRepository implements AppRepository<Item> {
  Future<List<Item>> search(String query);

  Future<List<ItemGroup>> getGroups();

  Future<List<ItemType>> getTypes({EntityId? groupId});
}
