import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'user_models.dart';

abstract interface class UserRepository {
  Future<List<AppUser>> search(UserQuery query);

  Future<AppUser?> getById(EntityId id);

  Future<AppUser> save(AppUser user);

  Future<AppUser> setStatus(EntityId id, UserAccountStatus status);

  Future<DeleteDecision> canDelete(EntityId id);

  Future<void> delete(EntityId id);
}
