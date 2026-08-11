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

        final byParentId = (first.parentId?.value ?? '')
            .compareTo(second.parentId?.value ?? '');
        if (byParentId != 0) return byParentId;

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

  Future<OperationalMasterDataRecord> _createRecord(
    CreateOperationalMasterDataRequest request,
  ) async {
    final saved = await _repository!.createNamedRecord(request);
    _store!.markDataChanged();
    await _load(showLoading: false);
    return saved;
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
        AppSelectionTabs<String>(
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
              onCreate: _createRecord,
              onSave: _saveRecord,
              canDelete: _canDelete,
              onDelete: _deleteRecord,
            ),
            _WorkplacesBranchesTemplate(
              accentColor: widget.accentColor,
              records: records,
              onCreate: _createRecord,
              onSave: _saveRecord,
              canDelete: _canDelete,
              onDelete: _deleteRecord,
            ),
            _CashboxAccountsTemplate(
              accentColor: widget.accentColor,
              records: records,
              onCreate: _createRecord,
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
typedef _CreateMasterDataRecord = Future<OperationalMasterDataRecord> Function(
  CreateOperationalMasterDataRequest request,
);
typedef _CanDeleteMasterDataRecord = Future<DeleteDecision> Function(
  EntityId id,
);
typedef _DeleteMasterDataRecord = Future<void> Function(EntityId id);

class _GroupsTypesTemplate extends StatelessWidget {
  const _GroupsTypesTemplate({
    required this.accentColor,
    required this.records,
    required this.onCreate,
    required this.onSave,
    required this.canDelete,
    required this.onDelete,
  });

  final Color accentColor;
  final List<OperationalMasterDataRecord> records;
  final _CreateMasterDataRecord onCreate;
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
    return AppResponsiveGrid(
      key: const Key('settingsGroupsTypesTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 620,
      children: [
        _SettingsManagementPanelAdapter(
          keyPrefix: 'settingsItemGroups',
          title: 'مجموعات المواد',
          fieldLabel: 'اسم المجموعة',
          icon: Icons.folder_copy_outlined,
          accentColor: accentColor,
          kind: OperationalMasterDataKind.itemGroup,
          entries: groups,
          dependentEntries: types,
          onCreate: onCreate,
          onSave: onSave,
          canDelete: canDelete,
          onDelete: onDelete,
        ),
        _SettingsManagementPanelAdapter(
          keyPrefix: 'settingsItemTypes',
          title: 'أنواع المواد',
          fieldLabel: 'اسم النوع',
          parentLabel: 'المجموعة',
          icon: Icons.account_tree_outlined,
          accentColor: accentColor,
          kind: OperationalMasterDataKind.itemType,
          entries: types,
          parentOptions: groups,
          onCreate: onCreate,
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
    required this.onCreate,
    required this.onSave,
    required this.canDelete,
    required this.onDelete,
  });

  final Color accentColor;
  final List<OperationalMasterDataRecord> records;
  final _CreateMasterDataRecord onCreate;
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
    return AppResponsiveGrid(
      key: const Key('settingsWorkplacesBranchesTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 620,
      children: [
        _SettingsManagementPanelAdapter(
          keyPrefix: 'settingsWorkplaces',
          title: 'جهات العمل',
          fieldLabel: 'اسم جهة العمل',
          icon: Icons.business_center_outlined,
          accentColor: accentColor,
          kind: OperationalMasterDataKind.workplace,
          entries: workplaces,
          dependentEntries: branches,
          onCreate: onCreate,
          onSave: onSave,
          canDelete: canDelete,
          onDelete: onDelete,
        ),
        _SettingsManagementPanelAdapter(
          keyPrefix: 'settingsWorkplaceBranches',
          title: 'الفروع',
          fieldLabel: 'اسم الفرع',
          parentLabel: 'جهة العمل',
          icon: Icons.fork_right_outlined,
          accentColor: accentColor,
          kind: OperationalMasterDataKind.branch,
          entries: branches,
          parentOptions: workplaces,
          onCreate: onCreate,
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
    required this.onCreate,
    required this.onSave,
    required this.canDelete,
    required this.onDelete,
  });

  final Color accentColor;
  final List<OperationalMasterDataRecord> records;
  final _CreateMasterDataRecord onCreate;
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
    return AppResponsiveGrid(
      key: const Key('settingsCashboxAccountsTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 620,
      children: [
        _SettingsManagementPanelAdapter(
          keyPrefix: 'settingsCashboxMainAccounts',
          title: 'الحسابات الرئيسية',
          fieldLabel: 'اسم الحساب الرئيسي',
          icon: Icons.account_balance_wallet_outlined,
          accentColor: accentColor,
          kind: OperationalMasterDataKind.cashboxMainAccount,
          entries: mainAccounts,
          dependentEntries: subaccounts,
          onCreate: onCreate,
          onSave: onSave,
          canDelete: canDelete,
          onDelete: onDelete,
        ),
        _SettingsManagementPanelAdapter(
          keyPrefix: 'settingsCashboxSubAccounts',
          title: 'الحسابات الفرعية',
          fieldLabel: 'اسم الحساب الفرعي',
          parentLabel: 'الحساب الرئيسي',
          icon: Icons.segment_outlined,
          accentColor: accentColor,
          kind: OperationalMasterDataKind.cashboxSubaccount,
          entries: subaccounts,
          parentOptions: mainAccounts,
          onCreate: onCreate,
          onSave: onSave,
          canDelete: canDelete,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _SettingsManagementPanelAdapter extends StatelessWidget {
  const _SettingsManagementPanelAdapter({
    required this.keyPrefix,
    required this.title,
    required this.fieldLabel,
    required this.icon,
    required this.accentColor,
    required this.kind,
    required this.entries,
    required this.onCreate,
    required this.onSave,
    required this.canDelete,
    required this.onDelete,
    this.parentLabel,
    this.parentOptions = const [],
    this.dependentEntries = const [],
  });

  final String keyPrefix;
  final String title;
  final String fieldLabel;
  final IconData icon;
  final Color accentColor;
  final OperationalMasterDataKind kind;
  final List<OperationalMasterDataRecord> entries;
  final List<OperationalMasterDataRecord> dependentEntries;
  final _CreateMasterDataRecord onCreate;
  final _SaveMasterDataRecord onSave;
  final _CanDeleteMasterDataRecord canDelete;
  final _DeleteMasterDataRecord onDelete;
  final String? parentLabel;
  final List<OperationalMasterDataRecord> parentOptions;

  @override
  Widget build(BuildContext context) {
    return AppSectionPanel(
      key: Key('${keyPrefix}Panel'),
      title: title,
      icon: icon,
      accentColor: accentColor,
      child: AppManagementPanel(
        keys: AppManagementPanelKeys(prefix: keyPrefix),
        fieldLabel: fieldLabel,
        parentLabel: parentLabel,
        accentColor: accentColor,
        entries: entries.map(_toManagementEntry).toList(growable: false),
        parentOptions:
            parentOptions.map(_toManagementEntry).toList(growable: false),
        referencedEntryIds: {
          for (final entry in dependentEntries)
            if (entry.parentId != null) entry.parentId!.value,
        },
        onCreate: _createEntry,
        onUpdate: _updateEntry,
        canDelete: _checkDelete,
        onDelete: _deleteEntry,
        errorMessage: _settingsRepositoryMessage,
      ),
    );
  }

  Future<AppManagementEntry> _createEntry(
    AppManagementEntryDraft draft,
  ) async {
    final record = await onCreate(
      CreateOperationalMasterDataRequest(
        kind: kind,
        name: draft.name,
        parentId:
            draft.parentId == null ? null : EntityId(draft.parentId!),
      ),
    );
    return _toManagementEntry(record);
  }

  Future<AppManagementEntry> _updateEntry(
    AppManagementEntry entry,
    AppManagementEntryDraft draft,
  ) async {
    final existing = entries
        .where((record) => record.id.value == entry.id)
        .firstOrNull;
    if (existing == null) throw StateError('السجل غير موجود');
    final record = OperationalMasterDataRecord(
      id: existing.id,
      kind: existing.kind,
      number: existing.number,
      name: draft.name,
      parentId:
          draft.parentId == null ? null : EntityId(draft.parentId!),
      relatedEntityId: existing.relatedEntityId,
      isProtected: existing.isProtected,
    );
    await onSave(record);
    return _toManagementEntry(record);
  }

  Future<AppManagementDeleteDecision> _checkDelete(
    AppManagementEntry entry,
  ) async {
    final decision = await canDelete(EntityId(entry.id));
    return decision.isAllowed
        ? const AppManagementDeleteDecision.allowed()
        : AppManagementDeleteDecision.blocked(decision.reason);
  }

  Future<void> _deleteEntry(AppManagementEntry entry) {
    return onDelete(EntityId(entry.id));
  }

  AppManagementEntry _toManagementEntry(
    OperationalMasterDataRecord record,
  ) {
    return AppManagementEntry(
      id: record.id.value,
      number: record.number,
      name: record.name,
      parentId: record.parentId?.value,
      isProtected: record.isProtected,
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
