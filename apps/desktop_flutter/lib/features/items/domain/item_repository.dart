import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'item.dart';

extension ItemRepositoryIdentity on Item {
  EntityId get entityId => EntityId(id);
}

extension ItemGroupRepositoryIdentity on ItemGroup {
  EntityId get entityId => EntityId(id);
}

extension ItemTypeRepositoryIdentity on ItemType {
  EntityId get entityId => EntityId(id);

  EntityId get groupEntityId => EntityId(groupId);
}

abstract interface class ItemRepository implements AppRepository<Item> {
  Future<List<Item>> search(String query);

  Future<List<ItemGroup>> getGroups();

  Future<List<ItemType>> getTypes({EntityId? groupId});
}
