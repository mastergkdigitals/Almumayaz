import '../../../core/domain/business_values.dart';
import '../../permissions/domain/permission_models.dart';
import '../../users/domain/user_models.dart';
import 'session_models.dart';

abstract interface class AuthenticationService {
  Future<AppSession?> currentSession();

  Future<AppSession> signIn(SignInCredentials credentials);

  Future<void> signOut(EntityId expectedSessionId);

  Future<AppSession> lock(
    EntityId expectedSessionId,
    SessionLockReason reason,
  );

  Future<AppSession> unlock(EntityId expectedSessionId, String password);

  Future<void> recordActivity(EntityId expectedSessionId);

  Future<void> changePassword(PasswordChangeRequest request);
}

abstract interface class SessionPolicyRepository {
  Future<AutoLockPolicy> loadAutoLockPolicy();

  Future<void> saveAutoLockPolicy(AutoLockPolicy policy);
}

/// Coordinates identity mutations that must keep users, credentials, roles,
/// active sessions, and the append-only audit journal consistent.
///
/// A future API adapter should map each method to one authoritative server
/// transaction rather than recreating this coordination in widgets.
abstract interface class SecurityAdministrationService {
  Future<AppUser> createUser(UserCreateRequest request);

  Future<AppUser> updateUser(UserUpdateRequest request);

  Future<AppUser> setUserStatus(
    EntityId id,
    UserAccountStatus status,
  );

  Future<void> deleteUser(EntityId id);

  Future<void> resetUserPassword(AdminPasswordResetRequest request);

  Future<AppRole> saveRole(RoleSaveRequest request);

  Future<void> deleteRole(EntityId id);
}
