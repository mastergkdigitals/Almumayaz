import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/services/service_failure.dart';
import '../../authentication/data/demo_identity_state.dart';
import '../domain/permission_models.dart';
import '../domain/role_repository.dart';

class DemoRoleRepository implements RoleRepository {
  DemoRoleRepository({
    DemoIdentityState? state,
    Iterable<AppRole>? initialRoles,
  })  : assert(
          state == null || initialRoles == null,
          'Do not combine shared state with adapter-specific seeds.',
        ),
        _state = state ?? DemoIdentityState(initialRoles: initialRoles);

  final DemoIdentityState _state;

  DemoIdentityState get identityState => _state;

  @override
  Future<List<AppRole>> getAll() async {
    final roles = _state.rolesById.values.toList()
      ..sort((a, b) => a.id.value.compareTo(b.id.value));
    return List.unmodifiable(roles);
  }

  @override
  Future<AppRole?> getById(EntityId id) async => _state.rolesById[id];

  @override
  Future<AppRole> save(AppRole role) {
    return _state.mutate(() {
      final stored = _state.rolesById[role.id];
      _validateName(role);
      if (stored == null && role.isSystemRole) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'system_role_flag_protected',
          message: 'لا يمكن إنشاء دور نظام إضافي',
        );
      }
      if (stored?.isSystemRole ?? false) {
        final protectedRole = stored!;
        if (!role.isSystemRole ||
            role.name != protectedRole.name ||
            !_samePermissions(
              role.permissions,
              protectedRole.permissions,
            )) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.permissionDenied,
            code: 'system_role_protected',
            message: 'لا يمكن تعديل دور النظام',
          );
        }
      } else if (role.isSystemRole) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'system_role_flag_protected',
          message: 'لا يمكن تحويل الدور إلى دور نظام',
        );
      }
      _state.rolesById[role.id] = role;
      _state.observeRoleId(role.id);
      return role;
    });
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    final role = _state.rolesById[id];
    if (role == null) return const DeleteDecision.blocked('الدور غير موجود');
    if (role.isSystemRole) {
      return const DeleteDecision.blocked('لا يمكن حذف دور النظام');
    }
    final isAssigned = _state.usersById.values.any(
      (user) => user.roleIds.contains(id),
    );
    if (isAssigned) {
      return const DeleteDecision.blocked(
        'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
    }
    return const DeleteDecision.allowed();
  }

  @override
  Future<void> delete(EntityId id) {
    return _state.mutate(() async {
      final decision = await canDelete(id);
      if (!decision.isAllowed) {
        throw ServiceFailure(
          kind: ServiceFailureKind.conflict,
          code: 'role_delete_blocked',
          message: decision.reason ?? 'لا يمكن حذف الدور',
        );
      }
      _state.rolesById.remove(id);
    });
  }

  void _validateName(AppRole role) {
    final normalized = role.name.toLowerCase();
    final duplicate = _state.rolesById.values.any(
      (candidate) =>
          candidate.id != role.id &&
          candidate.name.toLowerCase() == normalized,
    );
    if (duplicate) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.conflict,
        code: 'duplicate_role_name',
        message: 'اسم الدور مستخدم مسبقاً',
      );
    }
  }
}

List<AppRole> demoRoles() => demoIdentityRoles();

bool _samePermissions(
  Set<PermissionCode> first,
  Set<PermissionCode> second,
) {
  return first.length == second.length && first.containsAll(second);
}
