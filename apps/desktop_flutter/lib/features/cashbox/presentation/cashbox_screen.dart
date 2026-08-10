import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/data/app_repository.dart';
import '../../../core/design/app_design_system.dart';
import '../../../core/printing/document_output_service.dart';
import '../../../core/services/service_failure.dart';
import '../domain/cashbox_voucher.dart';
import 'cashbox_controller.dart';
import 'widgets/cashbox_form.dart';
import 'widgets/cashbox_table.dart';

class CashboxScreen extends StatefulWidget {
  const CashboxScreen({
    super.key,
    this.controller,
    this.printService = const DemoDocumentOutputService(),
  });

  final CashboxController? controller;
  final DocumentPrintService printService;

  @override
  State<CashboxScreen> createState() => _CashboxScreenState();
}

class _CashboxScreenState extends State<CashboxScreen> {
  late CashboxController _cashboxController;
  bool _controllerInitialized = false;
  bool _ownsController = false;
  bool _showEditorWhenEmpty = false;
  final _formControllers = CashboxFormControllers();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  DateTime _voucherDateTime = DateTime.now();
  CashboxVoucherType _voucherType = CashboxVoucherType.receipt;
  String _mainAccountId = '';
  String _subaccountId = '';
  late _CashboxFormSnapshot _baseline;
  bool _isApplyingFormState = false;
  bool _hasUnsavedChanges = false;
  bool _isPrinting = false;
  Future<bool>? _pendingDiscardConfirmation;

  Iterable<TextEditingController> get _editableControllers => [
        _formControllers.mainAccount,
        _formControllers.subaccount,
        _formControllers.exchangeRate,
        _formControllers.amountIqd,
        _formControllers.amountUsd,
        _formControllers.notes,
  ];

  List<CashboxMainAccount> get _mainAccounts =>
      _cashboxController.state.accounts
          .where((account) => account.subaccounts.isNotEmpty)
          .toList(growable: false);

  CashboxMainAccount get _selectedMainAccount {
    return _mainAccounts.firstWhere(
      (account) => account.id == _mainAccountId,
      orElse: () => _mainAccounts.first,
    );
  }
  List<CashboxSubaccount> get _visibleSubaccounts =>
      _selectedMainAccount.subaccounts;

  CashboxSubaccount get _selectedSubaccount {
    return _visibleSubaccounts.firstWhere(
      (subaccount) => subaccount.id == _subaccountId,
      orElse: () => _visibleSubaccounts.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _formControllers.setNew(number: 1, exchangeRateValue: 1310);
    _baseline = _currentSnapshot();
    for (final controller in _editableControllers) {
      controller.addListener(_refreshEditableState);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllerInitialized) return;
    _setController(widget.controller);
    _controllerInitialized = true;
    unawaited(_loadCashbox());
  }

  @override
  void didUpdateWidget(covariant CashboxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    final previousController = _cashboxController;
    final disposePreviousController = _ownsController;
    _setController(widget.controller);
    _showEditorWhenEmpty = false;
    _hasUnsavedChanges = false;
    _baseline = _currentSnapshot();
    if (disposePreviousController) previousController.dispose();
    unawaited(_loadCashbox());
  }

  void _setController(CashboxController? suppliedController) {
    if (suppliedController != null) {
      _cashboxController = suppliedController;
      _ownsController = false;
    } else {
      final store = AppStoreScope.of(context, listen: false);
      _cashboxController = CashboxController(
        repository: store.repositories.cashbox,
        settingsRepository: store.repositories.businessSettings,
        onDataChanged: store.markDataChanged,
      );
      _ownsController = true;
    }
  }

  Future<void> _loadCashbox() async {
    final controller = _cashboxController;
    await controller.load();
    if (!mounted || !identical(controller, _cashboxController)) return;
    final status = controller.state.dataState.status;
    if (status == AppDataStatus.ready || status == AppDataStatus.empty) {
      setState(_setNewForm);
    }
  }

  @override
  void dispose() {
    for (final controller in _editableControllers) {
      controller.removeListener(_refreshEditableState);
    }
    if (_controllerInitialized && _ownsController) {
      _cashboxController.dispose();
    }
    _formControllers.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setNewForm() {
    _isApplyingFormState = true;
    _voucherDateTime = DateTime.now();
    _voucherType = _cashboxController.state.defaultVoucherType;
    final requestedMainId = _cashboxController.state.defaultMainAccountId;
    final defaultMain = _mainAccounts.firstWhere(
      (account) => account.id == requestedMainId,
      orElse: () => _mainAccounts.first,
    );
    _mainAccountId = defaultMain.id;
    _subaccountId = defaultMain.subaccounts.first.id;
    _formControllers
      ..setSummary(_cashboxController.summary)
      ..setNew(
        number: _cashboxController.nextNumber,
        exchangeRateValue: _cashboxController.state.defaultExchangeRate,
      );
    _syncAccountFields();
    _syncCalculatedFields();
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  void _newVoucher() {
    _cashboxController.select(null);
    setState(_setNewForm);
  }

  void _loadVoucher(CashboxVoucher voucher) {
    _isApplyingFormState = true;
    _voucherDateTime = voucher.createdAt;
    _voucherType = voucher.type;
    _mainAccountId = voucher.mainAccountId;
    _subaccountId = voucher.subaccountId;
    _formControllers
      ..setSummary(_cashboxController.summary)
      ..load(voucher);
    _syncAccountFields();
    _syncCalculatedFields();
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    setState(() => _hasUnsavedChanges = false);
  }

  void _selectVoucher(CashboxVoucher voucher) {
    if (_cashboxController.selectedVoucher?.id == voucher.id) return;
    unawaited(_selectVoucherAfterConfirmation(voucher));
  }

  Future<void> _selectVoucherAfterConfirmation(
    CashboxVoucher voucher,
  ) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    _cashboxController.select(voucher.id);
    _loadVoucher(voucher);
  }

  void _navigate(VoidCallback navigation) {
    unawaited(_navigateAfterConfirmation(navigation));
  }

  Future<void> _navigateAfterConfirmation(VoidCallback navigation) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    navigation();
    final selected = _cashboxController.selectedVoucher;
    if (selected == null) {
      setState(_setNewForm);
    } else {
      _loadVoucher(selected);
    }
  }

  _CashboxFormSnapshot _currentSnapshot() => (
        voucherDateTime: _voucherDateTime,
        voucherType: _voucherType,
        mainAccountId: _mainAccountId,
        subaccountId: _subaccountId,
        mainAccountText: _formControllers.mainAccount.text,
        subaccountText: _formControllers.subaccount.text,
        exchangeRate: _formControllers.exchangeRate.text,
        amountIqd: _formControllers.amountIqd.text,
        amountUsd: _formControllers.amountUsd.text,
        notes: _formControllers.notes.text,
      );

  void _refreshEditableState() {
    if (_isApplyingFormState || !mounted) return;
    _syncCalculatedFields();
    final hasUnsavedChanges = _currentSnapshot() != _baseline;
    setState(() => _hasUnsavedChanges = hasUnsavedChanges);
  }

  void _refreshSelectionState() {
    _syncCalculatedFields();
    _hasUnsavedChanges = _currentSnapshot() != _baseline;
  }

  void _changeDate(DateTime value) {
    setState(() {
      _voucherDateTime = DateTime(
        value.year,
        value.month,
        value.day,
        _voucherDateTime.hour,
        _voucherDateTime.minute,
        _voucherDateTime.second,
        _voucherDateTime.millisecond,
        _voucherDateTime.microsecond,
      );
      _refreshSelectionState();
    });
  }

  void _changeVoucherType(CashboxVoucherType value) {
    if (_voucherType == value) return;
    setState(() {
      _voucherType = value;
      _refreshSelectionState();
    });
  }

  void _changeMainAccount(String value) {
    if (_mainAccountId == value) return;
    setState(() {
      _isApplyingFormState = true;
      try {
        _mainAccountId = value;
        _subaccountId = _selectedMainAccount.subaccounts.first.id;
        _syncAccountFields();
      } finally {
        _isApplyingFormState = false;
      }
      _refreshSelectionState();
    });
  }

  void _changeSubaccount(String value) {
    if (_subaccountId == value) return;
    setState(() {
      _isApplyingFormState = true;
      try {
        _subaccountId = value;
        _syncAccountFields();
      } finally {
        _isApplyingFormState = false;
      }
      _refreshSelectionState();
    });
  }

  void _syncAccountFields() {
    _formControllers.mainAccount.text = _selectedMainAccount.label;
    _formControllers.subaccount.text = _selectedSubaccount.label;
  }

  void _syncCalculatedFields() {
    final exchangeRate =
        AppFormatters.parseNumber(_formControllers.exchangeRate.text) ?? 0;
    final amountIqd =
        AppFormatters.parseNumber(_formControllers.amountIqd.text) ?? 0;
    final amountUsd =
        AppFormatters.parseNumber(_formControllers.amountUsd.text) ?? 0;
    final selectedVoucher = _cashboxController.selectedVoucher;
    final useStoredBalances = selectedVoucher != null &&
        selectedVoucher.mainAccountId == _mainAccountId &&
        selectedVoucher.subaccountId == _subaccountId;
    final currentBalance = _cashboxController.accountBalance(
      _selectedSubaccount.id,
      fallback: CashboxAccountBalance(
        iqd: _selectedSubaccount.balanceIqd,
        usd: _selectedSubaccount.balanceUsd,
      ),
    );
    final previousIqd = useStoredBalances
        ? selectedVoucher.balanceBeforeIqd
        : currentBalance.iqd;
    final previousUsd = useStoredBalances
        ? selectedVoucher.balanceBeforeUsd
        : currentBalance.usd;
    final direction =
        _voucherType == CashboxVoucherType.receipt ? -1 : 1;

    _formControllers
      ..setSummary(_cashboxController.summary)
      ..setCalculated(
        equivalentUsdValue:
            exchangeRate > 0 ? amountIqd / exchangeRate : 0,
        previousIqdValue: previousIqd,
        remainingIqdValue: previousIqd + amountIqd * direction,
        equivalentIqdValue: exchangeRate > 0 ? amountUsd * exchangeRate : 0,
        previousUsdValue: previousUsd,
        remainingUsdValue: previousUsd + amountUsd * direction,
      );
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

  bool _validateForm() {
    if (_formControllers.mainAccount.text.trim() !=
        _selectedMainAccount.label) {
      AppToast.showWarning(context, 'اختر الحساب الرئيسي من القائمة');
      return false;
    }
    if (_formControllers.subaccount.text.trim() !=
        _selectedSubaccount.label) {
      AppToast.showWarning(context, 'اختر الحساب الفرعي من القائمة');
      return false;
    }

    final exchangeRate =
        AppFormatters.parseNumber(_formControllers.exchangeRate.text);
    if (exchangeRate == null || exchangeRate <= 0) {
      AppToast.showWarning(context, 'سعر الصرف يجب أن يكون أكبر من صفر');
      return false;
    }

    final amountIqd =
        AppFormatters.parseNumber(_formControllers.amountIqd.text) ?? 0;
    final amountUsd =
        AppFormatters.parseNumber(_formControllers.amountUsd.text) ?? 0;
    if (amountIqd <= 0 && amountUsd <= 0) {
      AppToast.showWarning(
        context,
        'يجب إدخال مبلغ دينار أو مبلغ دولار',
      );
      return false;
    }
    return true;
  }

  CashboxVoucher _voucherFromForm({
    required String id,
    required int number,
  }) {
    final exchangeRate =
        AppFormatters.parseNumber(_formControllers.exchangeRate.text) ?? 0;
    final amountIqd =
        AppFormatters.parseNumber(_formControllers.amountIqd.text) ?? 0;
    final amountUsd =
        AppFormatters.parseNumber(_formControllers.amountUsd.text) ?? 0;
    final selectedVoucher = _cashboxController.selectedVoucher;
    final useStoredBalances = selectedVoucher != null &&
        selectedVoucher.mainAccountId == _mainAccountId &&
        selectedVoucher.subaccountId == _subaccountId;
    final currentBalance = _cashboxController.accountBalance(
      _selectedSubaccount.id,
      fallback: CashboxAccountBalance(
        iqd: _selectedSubaccount.balanceIqd,
        usd: _selectedSubaccount.balanceUsd,
      ),
    );
    final previousIqd = useStoredBalances
        ? selectedVoucher.balanceBeforeIqd
        : currentBalance.iqd;
    final previousUsd = useStoredBalances
        ? selectedVoucher.balanceBeforeUsd
        : currentBalance.usd;
    final direction =
        _voucherType == CashboxVoucherType.receipt ? -1 : 1;

    return CashboxVoucher(
      id: id,
      number: number,
      createdAt: _voucherDateTime,
      type: _voucherType,
      mainAccountId: _selectedMainAccount.id,
      mainAccountLabel: _selectedMainAccount.label,
      subaccountId: _selectedSubaccount.id,
      subaccountLabel: _selectedSubaccount.label,
      exchangeRate: exchangeRate,
      amountIqd: amountIqd,
      amountUsd: amountUsd,
      balanceBeforeIqd: previousIqd,
      balanceAfterIqd: previousIqd + amountIqd * direction,
      balanceBeforeUsd: previousUsd,
      balanceAfterUsd: previousUsd + amountUsd * direction,
      notes: _formControllers.notes.text.trim(),
    );
  }

  Future<void> _save() async {
    if (!_validateForm()) return;
    if (_cashboxController.selectedVoucher != null) {
      AppToast.showWarning(context, 'استخدم زر تحديث لتعديل السند المحدد');
      return;
    }

    final voucher = _voucherFromForm(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      number: _cashboxController.nextNumber,
    );
    final controller = _cashboxController;
    try {
      final saved = await controller.add(voucher);
      if (!mounted || !identical(controller, _cashboxController)) return;
      _loadVoucher(saved);
      AppToast.showInfo(context, 'تم حفظ سند الصندوق');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, _stateErrorMessage(error));
    }
  }

  Future<void> _update() async {
    final selected = _cashboxController.selectedVoucher;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر سنداً من الجدول لتحديثه');
      return;
    }
    if (!_validateForm()) return;

    final updated = _voucherFromForm(
      id: selected.id,
      number: selected.number,
    );
    final controller = _cashboxController;
    try {
      final saved = await controller.update(updated);
      if (!mounted || !identical(controller, _cashboxController)) return;
      _loadVoucher(saved);
      AppToast.showSuccess(context, 'تم تحديث سند الصندوق');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, _stateErrorMessage(error));
    }
  }

  void _undo() {
    final selected = _cashboxController.selectedVoucher;
    if (selected == null) {
      _newVoucher();
    } else {
      _loadVoucher(selected);
    }
    AppToast.showWarning(context, 'تم التراجع عن التغييرات');
  }

  DocumentOutputRequest _cashboxDocumentRequest() {
    final voucherNumber = _formControllers.voucherNumber.text;
    return DocumentOutputRequest(
      title: 'سند ${_voucherType.label} رقم $voucherNumber',
      subtitle: _formControllers.subaccount.text,
      fileNameBase: 'سند صندوق $voucherNumber',
      fields: [
        DocumentField(
          label: 'التاريخ',
          value: AppFormatters.date(_voucherDateTime),
        ),
        DocumentField(
          label: 'الوقت',
          value: AppFormatters.time(TimeOfDay.fromDateTime(_voucherDateTime)),
        ),
        DocumentField(label: 'نوع السند', value: _voucherType.label),
        DocumentField(
          label: 'سعر الصرف',
          value: _formControllers.exchangeRate.text,
        ),
      ],
      columns: const [
        DocumentColumn(label: 'الحساب الرئيسي'),
        DocumentColumn(label: 'الحساب الفرعي'),
        DocumentColumn(label: 'المبلغ دينار'),
        DocumentColumn(label: 'المبلغ دولار'),
        DocumentColumn(label: 'الرصيد بعد الحركة دينار'),
        DocumentColumn(label: 'الرصيد بعد الحركة دولار'),
        DocumentColumn(label: 'الملاحظات'),
      ],
      rows: [
        [
          _formControllers.mainAccount.text,
          _formControllers.subaccount.text,
          _formControllers.amountIqd.text.trim().isEmpty
              ? '0'
              : _formControllers.amountIqd.text,
          _formControllers.amountUsd.text.trim().isEmpty
              ? '0.00'
              : _formControllers.amountUsd.text,
          _formControllers.remainingBalanceIqd.text,
          _formControllers.remainingBalanceUsd.text,
          _formControllers.notes.text.trim().isEmpty
              ? '—'
              : _formControllers.notes.text.trim(),
        ],
      ],
    );
  }

  Future<void> _print() async {
    if (_isPrinting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isPrinting = true);
    try {
      final result = await widget.printService.createPreview(
        _cashboxDocumentRequest(),
      );
      if (!mounted) return;
      AppToast.showInfo(context, 'تم تجهيز معاينة طباعة الصندوق');
      await AppDocumentOutputDialog.show(
        context,
        result: result,
        accentColor: AppModuleColors.cashbox,
      );
    } on ServiceFailure catch (failure) {
      if (mounted) AppToast.showError(context, failure.message);
    } catch (_) {
      if (mounted) AppToast.showError(context, 'تعذر تجهيز سند الصندوق');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _delete() async {
    final selected = _cashboxController.selectedVoucher;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر سنداً من الجدول لحذفه');
      return;
    }

    final controller = _cashboxController;
    final decision = await controller.canDeleteSelected();
    if (!mounted || !identical(controller, _cashboxController)) return;
    if (!decision.isAllowed) {
      AppToast.showDanger(
        context,
        decision.reason ?? 'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف سند الصندوق',
      message: 'هل تريد حذف سند الصندوق رقم ${selected.number}؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted ||
        !confirmed ||
        !identical(controller, _cashboxController)) {
      return;
    }

    await controller.deleteSelected();
    if (!mounted || !identical(controller, _cashboxController)) return;
    setState(_setNewForm);
    AppToast.showDanger(context, 'تم حذف سند الصندوق');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cashboxController,
      builder: (context, _) {
        final hasSelectedVoucher =
            _cashboxController.selectedVoucher != null;
        final visibleVouchers = _cashboxController.visibleVouchers;
        final selectedVisibleIndex =
            _cashboxController.selectedVisibleIndex;
        final hasVisibleVouchers = visibleVouchers.isNotEmpty;
        final canMoveToFirstOrPrevious =
            hasVisibleVouchers && selectedVisibleIndex != 0;
        final canMoveToNextOrLast =
            hasVisibleVouchers && selectedVisibleIndex >= 0;
        final dataState = _cashboxController.state.dataState;
        final showEditor = dataState.status == AppDataStatus.ready ||
            (dataState.status == AppDataStatus.empty &&
                _showEditorWhenEmpty);

        return PopScope(
          canPop: !_hasUnsavedChanges,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _attemptBack();
          },
          child: AppScreenShell(
            key: const Key('cashboxScreen'),
            title: 'الصندوق',
            subtitle: 'إدارة سندات القبض والصرف وحركات الصندوق',
            backgroundColor: Color.alphaBlend(
              AppModuleColors.cashbox.withAlpha(12),
              AppColors.surface,
            ),
            onBack: _attemptBack,
            onSearch: _searchFocusNode.requestFocus,
            onSave: hasSelectedVoucher
                ? _hasUnsavedChanges
                    ? _update
                    : null
                : _save,
            actions: [
            AppHeaderIconButton(
              key: const Key('cashboxPrintButton'),
              tooltipKey: const Key('cashboxPrintTooltip'),
              icon: Icons.print_rounded,
              tooltip: 'طباعة',
              onPressed: _isPrinting ? null : _print,
            ),
          ],
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: showEditor
                  ? Column(
              children: [
                CashboxForm(
                  controllers: _formControllers,
                  voucherDateTime: _voucherDateTime,
                  voucherType: _voucherType,
                  mainAccounts: _mainAccounts,
                  subaccounts: _visibleSubaccounts,
                  onDateChanged: _changeDate,
                  onVoucherTypeChanged: _changeVoucherType,
                  onMainAccountChanged: _changeMainAccount,
                  onSubaccountChanged: _changeSubaccount,
                ),
                const SizedBox(height: AppSpacing.md),
                AppActionBar(
                  key: const Key('cashboxActionBar'),
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  searchFieldKey: const Key('cashboxSearchField'),
                  searchClearButtonKey:
                      const Key('cashboxSearchClearButton'),
                  firstButtonKey: const Key('cashboxFirstButton'),
                  previousButtonKey: const Key('cashboxPreviousButton'),
                  nextButtonKey: const Key('cashboxNextButton'),
                  lastButtonKey: const Key('cashboxLastButton'),
                  saveButtonKey: const Key('cashboxSaveButton'),
                  updateButtonKey: const Key('cashboxUpdateButton'),
                  undoButtonKey: const Key('cashboxUndoButton'),
                  deleteButtonKey: const Key('cashboxDeleteButton'),
                  searchHint:
                      'رقم السند أو النوع أو الحساب أو المبلغ أو التاريخ',
                  accentColor: AppModuleColors.cashbox,
                  onSearchChanged: _cashboxController.search,
                  onFirst: canMoveToFirstOrPrevious
                      ? () => _navigate(_cashboxController.first)
                      : null,
                  onPrevious: canMoveToFirstOrPrevious
                      ? () => _navigate(_cashboxController.previous)
                      : null,
                  onNext: canMoveToNextOrLast
                      ? () => _navigate(_cashboxController.next)
                      : null,
                  onLast: canMoveToNextOrLast
                      ? () => _navigate(_cashboxController.last)
                      : null,
                  onSave: hasSelectedVoucher ? null : _save,
                  onUpdate: hasSelectedVoucher && _hasUnsavedChanges
                      ? _update
                      : null,
                  onUndo: _hasUnsavedChanges ? _undo : null,
                  onDelete: hasSelectedVoucher ? _delete : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CashboxTable(
                        vouchers: visibleVouchers,
                        selectedVoucherId:
                            _cashboxController.state.selectedVoucherId,
                        onSelected: _selectVoucher,
                        height: constraints.maxHeight,
                      );
                    },
                  ),
                ),
              ],
                    )
                  : AppDataStateView<List<CashboxVoucher>>(
                      state: dataState,
                      dataBuilder: (_, _) => const SizedBox.shrink(),
                      loadingStateKey: const Key('cashboxLoadingState'),
                      emptyStateKey: const Key('cashboxEmptyState'),
                      missingReferenceStateKey:
                          const Key('cashboxMissingReferenceState'),
                      errorStateKey: const Key('cashboxErrorState'),
                      emptyActionLabel: 'إضافة سند صندوق',
                      onEmptyAction: () {
                        setState(() {
                          _showEditorWhenEmpty = true;
                          _setNewForm();
                        });
                      },
                      missingReferenceActionLabel: 'إعادة المحاولة',
                      onMissingReferenceAction: _loadCashbox,
                      onRetry: _loadCashbox,
                    ),
            ),
          ),
        );
      },
    );
  }
}

typedef _CashboxFormSnapshot = ({
  DateTime voucherDateTime,
  CashboxVoucherType voucherType,
  String mainAccountId,
  String subaccountId,
  String mainAccountText,
  String subaccountText,
  String exchangeRate,
  String amountIqd,
  String amountUsd,
  String notes,
});

String _stateErrorMessage(StateError error) {
  return error.message;
}
