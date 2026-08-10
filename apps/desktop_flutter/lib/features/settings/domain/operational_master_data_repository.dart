import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'operational_master_data.dart';

abstract interface class OperationalMasterDataRepository
    implements AppRepository<OperationalMasterDataRecord> {
  Future<List<OperationalMasterDataRecord>> getByKind(
    OperationalMasterDataKind kind, {
    EntityId? parentId,
  });
}
