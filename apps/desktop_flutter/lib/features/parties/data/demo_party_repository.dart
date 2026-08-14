import '../../../core/data/app_repository.dart';
import '../../../core/data/demo_transaction_runner.dart';
import '../../../core/domain/business_values.dart';
import '../../audit_log/data/demo_business_audit.dart';
import '../../audit_log/domain/audit_models.dart';
import '../../permissions/domain/permission_models.dart';
import '../../settings/domain/operational_master_data.dart';
import '../../settings/domain/operational_master_data_repository.dart';
import '../domain/party.dart';
import '../domain/party_repository.dart';

typedef PartyReferenceLookup = Future<bool> Function(EntityId partyId);

class DemoPartyBalanceAdjustment {
  const DemoPartyBalanceAdjustment({
    required this.partyId,
    required this.delta,
  });

  final EntityId partyId;
  final Money delta;
}

class DemoPartyRepository extends InMemoryDemoRepository<Party>
    implements PartyRepository {
  DemoPartyRepository({
    Iterable<Party>? initialValues,
    required OperationalMasterDataRepository masterData,
    Map<EntityId, PartyMasterDataReferences>? initialMasterDataReferences,
    Set<EntityId>? initiallyReferencedIds,
    PartyReferenceLookup? isReferenced,
    DemoTransactionRunner? transactionRunner,
    DemoBusinessAudit? businessAudit,
  })  : _masterData = masterData,
        _isReferenced = isReferenced ?? _neverReferenced,
        _transactionRunner = transactionRunner ?? DemoTransactionRunner(),
        _businessAudit = businessAudit,
        _initiallyReferencedIds = Set.unmodifiable(
          initiallyReferencedIds ?? const <EntityId>{},
        ),
        _masterDataReferences = Map.of(
          initialMasterDataReferences ?? demoPartyMasterDataReferences(),
        ),
        super(
          initialValues: initialValues ?? demoParties(),
          idOf: (party) => party.entityId,
        );

  final PartyReferenceLookup _isReferenced;
  final Set<EntityId> _initiallyReferencedIds;
  final OperationalMasterDataRepository _masterData;
  final DemoTransactionRunner _transactionRunner;
  final DemoBusinessAudit? _businessAudit;
  final Map<EntityId, PartyMasterDataReferences> _masterDataReferences;
  final Set<EntityId> _issuedIds = {};
  final Set<int> _issuedNumbers = {};
  int _highestIssuedNumber = 0;
  int _nextGeneratedIdSequence = 1;

  /// Builds a complete party snapshot with signed IQD/USD adjustments.
  Map<EntityId, Party> stageBalanceAdjustments(
    Iterable<DemoPartyBalanceAdjustment> adjustments,
  ) {
    final staged = createDemoSnapshot();
    final aggregated = <(EntityId, AppCurrency), Money>{};
    for (final adjustment in adjustments) {
      final key = (adjustment.partyId, adjustment.delta.currency);
      aggregated[key] = (aggregated[key] ??
              Money.zero(adjustment.delta.currency)) +
          adjustment.delta;
    }
    for (final entry in aggregated.entries) {
      final (partyId, currency) = entry.key;
      final party = staged[partyId];
      if (party == null) throw StateError('الطرف المحدد غير موجود');
      staged[partyId] = switch (currency) {
        AppCurrency.iqd => party.copyWithTyped(
            iqdBalance: party.iqdBalance + entry.value,
          ),
        AppCurrency.usd => party.copyWithTyped(
            usdBalance: party.usdBalance + entry.value,
          ),
      };
    }
    return staged;
  }

  /// Commits a snapshot already validated by the shared transaction runner.
  void commitPartySnapshot(Map<EntityId, Party> staged) {
    commitDemoSnapshot(staged);
  }

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
    final normalized = normalizePartyName(name);
    if (normalized.isEmpty) return null;
    for (final party in await getAll()) {
      if (normalizePartyName(party.name) == normalized) return party;
    }
    return null;
  }

  @override
  Future<Party> save(Party value) {
    return _transactionRunner.run(() {
      final staged = createDemoSnapshot();
      final before = staged[value.entityId];
      final beforeReferences = _masterDataReferences[value.entityId];
      final saved = _stageSaveUnlocked(staged, value);
      final audit = _prepareSaveAudit(
        before: before,
        beforeReferences: beforeReferences,
        after: saved,
        afterReferences: _masterDataReferences[saved.entityId],
      );
      commitDemoSnapshot(staged);
      _recordIssuedIdentity(saved);
      if (audit != null) _businessAudit!.appendPrepared(audit);
      return saved;
    });
  }

  Party _stageSaveUnlocked(Map<EntityId, Party> staged, Party value) {
    final currentValues = staged.values;
    _captureIssuedIdentity(currentValues);
    if (value.number < 1) throw StateError('رقم الطرف غير صالح');
    final current = staged[value.entityId];
    if (current == null && _issuedIds.contains(value.entityId)) {
      throw StateError('معرف الطرف مستخدم مسبقاً');
    }
    if (current == null && _issuedNumbers.contains(value.number)) {
      throw StateError('رقم الطرف مستخدم مسبقاً');
    }
    if (current != null && current.number != value.number) {
      throw StateError('لا يمكن تغيير رقم طرف صادر');
    }
    final duplicate = currentValues.any(
      (party) =>
          party.entityId != value.entityId &&
          (party.number == value.number ||
              normalizePartyName(party.name) ==
                  normalizePartyName(value.name)),
    );
    if (duplicate) {
      throw StateError('يوجد طرف آخر بالرقم أو الاسم نفسه');
    }
    final normalized = current == null
        ? value
        : value.copyWithTyped(
            // Party profile fields can be edited from a stale screen, but
            // balances are read-only projections owned by business
            // transactions and must always come from the live record.
            iqdBalance: current.iqdBalance,
            usdBalance: current.usdBalance,
          );
    staged[normalized.entityId] = normalized;
    return normalized;
  }

  @override
  Future<Party> saveWithMasterData(
    Party party,
    PartyMasterDataReferences references,
  ) {
    return _transactionRunner.run(
      () => _saveWithMasterDataUnlocked(party, references),
    );
  }

  Future<Party> _saveWithMasterDataUnlocked(
    Party party,
    PartyMasterDataReferences references,
  ) async {
    final resolved = await _resolveMasterDataReferences(
      workplaceId: references.workplaceId,
      branchId: references.branchId,
    );
    final staged = createDemoSnapshot();
    final before = staged[party.entityId];
    final beforeReferences = _masterDataReferences[party.entityId];
    final saved = _stageSaveUnlocked(
      staged,
      party.copyWithTyped(
        workplace: resolved.workplaceName,
        branch: resolved.branchName,
      ),
    );
    final audit = _prepareSaveAudit(
      before: before,
      beforeReferences: beforeReferences,
      after: saved,
      afterReferences: resolved.references,
    );
    commitDemoSnapshot(staged);
    _recordIssuedIdentity(saved);
    _masterDataReferences[saved.entityId] = resolved.references;
    if (audit != null) _businessAudit!.appendPrepared(audit);
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
  Future<int> nextPartyNumber() {
    return _transactionRunner.run(() async {
      _captureIssuedIdentity(await getAll());
      return _highestIssuedNumber + 1;
    });
  }

  @override
  Future<Party> quickCreate(PartyQuickCreateRequest request) {
    return _transactionRunner.run(() async {
      final name = request.name.trim();
      if (normalizePartyName(name).isEmpty) {
        throw StateError('أدخل اسم الطرف أولاً');
      }
      final currentValues = await getAll();
      _captureIssuedIdentity(currentValues);
      if (currentValues.any(
        (party) => normalizePartyName(party.name) == normalizePartyName(name),
      )) {
        throw StateError('يوجد طرف آخر بالاسم نفسه');
      }
      final party = Party.typed(
        entityId: _issuePartyId(),
        number: _highestIssuedNumber + 1,
        createdTimestamp:
            request.createdTimestamp ?? AuditTimestamp(DateTime.now()),
        name: name,
        type: request.type,
        workplace: '',
        branch: '',
        phone: request.phone.trim(),
        alternatePhone: request.alternatePhone.trim(),
        city: request.city.trim(),
        address: request.address.trim(),
        notes: request.notes.trim(),
        iqdBalance: Money.zero(AppCurrency.iqd),
        usdBalance: Money.zero(AppCurrency.usd),
      );
      return _saveWithMasterDataUnlocked(
        party,
        PartyMasterDataReferences(
          workplaceId: request.workplaceId,
          branchId: request.branchId,
        ),
      );
    });
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    if (await getById(id) == null) {
      return const DeleteDecision.blocked('السجل غير موجود');
    }
    if (_initiallyReferencedIds.contains(id) || await _isReferenced(id)) {
      return const DeleteDecision.blocked(
        'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
    }
    return const DeleteDecision.allowed();
  }

  @override
  Future<void> delete(EntityId id) {
    return _transactionRunner.run(() async {
      _captureIssuedIdentity(await getAll());
      final decision = await canDelete(id);
      if (!decision.isAllowed) {
        throw StateError(decision.reason ?? 'لا يمكن حذف الطرف');
      }
      final staged = createDemoSnapshot();
      final existing = staged[id]!;
      final references = _masterDataReferences[id];
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: AuditAction.delete,
          outcome: AuditOutcome.success,
          summary: 'حذف الطرف ${existing.name}',
          before: partyAuditSnapshot(
            existing,
            references: references,
          ),
          details: const {'permanent': true},
          entityType: 'party',
          entityId: existing.entityId,
        ),
        permission: PermissionCode(
          module: 'parties',
          action: PermissionAction.delete,
        ),
      );
      staged.remove(id);
      commitDemoSnapshot(staged);
      _masterDataReferences.remove(id);
      if (audit != null) _businessAudit!.appendPrepared(audit);
    });
  }

  DemoPreparedBusinessAudit? _prepareSaveAudit({
    required Party? before,
    required PartyMasterDataReferences? beforeReferences,
    required Party after,
    required PartyMasterDataReferences? afterReferences,
  }) {
    final isCreate = before == null;
    return _businessAudit?.prepare(
      event: AuditEvent(
        action: isCreate ? AuditAction.create : AuditAction.update,
        outcome: AuditOutcome.success,
        summary: isCreate
            ? 'إضافة الطرف ${after.name}'
            : 'تحديث الطرف ${after.name}',
        before: before == null
            ? const <String, Object?>{}
            : partyAuditSnapshot(before, references: beforeReferences),
        after: partyAuditSnapshot(after, references: afterReferences),
        entityType: 'party',
        entityId: after.entityId,
      ),
      permission: PermissionCode(
        module: 'parties',
        action: isCreate ? PermissionAction.create : PermissionAction.update,
      ),
    );
  }

  Future<_ResolvedPartyMasterData> _resolveMasterDataReferences({
    required EntityId? workplaceId,
    required EntityId? branchId,
  }) async {
    if ((workplaceId == null) != (branchId == null)) {
      throw StateError('اختر جهة العمل والفرع معاً');
    }
    if (workplaceId == null || branchId == null) {
      return const _ResolvedPartyMasterData(
        references: PartyMasterDataReferences(),
        workplaceName: '',
        branchName: '',
      );
    }
    final workplace = await _masterData.getById(workplaceId);
    final branch = await _masterData.getById(branchId);
    if (workplace == null ||
        workplace.kind != OperationalMasterDataKind.workplace) {
      throw StateError('جهة العمل المحددة غير موجودة');
    }
    if (branch == null || branch.kind != OperationalMasterDataKind.branch) {
      throw StateError('الفرع المحدد غير موجود');
    }
    if (branch.parentId != workplaceId) {
      throw StateError('الفرع لا يتبع جهة العمل المحددة');
    }
    return _ResolvedPartyMasterData(
      references: PartyMasterDataReferences(
        workplaceId: workplaceId,
        branchId: branchId,
      ),
      workplaceName: workplace.name,
      branchName: branch.name,
    );
  }

  void _captureIssuedIdentity(Iterable<Party> parties) {
    for (final party in parties) {
      _recordIssuedIdentity(party);
    }
  }

  void _recordIssuedIdentity(Party party) {
    _issuedIds.add(party.entityId);
    _issuedNumbers.add(party.number);
    if (party.number > _highestIssuedNumber) {
      _highestIssuedNumber = party.number;
    }
  }

  EntityId _issuePartyId() {
    while (true) {
      final sequence = _nextGeneratedIdSequence++;
      final candidate = EntityId(
        'local-party-${sequence.toString().padLeft(6, '0')}',
      );
      if (!_issuedIds.contains(candidate)) return candidate;
    }
  }
}

class _ResolvedPartyMasterData {
  const _ResolvedPartyMasterData({
    required this.references,
    required this.workplaceName,
    required this.branchName,
  });

  final PartyMasterDataReferences references;
  final String workplaceName;
  final String branchName;
}

Future<bool> _neverReferenced(EntityId _) async => false;

Party _demoParty({
  required String id,
  required int number,
  required DateTime createdAt,
  required String name,
  required PartyType type,
  required String workplace,
  required String branch,
  required String phone,
  required String alternatePhone,
  required String city,
  required String address,
  required String notes,
  required num balanceIqd,
  required num balanceUsd,
}) {
  return Party.typed(
    entityId: EntityId(id),
    number: number,
    createdTimestamp: AuditTimestamp(createdAt),
    name: name,
    type: type,
    workplace: workplace,
    branch: branch,
    phone: phone,
    alternatePhone: alternatePhone,
    city: city,
    address: address,
    notes: notes,
    iqdBalance: Money.fromMajor(balanceIqd, AppCurrency.iqd),
    usdBalance: Money.fromMajor(balanceUsd, AppCurrency.usd),
  );
}

List<Party> demoParties() => [
      _demoParty(
        id: 'party-001',
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
        // Current balance after seeded cashbox receipt cashbox-001.
        balanceIqd: 500000,
        balanceUsd: 850,
      ),
      _demoParty(
        id: 'party-002',
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
        // Current balance after seeded cashbox receipt cashbox-006.
        balanceIqd: 0,
        balanceUsd: 0,
      ),
      _demoParty(
        id: 'party-003',
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
        // Includes the seeded unpaid USD operating expense.
        balanceUsd: -950,
      ),
      _demoParty(
        id: 'party-004',
        number: 4,
        createdAt: DateTime(2026, 7, 4, 8, 45),
        name: 'سارة محمود',
        type: PartyType.employee,
        workplace: 'الإدارة',
        branch: 'الرئيسي',
        phone: '07501231234',
        alternatePhone: '',
        city: 'أربيل',
        address: 'عينكاوة',
        notes: '',
        balanceIqd: 0,
        balanceUsd: 0,
      ),
      _demoParty(
        id: 'party-005',
        number: 5,
        createdAt: DateTime(2026, 7, 5, 12, 20),
        name: 'أسواق دجلة',
        type: PartyType.customer,
        workplace: 'تجارة الجملة',
        branch: 'النجف',
        phone: '07601110000',
        alternatePhone: '',
        city: 'النجف',
        address: 'حي الأمير',
        notes: '',
        balanceIqd: 840000,
        balanceUsd: 300,
      ),
      _demoParty(
        id: 'party-006',
        number: 6,
        createdAt: DateTime(2026, 7, 6, 9, 5),
        name: 'شركة الموصل الحديثة',
        type: PartyType.supplier,
        workplace: 'الأجهزة المكتبية',
        branch: 'الموصل',
        phone: '07705554433',
        alternatePhone: '',
        city: 'الموصل',
        address: 'المجموعة الثقافية',
        notes: '',
        balanceIqd: -950000,
        balanceUsd: -425,
      ),
      _demoParty(
        id: 'party-007',
        number: 7,
        createdAt: DateTime(2026, 7, 7, 14, 10),
        name: 'مكتب البصرة',
        type: PartyType.customer,
        workplace: 'الخدمات',
        branch: 'البصرة',
        phone: '07805556677',
        alternatePhone: '',
        city: 'البصرة',
        address: 'الجزائر',
        notes: '',
        balanceIqd: 210000,
        balanceUsd: 75,
      ),
      _demoParty(
        id: 'party-008',
        number: 8,
        createdAt: DateTime(2026, 7, 8, 10, 50),
        name: 'علي حسن',
        type: PartyType.customer,
        workplace: 'تجارة المفرد',
        branch: 'الكاظمية',
        phone: '07701110022',
        alternatePhone: '',
        city: 'بغداد',
        address: 'الكاظمية',
        notes: '',
        balanceIqd: 0,
        balanceUsd: 150,
      ),
      _demoParty(
        id: 'party-009',
        number: 9,
        createdAt: DateTime(2026, 7, 9, 13, 40),
        name: 'مجهز الفرات',
        type: PartyType.supplier,
        workplace: 'تجهيز المواد',
        branch: 'كربلاء',
        phone: '07604443322',
        alternatePhone: '',
        city: 'كربلاء',
        address: 'حي الحسين',
        notes: '',
        balanceIqd: -1725000,
        balanceUsd: 0,
      ),
      _demoParty(
        id: 'party-010',
        number: 10,
        createdAt: DateTime(2026, 7, 10, 8, 30),
        name: 'نور فاضل',
        type: PartyType.employee,
        workplace: 'المبيعات',
        branch: 'الرئيسي',
        phone: '07507778899',
        alternatePhone: '',
        city: 'أربيل',
        address: 'الإسكان',
        notes: '',
        balanceIqd: 0,
        balanceUsd: 0,
      ),
      _demoParty(
        id: 'party-011',
        number: 11,
        createdAt: DateTime(2026, 7, 11, 9, 20),
        name: 'شركة الرافدين للتجهيز',
        type: PartyType.supplier,
        workplace: 'تجهيز المواد',
        branch: 'البصرة',
        phone: '07709990011',
        alternatePhone: '',
        city: 'البصرة',
        address: 'العشار',
        notes: '',
        // Includes the added source line in purchase 101.
        balanceIqd: -540000,
        balanceUsd: 0,
      ),
      _demoParty(
        id: 'party-012',
        number: 12,
        createdAt: DateTime(2026, 7, 12, 10, 15),
        name: 'شركة التجارة العالمية',
        type: PartyType.supplier,
        workplace: 'الأجهزة المكتبية',
        branch: 'الموصل',
        phone: '07705550012',
        alternatePhone: '',
        city: 'الموصل',
        address: 'المجموعة الثقافية',
        notes: '',
        balanceIqd: 0,
        balanceUsd: -1250,
      ),
      _demoParty(
        id: 'party-013',
        number: 13,
        createdAt: DateTime(2026, 7, 13, 11, 10),
        name: 'مجهز الكرادة',
        type: PartyType.supplier,
        workplace: 'التجارة العامة',
        branch: 'بغداد',
        phone: '07701230013',
        alternatePhone: '',
        city: 'بغداد',
        address: 'الكرادة',
        notes: '',
        balanceIqd: -80000,
        balanceUsd: 0,
      ),
    ];

Map<EntityId, PartyMasterDataReferences> demoPartyMasterDataReferences() => {
      EntityId('party-001'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 1),
        branchId: EntityId.demo('branch', 1),
      ),
      EntityId('party-002'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 2),
        branchId: EntityId.demo('branch', 2),
      ),
      EntityId('party-003'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 3),
        branchId: EntityId.demo('branch', 3),
      ),
      EntityId('party-004'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 4),
        branchId: EntityId.demo('branch', 4),
      ),
      EntityId('party-005'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 5),
        branchId: EntityId.demo('branch', 5),
      ),
      EntityId('party-006'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 6),
        branchId: EntityId.demo('branch', 6),
      ),
      EntityId('party-007'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 7),
        branchId: EntityId.demo('branch', 7),
      ),
      EntityId('party-008'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 2),
        branchId: EntityId.demo('branch', 8),
      ),
      EntityId('party-009'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 3),
        branchId: EntityId.demo('branch', 9),
      ),
      EntityId('party-010'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 8),
        branchId: EntityId.demo('branch', 10),
      ),
      EntityId('party-011'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 3),
        branchId: EntityId.demo('branch', 3),
      ),
      EntityId('party-012'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 6),
        branchId: EntityId.demo('branch', 6),
      ),
      EntityId('party-013'): PartyMasterDataReferences(
        workplaceId: EntityId.demo('workplace', 1),
        branchId: EntityId.demo('branch', 1),
      ),
    };
