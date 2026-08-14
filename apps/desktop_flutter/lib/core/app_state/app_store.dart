import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../features/audit_log/application/audit_write_support.dart';
import '../../features/audit_log/domain/audit_models.dart';
import '../../features/authentication/domain/session_models.dart';
import '../../features/permissions/domain/permission_models.dart';
import '../domain/business_values.dart';
import '../services/app_operation_gate.dart';
import '../services/service_failure.dart';
import 'app_data_composition.dart';
import 'app_data_profile.dart';
import 'app_repositories.dart';
import 'app_services.dart';

class AppStore extends ChangeNotifier {
  AppStore({
    required AppRepositories repositories,
    AppServices? services,
    bool internalToolsEnabled = true,
    AppDataCompositionBuilder? compositionBuilder,
  })  : _repositories = repositories,
        _services = services ?? AppServices.demo(),
        _internalToolsEnabled = internalToolsEnabled,
        _compositionBuilder =
            compositionBuilder ?? AppDataComposition.demo;

  factory AppStore.demo({
    bool internalToolsEnabled = true,
    AppDataCompositionBuilder? compositionBuilder,
  }) {
    final builder = compositionBuilder ?? AppDataComposition.demo;
    final composition = builder(AppDataProfile.originalDemo);
    return AppStore(
      repositories: composition.repositories,
      services: composition.services,
      internalToolsEnabled: internalToolsEnabled,
      compositionBuilder: builder,
    );
  }

  factory AppStore.desktop({
    bool internalToolsEnabled = true,
    AppDataCompositionBuilder? compositionBuilder,
  }) {
    final builder = compositionBuilder ?? AppDataComposition.desktop;
    final composition = builder(AppDataProfile.originalDemo);
    return AppStore(
      repositories: composition.repositories,
      services: composition.services,
      internalToolsEnabled: internalToolsEnabled,
      compositionBuilder: builder,
    );
  }

  AppRepositories _repositories;
  AppServices _services;
  final bool _internalToolsEnabled;
  final AppDataCompositionBuilder _compositionBuilder;
  AppSession? _session;
  AutoLockPolicy? _autoLockPolicy;
  Timer? _idleTimer;
  Timer? _idleRefreshCooldownTimer;
  Timer? _activitySyncCooldownTimer;
  bool _isRecordingActivity = false;
  bool _idleRefreshCoolingDown = false;
  bool _idleRefreshPending = false;
  bool _activitySyncCoolingDown = false;
  bool _idleMonitoringEnabled = true;
  bool _hasAuthenticated = false;
  bool _initialHydrationAvailable = true;
  bool _isSystemUserSession = false;
  bool _isReplacingData = false;
  Completer<void>? _dataReplacementSettled;
  bool _isDisposed = false;
  int _sessionGeneration = 0;
  int _activitySyncGeneration = 0;
  int _revision = 0;
  int _dataGeneration = 0;

  static const _activityThrottleDuration = Duration(seconds: 1);

  AppRepositories get repositories => _repositories;
  AppServices get services => _services;
  AppSession? get session => _session;
  bool get requiresAuthentication =>
      _hasAuthenticated && _session?.state != SessionState.active;
  int get revision => _revision;
  int get dataGeneration => _dataGeneration;
  bool get isReplacingData => _isReplacingData;
  bool get canManageInternalData =>
      _internalToolsEnabled &&
      _session?.state == SessionState.active &&
      _isSystemUserSession &&
      allows('settings', PermissionAction.manage);

  Future<AppSession> signIn(SignInCredentials credentials) async {
    _initialHydrationAvailable = false;
    final generation = ++_sessionGeneration;
    final session = await services.authentication.signIn(credentials);
    final policy = await _loadAutoLockPolicy();
    final user = await services.users.getById(session.userId);
    _requireCurrentSessionOperation(generation);
    _session = session;
    _isSystemUserSession = user?.isSystemUser ?? false;
    _hasAuthenticated = true;
    _autoLockPolicy = policy;
    _resetActivitySyncThrottle();
    _scheduleIdleLock();
    notifyListeners();
    return session;
  }

  Future<void> signOut() async {
    _initialHydrationAvailable = false;
    final expectedSessionId = _session?.id;
    final generation = ++_sessionGeneration;
    _idleTimer?.cancel();
    _resetActivitySyncThrottle();
    try {
      if (expectedSessionId != null) {
        await services.authentication.signOut(expectedSessionId);
      }
    } on Object {
      // Remote logout is best-effort. A user must always be able to clear the
      // local session and return to the sign-in screen.
    }
    if (!_isCurrentSessionOperation(generation)) return;
    _session = null;
    _isSystemUserSession = false;
    _hasAuthenticated = false;
    notifyListeners();
  }

  bool _isCurrentSessionOperation(int generation) =>
      !_isDisposed && generation == _sessionGeneration;

  void _requireCurrentSessionOperation(int generation) {
    if (!_isCurrentSessionOperation(generation)) {
      throw StateError('The session operation was superseded.');
    }
  }

  bool allows(String module, PermissionAction action) {
    final session = _session;
    return session?.allows(
          PermissionCode(module: module, action: action),
        ) ??
        false;
  }

  Future<AppSession> lock(SessionLockReason reason) async {
    final expectedSessionId = _session?.id;
    if (expectedSessionId == null) {
      throw StateError('Cannot lock without a local session.');
    }
    final generation = ++_sessionGeneration;
    _idleTimer?.cancel();
    _resetActivitySyncThrottle();
    try {
      final session = await services.authentication.lock(
        expectedSessionId,
        reason,
      );
      _requireCurrentSessionOperation(generation);
      final belongsToExpectedSession = session.id == expectedSessionId;
      if (!belongsToExpectedSession ||
          session.state != SessionState.locked) {
        if (!belongsToExpectedSession) {
          _session = null;
          _isSystemUserSession = false;
          _hasAuthenticated = true;
          notifyListeners();
        }
        throw StateError('The lock response is not the expected lock state.');
      }
      _session = session;
      notifyListeners();
      return session;
    } on Object {
      await _reconcileAfterFailedSessionTransition(
        expectedSessionId: expectedSessionId,
        generation: generation,
      );
      if (_isCurrentSessionOperation(generation) &&
          _session?.state == SessionState.active) {
        _scheduleIdleLock();
      }
      rethrow;
    }
  }

  Future<void> _reconcileAfterFailedSessionTransition({
    required EntityId expectedSessionId,
    required int generation,
  }) async {
    AppSession? authoritative;
    try {
      authoritative = await services.authentication.currentSession();
    } on Object {
      // An unavailable session endpoint cannot disprove the local session;
      // its existing timeout remains the safe fallback.
      return;
    }
    if (!_isCurrentSessionOperation(generation)) return;
    _session = authoritative?.id == expectedSessionId
        ? authoritative
        : null;
    if (_session == null) _isSystemUserSession = false;
    if (_session == null || _session!.state != SessionState.active) {
      _idleTimer?.cancel();
      _resetActivitySyncThrottle();
      notifyListeners();
    }
  }

  Future<AppSession> unlock(String password) async {
    final expectedSessionId = _session?.id;
    if (expectedSessionId == null) {
      throw StateError('Cannot unlock without a local session.');
    }
    final generation = ++_sessionGeneration;
    try {
      final session = await services.authentication.unlock(
        expectedSessionId,
        password,
      );
      final user = await services.users.getById(session.userId);
      _requireCurrentSessionOperation(generation);
      final belongsToExpectedSession = session.id == expectedSessionId;
      if (!belongsToExpectedSession ||
          session.state != SessionState.active) {
        if (!belongsToExpectedSession) {
          _session = null;
          _isSystemUserSession = false;
          _hasAuthenticated = true;
          notifyListeners();
        }
        throw StateError(
          'The unlock response is not the expected active state.',
        );
      }
      _session = session;
      _isSystemUserSession = user?.isSystemUser ?? false;
      _hasAuthenticated = true;
      _resetActivitySyncThrottle();
      _scheduleIdleLock();
      notifyListeners();
      return session;
    } on Object {
      await _reconcileAfterFailedSessionTransition(
        expectedSessionId: expectedSessionId,
        generation: generation,
      );
      rethrow;
    }
  }

  Future<void> recordActivity() async {
    final current = _session;
    if (current == null ||
        current.state != SessionState.active ||
        _isDisposed) {
      return;
    }
    // Refresh the local deadline independently of network telemetry, while
    // coalescing high-frequency hover events to avoid desktop Timer churn.
    _recordLocalActivity();
    if (_isRecordingActivity || _activitySyncCoolingDown) return;
    _isRecordingActivity = true;
    final generation = _sessionGeneration;
    final activityGeneration = ++_activitySyncGeneration;
    try {
      try {
        await services.authentication.recordActivity(current.id);
      } on Object {
        // A rejected activity write can mean that the authoritative session
        // was revoked. Still query it below before falling back to the local
        // timeout.
      }
      AppSession? latest;
      var sessionReadSucceeded = false;
      try {
        latest = await services.authentication.currentSession();
        sessionReadSucceeded = true;
      } on Object {
        // Keep the local timeout active when session refresh is unavailable.
      }
      final localSessionIsStillCurrent = !_isDisposed &&
          _sessionGeneration == generation &&
          _activitySyncGeneration == activityGeneration &&
          _session?.id == current.id &&
          _session?.state == SessionState.active;
      final isSameAuthoritativeSession = latest?.id == current.id;
      if (sessionReadSucceeded && localSessionIsStillCurrent) {
        // A different session may belong to a newer sign-in (possibly a
        // different user). Never adopt it into this store; fail closed and
        // require an explicit sign-in instead.
        _session = isSameAuthoritativeSession ? latest : null;
        if (_session == null) _isSystemUserSession = false;
        if (_session == null || _session!.state != SessionState.active) {
          _idleTimer?.cancel();
          _resetActivitySyncThrottle();
          notifyListeners();
        }
      }
    } finally {
      if (_activitySyncGeneration == activityGeneration) {
        _isRecordingActivity = false;
        if (_sessionGeneration == generation &&
            _session?.state == SessionState.active &&
            !_isDisposed) {
          _activitySyncCoolingDown = true;
          _activitySyncCooldownTimer?.cancel();
          _activitySyncCooldownTimer = Timer(
            _activityThrottleDuration,
            () => _activitySyncCoolingDown = false,
          );
        }
      }
    }
  }

  Future<void> reloadSessionPolicy() async {
    final generation = _sessionGeneration;
    final policy = await _loadAutoLockPolicy();
    if (!_isCurrentSessionOperation(generation)) return;
    _autoLockPolicy = policy;
    _scheduleIdleLock();
  }

  void resumeIdleMonitoring() {
    _idleMonitoringEnabled = true;
    _scheduleIdleLock();
  }

  void suspendIdleMonitoring() {
    _idleMonitoringEnabled = false;
    _idleTimer?.cancel();
    _resetActivitySyncThrottle();
  }

  Future<void> refreshSession() async {
    final expectedSessionId = _session?.id;
    final mayHydrate = _initialHydrationAvailable &&
        !_hasAuthenticated &&
        expectedSessionId == null;
    final generation = ++_sessionGeneration;
    try {
      final session = await services.authentication.currentSession();
      final authoritativeSessionIsExpected = session == null ||
          (expectedSessionId == null
              ? mayHydrate
              : session.id == expectedSessionId);
      final policy = authoritativeSessionIsExpected && session != null
          ? await _loadAutoLockPolicy()
          : _autoLockPolicy;
      final user = authoritativeSessionIsExpected && session != null
          ? await services.users.getById(session.userId)
          : null;
      _requireCurrentSessionOperation(generation);
      _initialHydrationAvailable = false;
      // Hydration may adopt the first authoritative session. Once this store
      // has participated in authentication, a different session must never be
      // adopted implicitly (for example after another user signs in).
      _session = authoritativeSessionIsExpected ? session : null;
      _isSystemUserSession =
          authoritativeSessionIsExpected && session != null
              ? user?.isSystemUser ?? false
              : false;
      if (authoritativeSessionIsExpected && session != null) {
        _hasAuthenticated = true;
        _autoLockPolicy = policy;
      }
      _resetActivitySyncThrottle();
      _scheduleIdleLock();
      notifyListeners();
    } on Object {
      if (_isCurrentSessionOperation(generation) &&
          _session?.state == SessionState.active) {
        _scheduleIdleLock();
      }
      rethrow;
    }
  }

  Future<AutoLockPolicy> _loadAutoLockPolicy() async {
    try {
      return await services.sessionPolicies.loadAutoLockPolicy();
    } on Object {
      // Retain the last valid rule, or fail closed to the standard desktop
      // timeout when no rule has ever loaded.
      return _autoLockPolicy ??
          AutoLockPolicy(
            isEnabled: true,
            idleTimeout: const Duration(minutes: 15),
          );
    }
  }

  void _scheduleIdleLock() {
    _idleTimer?.cancel();
    final session = _session;
    final policy = _autoLockPolicy;
    if (session == null ||
        session.state != SessionState.active ||
        policy == null ||
        !policy.isEnabled ||
        !_idleMonitoringEnabled ||
        _isDisposed) {
      return;
    }
    _idleTimer = Timer(policy.idleTimeout, _handleIdleTimeout);
  }

  void _handleIdleTimeout() {
    if (_isDisposed || _session?.state != SessionState.active) return;
    unawaited(_lockAfterIdleTimeout());
  }

  void _recordLocalActivity() {
    if (_idleRefreshCoolingDown) {
      _idleRefreshPending = true;
      return;
    }
    _scheduleIdleLock();
    final cooldown = _localActivityThrottleDuration();
    if (cooldown == Duration.zero) return;
    _idleRefreshCoolingDown = true;
    _idleRefreshCooldownTimer?.cancel();
    _idleRefreshCooldownTimer = Timer(
      cooldown,
      _completeIdleRefreshCooldown,
    );
  }

  void _completeIdleRefreshCooldown() {
    if (_isDisposed || _session?.state != SessionState.active) {
      _idleRefreshCoolingDown = false;
      _idleRefreshPending = false;
      _idleRefreshCooldownTimer = null;
      return;
    }
    if (_idleRefreshPending) {
      _idleRefreshPending = false;
      _scheduleIdleLock();
      final cooldown = _localActivityThrottleDuration();
      if (cooldown == Duration.zero) {
        _idleRefreshCoolingDown = false;
        _idleRefreshCooldownTimer = null;
        return;
      }
      _idleRefreshCooldownTimer = Timer(
        cooldown,
        _completeIdleRefreshCooldown,
      );
      return;
    }
    _idleRefreshCoolingDown = false;
    _idleRefreshCooldownTimer = null;
  }

  Duration _localActivityThrottleDuration() {
    final timeout = _autoLockPolicy?.idleTimeout;
    if (timeout == null || timeout.inMicroseconds <= 2) {
      return Duration.zero;
    }
    final halfTimeoutMicroseconds = timeout.inMicroseconds ~/ 2;
    final maximumMicroseconds = _activityThrottleDuration.inMicroseconds;
    return Duration(
      microseconds: halfTimeoutMicroseconds < maximumMicroseconds
          ? halfTimeoutMicroseconds
          : maximumMicroseconds,
    );
  }

  Future<void> _lockAfterIdleTimeout() async {
    try {
      await lock(SessionLockReason.idleTimeout);
    } on Object {
      // A concurrent sign-out or explicit lock already resolved the session.
      if (_session?.state == SessionState.active) _scheduleIdleLock();
    }
  }

  void _resetActivitySyncThrottle() {
    _activitySyncGeneration++;
    _isRecordingActivity = false;
    _activitySyncCooldownTimer?.cancel();
    _activitySyncCooldownTimer = null;
    _activitySyncCoolingDown = false;
    _idleRefreshCooldownTimer?.cancel();
    _idleRefreshCooldownTimer = null;
    _idleRefreshCoolingDown = false;
    _idleRefreshPending = false;
  }

  Future<void> clearAllData() => replaceData(AppDataProfile.cleared);

  Future<void> restoreDemoData() =>
      replaceData(AppDataProfile.originalDemo);

  /// Replaces the entire live data/service graph in one synchronous commit.
  ///
  /// Construction and every authorization read finish before any live field
  /// changes. A construction or authorization failure therefore leaves the
  /// old composition, session, revision, and generation untouched.
  Future<void> replaceData(AppDataProfile profile) async {
    final requestedBy = captureAuditActor(_services.auditWriter);
    final activeReplacementSettled = _dataReplacementSettled;
    if (activeReplacementSettled != null) {
      final conflict = const ServiceFailure(
        kind: ServiceFailureKind.conflict,
        code: 'data_replacement_in_progress',
        message: 'توجد عملية مسح أو استعادة بيانات قيد التنفيذ',
      );
      // The current graph may be retiring and unable to accept an audit write.
      // Wait for the active attempt to settle, then record the conflict in the
      // graph that actually remains live.
      await activeReplacementSettled.future;
      await _writeDataReplacementFailureAudit(
        profile: profile,
        actor: requestedBy,
        error: conflict,
      );
      throw conflict;
    }
    final replacementSettled = Completer<void>();
    _dataReplacementSettled = replacementSettled;
    _isReplacingData = true;
    var committed = false;
    AppOperationRetirement? operationRetirement;
    try {
      if (!_internalToolsEnabled) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'internal_tools_unavailable',
          message: 'هذه الأداة متاحة في النسخة الداخلية فقط',
        );
      }
      final activeSession = _session;
      if (activeSession == null ||
          activeSession.state != SessionState.active) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.authenticationRequired,
          code: 'active_session_required',
          message: 'يجب تسجيل الدخول بحساب نشط لتنفيذ هذه العملية',
        );
      }
      final authorizationGeneration = _sessionGeneration;
      if (!activeSession.allows(
        PermissionCode(
          module: 'settings',
          action: PermissionAction.manage,
        ),
      )) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'settings_manage_required',
          message: 'تتطلب هذه العملية صلاحية إدارة الإعدادات',
        );
      }
      operationRetirement =
          _services.beginOperationRetirementForDataReplacement();
      await operationRetirement.drained;
      final authoritativeSession =
          await services.authentication.currentSession();
      final authorizedUser = await services.users.getById(
        activeSession.userId,
      );
      if (!_isCurrentSessionOperation(authorizationGeneration) ||
          _session?.id != activeSession.id ||
          _session?.state != SessionState.active) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.authenticationRequired,
          code: 'active_session_required',
          message: 'انتهت الجلسة؛ سجل الدخول ثم أعد المحاولة',
        );
      }
      if (authoritativeSession == null ||
          authoritativeSession.id != activeSession.id ||
          authoritativeSession.userId != activeSession.userId ||
          authoritativeSession.state != SessionState.active ||
          !authoritativeSession.allows(
            PermissionCode(
              module: 'settings',
              action: PermissionAction.manage,
            ),
          )) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.authenticationRequired,
          code: 'authoritative_session_required',
          message: 'انتهت الجلسة؛ سجل الدخول ثم أعد المحاولة',
        );
      }
      if (authorizedUser == null || !authorizedUser.isSystemUser) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.permissionDenied,
          code: 'system_user_required',
          message: 'تتطلب هذه العملية مستخدم النظام المحمي',
        );
      }

      // This callback is deliberately synchronous: it prepares a completely
      // independent graph before the no-fail assignment block below.
      final replacement = _compositionBuilder(profile);
      await _services.retireTransactionsForDataReplacement(() async {
        // Every transaction accepted before retirement is now complete. Repeat
        // the authoritative checks against that final settled identity state.
        final finalAuthoritativeSession =
            await _services.authentication.currentSession();
        final finalAuthorizedUser = await _services.users.getById(
          activeSession.userId,
        );
        if (finalAuthoritativeSession == null ||
            finalAuthoritativeSession.id != activeSession.id ||
            finalAuthoritativeSession.userId != activeSession.userId ||
            finalAuthoritativeSession.state != SessionState.active ||
            !finalAuthoritativeSession.allows(
              PermissionCode(
                module: 'settings',
                action: PermissionAction.manage,
              ),
            )) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.authenticationRequired,
            code: 'authoritative_session_required',
            message: 'انتهت الجلسة؛ سجل الدخول ثم أعد المحاولة',
          );
        }
        if (finalAuthorizedUser == null || !finalAuthorizedUser.isSystemUser) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.permissionDenied,
            code: 'system_user_required',
            message: 'تتطلب هذه العملية مستخدم النظام المحمي',
          );
        }

        // Audit history is permanent application history, not resettable demo
        // profile data. Replace the new profile's seed journal, then append the
        // transition so IDs and request IDs continue monotonically.
        replacement.services.installAuditHistoryForDataReplacement(
          _services.auditHistoryForDataReplacement(),
        );
        await replacement.services.auditWriter.write(
          _dataReplacementEvent(
            profile: profile,
            actor: AuditActor(
              userId: finalAuthorizedUser.id,
              username: finalAuthorizedUser.username,
            ),
            outcome: AuditOutcome.success,
          ),
        );

        // These synchronous checks and assignments are the final authorization
        // gate. No local sign-out, external lock, or stale mutation can race
        // between successful revocation and the graph swap.
        if (!_isCurrentSessionOperation(authorizationGeneration) ||
            _session?.id != activeSession.id ||
            _session?.state != SessionState.active ||
            !_isSystemUserSession) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.authenticationRequired,
            code: 'active_session_required',
            message: 'انتهت الجلسة؛ سجل الدخول ثم أعد المحاولة',
          );
        }
        if (!_services.revokeSessionForDataReplacement(activeSession)) {
          throw const ServiceFailure(
            kind: ServiceFailureKind.authenticationRequired,
            code: 'authoritative_session_required',
            message: 'انتهت الجلسة؛ سجل الدخول ثم أعد المحاولة',
          );
        }

        operationRetirement!.commit();
        _repositories = replacement.repositories;
        _services = replacement.services;
        _idleTimer?.cancel();
        _resetActivitySyncThrottle();
        _sessionGeneration++;
        _session = null;
        _isSystemUserSession = false;
        _autoLockPolicy = null;
        _hasAuthenticated = false;
        _initialHydrationAvailable = false;
        _revision++;
        _dataGeneration++;
        _isReplacingData = false;
        committed = true;
        notifyListeners();
      });
    } on Object catch (error) {
      final retirement = operationRetirement;
      if (retirement != null && !retirement.isResolved) {
        retirement.rollback();
      }
      await _writeDataReplacementFailureAudit(
        profile: profile,
        actor: requestedBy,
        error: error,
      );
      rethrow;
    } finally {
      if (!committed) _isReplacingData = false;
      if (identical(_dataReplacementSettled, replacementSettled)) {
        _dataReplacementSettled = null;
      }
      if (!replacementSettled.isCompleted) replacementSettled.complete();
    }
  }

  AuditEvent _dataReplacementEvent({
    required AppDataProfile profile,
    required AuditActor actor,
    required AuditOutcome outcome,
    Map<String, Object?> failureDetails = const {},
  }) {
    final isClear = profile == AppDataProfile.cleared;
    return AuditEvent(
      action: isClear ? AuditAction.delete : AuditAction.restore,
      outcome: outcome,
      summary: switch ((isClear, outcome)) {
        (true, AuditOutcome.success) =>
          'اكتمل مسح بيانات التطبيق التجريبية',
        (false, AuditOutcome.success) =>
          'اكتملت استعادة بيانات التطبيق التجريبية',
        (true, _) => 'تعذر مسح بيانات التطبيق التجريبية',
        (false, _) => 'تعذرت استعادة بيانات التطبيق التجريبية',
      },
      actor: actor,
      details: {
        'workflow': 'internalDataReplacement',
        'targetProfile': profile.name,
        'demoOnly': true,
        if (isClear)
          'deletionScope': const [
            'businessData',
            'operationalSettings',
            'backupHistory',
            'archiveDocuments',
            'nonBootstrapIdentity',
          ],
        ...failureDetails,
      },
      before: {'dataGeneration': _dataGeneration},
      after: outcome == AuditOutcome.success
          ? {
              'dataGeneration': _dataGeneration + 1,
              'profile': profile.name,
            }
          : const {},
      entityType: 'applicationData',
      entityId: EntityId('application-data'),
    );
  }

  Future<void> _writeDataReplacementFailureAudit({
    required AppDataProfile profile,
    required AuditActor? actor,
    required Object error,
  }) {
    return writeAuditBestEffort(
      _services.auditWriter,
      _dataReplacementEvent(
        profile: profile,
        actor: actor ??
            const AuditActor(userId: null, username: 'system'),
        outcome: auditFailureOutcome(error),
        failureDetails: safeAuditFailureDetails(error),
      ),
    );
  }

  /// Feature controllers call this after a repository mutation when they are
  /// migrated. It gives cross-module listeners one lightweight invalidation
  /// signal without coupling repositories to presentation state.
  void markDataChanged() {
    _revision++;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sessionGeneration++;
    _idleTimer?.cancel();
    _idleRefreshCooldownTimer?.cancel();
    _activitySyncCooldownTimer?.cancel();
    super.dispose();
  }
}

class AppStoreScope extends InheritedNotifier<AppStore> {
  const AppStoreScope({
    super.key,
    required AppStore store,
    required super.child,
  }) : super(notifier: store);

  static AppStore of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppStoreScope>()
        : context.getInheritedWidgetOfExactType<AppStoreScope>();
    assert(scope != null, 'No AppStoreScope found in this context');
    return scope!.notifier!;
  }
}

class AppStoreProvider extends StatefulWidget {
  const AppStoreProvider({
    super.key,
    this.store,
    this.internalToolsEnabled = true,
    required this.child,
  });

  final AppStore? store;
  final bool internalToolsEnabled;
  final Widget child;

  @override
  State<AppStoreProvider> createState() => _AppStoreProviderState();
}

class _AppStoreProviderState extends State<AppStoreProvider> {
  late AppStore _store;
  late bool _ownsStore;

  @override
  void initState() {
    super.initState();
    _setStore(widget.store);
  }

  @override
  void didUpdateWidget(AppStoreProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store == widget.store &&
        oldWidget.internalToolsEnabled == widget.internalToolsEnabled) {
      return;
    }
    if (_ownsStore) _store.dispose();
    _setStore(widget.store);
  }

  void _setStore(AppStore? suppliedStore) {
    _ownsStore = suppliedStore == null;
    _store = suppliedStore ??
        AppStore.demo(
          internalToolsEnabled: widget.internalToolsEnabled,
        );
  }

  @override
  void dispose() {
    if (_ownsStore) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStoreScope(store: _store, child: widget.child);
  }
}
