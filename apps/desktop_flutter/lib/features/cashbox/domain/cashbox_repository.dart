import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'cashbox_voucher.dart';

extension CashboxVoucherRepositoryIdentity on CashboxVoucher {
  EntityId get entityId => EntityId(id);
}

extension CashboxMainAccountRepositoryIdentity on CashboxMainAccount {
  EntityId get entityId => EntityId(id);
}

extension CashboxSubaccountRepositoryIdentity on CashboxSubaccount {
  EntityId get entityId => EntityId(id);
}

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

  Future<bool> referencesParty(EntityId partyId);

  Future<bool> referencesMasterData(EntityId masterDataId);
}
