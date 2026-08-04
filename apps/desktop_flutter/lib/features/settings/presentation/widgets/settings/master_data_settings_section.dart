part of '../settings_sections.dart';

class MasterDataSettingsSection extends StatefulWidget {
  const MasterDataSettingsSection({
    required this.accentColor,
    super.key,
  });

  final Color accentColor;

  @override
  State<MasterDataSettingsSection> createState() =>
      _MasterDataSettingsSectionState();
}
class _MasterDataSettingsSectionState
    extends State<MasterDataSettingsSection> {
  var _selectedTab = 'groupsTypes';
  var _itemGroups = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(id: 1, name: 'المواد الغذائية'),
    const _SettingsNamedEntry(id: 2, name: 'الأجهزة الكهربائية'),
    const _SettingsNamedEntry(id: 3, name: 'القرطاسية'),
  ];
  var _itemTypes = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(
      id: 1,
      name: 'مشروبات',
      parent: 'المواد الغذائية',
    ),
    const _SettingsNamedEntry(
      id: 2,
      name: 'مواد جافة',
      parent: 'المواد الغذائية',
    ),
    const _SettingsNamedEntry(
      id: 3,
      name: 'أجهزة منزلية',
      parent: 'الأجهزة الكهربائية',
    ),
  ];
  var _workplaces = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(id: 1, name: 'شركة المميز'),
    const _SettingsNamedEntry(id: 2, name: 'السوق المحلي'),
    const _SettingsNamedEntry(id: 3, name: 'المبيعات المباشرة'),
  ];
  var _branches = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(
      id: 1,
      name: 'الفرع الرئيسي',
      parent: 'شركة المميز',
    ),
    const _SettingsNamedEntry(
      id: 2,
      name: 'فرع الكرادة',
      parent: 'السوق المحلي',
    ),
    const _SettingsNamedEntry(
      id: 3,
      name: 'فرع المنصور',
      parent: 'المبيعات المباشرة',
    ),
  ];
  var _cashboxMainAccounts = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(
      id: 1,
      name: 'الصندوق الرئيسي',
      isProtected: true,
    ),
    const _SettingsNamedEntry(id: 2, name: 'المصاريف العامة'),
    const _SettingsNamedEntry(id: 3, name: 'حساب الأطراف'),
  ];
  var _cashboxSubAccounts = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(
      id: 1,
      name: 'النقدية اليومية',
      parent: 'الصندوق الرئيسي',
    ),
    const _SettingsNamedEntry(
      id: 2,
      name: 'أجور النقل',
      parent: 'المصاريف العامة',
    ),
    const _SettingsNamedEntry(
      id: 3,
      name: 'مصروفات المكتب',
      parent: 'المصاريف العامة',
    ),
  ];

  int get _selectedTabIndex => switch (_selectedTab) {
        'workplacesBranches' => 1,
        'cashboxAccounts' => 2,
        _ => 0,
      };

  List<_SettingsNamedEntry> _cascadeParentChanges({
    required List<_SettingsNamedEntry> previousParents,
    required List<_SettingsNamedEntry> nextParents,
    required List<_SettingsNamedEntry> children,
  }) {
    final nextNamesById = {
      for (final entry in nextParents) entry.id: entry.name,
    };
    final previousIdsByName = {
      for (final entry in previousParents) entry.name: entry.id,
    };
    return [
      for (final child in children)
        if (child.parent == null)
          child
        else
          _cascadeChildParent(
            child: child,
            previousIdsByName: previousIdsByName,
            nextNamesById: nextNamesById,
            nextParents: nextParents,
          ),
    ];
  }

  _SettingsNamedEntry _cascadeChildParent({
    required _SettingsNamedEntry child,
    required Map<String, int> previousIdsByName,
    required Map<int, String> nextNamesById,
    required List<_SettingsNamedEntry> nextParents,
  }) {
    final renamedParent =
        nextNamesById[previousIdsByName[child.parent]];
    final unchangedParent = nextParents.any(
      (entry) => entry.name == child.parent,
    )
        ? child.parent
        : null;
    final nextParent = renamedParent ?? unchangedParent;

    return child.copyWith(
      parent: nextParent,
      clearParent: nextParent == null,
    );
  }

  void _replaceItemGroups(List<_SettingsNamedEntry> entries) {
    setState(() {
      _itemTypes = _cascadeParentChanges(
        previousParents: _itemGroups,
        nextParents: entries,
        children: _itemTypes,
      );
      _itemGroups = entries;
    });
  }

  void _replaceWorkplaces(List<_SettingsNamedEntry> entries) {
    setState(() {
      _branches = _cascadeParentChanges(
        previousParents: _workplaces,
        nextParents: entries,
        children: _branches,
      );
      _workplaces = entries;
    });
  }

  void _replaceCashboxMainAccounts(
    List<_SettingsNamedEntry> entries,
  ) {
    setState(() {
      _cashboxSubAccounts = _cascadeParentChanges(
        previousParents: _cashboxMainAccounts,
        nextParents: entries,
        children: _cashboxSubAccounts,
      );
      _cashboxMainAccounts = entries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('masterDataSettingsContent'),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SettingsTemplateTabs<String>(
          keyPrefix: 'masterDataTab_',
          accentColor: widget.accentColor,
          selected: _selectedTab,
          onChanged: (value) => setState(() => _selectedTab = value),
          items: const [
            (
              value: 'groupsTypes',
              label: 'المجموعات والأنواع',
              icon: Icons.category_outlined,
            ),
            (
              value: 'workplacesBranches',
              label: 'جهات العمل والفروع',
              icon: Icons.account_tree_outlined,
            ),
            (
              value: 'cashboxAccounts',
              label: 'حسابات الصندوق',
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        IndexedStack(
          key: const Key('settingsMasterDataTemplates'),
          index: _selectedTabIndex,
          children: [
            _GroupsTypesTemplate(
              accentColor: widget.accentColor,
              groups: _itemGroups,
              types: _itemTypes,
              onGroupsChanged: _replaceItemGroups,
              onTypesChanged: (entries) {
                setState(() => _itemTypes = entries);
              },
            ),
            _WorkplacesBranchesTemplate(
              accentColor: widget.accentColor,
              workplaces: _workplaces,
              branches: _branches,
              onWorkplacesChanged: _replaceWorkplaces,
              onBranchesChanged: (entries) {
                setState(() => _branches = entries);
              },
            ),
            _CashboxAccountsTemplate(
              accentColor: widget.accentColor,
              mainAccounts: _cashboxMainAccounts,
              subAccounts: _cashboxSubAccounts,
              onMainAccountsChanged: _replaceCashboxMainAccounts,
              onSubAccountsChanged: (entries) {
                setState(() => _cashboxSubAccounts = entries);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupsTypesTemplate extends StatelessWidget {
  const _GroupsTypesTemplate({
    required this.accentColor,
    required this.groups,
    required this.types,
    required this.onGroupsChanged,
    required this.onTypesChanged,
  });

  final Color accentColor;
  final List<_SettingsNamedEntry> groups;
  final List<_SettingsNamedEntry> types;
  final ValueChanged<List<_SettingsNamedEntry>> onGroupsChanged;
  final ValueChanged<List<_SettingsNamedEntry>> onTypesChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsResponsiveGrid(
      key: const Key('settingsGroupsTypesTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 620,
      children: [
        _SettingsManagementPanel(
          keyPrefix: 'settingsItemGroups',
          title: 'مجموعات المواد',
          fieldLabel: 'اسم المجموعة',
          icon: Icons.folder_copy_outlined,
          accentColor: accentColor,
          entries: groups,
          referencedNames: {
            for (final entry in types)
              if (entry.parent != null) entry.parent!,
          },
          onEntriesChanged: onGroupsChanged,
        ),
        _SettingsManagementPanel(
          keyPrefix: 'settingsItemTypes',
          title: 'أنواع المواد',
          fieldLabel: 'اسم النوع',
          parentLabel: 'المجموعة',
          parentOptions: [for (final entry in groups) entry.name],
          icon: Icons.account_tree_outlined,
          accentColor: accentColor,
          entries: types,
          onEntriesChanged: onTypesChanged,
        ),
      ],
    );
  }
}

class _WorkplacesBranchesTemplate extends StatelessWidget {
  const _WorkplacesBranchesTemplate({
    required this.accentColor,
    required this.workplaces,
    required this.branches,
    required this.onWorkplacesChanged,
    required this.onBranchesChanged,
  });

  final Color accentColor;
  final List<_SettingsNamedEntry> workplaces;
  final List<_SettingsNamedEntry> branches;
  final ValueChanged<List<_SettingsNamedEntry>> onWorkplacesChanged;
  final ValueChanged<List<_SettingsNamedEntry>> onBranchesChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsResponsiveGrid(
      key: const Key('settingsWorkplacesBranchesTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 620,
      children: [
        _SettingsManagementPanel(
          keyPrefix: 'settingsWorkplaces',
          title: 'جهات العمل',
          fieldLabel: 'اسم جهة العمل',
          icon: Icons.business_center_outlined,
          accentColor: accentColor,
          entries: workplaces,
          referencedNames: {
            for (final entry in branches)
              if (entry.parent != null) entry.parent!,
          },
          onEntriesChanged: onWorkplacesChanged,
        ),
        _SettingsManagementPanel(
          keyPrefix: 'settingsWorkplaceBranches',
          title: 'الفروع',
          fieldLabel: 'اسم الفرع',
          parentLabel: 'جهة العمل',
          parentOptions: [for (final entry in workplaces) entry.name],
          icon: Icons.fork_right_outlined,
          accentColor: accentColor,
          entries: branches,
          onEntriesChanged: onBranchesChanged,
        ),
      ],
    );
  }
}

class _CashboxAccountsTemplate extends StatelessWidget {
  const _CashboxAccountsTemplate({
    required this.accentColor,
    required this.mainAccounts,
    required this.subAccounts,
    required this.onMainAccountsChanged,
    required this.onSubAccountsChanged,
  });

  final Color accentColor;
  final List<_SettingsNamedEntry> mainAccounts;
  final List<_SettingsNamedEntry> subAccounts;
  final ValueChanged<List<_SettingsNamedEntry>> onMainAccountsChanged;
  final ValueChanged<List<_SettingsNamedEntry>> onSubAccountsChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsResponsiveGrid(
      key: const Key('settingsCashboxAccountsTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 620,
      children: [
        _SettingsManagementPanel(
          keyPrefix: 'settingsCashboxMainAccounts',
          title: 'الحسابات الرئيسية',
          fieldLabel: 'اسم الحساب الرئيسي',
          icon: Icons.account_balance_wallet_outlined,
          accentColor: accentColor,
          entries: mainAccounts,
          referencedNames: {
            for (final entry in subAccounts)
              if (entry.parent != null) entry.parent!,
          },
          onEntriesChanged: onMainAccountsChanged,
        ),
        _SettingsManagementPanel(
          keyPrefix: 'settingsCashboxSubAccounts',
          title: 'الحسابات الفرعية',
          fieldLabel: 'اسم الحساب الفرعي',
          parentLabel: 'الحساب الرئيسي',
          parentOptions: [for (final entry in mainAccounts) entry.name],
          icon: Icons.segment_outlined,
          accentColor: accentColor,
          entries: subAccounts,
          onEntriesChanged: onSubAccountsChanged,
        ),
      ],
    );
  }
}

class _SettingsNamedEntry {
  const _SettingsNamedEntry({
    required this.id,
    required this.name,
    this.isProtected = false,
    this.parent,
  });

  final int id;
  final String name;
  final bool isProtected;
  final String? parent;

  _SettingsNamedEntry copyWith({
    String? name,
    String? parent,
    bool clearParent = false,
  }) {
    return _SettingsNamedEntry(
      id: id,
      name: name ?? this.name,
      isProtected: isProtected,
      parent: clearParent ? null : parent ?? this.parent,
    );
  }
}

class _SettingsManagementPanel extends StatefulWidget {
  const _SettingsManagementPanel({
    required this.keyPrefix,
    required this.title,
    required this.fieldLabel,
    required this.icon,
    required this.accentColor,
    required this.entries,
    required this.onEntriesChanged,
    this.parentLabel,
    this.parentOptions = const [],
    this.referencedNames = const {},
  });

  final String keyPrefix;
  final String title;
  final String fieldLabel;
  final IconData icon;
  final Color accentColor;
  final List<_SettingsNamedEntry> entries;
  final ValueChanged<List<_SettingsNamedEntry>> onEntriesChanged;
  final String? parentLabel;
  final List<String> parentOptions;
  final Set<String> referencedNames;

  @override
  State<_SettingsManagementPanel> createState() =>
      _SettingsManagementPanelState();
}

class _SettingsManagementPanelState
    extends State<_SettingsManagementPanel> {
  final _nameController = TextEditingController();
  int? _selectedId;
  String? _selectedParent;

  @override
  void initState() {
    super.initState();
    _selectedParent =
        widget.parentOptions.isEmpty ? null : widget.parentOptions.first;
  }

  @override
  void didUpdateWidget(covariant _SettingsManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selectedId = _selectedId;
    if (selectedId != null) {
      final selectedIndex =
          widget.entries.indexWhere((entry) => entry.id == selectedId);
      if (selectedIndex < 0) {
        _selectedId = null;
        _nameController.clear();
      } else {
        final selectedEntry = widget.entries[selectedIndex];
        _selectedParent = selectedEntry.parent;
      }
    } else if (_selectedParent == null ||
        !widget.parentOptions.contains(_selectedParent)) {
      _selectedParent =
          widget.parentOptions.isEmpty ? null : widget.parentOptions.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedId = null;
      _nameController.clear();
      _selectedParent =
          widget.parentOptions.isEmpty ? null : widget.parentOptions.first;
    });
  }

  void _addEntry() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.showWarning(context, 'اكتب ${widget.fieldLabel} أولاً');
      return;
    }
    if (widget.entries.any(
      (entry) => entry.name.trim().toLowerCase() == name.toLowerCase(),
    )) {
      AppToast.showWarning(context, 'هذا الاسم مستخدم مسبقاً');
      return;
    }
    if (widget.parentLabel != null && _selectedParent == null) {
      AppToast.showWarning(context, 'اختر ${widget.parentLabel} أولاً');
      return;
    }

    final nextId = widget.entries.fold<int>(
          0,
          (largest, entry) => entry.id > largest ? entry.id : largest,
        ) +
        1;
    final nextEntries = [
      ...widget.entries,
      _SettingsNamedEntry(
        id: nextId,
        name: name,
        parent: widget.parentLabel == null ? null : _selectedParent,
      ),
    ];
    setState(() {
      _selectedId = nextId;
    });
    widget.onEntriesChanged(nextEntries);
    AppToast.showInfo(context, 'تمت الإضافة إلى نموذج ${widget.title}');
  }

  void _updateEntry() {
    final selectedId = _selectedId;
    final name = _nameController.text.trim();
    if (selectedId == null || name.isEmpty) {
      AppToast.showWarning(context, 'اختر سجلاً واكتب الاسم الجديد');
      return;
    }
    if (widget.entries.any(
      (entry) =>
          entry.id != selectedId &&
          entry.name.trim().toLowerCase() == name.toLowerCase(),
    )) {
      AppToast.showWarning(context, 'هذا الاسم مستخدم مسبقاً');
      return;
    }
    if (widget.parentLabel != null && _selectedParent == null) {
      AppToast.showWarning(context, 'اختر ${widget.parentLabel} أولاً');
      return;
    }

    final nextEntries = List<_SettingsNamedEntry>.of(widget.entries);
    final index =
        nextEntries.indexWhere((entry) => entry.id == selectedId);
    if (index < 0) return;
    nextEntries[index] = nextEntries[index].copyWith(
      name: name,
      parent: widget.parentLabel == null ? null : _selectedParent,
      clearParent: widget.parentLabel == null,
    );
    widget.onEntriesChanged(nextEntries);
    AppToast.showSuccess(context, 'تم تحديث السجل التجريبي');
  }

  Future<void> _deleteEntry(_SettingsNamedEntry entry) async {
    if (entry.isProtected) {
      AppToast.showWarning(context, 'لا يمكن حذف الحساب النظامي');
      return;
    }
    if (widget.referencedNames.contains(entry.name)) {
      AppToast.showDanger(
        context,
        'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف السجل',
      message: 'هل تريد حذف «${entry.name}» من النموذج؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!confirmed || !mounted) return;

    final nextEntries = [
      for (final candidate in widget.entries)
        if (candidate.id != entry.id) candidate,
    ];
    setState(() {
      if (_selectedId == entry.id) {
        _selectedId = null;
        _nameController.clear();
      }
    });
    widget.onEntriesChanged(nextEntries);
    AppToast.showDanger(context, 'تم حذف السجل التجريبي');
  }

  void _selectEntry(_SettingsNamedEntry entry) {
    setState(() {
      _selectedId = entry.id;
      _selectedParent = entry.parent;
      _nameController.text = entry.name;
      _nameController.selection = TextSelection.collapsed(
        offset: _nameController.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.keyPrefix;

    return SettingsTemplatePanel(
      key: Key('${prefix}Panel'),
      title: widget.title,
      icon: widget.icon,
      accentColor: widget.accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.parentLabel != null) ...[
            AppDropdownField<String>(
              fieldKey: Key('${prefix}ParentField'),
              label: widget.parentLabel!,
              icon: Icons.account_tree_outlined,
              accentColor: widget.accentColor,
              value: _selectedParent,
              enabled: widget.parentOptions.isNotEmpty,
              options: [
                for (final option in widget.parentOptions)
                  AppDropdownOption(value: option, label: option),
              ],
              useIntrinsicHeight: true,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              menuTextDirection: TextDirection.rtl,
              onChanged: (value) {
                if (value != null) setState(() => _selectedParent = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTextField(
            fieldKey: Key('${prefix}NameField'),
            controller: _nameController,
            label: widget.fieldLabel,
            icon: Icons.edit_outlined,
            accentColor: widget.accentColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _selectedId == null
                ? _addEntry()
                : _updateEntry(),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            textDirection: TextDirection.rtl,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                key: Key('${prefix}AddButton'),
                label: 'إضافة',
                icon: Icons.add_rounded,
                backgroundColor: widget.accentColor,
                minWidth: 115,
                onPressed: widget.parentLabel != null &&
                        _selectedParent == null
                    ? null
                    : _addEntry,
              ),
              AppButton(
                key: Key('${prefix}UpdateButton'),
                label: 'تحديث',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.success,
                minWidth: 115,
                onPressed: _selectedId == null ||
                        (widget.parentLabel != null &&
                            _selectedParent == null)
                    ? null
                    : _updateEntry,
              ),
              AppButton(
                key: Key('${prefix}ClearButton'),
                label: 'تراجع',
                icon: Icons.undo_rounded,
                variant: AppButtonVariant.warning,
                minWidth: 115,
                onPressed: _selectedId == null &&
                        _nameController.text.isEmpty
                    ? null
                    : _clearSelection,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: Key('${prefix}Table'),
            height: 270,
            rowHeight: 54,
            minimumColumnWidth: 115,
            accentColor: widget.accentColor,
            showShadow: false,
            columns: [
              const AppTableColumn(
                label: 'ت',
                flex: 0.45,
                numeric: true,
              ),
              const AppTableColumn(label: 'الاسم', flex: 1.8),
              if (widget.parentLabel != null)
                AppTableColumn(
                  label: widget.parentLabel!,
                  flex: 1.35,
                ),
              const AppTableColumn(label: 'الحالة', flex: 1),
              const AppTableColumn(label: 'الإجراءات', flex: 0.8),
            ],
            rows: [
              for (final entry in widget.entries)
                AppTableRow(
                  rowKey: Key('${prefix}Row_${entry.id}'),
                  selected: entry.id == _selectedId,
                  onTap: () => _selectEntry(entry),
                  cells: [
                    Text('${entry.id}', textAlign: TextAlign.center),
                    Text(entry.name, overflow: TextOverflow.ellipsis),
                    if (widget.parentLabel != null)
                      Text(
                        entry.parent ?? 'غير محدد',
                        overflow: TextOverflow.ellipsis,
                      ),
                    Center(
                      child: AppStatusBadge(
                        label: entry.isProtected ? 'نظامي' : 'نشط',
                        tone: entry.isProtected
                            ? AppStatusTone.info
                            : AppStatusTone.success,
                      ),
                    ),
                    Center(
                      child: AppTableActionButton(
                        key: Key('${prefix}Delete_${entry.id}'),
                        icon: Icons.delete_outline_rounded,
                        tooltip: entry.isProtected
                            ? 'حساب نظامي'
                            : 'حذف',
                        variant: AppButtonVariant.danger,
                        onPressed: () => _deleteEntry(entry),
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
}
