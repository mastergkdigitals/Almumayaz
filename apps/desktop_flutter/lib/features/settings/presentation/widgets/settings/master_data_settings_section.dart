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

class _MasterDataSettingsData {
  const _MasterDataSettingsData(this.records);

  final List<OperationalMasterDataRecord> records;
}

class _MasterDataSettingsSectionState
    extends State<MasterDataSettingsSection> {
  var _selectedTab = 'groupsTypes';
  AppDataState<_MasterDataSettingsData> _state =
      const AppDataState.loading();
  OperationalMasterDataRepository? _repository;
  AppStore? _store;

  int get _selectedTabIndex => switch (_selectedTab) {
        'workplacesBranches' => 1,
        'cashboxAccounts' => 2,
        _ => 0,
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repository != null) return;
    final store = AppStoreScope.of(context, listen: false);
    _store = store;
    _repository = store.repositories.operationalMasterData;
    _load(showLoading: true);
  }

  Future<void> _load({required bool showLoading}) async {
    if (showLoading) {
      setState(() => _state = const AppDataState.loading());
    }
    try {
      final records = [...await _repository!.getAll()];
      final recordsById = {
        for (final record in records) record.id: record,
      };
      records.sort((first, second) {
        final byKind = first.kind.index.compareTo(second.kind.index);
        if (byKind != 0) return byKind;

        final firstParentNumber = recordsById[first.parentId]?.number ?? 0;
        final secondParentNumber = recordsById[second.parentId]?.number ?? 0;
        final byParent = firstParentNumber.compareTo(secondParentNumber);
        if (byParent != 0) return byParent;

        final byNumber = first.number.compareTo(second.number);
        return byNumber != 0
            ? byNumber
            : first.id.value.compareTo(second.id.value);
      });
      if (!mounted) return;
      if (records.isEmpty) {
        setState(
          () => _state = const AppDataState.empty(
            message: 'لا توجد بيانات أساسية مسجلة حالياً.',
          ),
        );
        return;
      }
      final missingReference = _findMissingMasterDataReference(records);
      if (missingReference != null) {
        setState(
          () => _state = AppDataState.missingReference(missingReference),
        );
        return;
      }
      setState(
        () => _state = AppDataState.ready(
          _MasterDataSettingsData(List.unmodifiable(records)),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _state = AppDataState.error(
          error,
          message: _settingsRepositoryMessage(error),
        ),
      );
    }
  }

  Future<void> _saveRecord(OperationalMasterDataRecord record) async {
    await _repository!.save(record);
    _store!.markDataChanged();
    await _load(showLoading: false);
  }

  Future<DeleteDecision> _canDelete(EntityId id) {
    return _repository!.canDelete(id);
  }

  Future<void> _deleteRecord(EntityId id) async {
    await _repository!.delete(id);
    _store!.markDataChanged();
    await _load(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return AppDataStateView<_MasterDataSettingsData>(
      state: _state,
      loadingStateKey: const Key('masterDataLoadingState'),
      emptyStateKey: const Key('masterDataEmptyState'),
      missingReferenceStateKey: const Key('masterDataMissingReferenceState'),
      errorStateKey: const Key('masterDataErrorState'),
      emptyActionLabel: 'إضافة أول سجل',
      onEmptyAction: () {
        setState(
          () => _state = const AppDataState.ready(
            _MasterDataSettingsData(<OperationalMasterDataRecord>[]),
          ),
        );
      },
      onRetry: () => _load(showLoading: true),
      missingReferenceActionLabel: 'إعادة المحاولة',
      onMissingReferenceAction: () => _load(showLoading: true),
      dataBuilder: (context, data) => _buildContent(data.records),
    );
  }

  Widget _buildContent(List<OperationalMasterDataRecord> records) {
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
              records: records,
              onSave: _saveRecord,
              canDelete: _canDelete,
              onDelete: _deleteRecord,
            ),
            _WorkplacesBranchesTemplate(
              accentColor: widget.accentColor,
              records: records,
              onSave: _saveRecord,
              canDelete: _canDelete,
              onDelete: _deleteRecord,
            ),
            _CashboxAccountsTemplate(
              accentColor: widget.accentColor,
              records: records,
              onSave: _saveRecord,
              canDelete: _canDelete,
              onDelete: _deleteRecord,
            ),
          ],
        ),
      ],
    );
  }
}

typedef _SaveMasterDataRecord = Future<void> Function(
  OperationalMasterDataRecord record,
);
typedef _CanDeleteMasterDataRecord = Future<DeleteDecision> Function(
  EntityId id,
);
typedef _DeleteMasterDataRecord = Future<void> Function(EntityId id);

class _GroupsTypesTemplate extends StatelessWidget {
  const _GroupsTypesTemplate({
    required this.accentColor,
    required this.records,
    required this.onSave,
    required this.canDelete,
    required this.onDelete,
  });

  final Color accentColor;
  final List<OperationalMasterDataRecord> records;
  final _SaveMasterDataRecord onSave;
  final _CanDeleteMasterDataRecord canDelete;
  final _DeleteMasterDataRecord onDelete;

  @override
  Widget build(BuildContext context) {
    final groups = _recordsByKind(
      records,
      OperationalMasterDataKind.itemGroup,
    );
    final types = _recordsByKind(
      records,
      OperationalMasterDataKind.itemType,
    );
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
          kind: OperationalMasterDataKind.itemGroup,
          entries: groups,
          allKindEntries: groups,
          onSave: onSave,
          canDelete: canDelete,
          onDelete: onDelete,
        ),
        _SettingsManagementPanel(
          keyPrefix: 'settingsItemTypes',
          title: 'أنواع المواد',
          fieldLabel: 'اسم النوع',
          parentLabel: 'المجموعة',
          icon: Icons.account_tree_outlined,
          accentColor: accentColor,
          kind: OperationalMasterDataKind.itemType,
          entries: types,
          allKindEntries: types,
          parentOptions: groups,
          onSave: onSave,
          canDelete: canDelete,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _WorkplacesBranchesTemplate extends StatelessWidget {
  const _WorkplacesBranchesTemplate({
    required this.accentColor,
    required this.records,
    required this.onSave,
    required this.canDelete,
    required this.onDelete,
  });

  final Color accentColor;
  final List<OperationalMasterDataRecord> records;
  final _SaveMasterDataRecord onSave;
  final _CanDeleteMasterDataRecord canDelete;
  final _DeleteMasterDataRecord onDelete;

  @override
  Widget build(BuildContext context) {
    final workplaces = _recordsByKind(
      records,
      OperationalMasterDataKind.workplace,
    );
    final branches = _recordsByKind(
      records,
      OperationalMasterDataKind.branch,
    );
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
          kind: OperationalMasterDataKind.workplace,
          entries: workplaces,
          allKindEntries: workplaces,
          onSave: onSave,
          canDelete: canDelete,
          onDelete: onDelete,
        ),
        _SettingsManagementPanel(
          keyPrefix: 'settingsWorkplaceBranches',
          title: 'الفروع',
          fieldLabel: 'اسم الفرع',
          parentLabel: 'جهة العمل',
          icon: Icons.fork_right_outlined,
          accentColor: accentColor,
          kind: OperationalMasterDataKind.branch,
          entries: branches,
          allKindEntries: branches,
          parentOptions: workplaces,
          onSave: onSave,
          canDelete: canDelete,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _CashboxAccountsTemplate extends StatelessWidget {
  const _CashboxAccountsTemplate({
    required this.accentColor,
    required this.records,
    required this.onSave,
    required this.canDelete,
    required this.onDelete,
  });

  final Color accentColor;
  final List<OperationalMasterDataRecord> records;
  final _SaveMasterDataRecord onSave;
  final _CanDeleteMasterDataRecord canDelete;
  final _DeleteMasterDataRecord onDelete;

  @override
  Widget build(BuildContext context) {
    final mainAccounts = _recordsByKind(
      records,
      OperationalMasterDataKind.cashboxMainAccount,
    );
    final subaccounts = _recordsByKind(
      records,
      OperationalMasterDataKind.cashboxSubaccount,
    );
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
          kind: OperationalMasterDataKind.cashboxMainAccount,
          entries: mainAccounts,
          allKindEntries: mainAccounts,
          onSave: onSave,
          canDelete: canDelete,
          onDelete: onDelete,
        ),
        _SettingsManagementPanel(
          keyPrefix: 'settingsCashboxSubAccounts',
          title: 'الحسابات الفرعية',
          fieldLabel: 'اسم الحساب الفرعي',
          parentLabel: 'الحساب الرئيسي',
          icon: Icons.segment_outlined,
          accentColor: accentColor,
          kind: OperationalMasterDataKind.cashboxSubaccount,
          entries: subaccounts,
          allKindEntries: subaccounts,
          parentOptions: mainAccounts,
          onSave: onSave,
          canDelete: canDelete,
          onDelete: onDelete,
        ),
      ],
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
    required this.kind,
    required this.entries,
    required this.allKindEntries,
    required this.onSave,
    required this.canDelete,
    required this.onDelete,
    this.parentLabel,
    this.parentOptions = const [],
  });

  final String keyPrefix;
  final String title;
  final String fieldLabel;
  final IconData icon;
  final Color accentColor;
  final OperationalMasterDataKind kind;
  final List<OperationalMasterDataRecord> entries;
  final List<OperationalMasterDataRecord> allKindEntries;
  final _SaveMasterDataRecord onSave;
  final _CanDeleteMasterDataRecord canDelete;
  final _DeleteMasterDataRecord onDelete;
  final String? parentLabel;
  final List<OperationalMasterDataRecord> parentOptions;

  @override
  State<_SettingsManagementPanel> createState() =>
      _SettingsManagementPanelState();
}

class _SettingsManagementPanelState
    extends State<_SettingsManagementPanel> {
  final _nameController = TextEditingController();
  EntityId? _selectedId;
  EntityId? _selectedParentId;
  var _isMutating = false;

  @override
  void initState() {
    super.initState();
    _selectedParentId = widget.parentOptions.firstOrNull?.id;
  }

  @override
  void didUpdateWidget(covariant _SettingsManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedId = _selectedId;
    if (selectedId != null) {
      final selected = widget.entries
          .where((entry) => entry.id == selectedId)
          .firstOrNull;
      if (selected == null) {
        _selectedId = null;
        _nameController.clear();
      } else {
        _selectedParentId = selected.parentId;
      }
    } else if (!widget.parentOptions.any(
      (parent) => parent.id == _selectedParentId,
    )) {
      _selectedParentId = widget.parentOptions.firstOrNull?.id;
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
      _selectedParentId = widget.parentOptions.firstOrNull?.id;
    });
  }

  Future<void> _addEntry() async {
    final name = _nameController.text.trim();
    if (!_validateNameAndParent(name)) return;
    final numberedEntries = widget.parentLabel == null
        ? widget.allKindEntries
        : widget.allKindEntries.where(
            (entry) => entry.parentId == _selectedParentId,
          );
    final nextNumber = numberedEntries.fold<int>(
          0,
          (largest, entry) => entry.number > largest ? entry.number : largest,
        ) +
        1;
    final nextId = EntityId.demo(
      _masterDataEntityType(widget.kind),
      _nextEntitySequence(
        widget.allKindEntries.map((entry) => entry.id),
        fallback: nextNumber,
      ),
    );
    final record = OperationalMasterDataRecord(
      id: nextId,
      kind: widget.kind,
      number: nextNumber,
      name: name,
      parentId: widget.parentLabel == null ? null : _selectedParentId,
    );
    await _mutate(
      () => widget.onSave(record),
      onSuccess: () {
        _selectedId = nextId;
        AppToast.showInfo(context, 'تمت إضافة السجل');
      },
    );
  }

  Future<void> _updateEntry() async {
    final selectedId = _selectedId;
    final name = _nameController.text.trim();
    if (selectedId == null || !_validateNameAndParent(name)) {
      if (selectedId == null) {
        AppToast.showWarning(context, 'اختر سجلاً واكتب الاسم الجديد');
      }
      return;
    }
    final existing = widget.entries
        .where((entry) => entry.id == selectedId)
        .firstOrNull;
    if (existing == null) return;
    final record = OperationalMasterDataRecord(
      id: existing.id,
      kind: existing.kind,
      number: existing.number,
      name: name,
      parentId: widget.parentLabel == null ? null : _selectedParentId,
      relatedEntityId: existing.relatedEntityId,
      isProtected: existing.isProtected,
    );
    await _mutate(
      () => widget.onSave(record),
      onSuccess: () => AppToast.showSuccess(context, 'تم تحديث السجل'),
    );
  }

  bool _validateNameAndParent(String name) {
    if (name.isEmpty) {
      AppToast.showWarning(context, 'اكتب ${widget.fieldLabel} أولاً');
      return false;
    }
    if (widget.parentLabel != null && _selectedParentId == null) {
      AppToast.showWarning(context, 'اختر ${widget.parentLabel} أولاً');
      return false;
    }
    return true;
  }

  Future<void> _deleteEntry(OperationalMasterDataRecord entry) async {
    if (_isMutating) return;
    final decision = await widget.canDelete(entry.id);
    if (!mounted) return;
    if (!decision.isAllowed) {
      AppToast.showDanger(
        context,
        decision.reason ?? 'لا يمكن حذف هذا السجل',
      );
      return;
    }
    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف السجل',
      message: 'هل تريد حذف «${entry.name}»؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!confirmed || !mounted) return;
    await _mutate(
      () => widget.onDelete(entry.id),
      onSuccess: () {
        if (_selectedId == entry.id) {
          _selectedId = null;
          _nameController.clear();
        }
        AppToast.showDanger(context, 'تم حذف السجل');
      },
    );
  }

  Future<void> _mutate(
    Future<void> Function() operation, {
    required VoidCallback onSuccess,
  }) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await operation();
      if (!mounted) return;
      onSuccess();
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      AppToast.showDanger(context, _settingsRepositoryMessage(error));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _selectEntry(OperationalMasterDataRecord entry) {
    setState(() {
      _selectedId = entry.id;
      _selectedParentId = entry.parentId;
      _nameController.text = entry.name;
      _nameController.selection = TextSelection.collapsed(
        offset: _nameController.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.keyPrefix;
    final parentNames = {
      for (final parent in widget.parentOptions) parent.id: parent.name,
    };

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
              value: _selectedParentId?.value,
              enabled: widget.parentOptions.isNotEmpty && !_isMutating,
              options: [
                for (final option in widget.parentOptions)
                  AppDropdownOption(
                    value: option.id.value,
                    label: option.name,
                  ),
              ],
              useIntrinsicHeight: true,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              menuTextDirection: TextDirection.rtl,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedParentId = EntityId(value));
                }
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
            enabled: !_isMutating,
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
                onPressed: _isMutating ||
                        (widget.parentLabel != null &&
                            _selectedParentId == null)
                    ? null
                    : _addEntry,
              ),
              AppButton(
                key: Key('${prefix}UpdateButton'),
                label: 'تحديث',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.success,
                minWidth: 115,
                onPressed: _isMutating ||
                        _selectedId == null ||
                        (widget.parentLabel != null &&
                            _selectedParentId == null)
                    ? null
                    : _updateEntry,
              ),
              AppButton(
                key: Key('${prefix}ClearButton'),
                label: 'تراجع',
                icon: Icons.undo_rounded,
                variant: AppButtonVariant.warning,
                minWidth: 115,
                onPressed: _isMutating ||
                        (_selectedId == null &&
                            _nameController.text.isEmpty)
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
              const AppTableColumn(label: 'ت', flex: 0.45, numeric: true),
              const AppTableColumn(label: 'الاسم', flex: 1.8),
              if (widget.parentLabel != null)
                AppTableColumn(label: widget.parentLabel!, flex: 1.35),
              const AppTableColumn(label: 'الحالة', flex: 1),
              const AppTableColumn(label: 'الإجراءات', flex: 0.8),
            ],
            rows: [
              for (final entry in widget.entries)
                AppTableRow(
                  rowKey: Key('${prefix}Row_${entry.id.value}'),
                  selected: entry.id == _selectedId,
                  onTap: () => _selectEntry(entry),
                  cells: [
                    Text('${entry.number}', textAlign: TextAlign.center),
                    Text(entry.name, overflow: TextOverflow.ellipsis),
                    if (widget.parentLabel != null)
                      Text(
                        parentNames[entry.parentId] ?? 'غير محدد',
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
                        key: Key('${prefix}Delete_${entry.id.value}'),
                        icon: Icons.delete_outline_rounded,
                        tooltip: entry.isProtected ? 'سجل نظامي' : 'حذف',
                        variant: AppButtonVariant.danger,
                        onPressed:
                            _isMutating ? null : () => _deleteEntry(entry),
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

List<OperationalMasterDataRecord> _recordsByKind(
  List<OperationalMasterDataRecord> records,
  OperationalMasterDataKind kind,
) {
  return List.unmodifiable(
    records.where((record) => record.kind == kind),
  );
}

String? _findMissingMasterDataReference(
  List<OperationalMasterDataRecord> records,
) {
  final byId = {for (final record in records) record.id: record};
  for (final record in records) {
    final parentId = record.parentId;
    if (parentId == null) continue;
    final parent = byId[parentId];
    if (parent == null || parent.kind != _requiredMasterDataParent(record.kind)) {
      return 'السجل «${record.name}» مرتبط بسجل أب غير موجود.';
    }
  }
  return null;
}

OperationalMasterDataKind? _requiredMasterDataParent(
  OperationalMasterDataKind kind,
) =>
    switch (kind) {
      OperationalMasterDataKind.itemType =>
        OperationalMasterDataKind.itemGroup,
      OperationalMasterDataKind.branch =>
        OperationalMasterDataKind.workplace,
      OperationalMasterDataKind.cashboxSubaccount =>
        OperationalMasterDataKind.cashboxMainAccount,
      _ => null,
    };

String _masterDataEntityType(OperationalMasterDataKind kind) => switch (kind) {
      OperationalMasterDataKind.itemGroup => 'item-group',
      OperationalMasterDataKind.itemType => 'item-type',
      OperationalMasterDataKind.workplace => 'workplace',
      OperationalMasterDataKind.branch => 'branch',
      OperationalMasterDataKind.cashboxMainAccount =>
        'cashbox-main-account',
      OperationalMasterDataKind.cashboxSubaccount => 'cashbox-subaccount',
    };
