import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'permission_models.dart';

abstract interface class RoleRepository {
  Future<List<AppRole>> getAll();

  Future<AppRole?> getById(EntityId id);

  Future<AppRole> save(AppRole role);

  Future<DeleteDecision> canDelete(EntityId id);

  Future<void> delete(EntityId id);
}
