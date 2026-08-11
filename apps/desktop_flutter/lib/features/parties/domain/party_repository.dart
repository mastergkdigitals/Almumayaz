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

class PartyQuickCreateRequest {
  const PartyQuickCreateRequest({
    required this.name,
    this.type = PartyType.customerAndSupplier,
    this.createdTimestamp,
    this.workplaceId,
    this.branchId,
    this.phone = '',
    this.alternatePhone = '',
    this.city = '',
    this.address = '',
    this.notes = '',
  });

  final String name;
  final PartyType type;
  final AuditTimestamp? createdTimestamp;
  final EntityId? workplaceId;
  final EntityId? branchId;
  final String phone;
  final String alternatePhone;
  final String city;
  final String address;
  final String notes;
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

  /// Returns the next visible number after every number ever issued,
  /// including parties that were later deleted.
  Future<int> nextPartyNumber();

  /// Atomically validates master-data references and issues a stable party ID
  /// and a visible party number that will never be reused.
  Future<Party> quickCreate(PartyQuickCreateRequest request);
}
