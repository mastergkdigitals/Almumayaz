import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/services/service_failure.dart';
import '../domain/user_models.dart';
import '../domain/user_repository.dart';

class DemoUserRepository implements UserRepository {
  DemoUserRepository({Iterable<AppUser>? initialUsers})
      : _users = {
          for (final user in initialUsers ?? demoUsers()) user.id: user,
        };

  final Map<EntityId, AppUser> _users;

  @override
  Future<List<AppUser>> search(UserQuery query) async {
    final text = query.searchText.trim().toLowerCase();
    final users = _users.values.where((user) {
      final matchesText = text.isEmpty ||
          '${user.fullName} ${user.username}'.toLowerCase().contains(text);
      return matchesText &&
          (query.status == null || user.status == query.status);
    }).toList()
      ..sort((a, b) => a.id.value.compareTo(b.id.value));
    return List.unmodifiable(users);
  }

  @override
  Future<AppUser?> getById(EntityId id) async => _users[id];

  @override
  Future<AppUser> save(AppUser user) async {
    final normalizedUsername = user.username.toLowerCase();
    final duplicate = _users.values.any(
      (candidate) =>
          candidate.id != user.id &&
          candidate.username.toLowerCase() == normalizedUsername,
    );
    if (duplicate) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.conflict,
        code: 'duplicate_username',
        message: 'اسم المستخدم مستخدم مسبقاً',
      );
    }
    _users[user.id] = user;
    return user;
  }

  @override
  Future<AppUser> setStatus(EntityId id, UserAccountStatus status) async {
    final user = _users[id];
    if (user == null) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.notFound,
        code: 'user_not_found',
        message: 'المستخدم غير موجود',
      );
    }
    if (user.isSystemUser && status != UserAccountStatus.active) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.permissionDenied,
        code: 'system_user_status_protected',
        message: 'لا يمكن تعطيل أو قفل مستخدم النظام',
      );
    }
    final updated = AppUser(
      id: user.id,
      fullName: user.fullName,
      username: user.username,
      roleIds: user.roleIds,
      status: status,
      isSystemUser: user.isSystemUser,
      lastLoginAt: user.lastLoginAt,
    );
    _users[id] = updated;
    return updated;
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    final user = _users[id];
    if (user == null) return const DeleteDecision.blocked('المستخدم غير موجود');
    if (user.isSystemUser) {
      return const DeleteDecision.blocked('لا يمكن حذف مستخدم النظام');
    }
    return const DeleteDecision.allowed();
  }

  @override
  Future<void> delete(EntityId id) async {
    final decision = await canDelete(id);
    if (!decision.isAllowed) {
      throw ServiceFailure(
        kind: ServiceFailureKind.permissionDenied,
        message: decision.reason ?? 'لا يمكن حذف المستخدم',
      );
    }
    _users.remove(id);
  }

}

List<AppUser> demoUsers() => [
      AppUser(
        id: EntityId.demo('user', 1),
        fullName: 'مدير النظام',
        username: 'admin',
        roleIds: {EntityId.demo('role', 1)},
        status: UserAccountStatus.active,
        isSystemUser: true,
        lastLoginAt: AuditTimestamp(DateTime.utc(2026, 7, 29, 6, 2)),
      ),
      AppUser(
        id: EntityId.demo('user', 2),
        fullName: 'أحمد كريم',
        username: 'ahmed',
        roleIds: {EntityId.demo('role', 2)},
        status: UserAccountStatus.active,
        isSystemUser: false,
        lastLoginAt: AuditTimestamp(DateTime.utc(2026, 7, 28, 14, 40)),
      ),
      AppUser(
        id: EntityId.demo('user', 3),
        fullName: 'سارة علي',
        username: 'sara',
        roleIds: {EntityId.demo('role', 3)},
        status: UserAccountStatus.locked,
        isSystemUser: false,
        lastLoginAt: AuditTimestamp(DateTime.utc(2026, 7, 26, 8, 20)),
      ),
    ];
