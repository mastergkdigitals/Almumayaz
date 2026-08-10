import 'session_models.dart';

abstract interface class AuthenticationService {
  Future<AppSession?> currentSession();

  Future<AppSession> signIn(SignInCredentials credentials);

  Future<void> signOut();

  Future<AppSession> lock(SessionLockReason reason);

  Future<AppSession> unlock(String password);

  Future<void> recordActivity();

  Future<void> changePassword(PasswordChangeRequest request);
}

abstract interface class SessionPolicyRepository {
  Future<AutoLockPolicy> loadAutoLockPolicy();

  Future<void> saveAutoLockPolicy(AutoLockPolicy policy);
}
