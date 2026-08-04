import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/services/service_failure.dart';
import '../domain/permission_models.dart';
import '../domain/role_repository.dart';

class DemoRoleRepository implements RoleRepository {
  DemoRoleRepository({Iterable<AppRole>? initialRoles})
      : _roles = {
          for (final role in initialRoles ?? demoRoles()) role.id: role,
        };

  final Map<EntityId, AppRole> _roles;

  @override
  Future<List<AppRole>> getAll() async {
    final roles = _roles.values.toList()
      ..sort((a, b) => a.id.value.compareTo(b.id.value));
    return List.unmodifiable(roles);
  }

  @override
  Future<AppRole?> getById(EntityId id) async => _roles[id];

  @override
  Future<AppRole> save(AppRole role) async {
    final normalizedName = role.name.toLowerCase();
    final duplicate = _roles.values.any(
      (candidate) =>
          candidate.id != role.id &&
          candidate.name.toLowerCase() == normalizedName,
    );
    if (duplicate) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.conflict,
        code: 'duplicate_role_name',
        message: 'اسم الدور مستخدم مسبقاً',
      );
    }
    _roles[role.id] = role;
    return role;
  }

  @override
  Future<DeleteDecision> canDelete(EntityId id) async {
    final role = _roles[id];
    if (role == null) return const DeleteDecision.blocked('الدور غير موجود');
    if (role.isSystemRole) {
      return const DeleteDecision.blocked('لا يمكن حذف دور النظام');
    }
    return const DeleteDecision.allowed();
  }

  @override
  Future<void> delete(EntityId id) async {
    final decision = await canDelete(id);
    if (!decision.isAllowed) {
      throw ServiceFailure(
        kind: ServiceFailureKind.permissionDenied,
        message: decision.reason ?? 'لا يمكن حذف الدور',
      );
    }
    _roles.remove(id);
  }
}

List<AppRole> demoRoles() => [
      AppRole(
        id: EntityId.demo('role', 1),
        name: 'مدير النظام',
        permissions: _permissionsFor(
          modules: _demoModules,
          actions: PermissionAction.values,
        ),
        isSystemRole: true,
      ),
      AppRole(
        id: EntityId.demo('role', 2),
        name: 'المبيعات',
        permissions: {
          ..._permissionsFor(
            modules: const ['sales'],
            actions: PermissionAction.values,
          ),
          ..._permissionsFor(
            modules: const ['parties'],
            actions: const [PermissionAction.view, PermissionAction.update],
          ),
          ..._permissionsFor(
            modules: const ['reports'],
            actions: const [PermissionAction.view, PermissionAction.print],
          ),
        },
        isSystemRole: false,
      ),
      AppRole(
        id: EntityId.demo('role', 3),
        name: 'الحسابات',
        permissions: {
          ..._permissionsFor(
            modules: const ['cashbox'],
            actions: PermissionAction.values,
          ),
          ..._permissionsFor(
            modules: const ['parties'],
            actions: const [PermissionAction.view],
          ),
          ..._permissionsFor(
            modules: const ['reports'],
            actions: const [PermissionAction.view, PermissionAction.print],
          ),
        },
        isSystemRole: false,
      ),
      AppRole(
        id: EntityId.demo('role', 4),
        name: 'عرض فقط',
        permissions: _permissionsFor(
          modules: _demoModules,
          actions: const [PermissionAction.view],
        ),
        isSystemRole: false,
      ),
    ];

const _demoModules = [
  'sales',
  'purchases',
  'parties',
  'cashbox',
  'warehouses',
  'items',
  'reports',
  'settings',
];

Set<PermissionCode> _permissionsFor({
  required Iterable<String> modules,
  required Iterable<PermissionAction> actions,
}) {
  return {
    for (final module in modules)
      for (final action in actions)
        PermissionCode(module: module, action: action),
  };
}
