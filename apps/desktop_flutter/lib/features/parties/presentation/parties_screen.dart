import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/app_state/feature_action_permissions.dart';
import '../../../core/data/app_repository.dart';
import '../../../core/design/app_design_system.dart';
import '../../../core/domain/business_values.dart';
import '../../permissions/domain/permission_models.dart';
import '../application/party_statement_service.dart';
import '../domain/party.dart';
import 'parties_controller.dart';
import 'widgets/parties_table.dart';
import 'widgets/party_form.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({
    super.key,
    this.controller,
    this.statementService,
  });

  final PartiesController? controller;
  final PartyStatementService? statementService;

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  late PartiesController _partiesController;
  late PartyStatementService _statementService;
  bool _controllerInitialized = false;
  bool _ownsController = false;
  bool _isStatementLoading = false;
  bool _showEditorWhenEmpty = false;
  final _formControllers = PartyFormControllers();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  PartyType _partyType = PartyType.customer;
  DateTime _createdAt = DateTime.now();
  late _PartyFormSnapshot _baseline;
  bool _isApplyingFormState = false;
  bool _hasUnsavedChanges = false;
  Future<bool>? _pendingDiscardConfirmation;

  bool _allowsPartyAction(PermissionAction action) =>
      AppStoreScope.of(context, listen: false).allowsFeatureAction(
        'parties',
        action,
      );

  Iterable<TextEditingController> get _editableControllers => [
        _formControllers.name,
        _formControllers.workplace,
        _formControllers.branch,
        _formControllers.phone,
        _formControllers.alternatePhone,
        _formControllers.city,
        _formControllers.address,
        _formControllers.notes,
      ];

  @override
  void initState() {
    super.initState();
    _setNewForm();
    for (final controller in _editableControllers) {
      controller.addListener(_refreshUnsavedState);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllerInitialized) return;
    _setController(widget.controller);
    _setStatementService(widget.statementService);
    _controllerInitialized = true;
    unawaited(_loadParties());
  }

  @override
  void didUpdateWidget(covariant PartiesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.statementService, widget.statementService)) {
      _setStatementService(widget.statementService);
    }
    if (!identical(oldWidget.controller, widget.controller)) {
      final previousController = _partiesController;
      final disposePreviousController = _ownsController;
      _setController(widget.controller);
      _showEditorWhenEmpty = false;
      _hasUnsavedChanges = false;
      _baseline = _currentSnapshot();
      if (disposePreviousController) previousController.dispose();
      unawaited(_loadParties());
    }
  }

  void _setController(PartiesController? suppliedController) {
    if (suppliedController != null) {
      _partiesController = suppliedController;
      _ownsController = false;
    } else {
      final store = AppStoreScope.of(context, listen: false);
      _partiesController = PartiesController(
        repository: store.repositories.parties,
        masterData: store.repositories.operationalMasterData,
        onDataChanged: store.markDataChanged,
      );
      _ownsController = true;
    }
  }

  void _setStatementService(PartyStatementService? suppliedService) {
    if (suppliedService != null) {
      _statementService = suppliedService;
      return;
    }
    final repositories = AppStoreScope.of(
      context,
      listen: false,
    ).repositories;
    _statementService = RepositoryPartyStatementService(
      parties: repositories.parties,
      sales: repositories.sales,
      purchases: repositories.purchases,
      cashbox: repositories.cashbox,
    );
  }

  Future<void> _loadParties() async {
    final controller = _partiesController;
    await controller.load();
    if (!mounted || !identical(controller, _partiesController)) return;
    final status = controller.state.dataState.status;
    if (status == AppDataStatus.ready || status == AppDataStatus.empty) {
      setState(_setNewForm);
    }
  }

  @override
  void dispose() {
    for (final controller in _editableControllers) {
      controller.removeListener(_refreshUnsavedState);
    }
    if (_controllerInitialized && _ownsController) {
      _partiesController.dispose();
    }
    _formControllers.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setNewForm() {
    _isApplyingFormState = true;
    _createdAt = DateTime.now();
    _partyType = PartyType.customer;
    _formControllers.setNew(
      numberValue:
          _controllerInitialized ? _partiesController.nextNumber : 1,
      createdAt: _createdAt,
    );
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  void _newParty() {
    _partiesController.select(null);
    setState(_setNewForm);
  }

  void _loadParty(Party party) {
    _isApplyingFormState = true;
    _formControllers.load(party);
    _createdAt = party.createdAt;
    _partyType = party.type;
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    setState(() => _hasUnsavedChanges = false);
  }

  void _selectParty(Party party) {
    if (_partiesController.selectedParty?.id == party.id) return;
    unawaited(_selectPartyAfterConfirmation(party));
  }

  Future<void> _selectPartyAfterConfirmation(Party party) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    _partiesController.select(party.id);
    _loadParty(party);
  }

  void _navigate(VoidCallback navigation) {
    unawaited(_navigateAfterConfirmation(navigation));
  }

  Future<void> _navigateAfterConfirmation(VoidCallback navigation) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    navigation();
    final selected = _partiesController.selectedParty;
    if (selected == null) {
      setState(_setNewForm);
    } else {
      _loadParty(selected);
    }
  }

  _PartyFormSnapshot _currentSnapshot() => (
        name: _formControllers.name.text,
        type: _partyType,
        workplace: _formControllers.workplace.text,
        branch: _formControllers.branch.text,
        phone: _formControllers.phone.text,
        alternatePhone: _formControllers.alternatePhone.text,
        city: _formControllers.city.text,
        address: _formControllers.address.text,
        notes: _formControllers.notes.text,
      );

  void _refreshUnsavedState() {
    if (_isApplyingFormState || !mounted) return;
    final hasUnsavedChanges = _currentSnapshot() != _baseline;
    if (_hasUnsavedChanges == hasUnsavedChanges) return;
    setState(() => _hasUnsavedChanges = hasUnsavedChanges);
  }

  void _changePartyType(PartyType value) {
    if (_partyType == value) return;
    setState(() {
      _partyType = value;
      _hasUnsavedChanges = _currentSnapshot() != _baseline;
    });
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    final pendingConfirmation = _pendingDiscardConfirmation;
    if (pendingConfirmation != null) return pendingConfirmation;

    final confirmation = AppDialogs.confirm(
      context: context,
      title: 'تغييرات غير محفوظة',
      message: 'لديك بيانات أو تعديلات غير محفوظة. هل تريد تجاهلها؟',
      confirmLabel: 'تجاهل',
      cancelLabel: 'البقاء',
      isDanger: true,
    );
    _pendingDiscardConfirmation = confirmation;
    try {
      return await confirmation;
    } finally {
      if (identical(_pendingDiscardConfirmation, confirmation)) {
        _pendingDiscardConfirmation = null;
      }
    }
  }

  void _attemptBack() {
    unawaited(_leaveAfterConfirmation());
  }

  Future<void> _leaveAfterConfirmation() async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    if (_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = false);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    Navigator.of(context).pop();
  }

  bool _validateName() {
    if (_formControllers.name.text.trim().isNotEmpty) return true;
    AppToast.showWarning(context, 'أدخل اسم الطرف أولاً');
    return false;
  }

  bool _hasDuplicatePartyName({String? excludingPartyId}) {
    return _partiesController.nameExists(
      _formControllers.name.text,
      exceptPartyId: excludingPartyId,
    );
  }

  void _showDuplicateNameMessage() {
    AppToast.showWarning(context, 'يوجد طرف مسجل بهذا الاسم');
  }

  Party _newPartyFromForm() {
    return Party(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      number: _partiesController.nextNumber,
      createdAt: _createdAt,
      name: _formControllers.name.text.trim(),
      type: _partyType,
      workplace: _formControllers.workplace.text.trim(),
      branch: _formControllers.branch.text.trim(),
      phone: _formControllers.phone.text.trim(),
      alternatePhone: _formControllers.alternatePhone.text.trim(),
      city: _formControllers.city.text.trim(),
      address: _formControllers.address.text.trim(),
      notes: _formControllers.notes.text.trim(),
      balanceIqd: 0,
      balanceUsd: 0,
    );
  }

  Party _updatedPartyFromForm(Party current) {
    return current.copyWith(
      createdAt: _createdAt,
      name: _formControllers.name.text.trim(),
      type: _partyType,
      workplace: _formControllers.workplace.text.trim(),
      branch: _formControllers.branch.text.trim(),
      phone: _formControllers.phone.text.trim(),
      alternatePhone: _formControllers.alternatePhone.text.trim(),
      city: _formControllers.city.text.trim(),
      address: _formControllers.address.text.trim(),
      notes: _formControllers.notes.text.trim(),
    );
  }

  Future<void> _save() async {
    if (!_allowsPartyAction(PermissionAction.create)) return;
    if (!_validateName()) return;
    if (_partiesController.selectedParty != null) {
      AppToast.showWarning(context, 'استخدم زر تحديث لتعديل الطرف المحدد');
      return;
    }
    if (_hasDuplicatePartyName()) {
      _showDuplicateNameMessage();
      return;
    }

    try {
      final party = await _partiesController.add(_newPartyFromForm());
      if (!mounted) return;
      _loadParty(party);
      AppToast.showInfo(context, 'تم حفظ الطرف');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, _stateErrorMessage(error));
    }
  }

  Future<void> _update() async {
    if (!_allowsPartyAction(PermissionAction.update)) return;
    final selected = _partiesController.selectedParty;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر طرفاً من الجدول لتحديثه');
      return;
    }
    if (!_validateName()) return;
    if (_hasDuplicatePartyName(excludingPartyId: selected.id)) {
      _showDuplicateNameMessage();
      return;
    }

    try {
      final updated = await _partiesController.update(
        _updatedPartyFromForm(selected),
      );
      if (!mounted) return;
      _loadParty(updated);
      AppToast.showSuccess(context, 'تم تحديث الطرف');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, _stateErrorMessage(error));
    }
  }

  void _undo() {
    final selected = _partiesController.selectedParty;
    if (selected == null) {
      _newParty();
    } else {
      _loadParty(selected);
    }
    AppToast.showWarning(context, 'تم التراجع عن التغييرات');
  }

  Future<void> _delete() async {
    if (!_allowsPartyAction(PermissionAction.delete)) return;
    final selected = _partiesController.selectedParty;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر طرفاً من الجدول لحذفه');
      return;
    }
    final decision = await _partiesController.canDeleteSelected();
    if (!mounted) return;
    if (!decision.isAllowed) {
      AppToast.showDanger(
        context,
        decision.reason ?? 'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف الطرف',
      message: 'هل تريد حذف ${selected.name}؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted || !confirmed) return;

    await _partiesController.deleteSelected();
    if (!mounted) return;
    setState(_setNewForm);
    AppToast.showDanger(context, 'تم حذف الطرف');
  }

  void _showStatement(Party party) {
    unawaited(_showStatementAfterOptions(party));
  }

  Future<void> _showStatementAfterOptions(Party party) async {
    if (_isStatementLoading) return;
    final options = await AppStatementOptionsDialog.show(
      context,
      partyName: party.name,
      firstTransactionDate: party.createdAt,
      accentColor: AppModuleColors.parties,
    );
    if (!mounted || options == null) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    _isStatementLoading = true;
    final loadingDialog = _showStatementLoading();
    PartyStatementResult? result;
    Object? failure;
    try {
      result = await _statementService.load(
        PartyStatementQuery(
          partyId: party.entityId,
          fromDate: BusinessDate.fromDateTime(options.fromDate),
          toDate: BusinessDate.fromDateTime(options.toDate),
          currency: AppCurrency.parse(options.currencyCode),
        ),
      );
    } catch (error) {
      failure = error;
    } finally {
      if (navigator.mounted) navigator.pop();
      await loadingDialog;
      _isStatementLoading = false;
    }
    if (!mounted) return;
    if (failure != null || result == null) {
      AppToast.showError(
        context,
        'تعذر تحميل كشف الحساب. حاول مرة أخرى.',
      );
      return;
    }

    await AppStatementReportDialog.show(
      context,
      partyName: party.name,
      options: options,
      openingBalance: result.openingBalance.majorUnits,
      entries: [
        for (final entry in result.entries)
          AppStatementReportEntry(
            date: entry.date,
            balance: entry.balance.majorUnits,
            credit: entry.credit.majorUnits,
            debit: entry.debit.majorUnits,
            type: entry.type.label,
            quantity: entry.quantity,
            details: entry.details,
          ),
      ],
      accentColor: AppModuleColors.parties,
      allowPrint: _allowsPartyAction(PermissionAction.print),
      allowExport: _allowsPartyAction(PermissionAction.export),
    );
  }

  Future<void> _showStatementLoading() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: PopScope(
          canPop: false,
          child: Dialog(
            key: const Key('partyStatementLoadingDialog'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const SizedBox(
              width: 480,
              child: AppStatePanel(
                key: Key('partyStatementLoadingState'),
                type: AppStateType.loading,
                title: 'جاري تحميل كشف الحساب',
                message: 'يتم الآن تجميع الحركات وحساب الرصيد.',
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _partiesController,
      builder: (context, _) {
        final hasSelectedParty = _partiesController.selectedParty != null;
        final visibleParties = _partiesController.visibleParties;
        final selectedVisibleIndex =
            _partiesController.selectedVisibleIndex;
        final hasVisibleParties = visibleParties.isNotEmpty;
        final canMoveToFirstOrPrevious =
            hasVisibleParties && selectedVisibleIndex != 0;
        final canMoveToNextOrLast =
            hasVisibleParties && selectedVisibleIndex >= 0;
        final dataState = _partiesController.state.dataState;
        final showEditor = dataState.status == AppDataStatus.ready ||
            (dataState.status == AppDataStatus.empty &&
                _showEditorWhenEmpty);
        final canCreate = _allowsPartyAction(PermissionAction.create);
        final canUpdate = _allowsPartyAction(PermissionAction.update);
        final canDelete = _allowsPartyAction(PermissionAction.delete);

        return PopScope(
          canPop: !_hasUnsavedChanges,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _attemptBack();
          },
          child: AppScreenShell(
            key: const Key('partiesScreen'),
            title: 'الأطراف',
            subtitle: 'إدارة بيانات الزبائن والمجهزين والموظفين',
            onBack: _attemptBack,
            onSearch: _searchFocusNode.requestFocus,
            onSave: hasSelectedParty
                ? _hasUnsavedChanges && canUpdate
                    ? _update
                    : null
                : canCreate
                    ? _save
                    : null,
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: showEditor
                  ? Column(
              children: [
                PartyForm(
                  controllers: _formControllers,
                  createdAt: _createdAt,
                  partyType: _partyType,
                  workplaces: _partiesController.workplaceSuggestions,
                  branches: _partiesController.branchSuggestions,
                  cities: _partiesController.citySuggestions,
                  onPartyTypeChanged: (value) {
                    if (value == null) return;
                    _changePartyType(value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppActionBar(
                  key: const Key('partiesActionBar'),
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  searchFieldKey: const Key('partiesSearchField'),
                  searchClearButtonKey:
                      const Key('partiesSearchClearButton'),
                  firstButtonKey: const Key('partiesFirstButton'),
                  previousButtonKey: const Key('partiesPreviousButton'),
                  nextButtonKey: const Key('partiesNextButton'),
                  lastButtonKey: const Key('partiesLastButton'),
                  saveButtonKey: const Key('partiesSaveButton'),
                  updateButtonKey: const Key('partiesUpdateButton'),
                  undoButtonKey: const Key('partiesUndoButton'),
                  deleteButtonKey: const Key('partiesDeleteButton'),
                  searchHint: 'الاسم أو النوع أو الهاتف أو المدينة',
                  onSearchChanged: _partiesController.search,
                  onFirst: canMoveToFirstOrPrevious
                      ? () => _navigate(_partiesController.first)
                      : null,
                  onPrevious: canMoveToFirstOrPrevious
                      ? () => _navigate(_partiesController.previous)
                      : null,
                  onNext: canMoveToNextOrLast
                      ? () => _navigate(_partiesController.next)
                      : null,
                  onLast: canMoveToNextOrLast
                      ? () => _navigate(_partiesController.last)
                      : null,
                  onSave:
                      hasSelectedParty || !canCreate ? null : _save,
                  onUpdate:
                      hasSelectedParty && _hasUnsavedChanges && canUpdate
                          ? _update
                          : null,
                  onUndo: _hasUnsavedChanges ? _undo : null,
                  onDelete:
                      hasSelectedParty && canDelete ? _delete : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return PartiesTable(
                        parties: _partiesController.visibleParties,
                        selectedPartyId:
                            _partiesController.state.selectedPartyId,
                        onSelected: _selectParty,
                        onStatement: _showStatement,
                        height: constraints.maxHeight,
                      );
                    },
                  ),
                ),
              ],
                    )
                  : AppDataStateView<List<Party>>(
                      state: dataState,
                      dataBuilder: (_, _) => const SizedBox.shrink(),
                      loadingStateKey: const Key('partiesLoadingState'),
                      emptyStateKey: const Key('partiesEmptyState'),
                      missingReferenceStateKey:
                          const Key('partiesMissingReferenceState'),
                      errorStateKey: const Key('partiesErrorState'),
                      emptyActionLabel: 'إضافة طرف',
                      onEmptyAction: canCreate ? () {
                        setState(() {
                          _showEditorWhenEmpty = true;
                          _setNewForm();
                        });
                      } : null,
                      missingReferenceActionLabel: 'إعادة المحاولة',
                      onMissingReferenceAction: _loadParties,
                      onRetry: _loadParties,
                    ),
            ),
          ),
        );
      },
    );
  }
}

typedef _PartyFormSnapshot = ({
  String name,
  PartyType type,
  String workplace,
  String branch,
  String phone,
  String alternatePhone,
  String city,
  String address,
  String notes,
});

String _stateErrorMessage(StateError error) {
  return error.message;
}
