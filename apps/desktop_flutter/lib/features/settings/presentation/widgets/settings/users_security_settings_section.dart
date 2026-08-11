part of '../settings_sections.dart';

class UsersSecuritySettingsSection extends StatefulWidget {
  const UsersSecuritySettingsSection({
    required this.accentColor,
    super.key,
    this.userRepository,
    this.roleRepository,
    this.authenticationService,
    this.sessionPolicyRepository,
    this.auditRepository,
    this.administrationService,
  });

  final Color accentColor;
  final UserRepository? userRepository;
  final RoleRepository? roleRepository;
  final AuthenticationService? authenticationService;
  final SessionPolicyRepository? sessionPolicyRepository;
  final AuditRepository? auditRepository;
  final SecurityAdministrationService? administrationService;

  @override
  State<UsersSecuritySettingsSection> createState() =>
      _UsersSecuritySettingsSectionState();
}

class _UsersSecuritySettingsSectionState
    extends State<UsersSecuritySettingsSection> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _logSearchController = TextEditingController();
  final _logSearchFocusNode = FocusNode();
  var _selectedTab = 'users';
  var _idleLockEnabled = true;
  var _idleLockDuration = '15 دقيقة';
  var _logType = 'الكل';
  var _logOutcome = 'الكل';
  EntityId? _logUserId;
  DateTimeRange? _logDateRange;
  var _auditRefreshGeneration = 0;
  var _auditTotalCount = 0;
  var _isLoading = true;
  String? _loadError;
  late final UserRepository _userRepository;
  late final RoleRepository _roleRepository;
  late final AuthenticationService _authenticationService;
  late final SessionPolicyRepository _sessionPolicyRepository;
  late final AuditRepository _auditRepository;
  late final SecurityAdministrationService _administrationService;
  AppSession? _currentSession;
  final _users = <_SettingsUser>[];
  final _roles = <_SettingsRole>[];
  final _auditEntries = <_SettingsAuditEntry>[];

  bool get _canManageSecurity =>
      _currentSession?.allows(
        PermissionCode(
          module: 'settings',
          action: PermissionAction.manage,
        ),
      ) ??
      false;

  @override
  void initState() {
    super.initState();
    final useStandaloneBundle = widget.userRepository == null &&
        widget.roleRepository == null &&
        widget.authenticationService == null &&
        widget.sessionPolicyRepository == null &&
        widget.auditRepository == null &&
        widget.administrationService == null;
    final defaults =
        useStandaloneBundle ? DemoIdentityServiceBundle() : null;
    _userRepository = widget.userRepository ??
        defaults?.users ??
        DemoUserRepository();
    _roleRepository = widget.roleRepository ??
        defaults?.roles ??
        DemoRoleRepository();
    _authenticationService = widget.authenticationService ??
        defaults?.authentication ??
        DemoAuthenticationService();
    _sessionPolicyRepository = widget.sessionPolicyRepository ??
        defaults?.sessionPolicies ??
        DemoSessionPolicyRepository();
    _auditRepository = widget.auditRepository ??
        defaults?.audit ??
        DemoAuditRepository();
    _administrationService = widget.administrationService ??
        defaults?.administration ??
        DemoSecurityAdministrationService.fromAdapters(
          users: _userRepository,
          roles: _roleRepository,
          authentication: _authenticationService,
          audit: _auditRepository,
        );
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final roles = await _roleRepository.getAll();
      final users = await _userRepository.search(const UserQuery());
      final policy = await _sessionPolicyRepository.loadAutoLockPolicy();
      final session = await _authenticationService.currentSession();
      final auditPage = await _auditRepository.search(AuditQuery());
      if (!mounted) return;
      setState(() {
        _roles
          ..clear()
          ..addAll(roles.map(_settingsRoleFromDomain));
        _users
          ..clear()
          ..addAll(users.map(_settingsUserFromDomain));
        _idleLockEnabled = policy.isEnabled;
        _idleLockDuration = '${policy.idleTimeout.inMinutes} دقيقة';
        _currentSession = session;
        _auditEntries
          ..clear()
          ..addAll(auditPage.records.map(_settingsAuditFromDomain));
        _auditTotalCount = auditPage.totalCount;
        _isLoading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        final message = _serviceMessage(error);
        setState(() {
          _isLoading = false;
          _loadError = message;
        });
        AppToast.showError(context, message);
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _logSearchController.dispose();
    _logSearchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openAddUserDialog() async {
    final draft = await showDialog<_SettingsUserDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _SettingsUserDialog(
          accentColor: widget.accentColor,
          roles: _roles,
          existingUsernames: {
            for (final user in _users) user.username.toLowerCase(),
          },
        ),
      ),
    );
    if (draft == null || !mounted) return;
    try {
      final created = await _administrationService.createUser(
        UserCreateRequest(
          fullName: draft.fullName,
          username: draft.username,
          roleIds: draft.roleIds,
          initialPassword: draft.initialPassword!,
        ),
      );
      if (!mounted) return;
      setState(() => _users.add(_settingsUserFromDomain(created)));
      await _refreshAudit();
      if (mounted) AppToast.showInfo(context, 'تمت إضافة المستخدم');
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _openEditUserDialog(_SettingsUser user) async {
    final draft = await showDialog<_SettingsUserDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _SettingsUserDialog(
          accentColor: widget.accentColor,
          roles: _roles,
          initialUser: user,
          existingUsernames: {
            for (final entry in _users)
              if (entry.id != user.id) entry.username.toLowerCase(),
          },
        ),
      ),
    );
    if (draft == null || !mounted) return;
    try {
      final updated = await _administrationService.updateUser(
        UserUpdateRequest(
          id: user.id,
          fullName: draft.fullName,
          username: draft.username,
          roleIds: draft.roleIds,
        ),
      );
      if (!mounted) return;
      final index = _users.indexWhere((entry) => entry.id == user.id);
      if (index >= 0) {
        setState(() => _users[index] = _settingsUserFromDomain(updated));
      }
      await _refreshSessionAndAudit();
      if (mounted) AppToast.showSuccess(context, 'تم تحديث المستخدم');
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _toggleUserEnabled(_SettingsUser user) async {
    final index = _users.indexWhere((entry) => entry.id == user.id);
    if (index < 0) return;
    final isEnabled = !user.isEnabled;
    final status = _userStatusValue(
      isEnabled: isEnabled,
      isLocked: user.isLocked,
    );
    try {
      final updated =
          await _administrationService.setUserStatus(user.id, status);
      if (!mounted) return;
      setState(() => _users[index] = _settingsUserFromDomain(updated));
      await _refreshAudit();
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
      return;
    }
    if (!mounted) return;
    if (isEnabled) {
      AppToast.showSuccess(context, 'تم تفعيل الحساب');
    } else {
      AppToast.showWarning(context, 'تم تعطيل الحساب');
    }
  }

  Future<void> _toggleUserLock(_SettingsUser user) async {
    final index = _users.indexWhere((entry) => entry.id == user.id);
    if (index < 0) return;
    final isLocked = !user.isLocked;
    try {
      final updated = await _administrationService.setUserStatus(
        user.id,
        _userStatusValue(
          isEnabled: user.isEnabled,
          isLocked: isLocked,
        ),
      );
      if (!mounted) return;
      setState(() => _users[index] = _settingsUserFromDomain(updated));
      await _refreshAudit();
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
      return;
    }
    if (!mounted) return;
    AppToast.showWarning(
      context,
      isLocked ? 'تم قفل الحساب' : 'تم فتح قفل الحساب',
    );
  }

  Future<void> _openUserPasswordDialog(_SettingsUser user) async {
    final draft = await showDialog<_SettingsUserPasswordDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _SettingsUserPasswordDialog(
          user: user,
          accentColor: widget.accentColor,
        ),
      ),
    );
    if (draft == null || !mounted) return;
    try {
      await _administrationService.resetUserPassword(
        AdminPasswordResetRequest(
          userId: user.id,
          newPassword: draft.newPassword,
        ),
      );
      await _refreshAudit();
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        'تمت إعادة تعيين كلمة مرور ${user.fullName}',
      );
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _deleteUser(_SettingsUser user) async {
    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف المستخدم',
      message: 'سيتم حذف حساب ${user.fullName} نهائياً من البيانات التجريبية.',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await _administrationService.deleteUser(user.id);
      if (!mounted) return;
      setState(() => _users.removeWhere((entry) => entry.id == user.id));
      await _refreshAudit();
      if (mounted) AppToast.showSuccess(context, 'تم حذف المستخدم');
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _openRoleDialog({_SettingsRole? role}) async {
    final draft = await showDialog<_SettingsRoleDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _SettingsRoleDialog(
          accentColor: widget.accentColor,
          initialRole: role,
          existingRoleNames: {
            for (final entry in _roles)
              if (entry.id != role?.id) entry.name.trim().toLowerCase(),
          },
        ),
      ),
    );
    if (draft == null || !mounted) return;
    try {
      final saved = await _administrationService.saveRole(
        RoleSaveRequest(
          id: role?.id,
          name: draft.name,
          permissions: _permissionCodesFromSettings(draft.permissions),
        ),
      );
      if (!mounted) return;
      final view = _settingsRoleFromDomain(saved);
      setState(() {
        final index = _roles.indexWhere((entry) => entry.id == saved.id);
        if (index < 0) {
          _roles.add(view);
        } else {
          _roles[index] = view;
        }
      });
      await _refreshSessionAndAudit();
      if (mounted) {
        role == null
            ? AppToast.showInfo(context, 'تمت إضافة الدور')
            : AppToast.showSuccess(context, 'تم تحديث الدور والصلاحيات');
      }
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _deleteRole(_SettingsRole role) async {
    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف الدور',
      message: 'سيتم حذف الدور ${role.name} نهائياً إذا لم يكن مرتبطاً بمستخدم.',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await _administrationService.deleteRole(role.id);
      if (!mounted) return;
      setState(() => _roles.removeWhere((entry) => entry.id == role.id));
      await _refreshAudit();
      if (mounted) AppToast.showSuccess(context, 'تم حذف الدور');
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  int _roleUsersCount(EntityId roleId) {
    return _users.where((user) => user.roleIds.contains(roleId)).length;
  }

  void _focusLogSearch() {
    setState(() => _selectedTab = 'logs');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _logSearchFocusNode.requestFocus();
    });
  }

  Future<void> _refreshSessionAndAudit() async {
    final scope = context.getInheritedWidgetOfExactType<AppStoreScope>();
    await scope?.notifier?.refreshSession();
    _currentSession = await _authenticationService.currentSession();
    await _refreshAudit();
  }

  Future<void> _savePassword() async {
    final current = _currentPasswordController.text;
    final password = _newPasswordController.text;
    final confirmation = _confirmPasswordController.text;
    if (current.isEmpty || password.isEmpty || confirmation.isEmpty) {
      AppToast.showWarning(context, 'أكمل حقول كلمة المرور');
      return;
    }
    if (password != confirmation) {
      AppToast.showError(context, 'كلمتا المرور الجديدتان غير متطابقتين');
      return;
    }
    final userId = _currentSession?.userId;
    if (userId == null) {
      AppToast.showError(context, 'لا توجد جلسة حالية');
      return;
    }
    try {
      await _authenticationService.changePassword(
        PasswordChangeRequest(
          userId: userId,
          currentPassword: current,
          newPassword: password,
        ),
      );
      await _refreshAudit();
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      AppToast.showSuccess(context, 'تم تغيير كلمة المرور');
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _saveIdleLock() async {
    final minutes = int.tryParse(_idleLockDuration.split(' ').first) ?? 15;
    try {
      await _sessionPolicyRepository.saveAutoLockPolicy(
        AutoLockPolicy(
          isEnabled: _idleLockEnabled,
          idleTimeout: Duration(minutes: minutes),
        ),
      );
      if (!mounted) return;
      final scope = context.getInheritedWidgetOfExactType<AppStoreScope>();
      final store = scope?.notifier;
      if (store != null) {
        await store.reloadSessionPolicy();
        await store.recordActivity();
      } else {
        final current = await _authenticationService.currentSession();
        if (current != null) {
          await _authenticationService.recordActivity(current.id);
        }
      }
      _currentSession = await _authenticationService.currentSession();
      await _refreshAudit();
      if (!mounted) return;
      setState(() {});
      AppToast.showSuccess(context, 'تم حفظ سياسة القفل');
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _toggleCurrentSessionLock() async {
    try {
      final scope = context.getInheritedWidgetOfExactType<AppStoreScope>();
      final store = scope?.notifier;
      final current = store?.session ??
          await _authenticationService.currentSession();
      if (current == null || current.state != SessionState.active) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.authenticationRequired,
          message: 'لا توجد جلسة نشطة حالية',
        );
      }
      final session = store == null
          ? await _authenticationService.lock(
              current.id,
              SessionLockReason.userRequest,
            )
          : await store.lock(SessionLockReason.userRequest);
      if (!mounted) return;
      setState(() => _currentSession = session);
      await _refreshAudit();
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _refreshAudit() async {
    final generation = ++_auditRefreshGeneration;
    final range = _logDateRange;
    try {
      final page = await _auditRepository.search(
        AuditQuery(
          searchText: _logSearchController.text,
          actorUserId: _logUserId,
          action: _auditActionForLabel(_logType),
          outcome: _auditOutcomeForLabel(_logOutcome),
          from: range == null ? null : AuditTimestamp(range.start),
          to: range == null
              ? null
              : AuditTimestamp(
                  DateTime(
                    range.end.year,
                    range.end.month,
                    range.end.day,
                    23,
                    59,
                    59,
                    999,
                  ),
                ),
        ),
      );
      if (!mounted || generation != _auditRefreshGeneration) return;
      setState(() {
        _auditEntries
          ..clear()
          ..addAll(page.records.map(_settingsAuditFromDomain));
        _auditTotalCount = page.totalCount;
      });
    } on Object catch (error) {
      if (!mounted || generation != _auditRefreshGeneration) return;
      AppToast.showError(context, _serviceMessage(error));
    }
  }

  void _setSecurityViewState(VoidCallback update) => setState(update);

  @override
  Widget build(BuildContext context) {
    final selectedTabIndex = switch (_selectedTab) {
      'roles' => 1,
      'security' => 2,
      'logs' => 3,
      _ => 0,
    };
    final content = ListView(
      key: const Key('usersSecuritySettingsContent'),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (_loadError != null) ...[
          AppStatePanel(
            key: const Key('settingsUsersSecurityLoadError'),
            type: AppStateType.error,
            title: 'تعذر تحميل بيانات المستخدمين والأمان',
            message: _loadError!,
            actionLabel: 'إعادة المحاولة',
            onAction: _loadSecurityState,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AppSelectionTabs<String>(
          keyPrefix: 'usersSecurityTab_',
          accentColor: widget.accentColor,
          selected: _selectedTab,
          onChanged: (value) => setState(() => _selectedTab = value),
          items: const [
            (
              value: 'users',
              label: 'المستخدمون',
              icon: Icons.manage_accounts_outlined,
            ),
            (
              value: 'roles',
              label: 'الأدوار والصلاحيات',
              icon: Icons.admin_panel_settings_outlined,
            ),
            (
              value: 'security',
              label: 'كلمة المرور والقفل',
              icon: Icons.lock_outline_rounded,
            ),
            (
              value: 'logs',
              label: 'السجلات',
              icon: Icons.receipt_long_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        IndexedStack(
          key: const Key('settingsUsersSecurityTabStack'),
          index: selectedTabIndex,
          children: [
            _buildUsersTemplate(),
            _buildRolesTemplate(),
            _buildSecurityTemplate(),
            _buildLogsTemplate(),
          ],
        ),
      ],
    );
    return AppShortcutScope(
      onSearch: _focusLogSearch,
      child: AppLoadingOverlay(
        key: const Key('settingsUsersSecurityLoadingOverlay'),
        isLoading: _isLoading,
        message: 'جاري تحميل المستخدمين والأمان',
        child: content,
      ),
    );
  }
}
