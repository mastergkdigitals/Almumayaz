import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/app_state/feature_action_permissions.dart';
import '../../../core/data/app_repository.dart';
import '../../../core/design/app_design_system.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/printing/document_output_service.dart';
import '../../../core/services/service_failure.dart';
import '../../parties/domain/party.dart';
import '../../permissions/domain/permission_models.dart';
import '../domain/expense.dart';
import 'expenses_controller.dart';
import 'widgets/expense_form.dart';
import 'widgets/expenses_table.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({
    super.key,
    this.controller,
    this.outputService,
    this.allowsAction,
  });

  final ExpensesController? controller;
  final DocumentOutputService? outputService;
  final bool Function(PermissionAction action)? allowsAction;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  static const _accent = AppModuleColors.cashbox;

  late ExpensesController _controller;
  late DocumentOutputService _outputService;
  bool _initialized = false;
  bool _ownsController = false;
  bool _showEditorWhenEmpty = false;
  bool _isApplyingForm = false;
  bool _hasUnsavedChanges = false;
  bool _isMutating = false;
  bool _isOutputting = false;
  Future<bool>? _pendingDiscardConfirmation;

  final _numberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _supplierController = TextEditingController();
  final _amountController = TextEditingController();
  final _exchangeRateController = TextEditingController(text: '1310');
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  DateTime _expenseDateTime = DateTime.now();
  ExpensePaymentStatus _paymentStatus = ExpensePaymentStatus.paid;
  AppCurrency _currency = AppCurrency.iqd;
  EntityId? _supplierId;
  late _ExpenseFormSnapshot _baseline;

  Iterable<TextEditingController> get _editableControllers => [
        _descriptionController,
        _supplierController,
        _amountController,
        _exchangeRateController,
        _notesController,
      ];

  bool _allowsExpenseAction(PermissionAction action) =>
      widget.allowsAction?.call(action) ??
      AppStoreScope.of(context, listen: false).allowsFeatureAction(
        'expenses',
        action,
      );

  bool get _isBusy => _isMutating || _isOutputting;

  bool _startMutation() {
    if (_isBusy) return false;
    setState(() => _isMutating = true);
    return true;
  }

  void _finishMutation() {
    if (mounted) setState(() => _isMutating = false);
  }

  @override
  void initState() {
    super.initState();
    _baseline = _currentSnapshot();
    for (final controller in _editableControllers) {
      controller.addListener(_refreshDirtyState);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final needsStore = widget.outputService == null || widget.controller == null;
    final store = needsStore
        ? AppStoreScope.of(context, listen: false)
        : null;
    _outputService = widget.outputService ?? store!.services.documentOutput;
    if (widget.controller == null) {
      final resolvedStore = store!;
      _controller = ExpensesController(
        repository: resolvedStore.repositories.expenses,
        parties: resolvedStore.repositories.parties,
        onDataChanged: resolvedStore.markDataChanged,
      );
      _ownsController = true;
    } else {
      _controller = widget.controller!;
    }
    _initialized = true;
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final controller in _editableControllers) {
      controller.removeListener(_refreshDirtyState);
    }
    if (_initialized && _ownsController) _controller.dispose();
    _numberController.dispose();
    _descriptionController.dispose();
    _supplierController.dispose();
    _amountController.dispose();
    _exchangeRateController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final controller = _controller;
    await controller.load();
    if (!mounted || !identical(controller, _controller)) return;
    final status = controller.state.dataState.status;
    if (status == AppDataStatus.ready || status == AppDataStatus.empty) {
      setState(_setNewForm);
    }
  }

  void _setNewForm() {
    _isApplyingForm = true;
    _controller.select(null);
    _expenseDateTime = DateTime.now();
    _paymentStatus = ExpensePaymentStatus.paid;
    _currency = AppCurrency.iqd;
    _supplierId = null;
    _numberController.text = '${_controller.nextDocumentNumber}';
    _descriptionController.clear();
    _supplierController.clear();
    _amountController.clear();
    _exchangeRateController.text = '1310';
    _notesController.clear();
    _isApplyingForm = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  void _loadExpense(Expense expense) {
    _isApplyingForm = true;
    _expenseDateTime = expense.date.atTime(
      hour: expense.minuteOfDay ~/ Duration.minutesPerHour,
      minute: expense.minuteOfDay % Duration.minutesPerHour,
    );
    _paymentStatus = expense.paymentStatus;
    _currency = expense.amount.currency;
    _supplierId = expense.supplierId;
    _numberController.text = '${expense.documentNumber}';
    _descriptionController.text = expense.description;
    _supplierController.text = expense.supplierNameSnapshot ?? '';
    _amountController.text = expense.amount.toPlainString();
    _exchangeRateController.text = expense.exchangeRate.toPlainString();
    _notesController.text = expense.notes;
    _isApplyingForm = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  _ExpenseFormSnapshot _currentSnapshot() => (
        dateTime: _expenseDateTime,
        paymentStatus: _paymentStatus,
        currency: _currency,
        supplierId: _supplierId,
        description: _descriptionController.text,
        supplier: _supplierController.text,
        amount: _amountController.text,
        exchangeRate: _exchangeRateController.text,
        notes: _notesController.text,
      );

  void _refreshDirtyState() {
    if (!mounted || _isApplyingForm) return;
    final dirty = _currentSnapshot() != _baseline;
    if (dirty != _hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = dirty);
    }
  }

  void _changeDate(DateTime value) {
    setState(() {
      _expenseDateTime = DateTime(
        value.year,
        value.month,
        value.day,
        _expenseDateTime.hour,
        _expenseDateTime.minute,
      );
      _hasUnsavedChanges = _currentSnapshot() != _baseline;
    });
  }

  void _changeStatus(ExpensePaymentStatus value) {
    setState(() {
      _paymentStatus = value;
      _hasUnsavedChanges = _currentSnapshot() != _baseline;
    });
  }

  void _changeCurrency(AppCurrency value) {
    setState(() {
      _currency = value;
      final parsed = AppFormatters.parseNumber(_amountController.text);
      if (parsed != null) {
        _isApplyingForm = true;
        _amountController.text = AppFormatters.money(
          parsed,
          decimalPlaces: value.decimalPlaces,
        );
        _isApplyingForm = false;
      }
      _hasUnsavedChanges = _currentSnapshot() != _baseline;
    });
  }

  void _selectSupplier(Party supplier) {
    setState(() {
      _supplierId = supplier.entityId;
      _isApplyingForm = true;
      _supplierController.text = supplier.name;
      _isApplyingForm = false;
      _hasUnsavedChanges = _currentSnapshot() != _baseline;
    });
  }

  void _changeSupplierText(String value) {
    final normalized = value.trim();
    EntityId? exactId;
    for (final supplier in _controller.state.suppliers) {
      if (supplier.name == normalized) {
        exactId = supplier.entityId;
        break;
      }
    }
    if (_supplierId == exactId) return;
    setState(() {
      _supplierId = exactId;
      _hasUnsavedChanges = _currentSnapshot() != _baseline;
    });
  }

  Future<void> _selectExpense(Expense expense) async {
    if (_controller.selectedExpense?.id == expense.id) return;
    if (!await _confirmDiscardChanges() || !mounted) return;
    _controller.select(expense.id);
    setState(() => _loadExpense(expense));
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    final pending = _pendingDiscardConfirmation;
    if (pending != null) return pending;
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

  Party? _supplierFromForm() {
    final text = _supplierController.text.trim();
    if (text.isEmpty) return null;
    for (final supplier in _controller.state.suppliers) {
      if (supplier.entityId == _supplierId && supplier.name == text) {
        return supplier;
      }
    }
    throw StateError('اختر المجهز من القائمة');
  }

  _ExpenseFormValues _readForm() {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) throw StateError('أدخل بيان المصروف');
    final supplier = _supplierFromForm();
    if (_paymentStatus == ExpensePaymentStatus.unpaid && supplier == null) {
      throw StateError('اختر المجهز للمصروف غير المدفوع');
    }
    final amount = Money.parse(_amountController.text, _currency);
    if (!amount.isPositive) throw StateError('مبلغ المصروف يجب أن يكون موجباً');
    final exchangeRate = ExchangeRate.parse(_exchangeRateController.text);
    return (
      date: BusinessDate.fromDateTime(_expenseDateTime),
      minuteOfDay: _expenseDateTime.hour * Duration.minutesPerHour +
          _expenseDateTime.minute,
      description: description,
      supplierId: supplier?.entityId,
      amount: amount,
      exchangeRate: exchangeRate,
      notes: _notesController.text.trim(),
    );
  }

  Future<void> _save() async {
    if (!_allowsExpenseAction(PermissionAction.create)) return;
    if (_controller.selectedExpense != null) {
      AppToast.showWarning(context, 'استخدم زر تحديث لتعديل المصروف المحدد');
      return;
    }
    if (!_startMutation()) return;
    try {
      final values = _readForm();
      final saved = await _controller.create(
        ExpenseCreateRequest(
          date: values.date,
          minuteOfDay: values.minuteOfDay,
          description: values.description,
          amount: values.amount,
          exchangeRate: values.exchangeRate,
          supplierId: values.supplierId,
          paymentStatus: _paymentStatus,
          paidAt: _paymentStatus == ExpensePaymentStatus.paid
              ? AuditTimestamp(_expenseDateTime)
              : null,
          notes: values.notes,
        ),
      );
      if (!mounted) return;
      setState(() => _loadExpense(saved));
      AppToast.showInfo(context, 'تم حفظ المصروف');
    } on FormatException catch (_) {
      if (mounted) AppToast.showWarning(context, 'تحقق من المبلغ وسعر الصرف');
    } on ArgumentError catch (_) {
      if (mounted) AppToast.showWarning(context, 'تحقق من بيانات المصروف');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, error.message);
    } on ServiceFailure catch (error) {
      if (mounted) AppToast.showError(context, error.message);
    } finally {
      _finishMutation();
    }
  }

  Future<void> _update() async {
    if (!_allowsExpenseAction(PermissionAction.update)) return;
    final selected = _controller.selectedExpense;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مصروفاً لتحديثه');
      return;
    }
    if (!_startMutation()) return;
    try {
      final values = _readForm();
      final saved = await _controller.update(
        ExpenseUpdateRequest(
          id: selected.id,
          date: values.date,
          minuteOfDay: values.minuteOfDay,
          description: values.description,
          amount: values.amount,
          exchangeRate: values.exchangeRate,
          supplierId: values.supplierId,
          notes: values.notes,
        ),
      );
      if (!mounted) return;
      setState(() => _loadExpense(saved));
      AppToast.showSuccess(context, 'تم تحديث المصروف');
    } on FormatException catch (_) {
      if (mounted) AppToast.showWarning(context, 'تحقق من المبلغ وسعر الصرف');
    } on ArgumentError catch (_) {
      if (mounted) AppToast.showWarning(context, 'تحقق من بيانات المصروف');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, error.message);
    } on ServiceFailure catch (error) {
      if (mounted) AppToast.showError(context, error.message);
    } finally {
      _finishMutation();
    }
  }

  Future<void> _settle() async {
    if (!_allowsExpenseAction(PermissionAction.update)) return;
    final selected = _controller.selectedExpense;
    if (selected == null || selected.isPaid) return;
    if (_hasUnsavedChanges) {
      AppToast.showWarning(context, 'احفظ التعديلات أو تراجع عنها أولاً');
      return;
    }
    if (!_startMutation()) return;
    try {
      final confirmed = await AppDialogs.confirm(
        context: context,
        title: 'تسديد المصروف بالكامل',
        message:
            'هل تريد تسديد المصروف رقم ${selected.documentNumber} بالكامل؟',
        confirmLabel: 'تسديد',
      );
      if (!mounted || !confirmed) return;
      final now = AuditTimestamp(DateTime.now());
      final paidAt = now.compareTo(selected.occurredAt) < 0
          ? selected.occurredAt
          : now;
      final saved = await _controller.settle(selected.id, paidAt: paidAt);
      if (!mounted) return;
      setState(() => _loadExpense(saved));
      AppToast.showSuccess(context, 'تم تسديد المصروف بالكامل');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, error.message);
    } on ServiceFailure catch (error) {
      if (mounted) AppToast.showError(context, error.message);
    } finally {
      _finishMutation();
    }
  }

  Future<void> _delete() async {
    if (!_allowsExpenseAction(PermissionAction.delete)) return;
    final selected = _controller.selectedExpense;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مصروفاً لحذفه');
      return;
    }
    if (!_startMutation()) return;
    try {
      final decision = await _controller.canDeleteSelected();
      if (!mounted) return;
      if (!decision.isAllowed) {
        AppToast.showDanger(
          context,
          decision.reason ?? 'لا يمكن حذف المصروف',
        );
        return;
      }
      final confirmed = await AppDialogs.confirm(
        context: context,
        title: 'حذف المصروف',
        message:
            'هل تريد حذف المصروف رقم ${selected.documentNumber}؟',
        confirmLabel: 'حذف',
        isDanger: true,
      );
      if (!mounted || !confirmed) return;
      await _controller.deleteSelected();
      if (!mounted) return;
      setState(_setNewForm);
      AppToast.showDanger(context, 'تم حذف المصروف');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, error.message);
    } on ServiceFailure catch (error) {
      if (mounted) AppToast.showError(context, error.message);
    } finally {
      _finishMutation();
    }
  }

  DocumentOutputRequest _documentRequest(Expense expense) {
    return DocumentOutputRequest(
      title: 'سند مصروف رقم ${expense.documentNumber}',
      subtitle: expense.description,
      fileNameBase: 'مصروف ${expense.documentNumber}',
      auditTarget: DocumentOutputAuditTarget(
        entityType: 'expense',
        entityId: expense.id,
      ),
      fields: [
        DocumentField(
          label: 'التاريخ',
          value: AppFormatters.date(expense.date.value),
          spreadsheetCellKind: DocumentSpreadsheetCellKind.date,
        ),
        DocumentField(
          label: 'الوقت',
          value: _formatMinuteOfDay(expense.minuteOfDay),
          spreadsheetCellKind: DocumentSpreadsheetCellKind.time,
        ),
        DocumentField(label: 'الحالة', value: expense.paymentStatus.label),
        DocumentField(
          label: 'المجهز',
          value: expense.supplierNameSnapshot ?? '—',
        ),
      ],
      columns: [
        const DocumentColumn(label: 'البيان'),
        const DocumentColumn(label: 'العملة'),
        DocumentColumn(
          label: 'المبلغ',
          isPrice: true,
          spreadsheetCellKind: DocumentSpreadsheetCellKind.decimal,
          spreadsheetDecimalPlaces: expense.amount.currency.decimalPlaces,
        ),
        const DocumentColumn(
          label: 'سعر الصرف',
          spreadsheetCellKind: DocumentSpreadsheetCellKind.decimal,
          spreadsheetDecimalPlaces: ExchangeRate.decimalPlaces,
        ),
        const DocumentColumn(label: 'الملاحظات'),
      ],
      rows: [
        [
          expense.description,
          expense.amount.currency.code,
          expense.amount.toPlainString(),
          expense.exchangeRate.toPlainString(),
          expense.notes.isEmpty ? '—' : expense.notes,
        ],
      ],
    );
  }

  Future<void> _runOutput(DocumentOutputAction action) async {
    final selected = _controller.selectedExpense;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مصروفاً أولاً');
      return;
    }
    final requiredPermission = action == DocumentOutputAction.print
        ? PermissionAction.print
        : PermissionAction.export;
    if (!_allowsExpenseAction(requiredPermission) ||
        _hasUnsavedChanges ||
        _isBusy) {
      return;
    }
    setState(() => _isOutputting = true);
    try {
      final latest = await _controller.refreshSelectedForOutput();
      if (!mounted) return;
      if (latest == null) {
        AppToast.showWarning(context, 'المصروف المحدد لم يعد موجوداً');
        return;
      }
      setState(() => _loadExpense(latest));
      final request = _documentRequest(latest);
      final result = action == DocumentOutputAction.print
          ? await _outputService.createPreview(request)
          : await _outputService.export(
              request,
              action == DocumentOutputAction.pdf
                  ? DocumentExportFormat.pdf
                  : DocumentExportFormat.excel,
            );
      if (!mounted) return;
      setState(() => _isOutputting = false);
      await AppDocumentOutputDialog.show(
        context,
        result: result,
        accentColor: _accent,
      );
    } on ServiceFailure catch (failure) {
      if (mounted) AppToast.showError(context, failure.message);
    } catch (_) {
      if (mounted) AppToast.showError(context, 'تعذر تجهيز مخرج المصروف');
    } finally {
      if (mounted && _isOutputting) {
        setState(() => _isOutputting = false);
      }
    }
  }

  void _navigate(VoidCallback action) {
    unawaited(_navigateAfterConfirmation(action));
  }

  Future<void> _navigateAfterConfirmation(VoidCallback action) async {
    if (_isBusy) return;
    if (!await _confirmDiscardChanges() || !mounted) return;
    action();
    final selected = _controller.selectedExpense;
    setState(() {
      if (selected == null) {
        _setNewForm();
      } else {
        _loadExpense(selected);
      }
    });
  }

  void _attemptBack() => unawaited(_leaveAfterConfirmation());

  Future<void> _leaveAfterConfirmation() async {
    if (_isBusy) return;
    if (!await _confirmDiscardChanges() || !mounted) return;
    if (_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = false);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final selected = _controller.selectedExpense;
        final dataState = state.dataState;
        final showEditor = dataState.status == AppDataStatus.ready ||
            (dataState.status == AppDataStatus.empty && _showEditorWhenEmpty);
        final visible = _controller.visibleExpenses;
        final selectedIndex = _controller.selectedVisibleIndex;
        final canCreate = _allowsExpenseAction(PermissionAction.create);
        final canUpdate = _allowsExpenseAction(PermissionAction.update);
        final canDelete = _allowsExpenseAction(PermissionAction.delete);
        final canPrint = _allowsExpenseAction(PermissionAction.print);
        final canExport = _allowsExpenseAction(PermissionAction.export);
        final isBusy = _isBusy;
        final fieldsEnabled =
            !isBusy && (selected == null ? canCreate : canUpdate);

        return PopScope(
          canPop: !_hasUnsavedChanges && !isBusy,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _attemptBack();
          },
          child: AppScreenShell(
            key: const Key('expensesScreen'),
            title: 'المصاريف',
            subtitle: 'إدارة المصاريف المدفوعة والمستحقة للمجهزين',
            backgroundColor: Color.alphaBlend(
              _accent.withAlpha(12),
              AppColors.surface,
            ),
            onBack: isBusy ? null : _attemptBack,
            onSearch: isBusy ? null : _searchFocusNode.requestFocus,
            onSave: isBusy
                ? null
                : selected == null
                    ? canCreate
                        ? _save
                        : null
                    : canUpdate && _hasUnsavedChanges
                        ? _update
                        : null,
            actions: [
              AppHeaderIconButton(
                key: const Key('expenseSettleButton'),
                tooltipKey: const Key('expenseSettleTooltip'),
                icon: Icons.price_check_rounded,
                tooltip: 'تسديد المصروف بالكامل',
                onPressed: selected?.isUnpaid == true &&
                        !_hasUnsavedChanges &&
                        canUpdate &&
                        !isBusy
                    ? _settle
                    : null,
              ),
              AppHeaderIconButton(
                key: const Key('expensePrintButton'),
                tooltipKey: const Key('expensePrintTooltip'),
                icon: Icons.print_rounded,
                tooltip: 'طباعة',
                onPressed: selected != null &&
                        !_hasUnsavedChanges &&
                        canPrint &&
                        !isBusy
                    ? () => _runOutput(DocumentOutputAction.print)
                    : null,
              ),
              AppHeaderIconButton(
                key: const Key('expensePdfButton'),
                tooltipKey: const Key('expensePdfTooltip'),
                icon: Icons.picture_as_pdf_rounded,
                tooltip: 'تصدير PDF',
                onPressed: selected != null &&
                        !_hasUnsavedChanges &&
                        canExport &&
                        !isBusy
                    ? () => _runOutput(DocumentOutputAction.pdf)
                    : null,
              ),
              AppHeaderIconButton(
                key: const Key('expenseExcelButton'),
                tooltipKey: const Key('expenseExcelTooltip'),
                icon: Icons.table_view_rounded,
                tooltip: 'تصدير Excel',
                onPressed: selected != null &&
                        !_hasUnsavedChanges &&
                        canExport &&
                        !isBusy
                    ? () => _runOutput(DocumentOutputAction.excel)
                    : null,
              ),
            ],
            body: AppLoadingOverlay(
              isLoading: isBusy,
              message: _isOutputting
                  ? 'جاري تجهيز المستند'
                  : 'جاري تنفيذ العملية',
              overlayKey: const Key('expenseBusyOverlay'),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: showEditor
                    ? Column(
                        children: [
                        ExpenseForm(
                          numberController: _numberController,
                          descriptionController: _descriptionController,
                          supplierController: _supplierController,
                          amountController: _amountController,
                          exchangeRateController: _exchangeRateController,
                          notesController: _notesController,
                          dateTime: _expenseDateTime,
                          paymentStatus: _paymentStatus,
                          currency: _currency,
                          suppliers: state.suppliers,
                          enabled: fieldsEnabled,
                          statusEditable: selected == null,
                          onDateChanged: _changeDate,
                          onStatusChanged: _changeStatus,
                          onCurrencyChanged: _changeCurrency,
                          onSupplierSelected: _selectSupplier,
                          onSupplierTextChanged: _changeSupplierText,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppActionBar(
                          key: const Key('expensesActionBar'),
                          searchController: _searchController,
                          searchFocusNode: _searchFocusNode,
                          searchFieldKey: const Key('expenseSearchField'),
                          searchClearButtonKey:
                              const Key('expenseSearchClearButton'),
                          firstButtonKey: const Key('expenseFirstButton'),
                          previousButtonKey:
                              const Key('expensePreviousButton'),
                          nextButtonKey: const Key('expenseNextButton'),
                          lastButtonKey: const Key('expenseLastButton'),
                          saveButtonKey: const Key('expenseSaveButton'),
                          updateButtonKey: const Key('expenseUpdateButton'),
                          undoButtonKey: const Key('expenseUndoButton'),
                          deleteButtonKey: const Key('expenseDeleteButton'),
                          searchHint:
                              'رقم المصروف أو البيان أو المجهز أو الحالة',
                          accentColor: _accent,
                          onSearchChanged: _controller.search,
                          onFirst: !isBusy &&
                                  visible.isNotEmpty &&
                                  selectedIndex != 0
                              ? () => _navigate(_controller.first)
                              : null,
                          onPrevious:
                              !isBusy &&
                                      visible.isNotEmpty &&
                                      selectedIndex != 0
                                  ? () => _navigate(_controller.previous)
                                  : null,
                          onNext: !isBusy && visible.isNotEmpty
                              ? () => _navigate(_controller.next)
                              : null,
                          onLast: !isBusy && visible.isNotEmpty
                              ? () => _navigate(_controller.last)
                              : null,
                          onSave: !isBusy && selected == null && canCreate
                              ? _save
                              : null,
                          onUpdate: !isBusy &&
                                  selected != null &&
                                  _hasUnsavedChanges &&
                                  canUpdate
                              ? _update
                              : null,
                          onUndo: !isBusy && _hasUnsavedChanges
                              ? () => setState(() {
                                    if (selected == null) {
                                      _setNewForm();
                                    } else {
                                      _loadExpense(selected);
                                    }
                                    AppToast.showWarning(
                                      context,
                                      'تم التراجع عن التغييرات',
                                    );
                                  })
                              : null,
                          onDelete: !isBusy && selected != null && canDelete
                              ? _delete
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) => ExpensesTable(
                              expenses: visible,
                              selectedExpenseId: selected?.id.value,
                              onSelected: (expense) {
                                unawaited(_selectExpense(expense));
                              },
                              height: constraints.maxHeight,
                            ),
                          ),
                        ),
                        ],
                      )
                    : AppDataStateView<List<Expense>>(
                        state: dataState,
                        dataBuilder: (_, _) => const SizedBox.shrink(),
                        loadingStateKey: const Key('expensesLoadingState'),
                        emptyStateKey: const Key('expensesEmptyState'),
                        missingReferenceStateKey:
                            const Key('expensesMissingReferenceState'),
                        errorStateKey: const Key('expensesErrorState'),
                        emptyActionLabel: 'إضافة مصروف',
                        onEmptyAction: canCreate
                            ? () => setState(() {
                                  _showEditorWhenEmpty = true;
                                  _setNewForm();
                                })
                            : null,
                        missingReferenceActionLabel: 'إعادة المحاولة',
                        onMissingReferenceAction: _load,
                        onRetry: _load,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

typedef _ExpenseFormSnapshot = ({
  DateTime dateTime,
  ExpensePaymentStatus paymentStatus,
  AppCurrency currency,
  EntityId? supplierId,
  String description,
  String supplier,
  String amount,
  String exchangeRate,
  String notes,
});

typedef _ExpenseFormValues = ({
  BusinessDate date,
  int minuteOfDay,
  String description,
  EntityId? supplierId,
  Money amount,
  ExchangeRate exchangeRate,
  String notes,
});

String _formatMinuteOfDay(int minuteOfDay) {
  final hour = (minuteOfDay ~/ Duration.minutesPerHour)
      .toString()
      .padLeft(2, '0');
  final minute = (minuteOfDay % Duration.minutesPerHour)
      .toString()
      .padLeft(2, '0');
  return '$hour:$minute';
}
