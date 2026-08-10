import '../../../core/domain/business_values.dart';

enum UserAccountStatus { active, disabled, locked, disabledAndLocked }

const _unsetLastLogin = Object();

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

  AppUser copyWith({
    String? fullName,
    String? username,
    Set<EntityId>? roleIds,
    UserAccountStatus? status,
    bool? isSystemUser,
    Object? lastLoginAt = _unsetLastLogin,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      roleIds: roleIds ?? this.roleIds,
      status: status ?? this.status,
      isSystemUser: isSystemUser ?? this.isSystemUser,
      lastLoginAt: identical(lastLoginAt, _unsetLastLogin)
          ? this.lastLoginAt
          : lastLoginAt as AuditTimestamp?,
    );
  }
}

class UserQuery {
  const UserQuery({this.searchText = '', this.status});

  final String searchText;
  final UserAccountStatus? status;
}

class UserCreateRequest {
  UserCreateRequest({
    required String fullName,
    required String username,
    required Set<EntityId> roleIds,
    required String initialPassword,
  })  : fullName = fullName.trim(),
        username = username.trim(),
        roleIds = Set.unmodifiable(roleIds),
        initialPassword = initialPassword {
    _validateUserInput(
      fullName: this.fullName,
      username: this.username,
      roleIds: this.roleIds,
    );
    if (initialPassword.length < 6) {
      throw ArgumentError.value(
        initialPassword,
        'initialPassword',
        'Must contain at least 6 characters',
      );
    }
  }

  final String fullName;
  final String username;
  final Set<EntityId> roleIds;
  final String initialPassword;
}

class UserUpdateRequest {
  UserUpdateRequest({
    required this.id,
    required String fullName,
    required String username,
    required Set<EntityId> roleIds,
  })  : fullName = fullName.trim(),
        username = username.trim(),
        roleIds = Set.unmodifiable(roleIds) {
    _validateUserInput(
      fullName: this.fullName,
      username: this.username,
      roleIds: this.roleIds,
    );
  }

  final EntityId id;
  final String fullName;
  final String username;
  final Set<EntityId> roleIds;
}

void _validateUserInput({
  required String fullName,
  required String username,
  required Set<EntityId> roleIds,
}) {
  if (fullName.isEmpty) {
    throw ArgumentError.value(fullName, 'fullName', 'Must not be empty');
  }
  if (username.isEmpty) {
    throw ArgumentError.value(username, 'username', 'Must not be empty');
  }
  if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(username)) {
    throw ArgumentError.value(
      username,
      'username',
      'Contains unsupported characters',
    );
  }
  if (roleIds.isEmpty) {
    throw ArgumentError.value(
      roleIds,
      'roleIds',
      'At least one role is required',
    );
  }
}
