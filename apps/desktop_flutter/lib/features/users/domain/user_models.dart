import '../../../core/domain/business_values.dart';

enum UserAccountStatus { active, disabled, locked, disabledAndLocked }

class AppUser {
  AppUser({
    required this.id,
    required String fullName,
    required String username,
    required Set<EntityId> roleIds,
    required this.status,
    required this.isSystemUser,
    this.lastLoginAt,
  })  : fullName = fullName.trim(),
        username = username.trim(),
        roleIds = Set.unmodifiable(roleIds) {
    if (this.fullName.isEmpty) {
      throw ArgumentError.value(fullName, 'fullName', 'Must not be empty');
    }
    if (this.username.isEmpty) {
      throw ArgumentError.value(username, 'username', 'Must not be empty');
    }
    if (this.roleIds.isEmpty) {
      throw ArgumentError.value(
        roleIds,
        'roleIds',
        'At least one role is required',
      );
    }
  }

  final EntityId id;
  final String fullName;
  final String username;
  final Set<EntityId> roleIds;
  final UserAccountStatus status;
  final bool isSystemUser;
  final AuditTimestamp? lastLoginAt;
}

class UserQuery {
  const UserQuery({this.searchText = '', this.status});

  final String searchText;
  final UserAccountStatus? status;
}
