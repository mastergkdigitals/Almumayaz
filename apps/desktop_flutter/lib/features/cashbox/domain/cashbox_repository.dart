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

  /// Returns vouchers related to the party, including source-linked system
  /// postings. Consumers that already represent invoice settlement must
  /// exclude [CashboxVoucher.isSystemGenerated].
  Future<List<CashboxVoucher>> getByParty(EntityId partyId);

  Future<bool> referencesParty(EntityId partyId);

  Future<bool> referencesMasterData(EntityId masterDataId);
}

/// Capability exposed by repositories that retain issued-number history.
abstract interface class CashboxIssuedNumberRepository {
  /// Returns a number greater than every number ever issued, including
  /// deleted vouchers.
  Future<int> nextVoucherNumber();
}
