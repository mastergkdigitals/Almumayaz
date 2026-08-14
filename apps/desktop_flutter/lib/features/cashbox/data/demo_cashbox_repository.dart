import '../../../core/data/app_repository.dart';
import '../../../core/data/demo_transaction_runner.dart';
import '../../../core/domain/business_values.dart';
import '../../audit_log/data/demo_business_audit.dart';
import '../../audit_log/domain/audit_models.dart';
import '../../parties/data/demo_party_repository.dart';
import '../../permissions/domain/permission_models.dart';
import '../../settings/domain/operational_master_data.dart';
import '../../settings/domain/operational_master_data_repository.dart';
import '../domain/cashbox_repository.dart';
import '../domain/cashbox_voucher.dart';

class DemoSystemCashboxPosting {
  const DemoSystemCashboxPosting({
    required this.source,
    required this.createdTimestamp,
    required this.type,
    required this.exchangeRate,
    required this.amount,
    required this.notes,
  });

  final CashboxVoucherSource source;
  final AuditTimestamp createdTimestamp;
  final CashboxVoucherType type;
  final ExchangeRate exchangeRate;
  final Money amount;
  final String notes;
}

/// Backwards-compatible name retained for invoice coordinators.
typedef DemoInvoiceCashboxPosting = DemoSystemCashboxPosting;

/// Fully validated Cashbox projection waiting for a synchronous commit.
class DemoCashboxStagedMutation {
  const DemoCashboxStagedMutation._({
    required this.values,
    this.newlyIssuedNumber,
  });

  final Map<EntityId, CashboxVoucher> values;
  final int? newlyIssuedNumber;
}

class DemoCashboxRepository extends InMemoryDemoRepository<CashboxVoucher>
    implements CashboxRepository, CashboxIssuedNumberRepository {
  factory DemoCashboxRepository({
    Iterable<CashboxVoucher>? initialValues,
    required OperationalMasterDataRepository masterData,
    DemoPartyRepository? parties,
    DemoTransactionRunner? transactionRunner,
    CashboxBalanceSnapshot openingBalance = const CashboxBalanceSnapshot(
      iqd: Money.fromMinorUnits(9800000, AppCurrency.iqd),
      usd: Money.fromMinorUnits(450000, AppCurrency.usd),
    ),
    DemoBusinessAudit? businessAudit,
  }) {
    final values = List<CashboxVoucher>.of(
      initialValues ?? demoCashboxVouchers(),
    );
    final resolvedRunner = transactionRunner ?? DemoTransactionRunner();
    final resolvedParties = parties ??
        DemoPartyRepository(
          masterData: masterData,
          transactionRunner: resolvedRunner,
        );
    return DemoCashboxRepository._(
      initialValues: values,
      masterData: masterData,
      parties: resolvedParties,
      transactionRunner: resolvedRunner,
      openingBalance: openingBalance,
      businessAudit: businessAudit,
    );
  }

  DemoCashboxRepository._({
    required List<CashboxVoucher> initialValues,
    required OperationalMasterDataRepository masterData,
    required DemoPartyRepository parties,
    required DemoTransactionRunner transactionRunner,
    required CashboxBalanceSnapshot openingBalance,
    required DemoBusinessAudit? businessAudit,
  })  : _masterData = masterData,
        _parties = parties,
        _transactionRunner = transactionRunner,
        _openingBalance = openingBalance,
        _businessAudit = businessAudit,
        _openingBalances = _resolveOpeningBalances(initialValues),
        _highestIssuedNumber = _highestVoucherNumber(initialValues),
        _issuedNumbers = {
          for (final voucher in initialValues) voucher.number,
        },
        super(
          initialValues: initialValues,
          idOf: (voucher) => voucher.entityId,
        );

  final OperationalMasterDataRepository _masterData;
  final DemoPartyRepository _parties;
  final DemoTransactionRunner _transactionRunner;
  final CashboxBalanceSnapshot _openingBalance;
  final DemoBusinessAudit? _businessAudit;
  final Map<EntityId, CashboxAccountBalance> _openingBalances;
  int _highestIssuedNumber;
  final Set<int> _issuedNumbers;

  @override
  Future<List<CashboxVoucher>> search(String query) async {
    final normalized = query.trim().toLowerCase().replaceAll(',', '');
    final values = await getAll();
    if (normalized.isEmpty) return values;
    return List.unmodifiable(
      values.where(
        (voucher) =>
            voucher.searchText.replaceAll(',', '').contains(normalized),
      ),
    );
  }

  @override
  Future<List<CashboxMainAccount>> getMainAccounts() async {
    final mainRecords = await _masterData.getByKind(
      OperationalMasterDataKind.cashboxMainAccount,
    );
    return Future.wait(
      mainRecords.map((record) async {
        return CashboxMainAccount.typed(
          entityId: record.id,
          label: record.name,
          subaccounts: await getSubaccounts(record.id),
        );
      }),
    );
  }

  @override
  Future<List<CashboxSubaccount>> getSubaccounts(
    EntityId parentId,
  ) async {
    final records = await _masterData.getByKind(
      OperationalMasterDataKind.cashboxSubaccount,
      parentId: parentId,
    );
    final accounts = await Future.wait(
      records.map((record) async {
        final balance = await getBalance(record.id);
        return CashboxSubaccount.typed(
          entityId: record.id,
          label: '${record.number} - ${record.name}',
          iqdBalance: balance.iqd,
          usdBalance: balance.usd,
        );
      }),
    );
    return List.unmodifiable(accounts);
  }

  @override
  Future<CashboxVoucher> save(CashboxVoucher value) {
    return _transactionRunner.run(() async {
      if (value.isSystemGenerated) {
        throw StateError('لا يمكن حفظ قيد صندوق آلي يدوياً');
      }
      final existing = getDemoValue(value.entityId);
      if (existing?.isSystemGenerated ?? false) {
        throw StateError('لا يمكن تعديل قيد صندوق آلي');
      }
      _ensureManualNumberAvailable(value, existing: existing);
      final account = await _loadAccount(
        value.mainAccountEntityId,
        value.subaccountEntityId,
      );
      final normalizedValue = value.copyWithTyped(
        mainAccountLabel: account.main.name,
        subaccountLabel: '${account.sub.number} - ${account.sub.name}',
      );
      final partyAdjustments = <DemoPartyBalanceAdjustment>[
        if (existing != null)
          ...await _partyAdjustments(existing, direction: -1),
        ...await _partyAdjustments(normalizedValue, direction: 1),
      ];
      final stagedCashbox = _stageUpsert(
        normalizedValue,
        newlyIssuedNumber: existing == null ? value.number : null,
      );
      final stagedParties = _parties.stageBalanceAdjustments(
        partyAdjustments,
      );
      final saved = stagedCashbox.values[value.entityId]!;
      final isCreate = existing == null;
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: isCreate ? AuditAction.create : AuditAction.update,
          outcome: AuditOutcome.success,
          summary: isCreate
              ? 'إضافة سند الصندوق رقم ${saved.number}'
              : 'تحديث سند الصندوق رقم ${saved.number}',
          before: existing == null
              ? const <String, Object?>{}
              : cashboxVoucherAuditSnapshot(existing),
          after: cashboxVoucherAuditSnapshot(saved),
          details: const {'systemGenerated': false},
          entityType: 'cashbox_voucher',
          entityId: saved.entityId,
        ),
        permission: PermissionCode(
          module: 'cashbox',
          action:
              isCreate ? PermissionAction.create : PermissionAction.update,
        ),
      );

      commitCashboxMutation(stagedCashbox);
      _parties.commitPartySnapshot(stagedParties);
      if (audit != null) _businessAudit!.appendPrepared(audit);
      return saved;
    });
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    final existing = getDemoValue(id);
    if (existing == null) {
      return const DeleteDecision.blocked('السجل غير موجود');
    }
    if (existing.isSystemGenerated) {
      return const DeleteDecision.blocked(
        'لا يمكن حذف قيد صندوق مولد آلياً',
      );
    }
    return const DeleteDecision.allowed();
  }

  @override
  Future<void> delete(EntityId id) {
    return _transactionRunner.run(() async {
      final existing = getDemoValue(id);
      if (existing == null) throw StateError('السجل غير موجود');
      if (existing.isSystemGenerated) {
        throw StateError('لا يمكن حذف قيد صندوق مولد آلياً');
      }
      final stagedParties = _parties.stageBalanceAdjustments(
        await _partyAdjustments(existing, direction: -1),
      );
      final stagedCashbox = _stageRemove(existing.entityId);
      final audit = _businessAudit?.prepare(
        event: AuditEvent(
          action: AuditAction.delete,
          outcome: AuditOutcome.success,
          summary: 'حذف سند الصندوق رقم ${existing.number}',
          before: cashboxVoucherAuditSnapshot(existing),
          details: const {
            'permanent': true,
            'systemGenerated': false,
          },
          entityType: 'cashbox_voucher',
          entityId: existing.entityId,
        ),
        permission: PermissionCode(
          module: 'cashbox',
          action: PermissionAction.delete,
        ),
      );

      commitCashboxMutation(stagedCashbox);
      _parties.commitPartySnapshot(stagedParties);
      if (audit != null) _businessAudit!.appendPrepared(audit);
    });
  }

  @override
  Future<CashboxBalanceSnapshot> getBalance(EntityId subaccountId) async {
    final record = await _masterData.getById(subaccountId);
    final exists =
        record?.kind == OperationalMasterDataKind.cashboxSubaccount;
    if (!exists) throw StateError('الحساب الفرعي غير موجود');
    final vouchers = (await getAll())
        .where((voucher) => voucher.subaccountEntityId == subaccountId)
        .toList()
      ..sort((first, second) {
        final byDate =
            first.createdTimestamp.compareTo(second.createdTimestamp);
        return byDate != 0 ? byDate : first.number.compareTo(second.number);
      });
    if (vouchers.isEmpty) {
      final opening = _openingBalances[subaccountId];
      return CashboxBalanceSnapshot(
        iqd: opening?.iqdMoney ?? Money.zero(AppCurrency.iqd),
        usd: opening?.usdMoney ?? Money.zero(AppCurrency.usd),
      );
    }
    final latest = vouchers.last;
    return CashboxBalanceSnapshot(
      iqd: latest.iqdBalanceAfter,
      usd: latest.usdBalanceAfter,
    );
  }

  @override
  Future<CashboxBalanceSnapshot> getOpeningBalance() async => _openingBalance;

  @override
  Future<int> nextVoucherNumber() async => _highestIssuedNumber + 1;

  /// Stages creation, replacement, or zero-amount removal of the one system
  /// voucher owned by [posting.source]. The caller must already own the
  /// shared transaction runner and must commit with [commitCashboxMutation].
  Future<DemoCashboxStagedMutation> stageInvoicePosting(
    DemoInvoiceCashboxPosting posting,
  ) =>
      stageSystemPosting(posting);

  /// Stages the single read-only Cashbox voucher owned by [posting.source].
  /// Invoice receipts, purchase payments and installment settlements share
  /// this path so source identity and issued-number retention stay uniform.
  Future<DemoCashboxStagedMutation> stageSystemPosting(
    DemoSystemCashboxPosting posting,
  ) async {
    final existing = _sourceVoucher(posting.source);
    if (posting.amount.isZero) {
      return existing == null
          ? DemoCashboxStagedMutation._(values: createDemoSnapshot())
          : _stageRemove(existing.entityId);
    }
    if (posting.amount.isNegative) {
      throw StateError('مبلغ قيد الصندوق الآلي لا يمكن أن يكون سالباً');
    }
    final accounts = await _loadPostingAccount();
    final number = existing?.number ?? _highestIssuedNumber + 1;
    final entityId = existing?.entityId ?? _sourceVoucherId(posting.source);
    final collision = getDemoValue(entityId);
    if (collision != null && collision.entityId != existing?.entityId) {
      throw StateError('معرف قيد الصندوق الآلي مستخدم مسبقاً');
    }
    final zeroIqd = Money.zero(AppCurrency.iqd);
    final zeroUsd = Money.zero(AppCurrency.usd);
    final value = CashboxVoucher.typed(
      entityId: entityId,
      number: number,
      createdTimestamp: posting.createdTimestamp,
      type: posting.type,
      mainAccountEntityId: accounts.main.id,
      mainAccountLabel: accounts.main.name,
      subaccountEntityId: accounts.sub.id,
      subaccountLabel: '${accounts.sub.number} - ${accounts.sub.name}',
      exchangeRateValue: posting.exchangeRate,
      iqdAmount:
          posting.amount.currency == AppCurrency.iqd ? posting.amount : zeroIqd,
      usdAmount:
          posting.amount.currency == AppCurrency.usd ? posting.amount : zeroUsd,
      iqdBalanceBefore: existing?.iqdBalanceBefore ?? zeroIqd,
      iqdBalanceAfter: existing?.iqdBalanceAfter ?? zeroIqd,
      usdBalanceBefore: existing?.usdBalanceBefore ?? zeroUsd,
      usdBalanceAfter: existing?.usdBalanceAfter ?? zeroUsd,
      notes: posting.notes,
      source: posting.source,
    );
    return _stageUpsert(
      value,
      newlyIssuedNumber: existing == null ? number : null,
    );
  }

  /// Stages removal of the system posting for an invoice. Issued voucher
  /// numbers remain reserved after the posting is removed.
  DemoCashboxStagedMutation stageRemoveInvoicePosting(
    CashboxVoucherSource source,
  ) =>
      stageRemoveSystemPosting(source);

  DemoCashboxStagedMutation stageRemoveSystemPosting(
    CashboxVoucherSource source,
  ) {
    final existing = _sourceVoucher(source);
    return existing == null
        ? DemoCashboxStagedMutation._(values: createDemoSnapshot())
        : _stageRemove(existing.entityId);
  }

  /// Removes several source-owned vouchers and normalizes balances once.
  /// Issued voucher numbers remain reserved by design.
  DemoCashboxStagedMutation stageRemoveSystemPostings(
    Iterable<CashboxVoucherSource> sources,
  ) {
    final sourceKeys = {
      for (final source in sources) _sourceKey(source),
    };
    if (sourceKeys.isEmpty) {
      return DemoCashboxStagedMutation._(values: createDemoSnapshot());
    }
    final staged = createDemoSnapshot();
    staged.removeWhere((_, voucher) {
      final source = voucher.source;
      return source != null && sourceKeys.contains(_sourceKey(source));
    });
    return DemoCashboxStagedMutation._(
      values: {
        for (final voucher in _normalizeBalances(staged.values.toList()))
          voucher.entityId: voucher,
      },
    );
  }

  /// Synchronous/no-fail final commit used by the invoice coordinator.
  void commitCashboxMutation(DemoCashboxStagedMutation staged) {
    commitDemoSnapshot(staged.values);
    final issuedNumber = staged.newlyIssuedNumber;
    if (issuedNumber == null) return;
    _issuedNumbers.add(issuedNumber);
    if (issuedNumber > _highestIssuedNumber) {
      _highestIssuedNumber = issuedNumber;
    }
  }

  @override
  Future<List<CashboxVoucher>> getByParty(EntityId partyId) async {
    final relatedAccountIds = (await _masterData.getByKind(
      OperationalMasterDataKind.cashboxSubaccount,
    ))
        .where((account) => account.relatedEntityId == partyId)
        .map((account) => account.id)
        .toSet();
    return List.unmodifiable(
      (await getAll()).where(
        (voucher) =>
            relatedAccountIds.contains(voucher.subaccountEntityId) ||
            voucher.source?.partyId == partyId,
      ),
    );
  }

  @override
  Future<bool> referencesParty(EntityId partyId) async {
    final relatedAccounts = (await _masterData.getByKind(
      OperationalMasterDataKind.cashboxSubaccount,
    ))
        .where((account) => account.relatedEntityId == partyId)
        .map((account) => account.id)
        .toSet();
    if (relatedAccounts.isNotEmpty) return true;
    return (await getAll()).any(
      (voucher) => voucher.source?.partyId == partyId,
    );
  }

  @override
  Future<bool> referencesMasterData(EntityId masterDataId) async {
    final record = await _masterData.getById(masterDataId);
    if (record == null) return false;
    if (record.kind == OperationalMasterDataKind.cashboxMainAccount) {
      final childIds = (await _masterData.getByKind(
        OperationalMasterDataKind.cashboxSubaccount,
        parentId: record.id,
      )).map((child) => child.id).toSet();
      return (await getAll()).any(
        (voucher) =>
            voucher.mainAccountEntityId == masterDataId ||
            childIds.contains(voucher.subaccountEntityId),
      );
    }
    if (record.kind == OperationalMasterDataKind.cashboxSubaccount) {
      return (await getAll()).any(
        (voucher) => voucher.subaccountEntityId == masterDataId,
      );
    }
    return false;
  }

  void _ensureManualNumberAvailable(
    CashboxVoucher value, {
    required CashboxVoucher? existing,
  }) {
    if (value.number < 1) {
      throw StateError('رقم سند الصندوق يجب أن يكون موجباً');
    }
    if (existing != null && existing.number != value.number) {
      throw StateError('لا يمكن تغيير رقم سند صندوق صادر');
    }
    if (existing == null && _issuedNumbers.contains(value.number)) {
      throw StateError('رقم سند الصندوق مستخدم مسبقاً');
    }
  }

  Future<({
    OperationalMasterDataRecord main,
    OperationalMasterDataRecord sub,
  })> _loadAccount(EntityId mainId, EntityId subId) async {
    final main = await _masterData.getById(mainId);
    final sub = await _masterData.getById(subId);
    if (main?.kind != OperationalMasterDataKind.cashboxMainAccount ||
        sub?.kind != OperationalMasterDataKind.cashboxSubaccount ||
        sub?.parentId != mainId) {
      throw StateError('حساب الصندوق المحدد غير موجود');
    }
    return (main: main!, sub: sub!);
  }

  Future<({
    OperationalMasterDataRecord main,
    OperationalMasterDataRecord sub,
  })> _loadPostingAccount() async {
    // Invoice Party balances already contain the authoritative net invoice
    // effect. Generated received/paid postings therefore use a generic
    // settlement account and retain Party linkage only in source metadata.
    final fallbackMainId = EntityId.demo('cashbox-main-account', 1);
    final fallbackSubId = EntityId.demo('cashbox-subaccount', 1);
    final main = await _masterData.getById(fallbackMainId);
    final sub = await _masterData.getById(fallbackSubId);
    if (main?.kind == OperationalMasterDataKind.cashboxMainAccount &&
        sub?.kind == OperationalMasterDataKind.cashboxSubaccount &&
        sub?.parentId == fallbackMainId &&
        sub?.relatedEntityId == null) {
      return (main: main!, sub: sub!);
    }
    throw StateError('حساب تسويات الفواتير الآلي غير موجود');
  }

  Future<List<DemoPartyBalanceAdjustment>> _partyAdjustments(
    CashboxVoucher voucher, {
    required int direction,
  }) async {
    final subaccount = await _masterData.getById(
      voucher.subaccountEntityId,
    );
    final partyId = subaccount?.relatedEntityId;
    if (partyId == null) return const [];
    final voucherDirection =
        voucher.type == CashboxVoucherType.receipt ? -1 : 1;
    final multiplier = voucherDirection * direction;
    return [
      DemoPartyBalanceAdjustment(
        partyId: partyId,
        delta: voucher.iqdAmount * multiplier,
      ),
      DemoPartyBalanceAdjustment(
        partyId: partyId,
        delta: voucher.usdAmount * multiplier,
      ),
    ];
  }

  CashboxVoucher? _sourceVoucher(CashboxVoucherSource source) {
    final matches = createDemoSnapshot().values.where((voucher) {
      final candidate = voucher.source;
      return candidate?.kind == source.kind &&
          candidate?.sourceId == source.sourceId;
    }).toList();
    if (matches.length > 1) {
      throw StateError('يوجد أكثر من قيد صندوق للمصدر نفسه');
    }
    return matches.isEmpty ? null : matches.single;
  }

  EntityId _sourceVoucherId(CashboxVoucherSource source) {
    return EntityId(
      'cashbox-system-${source.kind.name}-${source.sourceId.value}',
    );
  }

  String _sourceKey(CashboxVoucherSource source) =>
      '${source.kind.name}\u001f${source.sourceId.value}';

  DemoCashboxStagedMutation _stageUpsert(
    CashboxVoucher value, {
    required int? newlyIssuedNumber,
  }) {
    final staged = createDemoSnapshot()..[value.entityId] = value;
    return DemoCashboxStagedMutation._(
      values: {
        for (final voucher in _normalizeBalances(staged.values.toList()))
          voucher.entityId: voucher,
      },
      newlyIssuedNumber: newlyIssuedNumber,
    );
  }

  DemoCashboxStagedMutation _stageRemove(EntityId id) {
    final staged = createDemoSnapshot()..remove(id);
    return DemoCashboxStagedMutation._(
      values: {
        for (final voucher in _normalizeBalances(staged.values.toList()))
          voucher.entityId: voucher,
      },
    );
  }

  List<CashboxVoucher> _normalizeBalances(List<CashboxVoucher> values) {
    final balances = <EntityId, CashboxAccountBalance>{..._openingBalances};
    final chronological = [...values]..sort((first, second) {
        final byDate =
            first.createdTimestamp.compareTo(second.createdTimestamp);
        return byDate != 0 ? byDate : first.number.compareTo(second.number);
      });
    final normalized = <EntityId, CashboxVoucher>{};
    for (final voucher in chronological) {
      final before = balances[voucher.subaccountEntityId] ??
          CashboxAccountBalance.typed(
            iqdMoney: voucher.iqdBalanceBefore,
            usdMoney: voucher.usdBalanceBefore,
          );
      final direction =
          voucher.type == CashboxVoucherType.receipt ? -1 : 1;
      final after = CashboxAccountBalance.typed(
        iqdMoney: before.iqdMoney + voucher.iqdAmount * direction,
        usdMoney: before.usdMoney + voucher.usdAmount * direction,
      );
      balances[voucher.subaccountEntityId] = after;
      normalized[voucher.entityId] = voucher.copyWithTyped(
        iqdBalanceBefore: before.iqdMoney,
        iqdBalanceAfter: after.iqdMoney,
        usdBalanceBefore: before.usdMoney,
        usdBalanceAfter: after.usdMoney,
      );
    }
    return List.unmodifiable(
      values.map((voucher) => normalized[voucher.entityId]!),
    );
  }
}

Map<EntityId, CashboxAccountBalance> _resolveOpeningBalances(
  Iterable<CashboxVoucher> values,
) {
  final chronological = values.toList()..sort((first, second) {
      final byDate =
          first.createdTimestamp.compareTo(second.createdTimestamp);
      return byDate != 0 ? byDate : first.number.compareTo(second.number);
    });
  final openings = <EntityId, CashboxAccountBalance>{};
  for (final voucher in chronological) {
    openings.putIfAbsent(
      voucher.subaccountEntityId,
      () => CashboxAccountBalance.typed(
        iqdMoney: voucher.iqdBalanceBefore,
        usdMoney: voucher.usdBalanceBefore,
      ),
    );
  }
  return Map.unmodifiable(openings);
}

int _highestVoucherNumber(Iterable<CashboxVoucher> values) {
  var highest = 0;
  for (final voucher in values) {
    if (voucher.number > highest) highest = voucher.number;
  }
  return highest;
}

CashboxVoucher _demoCashboxVoucher({
  required String id,
  required int number,
  required DateTime createdAt,
  required CashboxVoucherType type,
  required EntityId mainAccountId,
  required String mainAccountLabel,
  required EntityId subaccountId,
  required String subaccountLabel,
  required num exchangeRate,
  required num amountIqd,
  required num amountUsd,
  required num balanceBeforeIqd,
  required num balanceAfterIqd,
  required num balanceBeforeUsd,
  required num balanceAfterUsd,
  required String notes,
}) {
  return CashboxVoucher.typed(
    entityId: EntityId(id),
    number: number,
    createdTimestamp: AuditTimestamp(createdAt),
    type: type,
    mainAccountEntityId: mainAccountId,
    mainAccountLabel: mainAccountLabel,
    subaccountEntityId: subaccountId,
    subaccountLabel: subaccountLabel,
    exchangeRateValue: ExchangeRate.parse(exchangeRate.toString()),
    iqdAmount: Money.fromMajor(amountIqd, AppCurrency.iqd),
    usdAmount: Money.fromMajor(amountUsd, AppCurrency.usd),
    iqdBalanceBefore: Money.fromMajor(balanceBeforeIqd, AppCurrency.iqd),
    iqdBalanceAfter: Money.fromMajor(balanceAfterIqd, AppCurrency.iqd),
    usdBalanceBefore: Money.fromMajor(balanceBeforeUsd, AppCurrency.usd),
    usdBalanceAfter: Money.fromMajor(balanceAfterUsd, AppCurrency.usd),
    notes: notes,
  );
}

List<CashboxVoucher> demoCashboxVouchers() => [
      _demoCashboxVoucher(
        id: 'cashbox-001',
        number: 1,
        createdAt: DateTime(2026, 7, 27, 8, 30),
        type: CashboxVoucherType.receipt,
        mainAccountId: EntityId.demo('cashbox-main-account', 4),
        mainAccountLabel: 'الأطراف',
        subaccountId: EntityId.demo('cashbox-subaccount', 4),
        subaccountLabel: '1 - شركة النخيل للتجارة',
        exchangeRate: 1310,
        amountIqd: 750000,
        amountUsd: 0,
        balanceBeforeIqd: 1250000,
        balanceAfterIqd: 500000,
        balanceBeforeUsd: 850,
        balanceAfterUsd: 850,
        notes: 'دفعة على الحساب',
      ),
      _demoCashboxVoucher(
        id: 'cashbox-002',
        number: 2,
        createdAt: DateTime(2026, 7, 27, 9, 10),
        type: CashboxVoucherType.payment,
        mainAccountId: EntityId.demo('cashbox-main-account', 5),
        mainAccountLabel: 'المصاريف',
        subaccountId: EntityId.demo('cashbox-subaccount', 7),
        subaccountLabel: 'نقل',
        exchangeRate: 1310,
        amountIqd: 125000,
        amountUsd: 0,
        balanceBeforeIqd: 0,
        balanceAfterIqd: 125000,
        balanceBeforeUsd: 0,
        balanceAfterUsd: 0,
        notes: 'نقل مواد إلى المخزن',
      ),
      _demoCashboxVoucher(
        id: 'cashbox-003',
        number: 3,
        createdAt: DateTime(2026, 7, 27, 10, 5),
        type: CashboxVoucherType.payment,
        mainAccountId: EntityId.demo('cashbox-main-account', 4),
        mainAccountLabel: 'الأطراف',
        subaccountId: EntityId.demo('cashbox-subaccount', 6),
        subaccountLabel: '3 - مجهز الرافدين',
        exchangeRate: 1310,
        amountIqd: 0,
        amountUsd: 400,
        balanceBeforeIqd: -3200000,
        balanceAfterIqd: -3200000,
        balanceBeforeUsd: -1200,
        balanceAfterUsd: -800,
        notes: 'تسديد جزء من الرصيد',
      ),
      _demoCashboxVoucher(
        id: 'cashbox-004',
        number: 4,
        createdAt: DateTime(2026, 7, 26, 11, 40),
        type: CashboxVoucherType.receipt,
        mainAccountId: EntityId.demo('cashbox-main-account', 6),
        mainAccountLabel: 'إيرادات أخرى',
        subaccountId: EntityId.demo('cashbox-subaccount', 10),
        subaccountLabel: 'خدمات',
        exchangeRate: 1310,
        amountIqd: 300000,
        amountUsd: 0,
        balanceBeforeIqd: 0,
        balanceAfterIqd: -300000,
        balanceBeforeUsd: 0,
        balanceAfterUsd: 0,
        notes: '',
      ),
      _demoCashboxVoucher(
        id: 'cashbox-005',
        number: 5,
        createdAt: DateTime(2026, 7, 25, 13, 15),
        type: CashboxVoucherType.payment,
        mainAccountId: EntityId.demo('cashbox-main-account', 5),
        mainAccountLabel: 'المصاريف',
        subaccountId: EntityId.demo('cashbox-subaccount', 8),
        subaccountLabel: 'صيانة',
        exchangeRate: 1310,
        amountIqd: 85000,
        amountUsd: 0,
        balanceBeforeIqd: 125000,
        balanceAfterIqd: 210000,
        balanceBeforeUsd: 0,
        balanceAfterUsd: 0,
        notes: 'صيانة أجهزة المكتب',
      ),
      _demoCashboxVoucher(
        id: 'cashbox-006',
        number: 6,
        createdAt: DateTime(2026, 7, 24, 15, 20),
        type: CashboxVoucherType.receipt,
        mainAccountId: EntityId.demo('cashbox-main-account', 4),
        mainAccountLabel: 'الأطراف',
        subaccountId: EntityId.demo('cashbox-subaccount', 5),
        subaccountLabel: '2 - أحمد كريم',
        exchangeRate: 1310,
        amountIqd: 475000,
        amountUsd: 0,
        balanceBeforeIqd: 475000,
        balanceAfterIqd: 0,
        balanceBeforeUsd: 0,
        balanceAfterUsd: 0,
        notes: 'تسديد كامل الرصيد',
      ),
    ];
