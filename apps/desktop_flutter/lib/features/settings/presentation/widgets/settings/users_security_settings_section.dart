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
  });

  final Color accentColor;
  final UserRepository? userRepository;
  final RoleRepository? roleRepository;
  final AuthenticationService? authenticationService;
  final SessionPolicyRepository? sessionPolicyRepository;
  final AuditRepository? auditRepository;

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
  var _nextUserId = 4;
  var _nextRoleId = 5;
  var _nextAuditId = 6;
  var _isLoading = true;
  String? _loadError;
  late final UserRepository _userRepository;
  late final RoleRepository _roleRepository;
  late final AuthenticationService _authenticationService;
  late final SessionPolicyRepository _sessionPolicyRepository;
  late final AuditRepository _auditRepository;
  AppSession? _currentSession;
  final _users = <_SettingsUser>[
    const _SettingsUser(
      id: 1,
      fullName: 'مدير النظام',
      username: 'admin',
      role: 'مدير النظام',
      isEnabled: true,
      isLocked: false,
      lastLogin: '2026/07/29 09:02 ص',
    ),
    const _SettingsUser(
      id: 2,
      fullName: 'أحمد كريم',
      username: 'ahmed',
      role: 'المبيعات',
      isEnabled: true,
      isLocked: false,
      lastLogin: '2026/07/28 05:40 م',
    ),
    const _SettingsUser(
      id: 3,
      fullName: 'سارة علي',
      username: 'sara',
      role: 'الحسابات',
      isEnabled: true,
      isLocked: true,
      lastLogin: '2026/07/26 11:20 ص',
    ),
  ];

  final _roles = <_SettingsRole>[
    _SettingsRole(
      id: 1,
      name: 'مدير النظام',
      permissions: _allSettingsRolePermissions(),
    ),
    _SettingsRole(
      id: 2,
      name: 'المبيعات',
      permissions: _settingsRolePermissions(
        sales: _allPermissionActionIds,
        parties: {'view', 'edit'},
        reports: {'view', 'print'},
      ),
    ),
    _SettingsRole(
      id: 3,
      name: 'الحسابات',
      permissions: _settingsRolePermissions(
        cashbox: _allPermissionActionIds,
        parties: {'view'},
        reports: {'view', 'print'},
      ),
    ),
    _SettingsRole(
      id: 4,
      name: 'عرض فقط',
      permissions: _viewOnlySettingsRolePermissions(),
    ),
  ];

  final _auditEntries = <_SettingsAuditEntry>[
    _SettingsAuditEntry(
      id: 1,
      createdAt: '2026/07/29 09:02 ص',
      username: 'admin',
      type: 'تسجيل الدخول',
      details: 'تسجيل دخول ناجح من جهاز المكتب الرئيسي',
      status: 'ناجح',
    ),
    _SettingsAuditEntry(
      id: 2,
      createdAt: '2026/07/29 09:18 ص',
      username: 'admin',
      type: 'تعديل',
      details: 'تعديل بيانات المادة: ورق A4',
      status: 'مكتمل',
    ),
    _SettingsAuditEntry(
      id: 3,
      createdAt: '2026/07/29 09:27 ص',
      username: 'ahmed',
      type: 'حذف',
      details: 'حذف قائمة بيع تجريبية رقم 1042',
      status: 'مكتمل',
    ),
    _SettingsAuditEntry(
      id: 4,
      createdAt: '2026/07/29 09:31 ص',
      username: 'admin',
      type: 'استعادة',
      details: 'استعادة قائمة البيع رقم 1042',
      status: 'مكتمل',
    ),
    _SettingsAuditEntry(
      id: 5,
      createdAt: '2026/07/28 04:12 م',
      username: 'sara',
      type: 'تسجيل الدخول',
      details: 'محاولة دخول بكلمة مرور غير صحيحة',
      status: 'فشل',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _userRepository = widget.userRepository ?? DemoUserRepository();
    _roleRepository = widget.roleRepository ?? DemoRoleRepository();
    _authenticationService =
        widget.authenticationService ?? DemoAuthenticationService();
    _sessionPolicyRepository = widget.sessionPolicyRepository ??
        DemoSessionPolicyRepository();
    _auditRepository = widget.auditRepository ?? DemoAuditRepository();
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
      final roleNames = {for (final role in roles) role.id: role.name};
      setState(() {
        _nextRoleId = _nextEntitySequence(
          roles.map((role) => role.id),
          fallback: 5,
        );
        _nextUserId = _nextEntitySequence(
          users.map((user) => user.id),
          fallback: 4,
        );
        _nextAuditId = _nextEntitySequence(
          auditPage.records.map((record) => record.id),
          fallback: 6,
        );
        _roles
          ..clear()
          ..addAll(roles.map(_settingsRoleFromDomain));
        _users
          ..clear()
          ..addAll(
            users.map((user) => _settingsUserFromDomain(user, roleNames)),
          );
        _idleLockEnabled = policy.isEnabled;
        _idleLockDuration = '${policy.idleTimeout.inMinutes} دقيقة';
        _currentSession = session;
        _auditEntries
          ..clear()
          ..addAll(auditPage.records.map(_settingsAuditFromDomain));
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
    final roleNames = _roles.map((role) => role.name).toList();
    final draft = await showDialog<_SettingsUserDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _SettingsUserDialog(
          accentColor: widget.accentColor,
          roleNames: roleNames,
          existingUsernames: {
            for (final user in _users) user.username.toLowerCase(),
          },
        ),
      ),
    );
    if (draft == null || !mounted) return;

    final normalizedUsername = draft.username.toLowerCase();
    if (_users.any(
      (user) => user.username.toLowerCase() == normalizedUsername,
    )) {
      AppToast.showWarning(context, 'اسم المستخدم مستخدم مسبقاً');
      return;
    }

    final role = _roles.where((entry) => entry.name == draft.role).firstOrNull;
    if (role == null) {
      AppToast.showError(context, 'الدور المحدد غير موجود');
      return;
    }
    final user = _SettingsUser(
      id: _nextUserId++,
      fullName: draft.fullName,
      username: draft.username,
      role: draft.role,
      isEnabled: true,
      isLocked: false,
      lastLogin: 'لم يسجل الدخول',
    );
    try {
      await _userRepository.save(_appUserFromSettings(user, role.id));
      if (!mounted) return;
      setState(() => _users.add(user));
      await _appendAudit(
        action: AuditAction.create,
        outcome: AuditOutcome.success,
        summary: 'إضافة المستخدم ${user.username}',
        entityType: 'user',
        entityId: EntityId.demo('user', user.id),
      );
      if (mounted) AppToast.showInfo(context, 'تمت إضافة مستخدم تجريبي');
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
      await _userRepository.setStatus(
        EntityId.demo('user', user.id),
        status,
      );
      if (!mounted) return;
      setState(() {
        _users[index] = user.copyWith(isEnabled: isEnabled);
      });
      await _appendAudit(
        action: AuditAction.accountStatusChange,
        outcome: AuditOutcome.success,
        summary: isEnabled
            ? 'تفعيل حساب ${user.username}'
            : 'تعطيل حساب ${user.username}',
        entityType: 'user',
        entityId: EntityId.demo('user', user.id),
      );
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
      await _userRepository.setStatus(
        EntityId.demo('user', user.id),
        _userStatusValue(
          isEnabled: user.isEnabled,
          isLocked: isLocked,
        ),
      );
      if (!mounted) return;
      setState(() {
        _users[index] = user.copyWith(isLocked: isLocked);
      });
      await _appendAudit(
        action: AuditAction.accountStatusChange,
        outcome: AuditOutcome.success,
        summary: isLocked
            ? 'قفل حساب ${user.username}'
            : 'فتح قفل حساب ${user.username}',
        entityType: 'user',
        entityId: EntityId.demo('user', user.id),
      );
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
      await _authenticationService.changePassword(
        PasswordChangeRequest(
          userId: EntityId.demo('user', user.id),
          currentPassword: draft.currentPassword,
          newPassword: draft.newPassword,
        ),
      );
      await _appendAudit(
        action: AuditAction.update,
        outcome: AuditOutcome.success,
        summary: 'تغيير كلمة مرور ${user.username}',
        entityType: 'user',
        entityId: EntityId.demo('user', user.id),
      );
      if (!mounted) return;
      AppToast.showSuccess(
        context,
        'تم تغيير كلمة مرور ${user.fullName} تجريبياً',
      );
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

    final duplicate = _roles.any(
      (entry) =>
          entry.id != role?.id &&
          entry.name.trim().toLowerCase() ==
              draft.name.trim().toLowerCase(),
    );
    if (duplicate) {
      AppToast.showWarning(context, 'اسم الدور مستخدم مسبقاً');
      return;
    }

    if (role == null) {
      final newRole = _SettingsRole(
        id: _nextRoleId++,
        name: draft.name,
        permissions: draft.permissions,
      );
      try {
        await _roleRepository.save(_appRoleFromSettings(newRole));
        if (!mounted) return;
        setState(() => _roles.add(newRole));
        await _appendAudit(
          action: AuditAction.permissionChange,
          outcome: AuditOutcome.success,
          summary: 'إضافة الدور ${newRole.name}',
          entityType: 'role',
          entityId: EntityId.demo('role', newRole.id),
        );
        if (mounted) AppToast.showInfo(context, 'تمت إضافة دور تجريبي');
      } on Object catch (error) {
        if (mounted) AppToast.showError(context, _serviceMessage(error));
      }
      return;
    }

    final index = _roles.indexWhere((entry) => entry.id == role.id);
    if (index < 0) return;
    final updatedRole = _SettingsRole(
      id: role.id,
      name: draft.name,
      permissions: draft.permissions,
    );
    try {
      await _roleRepository.save(_appRoleFromSettings(updatedRole));
      if (!mounted) return;
      setState(() {
        _roles[index] = updatedRole;
        if (role.name != draft.name) {
          for (var userIndex = 0;
              userIndex < _users.length;
              userIndex++) {
            final user = _users[userIndex];
            if (user.role == role.name) {
              _users[userIndex] = user.copyWith(role: draft.name);
            }
          }
        }
      });
      await _appendAudit(
        action: AuditAction.permissionChange,
        outcome: AuditOutcome.success,
        summary: 'تحديث الدور والصلاحيات: ${updatedRole.name}',
        entityType: 'role',
        entityId: EntityId.demo('role', updatedRole.id),
      );
      if (mounted) {
        AppToast.showSuccess(context, 'تم تحديث الدور والصلاحيات');
      }
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  int _roleUsersCount(String roleName) {
    return _users.where((user) => user.role == roleName).length;
  }

  void _focusLogSearch() {
    setState(() => _selectedTab = 'logs');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _logSearchFocusNode.requestFocus();
    });
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
    final userId = _currentSession?.userId ?? EntityId.demo('user', 1);
    try {
      await _authenticationService.changePassword(
        PasswordChangeRequest(
          userId: userId,
          currentPassword: current,
          newPassword: password,
        ),
      );
      await _appendAudit(
        action: AuditAction.update,
        outcome: AuditOutcome.success,
        summary: 'تغيير كلمة مرور المستخدم الحالي',
        entityType: 'user',
        entityId: userId,
      );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      AppToast.showSuccess(context, 'تم تغيير كلمة المرور تجريبياً');
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
      await _authenticationService.recordActivity();
      _currentSession = await _authenticationService.currentSession();
      await _appendAudit(
        action: AuditAction.update,
        outcome: AuditOutcome.success,
        summary: _idleLockEnabled
            ? 'تفعيل القفل التلقائي بعد $minutes دقيقة'
            : 'تعطيل القفل التلقائي',
        entityType: 'session_policy',
        entityId: EntityId.demo('session_policy', 1),
      );
      if (!mounted) return;
      setState(() {});
      AppToast.showSuccess(context, 'تم حفظ سياسة القفل التجريبية');
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _toggleCurrentSessionLock() async {
    try {
      final current = await _authenticationService.currentSession();
      if (current == null) {
        throw const ServiceFailure(
          kind: ServiceFailureKind.authenticationRequired,
          message: 'لا توجد جلسة تجريبية حالية',
        );
      }
      final session = current.state == SessionState.locked
          ? await _authenticationService.unlock('password')
          : await _authenticationService.lock(SessionLockReason.idleTimeout);
      if (!mounted) return;
      setState(() => _currentSession = session);
      await _appendAudit(
        action: AuditAction.other,
        outcome: AuditOutcome.success,
        summary: session.state == SessionState.locked
            ? 'قفل الجلسة التجريبية لمحاكاة الخمول'
            : 'فتح الجلسة التجريبية',
        entityType: 'session',
        entityId: session.id,
      );
      if (mounted) {
        AppToast.showInfo(
          context,
          session.state == SessionState.locked
              ? 'تم قفل الجلسة تجريبياً'
              : 'تم فتح الجلسة تجريبياً',
        );
      }
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
    }
  }

  Future<void> _appendAudit({
    required AuditAction action,
    required AuditOutcome outcome,
    required String summary,
    String? entityType,
    EntityId? entityId,
  }) async {
    final actorId = _currentSession?.userId ?? EntityId.demo('user', 1);
    final actor = _users.where(
      (user) => EntityId.demo('user', user.id) == actorId,
    ).firstOrNull;
    final record = AuditRecord(
      id: EntityId.demo('audit', _nextAuditId++),
      occurredAt: AuditTimestamp(
        DateTime.utc(2026, 7, 29, 7, 30 + _nextAuditId),
      ),
      actorUserId: actorId,
      actorUsername: actor?.username ?? 'admin',
      action: action,
      outcome: outcome,
      summary: summary,
      details: const {'mode': 'demo'},
      entityType: entityType,
      entityId: entityId,
    );
    await _auditRepository.append(record);
    if (!mounted) return;
    setState(() => _auditEntries.insert(0, _settingsAuditFromDomain(record)));
  }

  Future<void> _refreshAudit() async {
    try {
      final page = await _auditRepository.search(
        AuditQuery(
          searchText: _logSearchController.text,
          action: _auditActionForLabel(_logType),
        ),
      );
      if (!mounted) return;
      setState(() {
        _auditEntries
          ..clear()
          ..addAll(page.records.map(_settingsAuditFromDomain));
      });
    } on Object catch (error) {
      if (mounted) AppToast.showError(context, _serviceMessage(error));
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
          onPressed: _openAddUserDialog,
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
              AppTableColumn(label: 'الإجراءات', flex: 1.15),
            ],
            rows: [
              for (final user in _users)
                AppTableRow(
                  rowKey: Key('settingsUserRow_${user.id}'),
                  cells: [
                    Text(user.fullName),
                    Text(user.username, textDirection: TextDirection.ltr),
                    Text(user.role),
                    Center(
                      key: Key('settingsUserStatus_${user.id}'),
                      child: _userStatusBadge(user),
                    ),
                    Text(user.lastLogin),
                    Center(
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          AppTableActionButton(
                            key: Key('settingsUserEnable_${user.id}'),
                            icon: user.isEnabled
                                ? Icons.person_off_outlined
                                : Icons.person_outline_rounded,
                            tooltip: user.isEnabled
                                ? 'تعطيل الحساب'
                                : 'تفعيل الحساب',
                            variant: user.isEnabled
                                ? AppButtonVariant.warning
                                : AppButtonVariant.success,
                            onPressed: user.username == 'admin'
                                ? null
                                : () => _toggleUserEnabled(user),
                          ),
                          AppTableActionButton(
                            key: Key('settingsUserLock_${user.id}'),
                            icon: user.isLocked
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            tooltip: user.isLocked
                                ? 'فتح القفل'
                                : 'قفل الحساب',
                            variant: AppButtonVariant.warning,
                            onPressed: user.username == 'admin'
                                ? null
                                : () => _toggleUserLock(user),
                          ),
                          AppTableActionButton(
                            key: Key('settingsUserPassword_${user.id}'),
                            icon: Icons.password_rounded,
                            tooltip: 'تغيير كلمة المرور',
                            onPressed: () =>
                                _openUserPasswordDialog(user),
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
          onPressed: _openRoleDialog,
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
              AppTableColumn(label: 'الإجراءات', flex: 0.7),
            ],
            rows: [
              for (final role in _roles)
                AppTableRow(
                  rowKey: Key('settingsRoleRow_${role.id}'),
                  cells: [
                    Text('${role.id}', textAlign: TextAlign.center),
                    Text(role.name),
                    Text(
                      '${_roleUsersCount(role.name)}',
                      key: Key('settingsRoleUserCount_${role.id}'),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _rolePermissionSummary(role.permissions),
                      key: Key('settingsRoleSummary_${role.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Center(
                      child: AppTableActionButton(
                        key: Key('settingsRolePermissions_${role.id}'),
                        icon: Icons.rule_rounded,
                        tooltip: 'تعديل الصلاحيات',
                        onPressed: () => _openRoleDialog(role: role),
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
                  label: _currentSession?.state == SessionState.locked
                      ? 'فتح الجلسة التجريبية'
                      : 'محاكاة القفل الآن',
                  icon: _currentSession?.state == SessionState.locked
                      ? Icons.lock_open_rounded
                      : Icons.lock_clock_outlined,
                  onPressed: _toggleCurrentSessionLock,
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
                  onPressed: _saveIdleLock,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogsTemplate() {
    final query = _logSearchController.text.trim().toLowerCase();
    final filteredEntries = _auditEntries.where((entry) {
      final matchesType = _logType == 'الكل' || entry.type == _logType;
      final haystack =
          '${entry.createdAt} ${entry.username} ${entry.type} '
          '${entry.details} ${entry.status}'
              .toLowerCase();
      return matchesType && (query.isEmpty || haystack.contains(query));
    }).toList();

    return SettingsTemplatePanel(
      key: const Key('settingsSecurityLogsPanel'),
      title: 'سجل الدخول والنشاط والتعديلات',
      icon: Icons.receipt_long_outlined,
      accentColor: widget.accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsResponsiveGrid(
            preferredColumns: 2,
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
                  AppDropdownOption(
                    value: 'تسجيل الدخول',
                    label: 'تسجيل الدخول',
                  ),
                  AppDropdownOption(value: 'تعديل', label: 'تعديل'),
                  AppDropdownOption(value: 'حذف', label: 'حذف'),
                  AppDropdownOption(value: 'استعادة', label: 'استعادة'),
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
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
              for (final entry in filteredEntries)
                AppTableRow(
                  rowKey: Key('settingsAuditRow_${entry.id}'),
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
                        tone: entry.status == 'فشل'
                            ? AppStatusTone.danger
                            : AppStatusTone.success,
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
