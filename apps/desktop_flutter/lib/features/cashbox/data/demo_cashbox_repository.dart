import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../settings/domain/operational_master_data.dart';
import '../../settings/domain/operational_master_data_repository.dart';
import '../domain/cashbox_repository.dart';
import '../domain/cashbox_voucher.dart';

class DemoCashboxRepository extends InMemoryDemoRepository<CashboxVoucher>
    implements CashboxRepository {
  factory DemoCashboxRepository({
    Iterable<CashboxVoucher>? initialValues,
    required OperationalMasterDataRepository masterData,
    CashboxBalanceSnapshot openingBalance = const CashboxBalanceSnapshot(
      iqd: Money.fromMinorUnits(9800000, AppCurrency.iqd),
      usd: Money.fromMinorUnits(450000, AppCurrency.usd),
    ),
  }) {
    final values = List<CashboxVoucher>.of(
      initialValues ?? demoCashboxVouchers(),
    );
    return DemoCashboxRepository._(
      initialValues: values,
      masterData: masterData,
      openingBalance: openingBalance,
    );
  }

  DemoCashboxRepository._({
    required List<CashboxVoucher> initialValues,
    required OperationalMasterDataRepository masterData,
    required CashboxBalanceSnapshot openingBalance,
  })  : _masterData = masterData,
        _openingBalance = openingBalance,
        _openingBalances = _resolveOpeningBalances(initialValues),
        super(
          initialValues: initialValues,
          idOf: (voucher) => voucher.entityId,
        );

  final OperationalMasterDataRepository _masterData;
  final CashboxBalanceSnapshot _openingBalance;
  final Map<EntityId, CashboxAccountBalance> _openingBalances;

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
  Future<CashboxVoucher> save(CashboxVoucher value) async {
    final mainId = value.mainAccountEntityId;
    final subId = value.subaccountEntityId;
    final mainExists = (await getMainAccounts()).any(
      (account) => account.entityId == mainId,
    );
    final subExists = (await getSubaccounts(mainId)).any(
      (account) => account.entityId == subId,
    );
    if (!mainExists || !subExists) {
      throw StateError('حساب الصندوق المحدد غير موجود');
    }
    final values = await getAll();
    final index = values.indexWhere(
      (voucher) => voucher.entityId == value.entityId,
    );
    final updated = [...values];
    if (index < 0) {
      updated.add(value);
    } else {
      updated[index] = value;
    }
    final normalized = _normalizeBalances(updated);
    for (final voucher in normalized) {
      await super.save(voucher);
    }
    return normalized.firstWhere(
      (voucher) => voucher.entityId == value.entityId,
    );
  }

  @override
  Future<void> delete(EntityId id) async {
    await super.delete(id);
    final normalized = _normalizeBalances(await getAll());
    for (final voucher in normalized) {
      await super.save(voucher);
    }
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
  Future<List<CashboxVoucher>> getByParty(EntityId partyId) async {
    final relatedAccountIds = (await _masterData.getByKind(
      OperationalMasterDataKind.cashboxSubaccount,
    ))
        .where((account) => account.relatedEntityId == partyId)
        .map((account) => account.id)
        .toSet();
    if (relatedAccountIds.isEmpty) return const [];
    return List.unmodifiable(
      (await getAll()).where(
        (voucher) => relatedAccountIds.contains(voucher.subaccountEntityId),
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
    return relatedAccounts.isNotEmpty;
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
