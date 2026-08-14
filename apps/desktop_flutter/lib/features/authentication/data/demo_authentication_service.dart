import '../../../core/domain/business_values.dart';
import '../../../core/services/service_failure.dart';
import '../../audit_log/data/demo_audit_repository.dart';
import '../../audit_log/domain/audit_models.dart';
import '../../audit_log/domain/audit_repository.dart';
import '../../permissions/data/demo_role_repository.dart';
import '../../permissions/domain/permission_models.dart';
import '../../permissions/domain/role_repository.dart';
import '../../users/data/demo_user_repository.dart';
import '../../users/domain/user_models.dart';
import '../../users/domain/user_repository.dart';
import '../domain/authentication_service.dart';
import '../domain/session_models.dart';
import 'demo_identity_state.dart';

class DemoIdentityServiceBundle {
  DemoIdentityServiceBundle._({
    required this.state,
    required this.users,
    required this.roles,
    required this.audit,
    required this.auditWriter,
    required this.authentication,
    required this.sessionPolicies,
    required this.administration,
  });

  factory DemoIdentityServiceBundle({
    bool startsAuthenticated = true,
    DemoIdentityState? state,
  }) {
    final resolvedState = state ?? DemoIdentityState();
    return DemoIdentityServiceBundle._(
      state: resolvedState,
      users: DemoUserRepository(state: resolvedState),
      roles: DemoRoleRepository(state: resolvedState),
      audit: DemoAuditRepository(state: resolvedState),
      auditWriter: DemoIdentityAuditWriter(state: resolvedState),
      authentication: DemoAuthenticationService(
        state: resolvedState,
        startsAuthenticated: startsAuthenticated,
      ),
      sessionPolicies: DemoSessionPolicyRepository(state: resolvedState),
      administration:
          DemoSecurityAdministrationService(state: resolvedState),
    );
  }

  final DemoIdentityState state;
  final DemoUserRepository users;
  final DemoRoleRepository roles;
  final DemoAuditRepository audit;
  final DemoIdentityAuditWriter auditWriter;
  final DemoAuthenticationService authentication;
  final DemoSessionPolicyRepository sessionPolicies;
  final DemoSecurityAdministrationService administration;
}

class DemoAuthenticationService implements AuthenticationService {
  DemoAuthenticationService({
    DemoIdentityState? state,
    AuditTimestamp Function()? clock,
    bool startsAuthenticated = true,
  })  : assert(
          state == null || clock == null,
          'The shared identity state owns its clock.',
        ),
        _state = state ?? DemoIdentityState(clock: clock) {
    if (startsAuthenticated && _state.currentSession == null) {
      final administrator = _state.usersById.values.where(
        (user) => user.isSystemUser,
      ).firstOrNull;
      if (administrator != null) {
        final now = _state.now();
        _state.currentSession = AppSession(
          id: _state.nextSessionId(),
          userId: administrator.id,
          issuedAt: now,
          lastActivityAt: now,
          state: SessionState.active,
          permissions: _state.permissionsFor(administrator),
        );
      }
    }
  }

  final DemoIdentityState _state;

  DemoIdentityState get identityState => _state;

  /// No-fail synchronous revocation used by an atomic whole-data swap.
  ///
  /// It emits no audit record because the old identity graph is discarded in
  /// the same uninterrupted commit and the replacement owns its own history.
  bool revokeForDataReplacement(AppSession expectedSession) {
    final current = _state.currentSession;
    final requiredPermission = PermissionCode(
      module: 'settings',
      action: PermissionAction.manage,
    );
    if (current == null ||
        current.id != expectedSession.id ||
        current.userId != expectedSession.userId ||
        current.state != SessionState.active ||
        !current.allows(requiredPermission)) {
      return false;
    }
    _state.currentSession = null;
    return true;
  }

  @override
  Future<AppSession?> currentSession() async => _state.currentSession;

  @override
  Future<AppSession> signIn(SignInCredentials credentials) {
    return _state.mutate(() {
      final normalizedUsername = credentials.username.toLowerCase();
      final user = _state.usersById.values.where(
        (entry) => entry.username.toLowerCase() == normalizedUsername,
      ).firstOrNull;
      final credential = user == null
          ? null
          : _state.credentialsByUserId[user.id];
      if (user == null ||
          credential == null ||
          !credential.verifies(credentials.password)) {
        _state.appendAudit(
          actorUserId: user?.id,
          actorUsername: credentials.username,
          action: AuditAction.signIn,
          outcome: AuditOutcome.failure,
          summary: 'محاولة دخول ببيانات اعتماد غير صحيحة',
          details: const {'reason': 'invalid_credentials'},
        );
        throw const ServiceFailure(
          kind: ServiceFailureKind.authenticationRequired,
          code: 'invalid_credentials',
          message: 'اسم المستخدم أو كلمة المرور غير صحيحة',
        );
      }
      if (user.status != UserAccountStatus.active) {
        final code = switch (user.status) {
          UserAccountStatus.disabled => 'account_disabled',
          UserAccountStatus.locked => 'account_locked',
          UserAccountStatus.disabledAndLocked => 'account_disabled_locked',
          UserAccountStatus.active => 'account_active',
        };
        _state.appendAudit(
          actorUserId: user.id,
          actorUsername: user.username,
          action: AuditAction.signIn,
          outcome: AuditOutcome.blocked,
          summary: 'تم منع تسجيل الدخول بسبب حالة الحساب',
          details: {'reason': code},
          entityType: 'user',
          entityId: user.id,
        );
        throw ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: code,
          message: user.status == UserAccountStatus.locked
              ? 'الحساب مقفل'
              : 'الحساب معطل',
        );
      }
      final missingRoles = _state.missingRoleIds(user);
      if (missingRoles.isNotEmpty) {
        _state.appendAudit(
          actorUserId: user.id,
          actorUsername: user.username,
          action: AuditAction.signIn,
          outcome: AuditOutcome.blocked,
          summary: 'تم منع تسجيل الدخول بسبب دور مفقود',
          details: {'missingRoleId': missingRoles.first.value},
          entityType: 'user',
          entityId: user.id,
        );
        throw const ServiceFailure(
          kind: ServiceFailureKind.validation,
          code: 'missing_role_reference',
          message: 'تعذر تحميل صلاحيات المستخدم لأن أحد الأدوار غير موجود',
        );
      }

      final now = _state.now();
      final updatedUser = user.copyWith(lastLoginAt: now);
      _state.usersById[user.id] = updatedUser;
      final session = AppSession(
        id: _state.nextSessionId(),
        userId: user.id,
        issuedAt: now,
        lastActivityAt: now,
        state: SessionState.active,
        permissions: _state.permissionsFor(updatedUser),
      );
      _state.currentSession = session;
      _state.appendAudit(
        actorUserId: user.id,
        actorUsername: user.username,
        action: AuditAction.signIn,
        outcome: AuditOutcome.success,
        summary: 'تسجيل دخول ناجح',
        before: {'lastLoginAt': user.lastLoginAt?.toString()},
        after: {'lastLoginAt': now.toString()},
        entityType: 'session',
        entityId: session.id,
      );
      return session;
    });
  }

  @override
  Future<void> signOut(EntityId expectedSessionId) {
    return _state.mutate(() {
      final session = _requireExpectedSession(expectedSessionId);
      final user = _requireUser(session.userId);
      _state.appendAudit(
        actorUserId: user.id,
        actorUsername: user.username,
        action: AuditAction.signOut,
        outcome: AuditOutcome.success,
        summary: 'تسجيل خروج',
        entityType: 'session',
        entityId: session.id,
      );
      _state.currentSession = null;
    });
  }

  @override
  Future<AppSession> lock(
    EntityId expectedSessionId,
    SessionLockReason reason,
  ) {
    return _state.mutate(() {
      final session = _requireExpectedSession(expectedSessionId);
      if (session.state != SessionState.active) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.conflict,
          code: 'session_not_active',
          message: 'الجلسة ليست نشطة',
        );
      }
      final user = _requireUser(session.userId);
      final locked = _copySession(
        session,
        state: SessionState.locked,
        lockReason: reason,
      );
      _state.currentSession = locked;
      _state.appendAudit(
        actorUserId: user.id,
        actorUsername: user.username,
        action: AuditAction.sessionLock,
        outcome: AuditOutcome.success,
        summary: 'قفل الجلسة',
        details: {'reason': reason.name},
        entityType: 'session',
        entityId: session.id,
      );
      return locked;
    });
  }

  @override
  Future<AppSession> unlock(
    EntityId expectedSessionId,
    String password,
  ) {
    return _state.mutate(() {
      final session = _requireExpectedSession(expectedSessionId);
      if (session.state != SessionState.locked) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.conflict,
          code: 'session_not_locked',
          message: 'الجلسة غير مقفلة',
        );
      }
      final user = _requireUser(session.userId);
      final credential = _state.credentialsByUserId[user.id];
      if (credential == null || !credential.verifies(password)) {
        _state.appendAudit(
          actorUserId: user.id,
          actorUsername: user.username,
          action: AuditAction.sessionUnlock,
          outcome: AuditOutcome.failure,
          summary: 'فشل فتح قفل الجلسة',
          entityType: 'session',
          entityId: session.id,
        );
        throw const ServiceFailure(
          kind: ServiceFailureKind.authenticationRequired,
          code: 'unlock_password_invalid',
          message: 'كلمة المرور غير صحيحة',
        );
      }
      final unlocked = _copySession(
        session,
        state: SessionState.active,
        lastActivityAt: _state.now(),
      );
      _state.currentSession = unlocked;
      _state.appendAudit(
        actorUserId: user.id,
        actorUsername: user.username,
        action: AuditAction.sessionUnlock,
        outcome: AuditOutcome.success,
        summary: 'فتح قفل الجلسة',
        entityType: 'session',
        entityId: session.id,
      );
      return unlocked;
    });
  }

  @override
  Future<void> recordActivity(EntityId expectedSessionId) {
    return _state.mutate(() {
      final session = _requireExpectedSession(expectedSessionId);
      if (session.state != SessionState.active) return;
      _state.currentSession = _copySession(
        session,
        lastActivityAt: _state.now(),
      );
    });
  }

  @override
  Future<void> changePassword(PasswordChangeRequest request) {
    return _state.mutate(() {
      final session = _requireActiveSession();
      if (session.userId != request.userId) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'password_change_wrong_actor',
          message: 'يمكن للمستخدم تغيير كلمة مروره فقط',
        );
      }
      final user = _requireUser(request.userId);
      final credential = _state.credentialsByUserId[user.id];
      if (credential == null ||
          !credential.verifies(request.currentPassword)) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.authenticationRequired,
          code: 'current_password_invalid',
          message: 'كلمة المرور الحالية غير صحيحة',
        );
      }
      final validation = PasswordPolicy.validationMessage(request.newPassword);
      if (validation != null) {
        throw ServiceFailure(
          kind: ServiceFailureKind.validation,
          code: 'password_too_short',
          message: validation,
        );
      }
      _state.credentialsByUserId[user.id] =
          DemoPasswordCredential.fromPassword(
        salt: '${user.id.value}-credential',
        password: request.newPassword,
      );
      _state.appendAudit(
        actorUserId: user.id,
        actorUsername: user.username,
        action: AuditAction.passwordChange,
        outcome: AuditOutcome.success,
        summary: 'تغيير كلمة مرور المستخدم الحالي',
        entityType: 'user',
        entityId: user.id,
      );
    });
  }

  AppSession _requireSession() {
    final session = _state.currentSession;
    if (session == null) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.authenticationRequired,
        code: 'session_missing',
        message: 'لا توجد جلسة حالية',
      );
    }
    return session;
  }

  AppSession _requireExpectedSession(EntityId expectedSessionId) {
    final session = _requireSession();
    if (session.id != expectedSessionId) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.conflict,
        code: 'session_replaced',
        message: 'تم استبدال الجلسة الحالية بجلسة أخرى',
      );
    }
    return session;
  }

  AppSession _requireActiveSession() {
    final session = _requireSession();
    if (session.state != SessionState.active) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.authenticationRequired,
        code: 'session_not_active',
        message: 'الجلسة ليست نشطة',
      );
    }
    return session;
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
}

class DemoSessionPolicyRepository implements SessionPolicyRepository {
  DemoSessionPolicyRepository({
    DemoIdentityState? state,
    AutoLockPolicy? initialPolicy,
    bool? enforceManagerPermission,
  })  : assert(
          state == null || initialPolicy == null,
          'Do not combine shared state with an adapter-specific policy.',
        ),
        _state = state ?? DemoIdentityState(initialPolicy: initialPolicy),
        _enforceManagerPermission = enforceManagerPermission ?? state != null;

  final DemoIdentityState _state;
  final bool _enforceManagerPermission;

  DemoIdentityState get identityState => _state;

  @override
  Future<AutoLockPolicy> loadAutoLockPolicy() async =>
      _state.autoLockPolicy;

  @override
  Future<void> saveAutoLockPolicy(AutoLockPolicy policy) {
    return _state.mutate(() {
      if (_enforceManagerPermission) {
        final session = _state.currentSession;
        final permission = PermissionCode(
          module: 'settings',
          action: PermissionAction.manage,
        );
        if (session == null ||
            session.state != SessionState.active ||
            !session.permissions.contains(permission)) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.permissionDenied,
            code: 'manage_session_policy_permission_required',
            message: 'ليست لديك صلاحية إدارة سياسة القفل',
          );
        }
      }
      _state.autoLockPolicy = policy;
      final session = _state.currentSession;
      final actor = session == null ? null : _state.usersById[session.userId];
      if (actor != null) {
        _state.appendAudit(
          actorUserId: actor.id,
          actorUsername: actor.username,
          action: AuditAction.update,
          outcome: AuditOutcome.success,
          summary: 'تحديث سياسة القفل التلقائي',
          after: {
            'enabled': policy.isEnabled,
            'idleMinutes': policy.idleTimeout.inMinutes,
          },
          entityType: 'session_policy',
          entityId: EntityId.demo('session_policy', 1),
        );
      }
    });
  }
}

class DemoSecurityAdministrationService
    implements SecurityAdministrationService {
  DemoSecurityAdministrationService({required DemoIdentityState state})
      : _state = state;

  factory DemoSecurityAdministrationService.fromAdapters({
    required UserRepository users,
    required RoleRepository roles,
    required AuthenticationService authentication,
    required AuditRepository audit,
  }) {
    if (users is DemoUserRepository) {
      final identityState = users.identityState;
      final roleState = roles is DemoRoleRepository
          ? roles.identityState
          : null;
      final authState = authentication is DemoAuthenticationService
          ? authentication.identityState
          : null;
      final auditState = audit is DemoAuditRepository
          ? audit.identityState
          : null;
      if (identical(identityState, roleState) &&
          identical(identityState, authState) &&
          identical(identityState, auditState)) {
        return DemoSecurityAdministrationService(state: identityState);
      }
    }
    throw StateError(
      'Inject SecurityAdministrationService when identity adapters do not '
      'share one DemoIdentityState.',
    );
  }

  final DemoIdentityState _state;

  DemoIdentityState get identityState => _state;

  @override
  Future<AppUser> createUser(UserCreateRequest request) {
    return _state.mutate(() {
      final actor = _requireAdministrator();
      _validateRoles(request.roleIds);
      _validateUniqueUsername(request.username);
      final id = _state.nextUserId();
      final user = AppUser(
        id: id,
        fullName: request.fullName,
        username: request.username,
        roleIds: request.roleIds,
        status: UserAccountStatus.active,
        isSystemUser: false,
      );
      final credential = DemoPasswordCredential.fromPassword(
        salt: '${id.value}-credential',
        password: request.initialPassword,
      );
      _state.usersById[id] = user;
      _state.credentialsByUserId[id] = credential;
      _state.appendAudit(
        actorUserId: actor.id,
        actorUsername: actor.username,
        action: AuditAction.create,
        outcome: AuditOutcome.success,
        summary: 'إضافة المستخدم ${user.username}',
        after: _userSnapshot(user),
        entityType: 'user',
        entityId: id,
      );
      return user;
    });
  }

  @override
  Future<AppUser> updateUser(UserUpdateRequest request) {
    return _state.mutate(() {
      final actor = _requireAdministrator();
      final stored = _requireUser(request.id);
      _validateRoles(request.roleIds);
      _validateUniqueUsername(request.username, excluding: request.id);
      if (stored.isSystemUser &&
          (stored.username.toLowerCase() != request.username.toLowerCase() ||
              !_sameRoleIds(request.roleIds, stored.roleIds))) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'system_user_protected',
          message: 'لا يمكن تغيير هوية مستخدم النظام أو صلاحياته الأساسية',
        );
      }
      final updated = stored.copyWith(
        fullName: request.fullName,
        username: request.username,
        roleIds: request.roleIds,
      );
      _state.usersById[stored.id] = updated;
      _refreshCurrentSessionPermissions();
      _state.appendAudit(
        actorUserId: actor.id,
        actorUsername: actor.username,
        action: AuditAction.update,
        outcome: AuditOutcome.success,
        summary: 'تحديث المستخدم ${updated.username}',
        before: _userSnapshot(stored),
        after: _userSnapshot(updated),
        entityType: 'user',
        entityId: stored.id,
      );
      return updated;
    });
  }

  @override
  Future<AppUser> setUserStatus(
    EntityId id,
    UserAccountStatus status,
  ) {
    return _state.mutate(() {
      final actor = _requireAdministrator();
      final stored = _requireUser(id);
      if (stored.isSystemUser && status != UserAccountStatus.active) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'system_user_status_protected',
          message: 'لا يمكن تعطيل أو قفل مستخدم النظام',
        );
      }
      if (actor.id == id && status != UserAccountStatus.active) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'current_user_status_protected',
          message: 'لا يمكن تعطيل أو قفل المستخدم الحالي',
        );
      }
      final updated = stored.copyWith(status: status);
      _state.usersById[id] = updated;
      _state.appendAudit(
        actorUserId: actor.id,
        actorUsername: actor.username,
        action: AuditAction.accountStatusChange,
        outcome: AuditOutcome.success,
        summary: 'تغيير حالة حساب ${updated.username}',
        before: {'status': stored.status.name},
        after: {'status': updated.status.name},
        entityType: 'user',
        entityId: id,
      );
      return updated;
    });
  }

  @override
  Future<void> deleteUser(EntityId id) {
    return _state.mutate(() {
      final actor = _requireAdministrator();
      final stored = _requireUser(id);
      if (stored.isSystemUser) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'system_user_delete_protected',
          message: 'لا يمكن حذف مستخدم النظام',
        );
      }
      if (actor.id == id) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'current_user_delete_protected',
          message: 'لا يمكن حذف المستخدم الحالي',
        );
      }
      _state.usersById.remove(id);
      _state.credentialsByUserId.remove(id);
      _state.appendAudit(
        actorUserId: actor.id,
        actorUsername: actor.username,
        action: AuditAction.delete,
        outcome: AuditOutcome.success,
        summary: 'حذف المستخدم ${stored.username}',
        before: _userSnapshot(stored),
        entityType: 'user',
        entityId: id,
      );
    });
  }

  @override
  Future<void> resetUserPassword(AdminPasswordResetRequest request) {
    return _state.mutate(() {
      final actor = _requireAdministrator();
      final target = _requireUser(request.userId);
      _state.credentialsByUserId[target.id] =
          DemoPasswordCredential.fromPassword(
        salt: '${target.id.value}-credential',
        password: request.newPassword,
      );
      _state.appendAudit(
        actorUserId: actor.id,
        actorUsername: actor.username,
        action: AuditAction.passwordChange,
        outcome: AuditOutcome.success,
        summary: 'إعادة تعيين كلمة مرور ${target.username}',
        details: const {'mode': 'administrator_reset'},
        entityType: 'user',
        entityId: target.id,
      );
    });
  }

  @override
  Future<AppRole> saveRole(RoleSaveRequest request) {
    return _state.mutate(() {
      final actor = _requireAdministrator();
      final stored = request.id == null ? null : _state.rolesById[request.id];
      if (request.id != null && stored == null) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.notFound,
          code: 'role_not_found',
          message: 'الدور غير موجود',
        );
      }
      _validateUniqueRoleName(request.name, excluding: request.id);
      if (stored?.isSystemRole ?? false) {
        final changed = stored!.name != request.name ||
            !_samePermissions(stored.permissions, request.permissions);
        if (changed) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.permissionDenied,
            code: 'system_role_protected',
            message: 'لا يمكن تعديل دور النظام',
          );
        }
      }
      final role = AppRole(
        id: stored?.id ?? _state.nextRoleId(),
        name: request.name,
        permissions: request.permissions,
        isSystemRole: stored?.isSystemRole ?? false,
      );
      _state.rolesById[role.id] = role;
      _refreshCurrentSessionPermissions();
      _state.appendAudit(
        actorUserId: actor.id,
        actorUsername: actor.username,
        action: AuditAction.permissionChange,
        outcome: AuditOutcome.success,
        summary: stored == null
            ? 'إضافة الدور ${role.name}'
            : 'تحديث الدور والصلاحيات: ${role.name}',
        before: stored == null ? const {} : _roleSnapshot(stored),
        after: _roleSnapshot(role),
        entityType: 'role',
        entityId: role.id,
      );
      return role;
    });
  }

  @override
  Future<void> deleteRole(EntityId id) {
    return _state.mutate(() {
      final actor = _requireAdministrator();
      final stored = _state.rolesById[id];
      if (stored == null) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.notFound,
          code: 'role_not_found',
          message: 'الدور غير موجود',
        );
      }
      if (stored.isSystemRole) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'system_role_delete_protected',
          message: 'لا يمكن حذف دور النظام',
        );
      }
      if (_state.usersById.values.any((user) => user.roleIds.contains(id))) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.conflict,
          code: 'role_has_users',
          message: 'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
        );
      }
      _state.rolesById.remove(id);
      _state.appendAudit(
        actorUserId: actor.id,
        actorUsername: actor.username,
        action: AuditAction.delete,
        outcome: AuditOutcome.success,
        summary: 'حذف الدور ${stored.name}',
        before: _roleSnapshot(stored),
        entityType: 'role',
        entityId: id,
      );
    });
  }

  AppUser _requireAdministrator() {
    final session = _state.currentSession;
    if (session == null || session.state != SessionState.active) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.authenticationRequired,
        code: 'active_session_required',
        message: 'تتطلب العملية جلسة نشطة',
      );
    }
    final actor = _requireUser(session.userId);
    final manageSettings = PermissionCode(
      module: 'settings',
      action: PermissionAction.manage,
    );
    if (!session.permissions.contains(manageSettings)) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.permissionDenied,
        code: 'manage_users_permission_required',
        message: 'ليست لديك صلاحية إدارة المستخدمين والأمان',
      );
    }
    return actor;
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

  void _validateRoles(Set<EntityId> roleIds) {
    final missing = roleIds.where(
      (roleId) => !_state.rolesById.containsKey(roleId),
    );
    if (missing.isNotEmpty) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.validation,
        code: 'user_role_not_found',
        message: 'الدور المحدد غير موجود',
      );
    }
  }

  void _validateUniqueUsername(String username, {EntityId? excluding}) {
    final normalized = username.toLowerCase();
    if (_state.usersById.values.any(
      (user) =>
          user.id != excluding && user.username.toLowerCase() == normalized,
    )) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.conflict,
        code: 'duplicate_username',
        message: 'اسم المستخدم مستخدم مسبقاً',
      );
    }
  }

  void _validateUniqueRoleName(String name, {EntityId? excluding}) {
    final normalized = name.toLowerCase();
    if (_state.rolesById.values.any(
      (role) => role.id != excluding && role.name.toLowerCase() == normalized,
    )) {
      throw const ServiceFailure(
        kind: ServiceFailureKind.conflict,
        code: 'duplicate_role_name',
        message: 'اسم الدور مستخدم مسبقاً',
      );
    }
  }

  void _refreshCurrentSessionPermissions() {
    final session = _state.currentSession;
    if (session == null) return;
    final user = _state.usersById[session.userId];
    if (user == null) return;
    _state.currentSession = AppSession(
      id: session.id,
      userId: session.userId,
      issuedAt: session.issuedAt,
      lastActivityAt: session.lastActivityAt,
      state: session.state,
      lockReason: session.lockReason,
      permissions: _state.permissionsFor(user),
    );
  }
}

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

Map<String, Object?> _userSnapshot(AppUser user) => {
      'fullName': user.fullName,
      'username': user.username,
      'roleIds': user.roleIds.map((roleId) => roleId.value).toList(),
      'status': user.status.name,
      'isSystemUser': user.isSystemUser,
    };

Map<String, Object?> _roleSnapshot(AppRole role) => {
      'name': role.name,
      'permissions': role.permissions.map((permission) => permission.value).toList()
        ..sort(),
      'isSystemRole': role.isSystemRole,
    };

bool _samePermissions(
  Set<PermissionCode> first,
  Set<PermissionCode> second,
) {
  return first.length == second.length && first.containsAll(second);
}

bool _sameRoleIds(Set<EntityId> first, Set<EntityId> second) {
  return first.length == second.length && first.containsAll(second);
}
