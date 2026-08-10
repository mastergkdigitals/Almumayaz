import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'cashbox_voucher.dart';

class CashboxBalanceSnapshot {
  const CashboxBalanceSnapshot({
    required this.iqd,
    required this.usd,
  });

  final Money iqd;
  final Money usd;
}

abstract interface class CashboxRepository
    implements AppRepository<CashboxVoucher> {
  Future<List<CashboxVoucher>> search(String query);

  Future<List<CashboxMainAccount>> getMainAccounts();

  Future<List<CashboxSubaccount>> getSubaccounts(EntityId parentId);

  Future<CashboxBalanceSnapshot> getBalance(EntityId subaccountId);

  Future<CashboxBalanceSnapshot> getOpeningBalance();

  /// Returns vouchers posted to the party's canonical cashbox subaccount.
  Future<List<CashboxVoucher>> getByParty(EntityId partyId);

  Future<bool> referencesParty(EntityId partyId);

  Future<bool> referencesMasterData(EntityId masterDataId);
}
