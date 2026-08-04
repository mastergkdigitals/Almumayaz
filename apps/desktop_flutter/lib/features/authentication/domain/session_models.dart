import '../../../core/domain/business_values.dart';
import '../../permissions/domain/permission_models.dart';

class SignInCredentials {
  SignInCredentials({
    required String username,
    required String password,
  })  : username = username.trim(),
        password = password {
    if (this.username.isEmpty) {
      throw ArgumentError.value(username, 'username', 'Must not be empty');
    }
    if (password.isEmpty) {
      throw ArgumentError.value(password, 'password', 'Must not be empty');
    }
  }

  final String username;
  final String password;
}

class PasswordChangeRequest {
  PasswordChangeRequest({
    required this.userId,
    required String currentPassword,
    required String newPassword,
  })  : currentPassword = currentPassword,
        newPassword = newPassword {
    if (currentPassword.isEmpty) {
      throw ArgumentError.value(
        currentPassword,
        'currentPassword',
        'Must not be empty',
      );
    }
    if (newPassword.isEmpty) {
      throw ArgumentError.value(
        newPassword,
        'newPassword',
        'Must not be empty',
      );
    }
    if (currentPassword == newPassword) {
      throw ArgumentError.value(
        newPassword,
        'newPassword',
        'New password must be different',
      );
    }
  }

  final EntityId userId;
  final String currentPassword;
  final String newPassword;
}

enum SessionState { active, locked, expired, signedOut }

enum SessionLockReason { userRequest, idleTimeout, systemLock, securityPolicy }

class AutoLockPolicy {
  AutoLockPolicy({required this.isEnabled, required this.idleTimeout}) {
    if (isEnabled && idleTimeout.inMicroseconds <= 0) {
      throw ArgumentError.value(
        idleTimeout,
        'idleTimeout',
        'Must be positive when automatic locking is enabled',
      );
    }
  }

  final bool isEnabled;
  final Duration idleTimeout;
}

class AppSession {
  AppSession({
    required this.id,
    required this.userId,
    required this.issuedAt,
    required this.lastActivityAt,
    required this.state,
    required Set<PermissionCode> permissions,
    this.lockReason,
  }) : permissions = Set.unmodifiable(permissions) {
    if (state == SessionState.locked && lockReason == null) {
      throw ArgumentError('A locked session requires a lock reason');
    }
  }

  final EntityId id;
  final EntityId userId;
  final AuditTimestamp issuedAt;
  final AuditTimestamp lastActivityAt;
  final SessionState state;
  final SessionLockReason? lockReason;
  final Set<PermissionCode> permissions;

  bool allows(PermissionCode permission) =>
      state == SessionState.active && permissions.contains(permission);
}
