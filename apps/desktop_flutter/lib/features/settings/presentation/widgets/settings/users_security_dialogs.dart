part of '../settings_sections.dart';

class _SettingsUserDraft {
  const _SettingsUserDraft({
    required this.fullName,
    required this.username,
    required this.roleIds,
    this.initialPassword,
  });

  final String fullName;
  final String username;
  final Set<EntityId> roleIds;
  final String? initialPassword;
}

class _SettingsUserPasswordDraft {
  const _SettingsUserPasswordDraft({
    required this.newPassword,
  });

  final String newPassword;
}

class _SettingsUserPasswordDialog extends StatefulWidget {
  const _SettingsUserPasswordDialog({
    required this.user,
    required this.accentColor,
  });

  final _SettingsUser user;
  final Color accentColor;

  @override
  State<_SettingsUserPasswordDialog> createState() =>
      _SettingsUserPasswordDialogState();
}

class _SettingsUserPasswordDialogState
    extends State<_SettingsUserPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  String? get _confirmationError {
    final confirmation = _confirmationController.text;
    if (confirmation.isEmpty || confirmation == _passwordController.text) {
      return null;
    }
    return 'كلمتا المرور غير متطابقتين';
  }

  bool get _canSave =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text.length >= 6 &&
      _confirmationController.text.isNotEmpty &&
      _confirmationError == null;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      _SettingsUserPasswordDraft(
        newPassword: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.user.keySuffix;
    return AppModuleDialog(
      key: Key('settingsUserPasswordDialog_$userId'),
      title: 'إعادة تعيين كلمة مرور المستخدم',
      subtitle: '${widget.user.fullName} — لن تظهر كلمة المرور الحالية',
      icon: Icons.password_rounded,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 620,
      actions: [
        AppButton(
          key: Key('settingsUserPasswordCancel_$userId'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _close,
        ),
        AppButton(
          key: Key('settingsUserPasswordConfirm_$userId'),
          label: 'تحديث',
          icon: Icons.refresh_rounded,
          variant: AppButtonVariant.success,
          width: 145,
          onPressed: _canSave ? _save : null,
        ),
      ],
      child: Column(
        children: [
          AppTextField(
            fieldKey: Key('settingsUserPasswordNewField_$userId'),
            controller: _passwordController,
            label: 'كلمة المرور الجديدة',
            icon: Icons.key_rounded,
            accentColor: widget.accentColor,
            obscureText: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: Key('settingsUserPasswordConfirmField_$userId'),
            controller: _confirmationController,
            label: 'تأكيد كلمة المرور',
            icon: Icons.verified_user_outlined,
            accentColor: widget.accentColor,
            obscureText: true,
            errorText: _confirmationError,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
    );
  }
}
class _SettingsRoleDraft {
  const _SettingsRoleDraft({
    required this.name,
    required this.permissions,
  });

  final String name;
  final Map<String, Set<String>> permissions;
}

class _SettingsRoleDialog extends StatefulWidget {
  const _SettingsRoleDialog({
    required this.accentColor,
    required this.existingRoleNames,
    this.initialRole,
  });

  final Color accentColor;
  final Set<String> existingRoleNames;
  final _SettingsRole? initialRole;

  @override
  State<_SettingsRoleDialog> createState() =>
      _SettingsRoleDialogState();
}

class _SettingsRoleDialogState extends State<_SettingsRoleDialog> {
  late final TextEditingController _nameController;
  late final Map<String, Set<String>> _permissions;

  bool get _isEditing => widget.initialRole != null;

  String? get _nameError {
    final name = _nameController.text.trim().toLowerCase();
    if (name.isEmpty) return null;
    return widget.existingRoleNames.contains(name)
        ? 'اسم الدور مستخدم مسبقاً'
        : null;
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _nameError == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialRole?.name ?? '',
    );
    _permissions = widget.initialRole == null
        ? _settingsRolePermissions()
        : _copySettingsRolePermissions(
            widget.initialRole!.permissions,
          );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      _SettingsRoleDraft(
        name: _nameController.text.trim(),
        permissions: _copySettingsRolePermissions(_permissions),
      ),
    );
  }

  void _setAllPermissions(bool selected) {
    setState(() {
      for (final screen in _settingsPermissionScreens) {
        _permissions[screen.id] = selected
            ? {..._allPermissionActionIds}
            : <String>{};
      }
    });
  }

  void _togglePermission(
    String screenId,
    String actionId,
    bool selected,
  ) {
    setState(() {
      final actions = _permissions.putIfAbsent(
        screenId,
        () => <String>{},
      );
      if (selected) {
        actions.add(actionId);
      } else {
        actions.remove(actionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roleId = widget.initialRole?.id;
    return AppModuleDialog(
      key: Key(
        roleId == null
            ? 'settingsRoleDialog_new'
            : 'settingsRoleDialog_$roleId',
      ),
      title: _isEditing ? 'تعديل الدور والصلاحيات' : 'إضافة دور',
      subtitle: 'حدد صلاحيات كل شاشة وإجراء بشكل مستقل',
      icon: Icons.admin_panel_settings_outlined,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 980,
      maxHeightFactor: 0.94,
      actions: [
        AppButton(
          key: const Key('settingsRoleDialogCancelButton'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _close,
        ),
        AppButton(
          key: const Key('settingsRoleDialogConfirmButton'),
          label: _isEditing ? 'تحديث' : 'إضافة',
          icon: _isEditing ? Icons.refresh_rounded : Icons.add_rounded,
          variant: _isEditing
              ? AppButtonVariant.success
              : AppButtonVariant.primary,
          width: 145,
          onPressed: _canSave ? _save : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            fieldKey: const Key('settingsRoleNameField'),
            controller: _nameController,
            label: 'اسم الدور',
            icon: Icons.badge_outlined,
            accentColor: widget.accentColor,
            errorText: _nameError,
            autofocus: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'مصفوفة صلاحيات الشاشات والإجراءات',
                  style: AppTypography.sectionTitle,
                ),
              ),
              AppRegularButton(
                key: const Key('settingsRoleSelectAllButton'),
                label: 'تحديد الكل',
                icon: Icons.done_all_rounded,
                onPressed: () => _setAllPermissions(true),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppRegularButton(
                key: const Key('settingsRoleClearAllButton'),
                label: 'إلغاء الكل',
                icon: Icons.remove_done_rounded,
                onPressed: () => _setAllPermissions(false),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPermissionMatrix(),
        ],
      ),
    );
  }

  Widget _buildPermissionMatrix() {
    final borderColor = Color.lerp(
      widget.accentColor,
      AppColors.surface,
      0.62,
    )!;
    final headerColor = Color.alphaBlend(
      widget.accentColor.withAlpha(18),
      AppColors.surface,
    );

    Widget cell(Widget child, {double height = 46}) {
      return SizedBox(
        height: height,
        child: Center(child: child),
      );
    }

    return ClipRRect(
      key: const Key('settingsRolePermissionMatrix'),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1040,
          child: Table(
            textDirection: TextDirection.rtl,
            border: TableBorder.all(color: borderColor),
            columnWidths: const {
              0: FixedColumnWidth(190),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
              4: FlexColumnWidth(),
              5: FlexColumnWidth(),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: headerColor),
                children: [
                  cell(
                    const Text(
                      'الشاشة',
                      style: AppTypography.tableHeader,
                    ),
                    height: 50,
                  ),
                  for (final action in _settingsPermissionActions)
                    cell(
                      Text(
                        action.label,
                        style: AppTypography.tableHeader,
                      ),
                      height: 50,
                    ),
                ],
              ),
              for (final screen in _settingsPermissionScreens)
                TableRow(
                  children: [
                    cell(
                      Text(
                        screen.label,
                        style: AppTypography.fieldText,
                      ),
                    ),
                    for (final action in _settingsPermissionActions)
                      cell(
                        Checkbox(
                          key: Key(
                            'settingsRolePermission_'
                            '${screen.id}_${action.id}',
                          ),
                          value: _permissions[screen.id]?.contains(
                                action.id,
                              ) ??
                              false,
                          activeColor: widget.accentColor,
                          onChanged: (value) => _togglePermission(
                            screen.id,
                            action.id,
                            value ?? false,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsUserDialog extends StatefulWidget {
  const _SettingsUserDialog({
    required this.accentColor,
    required this.roles,
    required this.existingUsernames,
    this.initialUser,
  }) : assert(roles.length > 0);

  final Color accentColor;
  final List<_SettingsRole> roles;
  final Set<String> existingUsernames;
  final _SettingsUser? initialUser;

  @override
  State<_SettingsUserDialog> createState() =>
      _SettingsUserDialogState();
}

class _SettingsUserDialogState extends State<_SettingsUserDialog> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  late final Set<EntityId> _roleIds;

  bool get _isEditing => widget.initialUser != null;

  String? get _usernameError {
    final username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty) return null;
    if (!RegExp(r'^[a-z0-9._-]+$').hasMatch(username)) {
      return 'استخدم أحرفاً إنجليزية وأرقاماً و . _ - فقط';
    }
    if (widget.existingUsernames.contains(username)) {
      return 'اسم المستخدم مستخدم مسبقاً';
    }
    return null;
  }

  String? get _passwordError {
    if (_isEditing || _passwordController.text.isEmpty) return null;
    return PasswordPolicy.validationMessage(_passwordController.text);
  }

  String? get _confirmationError {
    if (_isEditing || _confirmationController.text.isEmpty) return null;
    return _confirmationController.text == _passwordController.text
        ? null
        : 'كلمتا المرور غير متطابقتين';
  }

  bool get _canSave =>
      _fullNameController.text.trim().isNotEmpty &&
      _usernameController.text.trim().isNotEmpty &&
      _usernameError == null &&
      _roleIds.isNotEmpty &&
      (_isEditing ||
          (_passwordController.text.isNotEmpty &&
              _confirmationController.text.isNotEmpty &&
              _passwordError == null &&
              _confirmationError == null));

  @override
  void initState() {
    super.initState();
    final initial = widget.initialUser;
    _fullNameController = TextEditingController(text: initial?.fullName ?? '');
    _usernameController = TextEditingController(text: initial?.username ?? '');
    _roleIds = initial == null
        ? {widget.roles.firstWhere(
            (role) => role.name == 'المبيعات',
            orElse: () => widget.roles.first,
          ).id}
        : {...initial.roleIds};
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      _SettingsUserDraft(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        roleIds: Set.unmodifiable(_roleIds),
        initialPassword: _isEditing ? null : _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: Key(_isEditing ? 'settingsEditUserDialog' : 'settingsAddUserDialog'),
      title: _isEditing ? 'تعديل المستخدم' : 'إضافة مستخدم',
      subtitle: _isEditing
          ? 'حدّث بيانات الحساب وأدواره باستخدام المعرّف المستقر نفسه'
          : 'أنشئ الحساب وكلمة مروره الأولية ضمن عملية واحدة',
      icon: Icons.person_add_alt_1_rounded,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 720,
      actions: [
        AppButton(
          key: const Key('settingsAddUserCancelButton'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _close,
        ),
        AppButton(
          key: Key(
            _isEditing
                ? 'settingsEditUserConfirmButton'
                : 'settingsAddUserConfirmButton',
          ),
          label: _isEditing ? 'تحديث' : 'إضافة',
          icon: _isEditing ? Icons.refresh_rounded : Icons.add_rounded,
          variant: _isEditing
              ? AppButtonVariant.success
              : AppButtonVariant.primary,
          width: 145,
          onPressed: _canSave ? _save : null,
        ),
      ],
      child: Column(
        children: [
          AppTextField(
            fieldKey: const Key('settingsAddUserFullNameField'),
            controller: _fullNameController,
            label: 'الاسم الكامل',
            icon: Icons.badge_outlined,
            accentColor: widget.accentColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const Key('settingsAddUserUsernameField'),
            controller: _usernameController,
            label: 'اسم المستخدم',
            icon: Icons.alternate_email_rounded,
            accentColor: widget.accentColor,
            errorText: _usernameError,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            enabled: !(widget.initialUser?.isSystemUser ?? false),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'الأدوار',
              prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
              errorText: _roleIds.isEmpty ? 'اختر دوراً واحداً على الأقل' : null,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final role in widget.roles)
                  FilterChip(
                    key: Key('settingsUserRole_${role.keySuffix}'),
                    label: Text(role.name),
                    selected: _roleIds.contains(role.id),
                    onSelected: widget.initialUser?.isSystemUser ?? false
                        ? null
                        : (selected) => setState(() {
                            if (selected) {
                              _roleIds.add(role.id);
                            } else {
                              _roleIds.remove(role.id);
                            }
                          }),
                  ),
              ],
            ),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('settingsAddUserPasswordField'),
              controller: _passwordController,
              label: 'كلمة المرور الأولية',
              icon: Icons.password_rounded,
              accentColor: widget.accentColor,
              obscureText: true,
              errorText: _passwordError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              fieldKey: const Key('settingsAddUserPasswordConfirmField'),
              controller: _confirmationController,
              label: 'تأكيد كلمة المرور',
              icon: Icons.verified_user_outlined,
              accentColor: widget.accentColor,
              obscureText: true,
              errorText: _confirmationError,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
            ),
          ],
        ],
      ),
    );
  }
}
