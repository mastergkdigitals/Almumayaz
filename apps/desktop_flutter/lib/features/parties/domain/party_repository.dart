import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'party.dart';

class PartyMasterDataReferences {
  const PartyMasterDataReferences({
    this.workplaceId,
    this.branchId,
  });

  final EntityId? workplaceId;
  final EntityId? branchId;
}

abstract interface class PartyRepository implements AppRepository<Party> {
  Future<List<Party>> search(String query);

  Future<Party?> findByName(String name);

  Future<Party> saveWithMasterData(
    Party party,
    PartyMasterDataReferences references,
  );

  Future<PartyMasterDataReferences?> getMasterDataReferences(EntityId partyId);

  Future<bool> referencesMasterData(EntityId masterDataId);
}
