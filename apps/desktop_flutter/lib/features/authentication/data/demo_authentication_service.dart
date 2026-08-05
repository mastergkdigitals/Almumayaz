import '../../../core/domain/business_values.dart';
import '../../../core/services/service_failure.dart';
import '../../permissions/domain/permission_models.dart';
import '../domain/authentication_service.dart';
import '../domain/session_models.dart';

class DemoAuthenticationService implements AuthenticationService {
  DemoAuthenticationService({
    AuditTimestamp Function()? clock,
    bool startsAuthenticated = true,
  })  : _clock = clock ?? _DemoAuthenticationClock().call,
        _session = startsAuthenticated
            ? AppSession(
                id: EntityId.demo('session', 1),
                userId: EntityId.demo('user', 1),
                issuedAt: AuditTimestamp(DateTime.utc(2026, 7, 29, 6, 2)),
                lastActivityAt:
                    AuditTimestamp(DateTime.utc(2026, 7, 29, 7, 10)),
                state: SessionState.active,
                permissions: _administratorPermissions(),
              )
            : null;

  final AuditTimestamp Function() _clock;
  final Map<EntityId, String> _passwords = {
    EntityId.demo('user', 1): 'password',
    EntityId.demo('user', 2): 'demo123',
    EntityId.demo('user', 3): 'demo123',
  };
  final Map<String, EntityId> _userIdsByName = {
    'admin': EntityId.demo('user', 1),
    'ahmed': EntityId.demo('user', 2),
    'sara': EntityId.demo('user', 3),
  };
  AppSession? _session;
  int _nextSessionSequence = 2;

  @override
  Future<AppSession?> currentSession() async => _session;

  @override
  Future<AppSession> signIn(SignInCredentials credentials) async {
    final userId = _userIdsByName[credentials.username.toLowerCase()];
    if (userId == null || _passwords[userId] != credentials.password) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.authenticationRequired,
        code: 'invalid_credentials',
        message: 'اسم المستخدم أو كلمة المرور غير صحيحة',
      );
    }
    final now = _clock();
    _session = AppSession(
      id: EntityId.demo('session', _nextSessionSequence++),
      userId: userId,
      issuedAt: now,
      lastActivityAt: now,
      state: SessionState.active,
      permissions: userId == EntityId.demo('user', 1)
          ? _administratorPermissions()
          : {
              PermissionCode(
                module: 'settings',
                action: PermissionAction.view,
              ),
            },
    );
    return _session!;
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }

  @override
  Future<AppSession> lock(SessionLockReason reason) async {
    final session = _requireSession();
    if (session.state != SessionState.active) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.conflict,
        message: 'الجلسة ليست نشطة',
      );
    }
    _session = _copySession(
      session,
      state: SessionState.locked,
      lockReason: reason,
    );
    return _session!;
  }

  @override
  Future<AppSession> unlock(String password) async {
    final session = _requireSession();
    if (session.state != SessionState.locked) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.conflict,
        message: 'الجلسة غير مقفلة',
      );
    }
    if (_passwords[session.userId] != password) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.authenticationRequired,
        message: 'كلمة المرور غير صحيحة',
      );
    }
    _session = _copySession(
      session,
      state: SessionState.active,
      lastActivityAt: _clock(),
    );
    return _session!;
  }

  @override
  Future<void> recordActivity() async {
    final session = _requireSession();
    if (session.state != SessionState.active) return;
    _session = _copySession(session, lastActivityAt: _clock());
  }

  @override
  Future<void> changePassword(PasswordChangeRequest request) async {
    final current = _passwords[request.userId];
    if (current == null) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.notFound,
        message: 'المستخدم غير موجود',
      );
    }
    if (current != request.currentPassword) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.authenticationRequired,
        code: 'current_password_invalid',
        message: 'كلمة المرور الحالية غير صحيحة',
      );
    }
    if (request.newPassword.length < 6) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.validation,
        code: 'password_too_short',
        message: 'يجب ألا تقل كلمة المرور عن 6 محارف',
      );
    }
    _passwords[request.userId] = request.newPassword;
  }

  AppSession _requireSession() {
    final session = _session;
    if (session == null) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.authenticationRequired,
        message: 'لا توجد جلسة حالية',
      );
    }
    return session;
  }
}

class DemoSessionPolicyRepository implements SessionPolicyRepository {
  DemoSessionPolicyRepository({AutoLockPolicy? initialPolicy})
      : _policy = initialPolicy ??
            AutoLockPolicy(
              isEnabled: true,
              idleTimeout: const Duration(minutes: 15),
            );

  AutoLockPolicy _policy;

  @override
  Future<AutoLockPolicy> loadAutoLockPolicy() async => _policy;

  @override
  Future<void> saveAutoLockPolicy(AutoLockPolicy policy) async {
    _policy = policy;
  }
}

class _DemoAuthenticationClock {
  var _minute = 0;

  AuditTimestamp call() => AuditTimestamp(
        DateTime.utc(2026, 7, 29, 7, 20 + _minute++),
      );
}

Set<PermissionCode> _administratorPermissions() => {
      for (final module in const [
        'sales',
        'purchases',
        'parties',
        'cashbox',
        'warehouses',
        'items',
        'reports',
        'settings',
      ])
        for (final action in PermissionAction.values)
          PermissionCode(module: module, action: action),
    };

AppSession _copySession(
  AppSession source, {
  SessionState? state,
  AuditTimestamp? lastActivityAt,
  SessionLockReason? lockReason,
}) {
  return AppSession(
    id: source.id,
    userId: source.userId,
    issuedAt: source.issuedAt,
    lastActivityAt: lastActivityAt ?? source.lastActivityAt,
    state: state ?? source.state,
    permissions: source.permissions,
    lockReason: (state ?? source.state) == SessionState.locked
        ? lockReason ?? source.lockReason
        : null,
  );
}
