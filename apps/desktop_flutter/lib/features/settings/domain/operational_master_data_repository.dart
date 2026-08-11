import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'operational_master_data.dart';

class CreateOperationalMasterDataRequest {
  const CreateOperationalMasterDataRequest({
    required this.kind,
    required this.name,
    this.parentId,
  });

  final OperationalMasterDataKind kind;
  final String name;
  final EntityId? parentId;
}

class CreateCashboxAccountPairRequest {
  const CreateCashboxAccountPairRequest({
    required this.mainAccountName,
    required this.firstSubaccountName,
  });

  final String mainAccountName;
  final String firstSubaccountName;
}

class OperationalCashboxAccountPair {
  const OperationalCashboxAccountPair({
    required this.mainAccount,
    required this.subaccount,
  });

  final OperationalMasterDataRecord mainAccount;
  final OperationalMasterDataRecord subaccount;
}

abstract interface class OperationalMasterDataRepository
    implements AppRepository<OperationalMasterDataRecord> {
  Future<List<OperationalMasterDataRecord>> getByKind(
    OperationalMasterDataKind kind, {
    EntityId? parentId,
  });

  /// Issues identity and a visible number inside the repository mutation
  /// boundary. Visible numbers remain consumed after deletion.
  Future<OperationalMasterDataRecord> createNamedRecord(
    CreateOperationalMasterDataRequest request,
  );

  /// Creates a main cashbox account and its first child as one mutation.
  Future<OperationalCashboxAccountPair> createCashboxAccountPair(
    CreateCashboxAccountPairRequest request,
  );
}
