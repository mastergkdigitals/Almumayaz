import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../features/authentication/domain/session_models.dart';
import '../../features/permissions/domain/permission_models.dart';
import '../domain/business_values.dart';
import 'app_repositories.dart';
import 'app_services.dart';

class AppStore extends ChangeNotifier {
  AppStore({
    required this.repositories,
    AppServices? services,
  }) : services = services ?? AppServices.demo();

  factory AppStore.demo() {
    return AppStore(
      repositories: AppRepositories.demo(),
      services: AppServices.demo(),
    );
  }

  factory AppStore.desktop() {
    final repositories = AppRepositories.demo();
    return AppStore(
      repositories: repositories,
      services: AppServices.desktop(
        deviceSettings: repositories.deviceSettings,
      ),
    );
  }

  final AppRepositories repositories;
  final AppServices services;
  AppSession? _session;
  AutoLockPolicy? _autoLockPolicy;
  Timer? _idleTimer;
  Timer? _activitySyncCooldownTimer;
  bool _isRecordingActivity = false;
  bool _activitySyncCoolingDown = false;
  bool _idleMonitoringEnabled = true;
  bool _hasAuthenticated = false;
  bool _initialHydrationAvailable = true;
  bool _isDisposed = false;
  int _sessionGeneration = 0;
  int _activitySyncGeneration = 0;
  int _revision = 0;

  AppSession? get session => _session;
  bool get requiresAuthentication =>
      _hasAuthenticated && _session?.state != SessionState.active;
  int get revision => _revision;

  Future<AppSession> signIn(SignInCredentials credentials) async {
    _initialHydrationAvailable = false;
    final generation = ++_sessionGeneration;
    final session = await services.authentication.signIn(credentials);
    final policy = await _loadAutoLockPolicy();
    _requireCurrentSessionOperation(generation);
    _session = session;
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
      _requireCurrentSessionOperation(generation);
      final belongsToExpectedSession = session.id == expectedSessionId;
      if (!belongsToExpectedSession ||
          session.state != SessionState.active) {
        if (!belongsToExpectedSession) {
          _session = null;
          _hasAuthenticated = true;
          notifyListeners();
        }
        throw StateError(
          'The unlock response is not the expected active state.',
        );
      }
      _session = session;
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
    // Reset the local deadline before any network/service await. If telemetry
    // hangs, the newly scheduled timer still enforces the lock policy.
    _scheduleIdleLock();
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
            const Duration(seconds: 1),
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
      _requireCurrentSessionOperation(generation);
      _initialHydrationAvailable = false;
      // Hydration may adopt the first authoritative session. Once this store
      // has participated in authentication, a different session must never be
      // adopted implicitly (for example after another user signs in).
      _session = authoritativeSessionIsExpected ? session : null;
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
    required this.child,
  });

  final AppStore? store;
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
    if (oldWidget.store == widget.store) return;
    if (_ownsStore) _store.dispose();
    _setStore(widget.store);
  }

  void _setStore(AppStore? suppliedStore) {
    _ownsStore = suppliedStore == null;
    _store = suppliedStore ?? AppStore.demo();
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
