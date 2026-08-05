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
  }) {
    final values = List<CashboxVoucher>.of(
      initialValues ?? demoCashboxVouchers(),
    );
    return DemoCashboxRepository._(
      initialValues: values,
      masterData: masterData,
    );
  }

  DemoCashboxRepository._({
    required List<CashboxVoucher> initialValues,
    required OperationalMasterDataRepository masterData,
  })  : _masterData = masterData,
        _openingBalances = _resolveOpeningBalances(initialValues),
        super(
          initialValues: initialValues,
          idOf: (voucher) => voucher.entityId,
        );

  final OperationalMasterDataRepository _masterData;
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
          label: '${record.number} - ${record.name}',
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
    return List.unmodifiable(
      records.map(
        (record) => CashboxSubaccount(
          id: record.id.value,
          label: '${record.number} - ${record.name}',
          balanceIqd: 0,
          balanceUsd: 0,
        ),
      ),
    );
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
        id: EntityId.demo('cashbox-voucher', 1).value,
        number: 1,
        createdAt: DateTime(2026, 7, 27, 8, 30),
        type: CashboxVoucherType.receipt,
        mainAccountId: EntityId.demo('cashbox-main-account', 1).value,
        mainAccountLabel: 'الأطراف',
        subaccountId: EntityId.demo('cashbox-subaccount', 1).value,
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
        id: EntityId.demo('cashbox-voucher', 2).value,
        number: 2,
        createdAt: DateTime(2026, 7, 27, 9, 10),
        type: CashboxVoucherType.payment,
        mainAccountId: EntityId.demo('cashbox-main-account', 2).value,
        mainAccountLabel: 'المصاريف',
        subaccountId: EntityId.demo('cashbox-subaccount', 2).value,
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
    ];
