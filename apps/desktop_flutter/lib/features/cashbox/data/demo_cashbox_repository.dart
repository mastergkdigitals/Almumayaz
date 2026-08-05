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
  final Map<String, CashboxAccountBalance> _openingBalances;

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
        return CashboxMainAccount(
          id: record.id.value,
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
        return CashboxSubaccount(
          id: record.id.value,
          label: '${record.number} - ${record.name}',
          balanceIqd: balance.iqd.majorUnits,
          balanceUsd: balance.usd.majorUnits,
        );
      }),
    );
    return List.unmodifiable(accounts);
  }

  @override
  Future<CashboxVoucher> save(CashboxVoucher value) async {
    final mainId = EntityId(value.mainAccountId);
    final subId = EntityId(value.subaccountId);
    final mainExists = (await getMainAccounts()).any(
      (account) => account.id == mainId.value,
    );
    final subExists = (await getSubaccounts(mainId)).any(
      (account) => account.id == subId.value,
    );
    if (!mainExists || !subExists) {
      throw StateError('حساب الصندوق المحدد غير موجود');
    }
    final values = await getAll();
    final index = values.indexWhere((voucher) => voucher.id == value.id);
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
    return normalized.firstWhere((voucher) => voucher.id == value.id);
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
        .where((voucher) => voucher.subaccountId == subaccountId.value)
        .toList()
      ..sort((first, second) {
        final byDate = first.createdAt.compareTo(second.createdAt);
        return byDate != 0 ? byDate : first.number.compareTo(second.number);
      });
    if (vouchers.isEmpty) {
      final opening = _openingBalances[subaccountId.value];
      return CashboxBalanceSnapshot(
        iqd: Money.fromMajor(opening?.iqd ?? 0, AppCurrency.iqd),
        usd: Money.fromMajor(opening?.usd ?? 0, AppCurrency.usd),
      );
    }
    final latest = vouchers.last;
    return CashboxBalanceSnapshot(
      iqd: Money.fromMajor(latest.balanceAfterIqd, AppCurrency.iqd),
      usd: Money.fromMajor(latest.balanceAfterUsd, AppCurrency.usd),
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
        .map((account) => account.id.value)
        .toSet();
    if (relatedAccountIds.isEmpty) return const [];
    return List.unmodifiable(
      (await getAll()).where(
        (voucher) => relatedAccountIds.contains(voucher.subaccountId),
      ),
    );
  }

  @override
  Future<bool> referencesParty(EntityId partyId) async {
    final relatedAccounts = (await _masterData.getByKind(
      OperationalMasterDataKind.cashboxSubaccount,
    ))
        .where((account) => account.relatedEntityId == partyId)
        .map((account) => account.id.value)
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
      )).map((child) => child.id.value).toSet();
      return (await getAll()).any(
        (voucher) =>
            voucher.mainAccountId == masterDataId.value ||
            childIds.contains(voucher.subaccountId),
      );
    }
    if (record.kind == OperationalMasterDataKind.cashboxSubaccount) {
      return (await getAll()).any(
        (voucher) => voucher.subaccountId == masterDataId.value,
      );
    }
    return false;
  }

  List<CashboxVoucher> _normalizeBalances(List<CashboxVoucher> values) {
    final balances = <String, CashboxAccountBalance>{..._openingBalances};
    final chronological = [...values]..sort((first, second) {
        final byDate = first.createdAt.compareTo(second.createdAt);
        return byDate != 0 ? byDate : first.number.compareTo(second.number);
      });
    final normalized = <String, CashboxVoucher>{};
    for (final voucher in chronological) {
      final before = balances[voucher.subaccountId] ??
          CashboxAccountBalance(
            iqd: voucher.balanceBeforeIqd,
            usd: voucher.balanceBeforeUsd,
          );
      final direction =
          voucher.type == CashboxVoucherType.receipt ? -1 : 1;
      final after = CashboxAccountBalance(
        iqd: before.iqd + voucher.amountIqd * direction,
        usd: before.usd + voucher.amountUsd * direction,
      );
      balances[voucher.subaccountId] = after;
      normalized[voucher.id] = voucher.copyWith(
        balanceBeforeIqd: before.iqd,
        balanceAfterIqd: after.iqd,
        balanceBeforeUsd: before.usd,
        balanceAfterUsd: after.usd,
      );
    }
    return List.unmodifiable(
      values.map((voucher) => normalized[voucher.id]!),
    );
  }
}

Map<String, CashboxAccountBalance> _resolveOpeningBalances(
  Iterable<CashboxVoucher> values,
) {
  final chronological = values.toList()..sort((first, second) {
      final byDate = first.createdAt.compareTo(second.createdAt);
      return byDate != 0 ? byDate : first.number.compareTo(second.number);
    });
  final openings = <String, CashboxAccountBalance>{};
  for (final voucher in chronological) {
    openings.putIfAbsent(
      voucher.subaccountId,
      () => CashboxAccountBalance(
        iqd: voucher.balanceBeforeIqd,
        usd: voucher.balanceBeforeUsd,
      ),
    );
  }
  return Map.unmodifiable(openings);
}

List<CashboxVoucher> demoCashboxVouchers() => [
      CashboxVoucher(
        id: 'cashbox-001',
        number: 1,
        createdAt: DateTime(2026, 7, 27, 8, 30),
        type: CashboxVoucherType.receipt,
        mainAccountId: EntityId.demo('cashbox-main-account', 4).value,
        mainAccountLabel: 'الأطراف',
        subaccountId: EntityId.demo('cashbox-subaccount', 4).value,
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
      CashboxVoucher(
        id: 'cashbox-002',
        number: 2,
        createdAt: DateTime(2026, 7, 27, 9, 10),
        type: CashboxVoucherType.payment,
        mainAccountId: EntityId.demo('cashbox-main-account', 5).value,
        mainAccountLabel: 'المصاريف',
        subaccountId: EntityId.demo('cashbox-subaccount', 7).value,
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
      CashboxVoucher(
        id: 'cashbox-003',
        number: 3,
        createdAt: DateTime(2026, 7, 27, 10, 5),
        type: CashboxVoucherType.payment,
        mainAccountId: EntityId.demo('cashbox-main-account', 4).value,
        mainAccountLabel: 'الأطراف',
        subaccountId: EntityId.demo('cashbox-subaccount', 6).value,
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
      CashboxVoucher(
        id: 'cashbox-004',
        number: 4,
        createdAt: DateTime(2026, 7, 26, 11, 40),
        type: CashboxVoucherType.receipt,
        mainAccountId: EntityId.demo('cashbox-main-account', 6).value,
        mainAccountLabel: 'إيرادات أخرى',
        subaccountId: EntityId.demo('cashbox-subaccount', 10).value,
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
      CashboxVoucher(
        id: 'cashbox-005',
        number: 5,
        createdAt: DateTime(2026, 7, 25, 13, 15),
        type: CashboxVoucherType.payment,
        mainAccountId: EntityId.demo('cashbox-main-account', 5).value,
        mainAccountLabel: 'المصاريف',
        subaccountId: EntityId.demo('cashbox-subaccount', 8).value,
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
      CashboxVoucher(
        id: 'cashbox-006',
        number: 6,
        createdAt: DateTime(2026, 7, 24, 15, 20),
        type: CashboxVoucherType.receipt,
        mainAccountId: EntityId.demo('cashbox-main-account', 4).value,
        mainAccountLabel: 'الأطراف',
        subaccountId: EntityId.demo('cashbox-subaccount', 5).value,
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
