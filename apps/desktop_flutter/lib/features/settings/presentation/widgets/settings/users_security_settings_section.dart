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
        SettingsTemplateTabs<String>(
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

  Widget _buildUsersTemplate() {
    return SettingsTemplatePanel(
      key: const Key('settingsUsersPanel'),
      title: 'المستخدمون',
      icon: Icons.people_alt_outlined,
      accentColor: widget.accentColor,
      actions: [
        AppRegularButton(
          key: const Key('settingsAddUserButton'),
          label: 'مستخدم جديد',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: _canManageSecurity ? _openAddUserDialog : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInfoBanner(
            message:
                'يمكن تفعيل الحساب أو تعطيله أو قفله، وتغيير كلمة مروره من قائمة المستخدمين.',
            icon: Icons.info_outline_rounded,
            foregroundColor: widget.accentColor,
            backgroundColor: Color.alphaBlend(
              widget.accentColor.withAlpha(18),
              AppColors.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: const Key('settingsUsersTable'),
            height: 430,
            rowHeight: 58,
            minimumColumnWidth: 150,
            accentColor: widget.accentColor,
            showShadow: false,
            emptyState: const AppStatePanel(
              type: AppStateType.empty,
              title: 'لا يوجد مستخدمون',
              message: 'أضف مستخدماً جديداً لبدء إدارة الحسابات.',
            ),
            columns: const [
              AppTableColumn(label: 'الاسم الكامل', flex: 1.3),
              AppTableColumn(
                label: 'اسم المستخدم',
                textDirection: TextDirection.ltr,
                flex: 1,
              ),
              AppTableColumn(label: 'الدور', flex: 1),
              AppTableColumn(label: 'الحالة', flex: 0.8),
              AppTableColumn(label: 'آخر دخول', numeric: true, flex: 1.35),
              AppTableColumn(label: 'الإجراءات', flex: 1.7),
            ],
            rows: [
              for (final user in _users)
                AppTableRow(
                  rowKey: Key('settingsUserRow_${user.keySuffix}'),
                  cells: [
                    Text(user.fullName),
                    Text(user.username, textDirection: TextDirection.ltr),
                    Builder(
                      builder: (context) {
                        final label = _settingsUserRoleLabel(user, _roles);
                        final missing = label == 'مرجع دور مفقود';
                        return Text(
                          label,
                          key: missing
                              ? Key(
                                  'settingsUserMissingRole_'
                                  '${user.keySuffix}',
                                )
                              : null,
                          style: missing
                              ? const TextStyle(color: AppColors.danger)
                              : null,
                        );
                      },
                    ),
                    Center(
                      key: Key('settingsUserStatus_${user.keySuffix}'),
                      child: _userStatusBadge(user),
                    ),
                    Text(
                      user.lastLoginAt == null
                          ? 'لم يسجل الدخول'
                          : _formatAuditTimestamp(user.lastLoginAt!),
                    ),
                    Center(
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          AppTableActionButton(
                            key: Key(
                              'settingsUserEnable_${user.keySuffix}',
                            ),
                            icon: user.isEnabled
                                ? Icons.person_off_outlined
                                : Icons.person_outline_rounded,
                            tooltip: user.isEnabled
                                ? 'تعطيل الحساب'
                                : 'تفعيل الحساب',
                            variant: user.isEnabled
                                ? AppButtonVariant.warning
                                : AppButtonVariant.success,
                            onPressed: user.isSystemUser || !_canManageSecurity
                                ? null
                                : () => _toggleUserEnabled(user),
                          ),
                          AppTableActionButton(
                            key: Key(
                              'settingsUserLock_${user.keySuffix}',
                            ),
                            icon: user.isLocked
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            tooltip: user.isLocked
                                ? 'فتح القفل'
                                : 'قفل الحساب',
                            variant: AppButtonVariant.warning,
                            onPressed: user.isSystemUser || !_canManageSecurity
                                ? null
                                : () => _toggleUserLock(user),
                          ),
                          AppTableActionButton(
                            key: Key(
                              'settingsUserPassword_${user.keySuffix}',
                            ),
                            icon: Icons.password_rounded,
                            tooltip: 'إعادة تعيين كلمة المرور',
                            onPressed: _canManageSecurity
                                ? () => _openUserPasswordDialog(user)
                                : null,
                          ),
                          AppTableActionButton(
                            key: Key(
                              'settingsUserEdit_${user.keySuffix}',
                            ),
                            icon: Icons.edit_outlined,
                            tooltip: 'تعديل المستخدم',
                            onPressed: _canManageSecurity
                                ? () => _openEditUserDialog(user)
                                : null,
                          ),
                          AppTableActionButton(
                            key: Key(
                              'settingsUserDelete_${user.keySuffix}',
                            ),
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'حذف المستخدم',
                            variant: AppButtonVariant.danger,
                            onPressed: user.isSystemUser || !_canManageSecurity
                                ? null
                                : () => _deleteUser(user),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolesTemplate() {
    return SettingsTemplatePanel(
      key: const Key('settingsRolesPanel'),
      title: 'الأدوار والصلاحيات',
      icon: Icons.admin_panel_settings_outlined,
      accentColor: widget.accentColor,
      actions: [
        AppRegularButton(
          key: const Key('settingsAddRoleButton'),
          label: 'دور جديد',
          icon: Icons.add_moderator_outlined,
          onPressed: _canManageSecurity ? _openRoleDialog : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInfoBanner(
            message:
                'هذا نموذج لتجميع صلاحيات العرض والإضافة والتعديل والحذف والطباعة والتصدير والإدارة ضمن أدوار واضحة.',
            icon: Icons.verified_user_outlined,
            foregroundColor: widget.accentColor,
            backgroundColor: Color.alphaBlend(
              widget.accentColor.withAlpha(18),
              AppColors.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: const Key('settingsRolesTable'),
            height: 390,
            rowHeight: 62,
            minimumColumnWidth: 160,
            accentColor: widget.accentColor,
            showShadow: false,
            emptyState: const AppStatePanel(
              type: AppStateType.empty,
              title: 'لا توجد أدوار',
              message: 'أضف دوراً جديداً وحدد صلاحياته.',
            ),
            columns: const [
              AppTableColumn(label: 'ت', flex: 0.4, numeric: true),
              AppTableColumn(label: 'الدور', flex: 1.1),
              AppTableColumn(
                label: 'عدد المستخدمين',
                numeric: true,
                flex: 0.9,
              ),
              AppTableColumn(label: 'ملخص الصلاحيات', flex: 2),
              AppTableColumn(label: 'الإجراءات', flex: 0.9),
            ],
            rows: [
              for (final role in _roles)
                AppTableRow(
                  rowKey: Key('settingsRoleRow_${role.keySuffix}'),
                  cells: [
                    Text(role.displayNumber, textAlign: TextAlign.center),
                    Text(role.name),
                    Text(
                      '${_roleUsersCount(role.id)}',
                      key: Key(
                        'settingsRoleUserCount_${role.keySuffix}',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _rolePermissionSummary(role.permissions),
                      key: Key('settingsRoleSummary_${role.keySuffix}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Center(
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          AppTableActionButton(
                            key: Key(
                              'settingsRolePermissions_${role.keySuffix}',
                            ),
                            icon: Icons.rule_rounded,
                            tooltip: role.isSystemRole
                                ? 'دور النظام محمي'
                                : 'تعديل الصلاحيات',
                            onPressed: role.isSystemRole || !_canManageSecurity
                                ? null
                                : () => _openRoleDialog(role: role),
                          ),
                          AppTableActionButton(
                            key: Key(
                              'settingsRoleDelete_${role.keySuffix}',
                            ),
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'حذف الدور',
                            variant: AppButtonVariant.danger,
                            onPressed: role.isSystemRole || !_canManageSecurity
                                ? null
                                : () => _deleteRole(role),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTemplate() {
    return SettingsResponsiveGrid(
      key: const Key('settingsPasswordLockTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 430,
      children: [
        SettingsTemplatePanel(
          key: const Key('settingsChangePasswordPanel'),
          title: 'تغيير كلمة المرور',
          icon: Icons.password_rounded,
          accentColor: widget.accentColor,
          child: Column(
            children: [
              AppTextField(
                fieldKey: const Key('settingsCurrentPasswordField'),
                controller: _currentPasswordController,
                label: 'كلمة المرور الحالية',
                icon: Icons.lock_outline_rounded,
                accentColor: widget.accentColor,
                obscureText: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                fieldKey: const Key('settingsNewPasswordField'),
                controller: _newPasswordController,
                label: 'كلمة المرور الجديدة',
                icon: Icons.key_rounded,
                accentColor: widget.accentColor,
                obscureText: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                fieldKey: const Key('settingsConfirmPasswordField'),
                controller: _confirmPasswordController,
                label: 'تأكيد كلمة المرور الجديدة',
                icon: Icons.verified_user_outlined,
                accentColor: widget.accentColor,
                obscureText: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                onSubmitted: (_) => _savePassword(),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  key: const Key('settingsSavePasswordButton'),
                  label: 'تغيير كلمة المرور',
                  icon: Icons.save_outlined,
                  minWidth: 190,
                  onPressed: _savePassword,
                ),
              ),
            ],
          ),
        ),
        SettingsTemplatePanel(
          key: const Key('settingsIdleLockPanel'),
          title: 'القفل التلقائي',
          icon: Icons.lock_clock_outlined,
          accentColor: widget.accentColor,
          child: Column(
            children: [
              AppSwitchField(
                key: const Key('settingsIdleLockSwitch'),
                title: 'قفل التطبيق بعد الخمول',
                subtitle:
                    'يعيد المستخدم إلى شاشة الدخول بعد مدة دون استخدام',
                icon: Icons.timer_outlined,
                accentColor: widget.accentColor,
                value: _idleLockEnabled,
                onChanged: (value) {
                  setState(() => _idleLockEnabled = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdownField<String>(
                fieldKey: const Key('settingsIdleLockDurationField'),
                label: 'مدة الخمول',
                icon: Icons.schedule_rounded,
                accentColor: widget.accentColor,
                value: _idleLockDuration,
                enabled: _idleLockEnabled,
                options: const [
                  AppDropdownOption(value: '5 دقائق', label: '5 دقائق'),
                  AppDropdownOption(
                    value: '15 دقيقة',
                    label: '15 دقيقة',
                  ),
                  AppDropdownOption(
                    value: '30 دقيقة',
                    label: '30 دقيقة',
                  ),
                  AppDropdownOption(value: '60 دقيقة', label: '60 دقيقة'),
                ],
                useIntrinsicHeight: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                menuTextDirection: TextDirection.rtl,
                onChanged: (value) {
                  if (value == null || value == _idleLockDuration) return;
                  setState(() => _idleLockDuration = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppInfoBanner(
                key: const Key('settingsCurrentSessionState'),
                message: _currentSession == null
                    ? 'لا توجد جلسة تجريبية حالية.'
                    : 'الجلسة ${_sessionStateLabel(_currentSession!.state)} — '
                        'آخر نشاط ${_formatAuditTimestamp(_currentSession!.lastActivityAt)}',
                icon: Icons.devices_outlined,
                foregroundColor: widget.accentColor,
                backgroundColor: Color.alphaBlend(
                  widget.accentColor.withAlpha(18),
                  AppColors.surface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppInfoBanner(
                message:
                    'القفل لا يغلق التطبيق ولا يفقد العمل المحفوظ؛ يطلب تسجيل الدخول فقط.',
                icon: Icons.security_rounded,
                foregroundColor: widget.accentColor,
                backgroundColor: Color.alphaBlend(
                  widget.accentColor.withAlpha(18),
                  AppColors.surface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: AppRegularButton(
                  key: const Key('settingsToggleDemoSessionLockButton'),
                  label: 'قفل الجلسة الآن',
                  icon: Icons.lock_clock_outlined,
                  onPressed: _currentSession?.state == SessionState.active
                      ? _toggleCurrentSessionLock
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  key: const Key('settingsSaveIdleLockButton'),
                  label: 'حفظ إعداد القفل',
                  icon: Icons.save_outlined,
                  minWidth: 180,
                  onPressed: _canManageSecurity ? _saveIdleLock : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAuditDetails(AuditRecord record) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _SettingsAuditDetailsDialog(
          record: record,
          accentColor: widget.accentColor,
        ),
      ),
    );
  }

  Widget _buildLogsTemplate() {
    return SettingsTemplatePanel(
      key: const Key('settingsSecurityLogsPanel'),
      title: 'سجل الدخول والنشاط والتعديلات',
      icon: Icons.receipt_long_outlined,
      accentColor: widget.accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsResponsiveGrid(
            preferredColumns: 3,
            children: [
              AppSearchField(
                fieldKey: const Key('settingsSecurityLogSearchField'),
                controller: _logSearchController,
                label: 'بحث في السجل',
                hint: 'المستخدم أو العملية أو التفاصيل',
                accentColor: widget.accentColor,
                focusNode: _logSearchFocusNode,
                onChanged: (_) => _refreshAudit(),
              ),
              AppDropdownField<String>(
                fieldKey: const Key('settingsSecurityLogTypeField'),
                label: 'نوع العملية',
                icon: Icons.filter_alt_outlined,
                accentColor: widget.accentColor,
                value: _logType,
                options: const [
                  AppDropdownOption(value: 'الكل', label: 'الكل'),
                  AppDropdownOption(value: 'تسجيل الدخول', label: 'تسجيل الدخول'),
                  AppDropdownOption(value: 'تسجيل الخروج', label: 'تسجيل الخروج'),
                  AppDropdownOption(value: 'قفل الجلسة', label: 'قفل الجلسة'),
                  AppDropdownOption(value: 'فتح الجلسة', label: 'فتح الجلسة'),
                  AppDropdownOption(value: 'نشاط الجلسة', label: 'نشاط الجلسة'),
                  AppDropdownOption(value: 'إضافة', label: 'إضافة'),
                  AppDropdownOption(value: 'تعديل', label: 'تعديل'),
                  AppDropdownOption(value: 'حذف', label: 'حذف'),
                  AppDropdownOption(value: 'استعادة', label: 'استعادة'),
                  AppDropdownOption(value: 'طباعة', label: 'طباعة'),
                  AppDropdownOption(value: 'تصدير', label: 'تصدير'),
                  AppDropdownOption(value: 'صلاحيات', label: 'صلاحيات'),
                  AppDropdownOption(value: 'حالة حساب', label: 'حالة حساب'),
                  AppDropdownOption(value: 'كلمة المرور', label: 'كلمة المرور'),
                  AppDropdownOption(value: 'نسخ احتياطي', label: 'نسخ احتياطي'),
                  AppDropdownOption(value: 'أخرى', label: 'أخرى'),
                ],
                useIntrinsicHeight: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                menuTextDirection: TextDirection.rtl,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _logType = value);
                  _refreshAudit();
                },
              ),
              AppDropdownField<String>(
                fieldKey: const Key('settingsSecurityLogOutcomeField'),
                label: 'نتيجة العملية',
                icon: Icons.fact_check_outlined,
                accentColor: widget.accentColor,
                value: _logOutcome,
                options: const [
                  AppDropdownOption(value: 'الكل', label: 'الكل'),
                  AppDropdownOption(value: 'مكتمل', label: 'مكتمل'),
                  AppDropdownOption(value: 'فشل', label: 'فشل'),
                  AppDropdownOption(value: 'محظور', label: 'محظور'),
                ],
                useIntrinsicHeight: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                menuTextDirection: TextDirection.rtl,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _logOutcome = value);
                  _refreshAudit();
                },
              ),
              AppDropdownField<String>(
                fieldKey: const Key('settingsSecurityLogUserField'),
                label: 'المستخدم',
                icon: Icons.person_search_outlined,
                accentColor: widget.accentColor,
                value: _logUserId?.value ?? 'all',
                options: [
                  const AppDropdownOption(value: 'all', label: 'الكل'),
                  for (final user in _users)
                    AppDropdownOption(
                      value: user.id.value,
                      label: '${user.fullName} (${user.username})',
                    ),
                ],
                useIntrinsicHeight: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                menuTextDirection: TextDirection.rtl,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _logUserId = value == 'all' ? null : EntityId(value);
                  });
                  _refreshAudit();
                },
              ),
              AppDateRangeField(
                fieldKey: const Key('settingsSecurityLogDateRangeField'),
                label: 'الفترة الزمنية',
                value: _logDateRange,
                accentColor: widget.accentColor,
                onChanged: (value) {
                  setState(() => _logDateRange = value);
                  _refreshAudit();
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AppRegularButton(
                  key: const Key('settingsSecurityLogResetFiltersButton'),
                  label: 'إعادة ضبط المرشحات',
                  icon: Icons.filter_alt_off_outlined,
                  onPressed: () {
                    _logSearchController.clear();
                    setState(() {
                      _logType = 'الكل';
                      _logOutcome = 'الكل';
                      _logUserId = null;
                      _logDateRange = null;
                    });
                    _refreshAudit();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'عدد النتائج: $_auditTotalCount',
            key: const Key('settingsSecurityLogResultCount'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDataTable(
            key: const Key('settingsSecurityLogsTable'),
            height: 430,
            rowHeight: 58,
            minimumColumnWidth: 155,
            accentColor: widget.accentColor,
            showShadow: false,
            emptyState: const AppStatePanel(
              type: AppStateType.empty,
              title: 'لا توجد نتائج',
              message: 'غيّر عبارة البحث أو نوع العملية.',
            ),
            columns: const [
              AppTableColumn(
                label: 'التاريخ والوقت',
                numeric: true,
                flex: 1.4,
              ),
              AppTableColumn(label: 'المستخدم', flex: 0.8),
              AppTableColumn(label: 'العملية', flex: 0.9),
              AppTableColumn(label: 'التفاصيل', flex: 2.2),
              AppTableColumn(label: 'الحالة', flex: 0.75),
            ],
            rows: [
              for (final entry in _auditEntries)
                AppTableRow(
                  rowKey: Key(
                    'settingsAuditRow_${_entityKeySuffix(entry.id)}',
                  ),
                  onTap: () => _showAuditDetails(entry.record),
                  cells: [
                    Text(entry.createdAt),
                    Text(
                      entry.username,
                      textDirection: TextDirection.ltr,
                    ),
                    Text(entry.type),
                    Text(entry.details, overflow: TextOverflow.ellipsis),
                    Center(
                      child: AppStatusBadge(
                        label: entry.status,
                        tone: switch (entry.record.outcome) {
                          AuditOutcome.success => AppStatusTone.success,
                          AuditOutcome.failure => AppStatusTone.danger,
                          AuditOutcome.blocked => AppStatusTone.warning,
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userStatusBadge(_SettingsUser user) {
    final (label, tone) = switch ((user.isEnabled, user.isLocked)) {
      (false, true) => ('معطل ومقفل', AppStatusTone.danger),
      (true, true) => ('مقفل', AppStatusTone.danger),
      (false, false) => ('معطل', AppStatusTone.warning),
      (true, false) => ('نشط', AppStatusTone.success),
    };
    return AppStatusBadge(
      label: label,
      tone: tone,
    );
  }
}
