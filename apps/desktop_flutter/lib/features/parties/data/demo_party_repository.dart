import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../settings/domain/operational_master_data.dart';
import '../../settings/domain/operational_master_data_repository.dart';
import '../domain/party.dart';
import '../domain/party_repository.dart';

typedef PartyReferenceLookup = Future<bool> Function(EntityId partyId);

class DemoPartyRepository extends InMemoryDemoRepository<Party>
    implements PartyRepository {
  DemoPartyRepository({
    Iterable<Party>? initialValues,
    required OperationalMasterDataRepository masterData,
    Map<EntityId, PartyMasterDataReferences>? initialMasterDataReferences,
    PartyReferenceLookup? isReferenced,
  })  : _masterData = masterData,
        _isReferenced = isReferenced ?? _neverReferenced,
        _masterDataReferences = Map.of(
          initialMasterDataReferences ?? demoPartyMasterDataReferences(),
        ),
        super(
          initialValues: initialValues ?? demoParties(),
          idOf: (party) => party.entityId,
        );

  final PartyReferenceLookup _isReferenced;
  final OperationalMasterDataRepository _masterData;
  final Map<EntityId, PartyMasterDataReferences> _masterDataReferences;

  @override
  Future<List<Party>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    final values = await getAll();
    if (normalized.isEmpty) return values;
    return List.unmodifiable(
      values.where((party) => party.searchText.contains(normalized)),
    );
  }

  @override
  Future<Party?> findByName(String name) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final party in await getAll()) {
      if (party.name.trim().toLowerCase() == normalized) return party;
    }
    return null;
  }

  @override
  Future<Party> save(Party value) async {
    final duplicate = (await getAll()).any(
      (party) =>
          party.entityId != value.entityId &&
          party.name.trim().toLowerCase() == value.name.trim().toLowerCase(),
    );
    if (duplicate) {
      throw StateError('يوجد طرف آخر بالاسم نفسه');
    }
    return super.save(value);
  }

  @override
  Future<Party> saveWithMasterData(
    Party party,
    PartyMasterDataReferences references,
  ) async {
    final workplaceId = references.workplaceId;
    final branchId = references.branchId;
    final workplace = workplaceId == null
        ? null
        : await _masterData.getById(workplaceId);
    final branch =
        branchId == null ? null : await _masterData.getById(branchId);
    if (workplaceId != null &&
        workplace?.kind != OperationalMasterDataKind.workplace) {
      throw StateError('جهة العمل المحددة غير موجودة');
    }
    if (branchId != null && branch?.kind != OperationalMasterDataKind.branch) {
      throw StateError('الفرع المحدد غير موجود');
    }
    if (workplaceId != null &&
        branch != null &&
        branch.parentId != workplaceId) {
      throw StateError('الفرع لا يتبع جهة العمل المحددة');
    }
    final saved = await save(party);
    _masterDataReferences[party.entityId] = references;
    return saved;
  }

  @override
  Future<PartyMasterDataReferences?> getMasterDataReferences(
    EntityId partyId,
  ) async {
    return _masterDataReferences[partyId];
  }

  @override
  Future<bool> referencesMasterData(EntityId masterDataId) async {
    return _masterDataReferences.values.any(
      (references) =>
          references.workplaceId == masterDataId ||
          references.branchId == masterDataId,
    );
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    if (await getById(id) == null) {
      return const DeleteDecision.blocked('السجل غير موجود');
    }
    if (await _isReferenced(id)) {
      return const DeleteDecision.blocked(
        'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
    }
    return const DeleteDecision.allowed();
  }

  @override
  Future<void> delete(EntityId id) async {
    await super.delete(id);
    _masterDataReferences.remove(id);
  }
}

Future<bool> _neverReferenced(EntityId _) async => false;

List<Party> demoParties() => [
      Party(
        id: EntityId.demo('party', 1).value,
        number: 1,
        createdAt: DateTime(2026, 7, 1, 9, 15),
        name: 'شركة النخيل للتجارة',
        type: PartyType.customerAndSupplier,
        workplace: 'التجارة العامة',
        branch: 'بغداد',
        phone: '07701234567',
        alternatePhone: '',
        city: 'بغداد',
        address: 'الكرادة',
        notes: '',
        balanceIqd: 1250000,
        balanceUsd: 850,
      ),
      Party(
        id: EntityId.demo('party', 2).value,
        number: 2,
        createdAt: DateTime(2026, 7, 2, 10, 30),
        name: 'أحمد كريم',
        type: PartyType.customer,
        workplace: 'تجارة المفرد',
        branch: 'المنصور',
        phone: '07801112233',
        alternatePhone: '',
        city: 'بغداد',
        address: 'المنصور',
        notes: '',
        balanceIqd: 475000,
        balanceUsd: 0,
      ),
      Party(
        id: EntityId.demo('party', 3).value,
        number: 3,
        createdAt: DateTime(2026, 7, 3, 11),
        name: 'مجهز الرافدين',
        type: PartyType.supplier,
        workplace: 'تجهيز المواد',
        branch: 'البصرة',
        phone: '07709998877',
        alternatePhone: '07809998877',
        city: 'البصرة',
        address: 'العشار',
        notes: 'التواصل صباحاً',
        balanceIqd: -3200000,
        balanceUsd: -1200,
      ),
    ];

Map<EntityId, PartyMasterDataReferences> demoPartyMasterDataReferences() => {
      EntityId.demo('party', 1): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 1),
        branchId: EntityId.demo('branch', 1),
      ),
      EntityId.demo('party', 2): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 2),
        branchId: EntityId.demo('branch', 2),
      ),
      EntityId.demo('party', 3): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 3),
        branchId: EntityId.demo('branch', 3),
      ),
    };
