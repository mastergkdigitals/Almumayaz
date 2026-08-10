import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/services/service_failure.dart';
import '../../authentication/data/demo_identity_state.dart';
import '../domain/user_models.dart';
import '../domain/user_repository.dart';

class DemoUserRepository implements UserRepository {
  DemoUserRepository({
    DemoIdentityState? state,
    Iterable<AppUser>? initialUsers,
  })  : assert(
          state == null || initialUsers == null,
          'Do not combine shared state with adapter-specific seeds.',
        ),
        _state = state ?? DemoIdentityState(initialUsers: initialUsers);

  final DemoIdentityState _state;

  DemoIdentityState get identityState => _state;

  @override
  Future<List<AppUser>> search(UserQuery query) async {
    final text = query.searchText.trim().toLowerCase();
    final users = _state.usersById.values.where((user) {
      final matchesText = text.isEmpty ||
          '${user.fullName} ${user.username}'.toLowerCase().contains(text);
      return matchesText &&
          (query.status == null || user.status == query.status);
    }).toList()
      ..sort((a, b) => a.id.value.compareTo(b.id.value));
    return List.unmodifiable(users);
  }

  @override
  Future<AppUser?> getById(EntityId id) async => _state.usersById[id];

  @override
  Future<AppUser?> getByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    return _state.usersById.values.where(
      (user) => user.username.toLowerCase() == normalized,
    ).firstOrNull;
  }

  @override
  Future<AppUser> save(AppUser user) {
    return _state.mutate(() {
      _validateRoleReferences(user.roleIds);
      _validateUsername(user);
      final stored = _state.usersById[user.id];
      if (stored == null && user.isSystemUser) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'system_user_flag_protected',
          message: 'لا يمكن إنشاء مستخدم نظام إضافي',
        );
      }
      if (stored?.isSystemUser ?? false) {
        final protectedUser = stored!;
        final changesProtectedIdentity = !user.isSystemUser ||
            user.username.toLowerCase() !=
                protectedUser.username.toLowerCase() ||
            user.status != UserAccountStatus.active ||
            !_sameRoleIds(user.roleIds, protectedUser.roleIds);
        if (changesProtectedIdentity) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.permissionDenied,
            code: 'system_user_protected',
            message: 'لا يمكن تغيير هوية مستخدم النظام أو صلاحياته الأساسية',
          );
        }
      } else if (user.isSystemUser) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'system_user_flag_protected',
          message: 'لا يمكن تحويل المستخدم إلى مستخدم نظام',
        );
      }
      // Authentication owns last-login updates. A profile editor may hold a
      // stale user snapshot while a sign-in completes, so never let a normal
      // repository save roll the live timestamp back.
      final saved = stored == null
          ? user
          : user.copyWith(lastLoginAt: stored.lastLoginAt);
      _state.usersById[user.id] = saved;
      _state.observeUserId(user.id);
      return saved;
    });
  }

  @override
  Future<AppUser> setStatus(EntityId id, UserAccountStatus status) {
    return _state.mutate(() {
      final user = _requireUser(id);
      if (user.isSystemUser && status != UserAccountStatus.active) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'system_user_status_protected',
          message: 'لا يمكن تعطيل أو قفل مستخدم النظام',
        );
      }
      final updated = user.copyWith(status: status);
      _state.usersById[id] = updated;
      return updated;
    });
  }

  @override
  Future<AppUser> setLastLogin(EntityId id, AuditTimestamp timestamp) {
    return _state.mutate(() {
      final user = _requireUser(id);
      final updated = user.copyWith(lastLoginAt: timestamp);
      _state.usersById[id] = updated;
      return updated;
    });
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    final user = _state.usersById[id];
    if (user == null) return const DeleteDecision.blocked('المستخدم غير موجود');
    if (user.isSystemUser) {
      return const DeleteDecision.blocked('لا يمكن حذف مستخدم النظام');
    }
    if (_state.currentSession?.userId == id) {
      return const DeleteDecision.blocked('لا يمكن حذف المستخدم الحالي');
    }
    return const DeleteDecision.allowed();
  }

  @override
  Future<void> delete(EntityId id) {
    return _state.mutate(() async {
      final decision = await canDelete(id);
      if (!decision.isAllowed) {
        throw ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'user_delete_blocked',
          message: decision.reason ?? 'لا يمكن حذف المستخدم',
        );
      }
      _state.usersById.remove(id);
      _state.credentialsByUserId.remove(id);
    });
  }

  AppUser _requireUser(EntityId id) {
    final user = _state.usersById[id];
    if (user == null) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.notFound,
        code: 'user_not_found',
        message: 'المستخدم غير موجود',
      );
    }
    return user;
  }

  void _validateUsername(AppUser user) {
    final normalized = user.username.toLowerCase();
    final duplicate = _state.usersById.values.any(
      (candidate) =>
          candidate.id != user.id &&
          candidate.username.toLowerCase() == normalized,
    );
    if (duplicate) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.conflict,
        code: 'duplicate_username',
        message: 'اسم المستخدم مستخدم مسبقاً',
      );
    }
  }

  void _validateRoleReferences(Set<EntityId> roleIds) {
    final missing = roleIds.where(
      (roleId) => !_state.rolesById.containsKey(roleId),
    );
    if (missing.isNotEmpty) {
      throw ServiceFailure(
        kind: ServiceFailureKind.validation,
        code: 'user_role_not_found',
        message: 'الدور المحدد غير موجود: ${missing.first.value}',
      );
    }
  }
}

List<AppUser> demoUsers() => demoIdentityUsers();

bool _sameRoleIds(Set<EntityId> first, Set<EntityId> second) {
  return first.length == second.length && first.containsAll(second);
}
