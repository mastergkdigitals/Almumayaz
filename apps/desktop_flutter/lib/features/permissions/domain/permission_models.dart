import '../../../core/domain/business_values.dart';

enum PermissionAction { view, create, update, delete, print, export, manage }

class PermissionCode {
  PermissionCode({
    required String module,
    required this.action,
  }) : module = module.trim().toLowerCase() {
    if (!RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(this.module)) {
      throw ArgumentError.value(module, 'module', 'Invalid module code');
    }
  }

  final String module;
  final PermissionAction action;

  String get value => '$module.${action.name}';

  @override
  bool operator ==(Object other) =>
      other is PermissionCode &&
      other.module == module &&
      other.action == action;

  @override
  int get hashCode => Object.hash(module, action);

  @override
  String toString() => value;
}

class AppRole {
  AppRole({
    required this.id,
    required String name,
    required Set<PermissionCode> permissions,
    required this.isSystemRole,
  })  : name = name.trim(),
        permissions = Set.unmodifiable(permissions) {
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Must not be empty');
    }
  }

  final EntityId id;
  final String name;
  final Set<PermissionCode> permissions;
  final bool isSystemRole;

  bool allows(PermissionCode permission) => permissions.contains(permission);
}
