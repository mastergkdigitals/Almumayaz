part of 'purchase_screen.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({
    super.key,
    this.printService = const DemoDocumentOutputService(),
    this.exportService = const DemoDocumentOutputService(),
  });

  final DocumentPrintService printService;
  final DocumentExportService exportService;

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _invoiceNumberController = TextEditingController(text: '1');
  final _exchangeRateController = TextEditingController(text: '1,310');
  final _originalInvoiceController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _expensesController = TextEditingController(text: '0');
  final _invoiceDiscountController = TextEditingController(text: '0');
  final _discountPercentageController = TextEditingController(text: '0');
  final _paidController = TextEditingController(text: '0');
  final _totalController = TextEditingController(text: '0');
  final _remainingController = TextEditingController(text: '0');
  final _currentBalanceController = TextEditingController(text: '0');
  final _expensesFocusNode = FocusNode();

  final List<_PurchaseInvoiceViewData> _purchaseInvoices = [];
  DateTime _invoiceDateTime = DateTime.now();
  _PurchaseInvoiceViewData? _selectedInvoice;
  List<AppPurchaseInvoiceTableRowData> _activeItems = const [];
  List<_PurchaseReturnLineDraft> _returnLines = const [];
  EntityId? _selectedOriginalPurchaseInvoiceId;
  var _warehouseId = '';
  var _purchaseType = 'محلي';
  var _paymentType = 'نقدي';
  var _currency = 'IQD';
  var _summaryQuantity = '0';
  var _summaryDiscount = '0';
  var _summaryTotal = '0';
  var _summaryTotalCost = '0';
  num _invoiceAdjustment = 0;
  var _tableDataVersion = 0;
  var _discountInputSource = _PurchaseDiscountInputSource.amount;
  num _balanceBeforeInvoice = 0;
  var _nonCashPaidText = '0';
  late final InvoiceEditorDirtyTracker<_PurchaseFormSnapshot> _dirtyTracker;
  var _isApplyingFormState = false;
  var _hasUnsavedChanges = false;
  var _isDocumentActionRunning = false;
  Future<bool>? _pendingDiscardConfirmation;
  AppStore? _store;
  late PartyStatementService _statementService;
  InvoiceEditorCoordinator<_PurchaseInvoiceViewData>? _coordinator;
  AppDataState<List<_PurchaseInvoiceViewData>> _invoiceState =
      const AppDataState.loading();
  var _didStartLoading = false;
  var _isRepositoryBusy = false;
  List<Party> _supplierOptions = const [];
  EntityId? _selectedSupplierId;
  List<AppDropdownOption<String>> _warehouseOptions = const [];
  var _defaultWarehouseId = '';
  var _defaultWarehouseName = '';
  var _defaultPurchaseType = 'محلي';
  var _defaultPaymentType = 'نقدي';
  var _defaultCurrency = 'IQD';
  var _defaultExchangeRate = '1,310';
  var _repositoryNextInvoiceNumber = 1;
  final Set<EntityId> _knownItemIds = {};
  final Map<String, String> _warehouseNamesById = {};
  List<AppInvoiceItemOption> _itemOptions = const [];

  bool _allowsPurchaseAction(PermissionAction action) =>
      _store?.allowsFeatureAction('purchases', action) ?? true;

  void _setPurchaseState(VoidCallback callback) => setState(callback);

  Iterable<TextEditingController> get _editableControllers => [
        _exchangeRateController,
        _originalInvoiceController,
        _supplierNameController,
        _notesController,
        _expensesController,
        _invoiceDiscountController,
        _discountPercentageController,
        _paidController,
      ];

  bool get _isPurchaseReturn => _purchaseType == 'إرجاع';

  int get _nextInvoiceNumber {
    return _repositoryNextInvoiceNumber;
  }

  List<AppSearchRecord<EntityId>> get _purchaseSearchRecords => [
        for (final invoice in _purchaseInvoices)
          AppSearchRecord(
            value: invoice.entityId,
            title: invoice.source.isReturn
                ? 'مرتجع شراء رقم ${invoice.documentNumber}'
                : 'قائمة شراء رقم ${invoice.documentNumber}',
            subtitle: invoice.supplierName,
            details: invoice.searchDetails,
            searchTerms: invoice.searchTerms,
            icon: Icons.shopping_cart_checkout_rounded,
          ),
      ];

  @override
  void initState() {
    super.initState();
    _dirtyTracker = InvoiceEditorDirtyTracker(_currentSnapshot());
    for (final controller in _editableControllers) {
      controller.addListener(_refreshUnsavedState);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) return;
    _didStartLoading = true;
    _store = AppStoreScope.of(context, listen: false);
    final repositories = _store!.repositories;
    _statementService = RepositoryPartyStatementService(
      parties: repositories.parties,
      sales: repositories.sales,
      purchases: repositories.purchases,
      cashbox: repositories.cashbox,
      salesReturns: repositories.salesReturns,
      expenses: repositories.expenses,
    );
    _coordinator = InvoiceEditorCoordinator<_PurchaseInvoiceViewData>(
      loadRecords: _loadRepositoryInvoices,
      idOf: (invoice) => invoice.entityId,
    );
    unawaited(_loadData());
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
    if (_isRepositoryBusy) return;
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

  void _navigate(InvoiceEditorNavigation destination) {
    unawaited(_navigateAfterConfirmation(destination));
  }

  Future<void> _navigateAfterConfirmation(
    InvoiceEditorNavigation destination,
  ) async {
    if (!await _confirmDiscardChanges() || !mounted) return;

    if (_purchaseInvoices.isEmpty) {
      setState(_setNewForm);
      return;
    }

    final coordinator = _coordinator!;
    coordinator.selection.select(_selectedInvoice?.entityId);
    final target = coordinator.selection.navigate(destination);

    setState(() {
      if (target == null) {
        _setNewForm();
      } else {
        _loadInvoice(target);
      }
    });
  }

  Future<void> _save() async {
    if (!_allowsPurchaseAction(PermissionAction.create)) return;
    if (!_validateForm()) return;
    if (_selectedInvoice != null) {
      AppToast.showWarning(
        context,
        'استخدم زر تحديث لتعديل مستند الشراء المحدد',
      );
      return;
    }

    final entityId = EntityId(
      'purchase-invoice-${_invoiceNumberController.text}-${DateTime.now().microsecondsSinceEpoch}',
    );
    late final PurchaseInvoice invoice;
    try {
      invoice = _domainInvoiceFromForm(entityId: entityId);
    } catch (_) {
      AppToast.showError(context, 'تحقق من قيم قائمة الشراء المدخلة');
      return;
    }
    final saved = await _runRepositoryMutation(
      () => _store!.repositories.purchases.createInvoice(invoice),
      failureMessage: _isPurchaseReturn
          ? 'تعذر حفظ مرتجع الشراء'
          : 'تعذر حفظ قائمة الشراء',
    );
    if (saved == null || !mounted) return;
    await _loadData(showLoading: false, selectEntityId: saved.id);
    if (!mounted) return;
    AppToast.showInfo(
      context,
      _isPurchaseReturn ? 'تم حفظ مرتجع الشراء' : 'تم حفظ قائمة الشراء',
    );
  }

  Future<void> _update() async {
    if (!_allowsPurchaseAction(PermissionAction.update)) return;
    final selected = _selectedInvoice;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مستند شراء لتحديثه');
      return;
    }
    if (!_validateForm()) return;

    late final PurchaseInvoice updated;
    try {
      updated = _domainInvoiceFromForm(entityId: selected.entityId);
    } catch (_) {
      AppToast.showError(context, 'تحقق من قيم قائمة الشراء المدخلة');
      return;
    }
    final saved = await _runRepositoryMutation(
      () => _store!.repositories.purchases.replaceInvoice(updated),
      failureMessage: _isPurchaseReturn
          ? 'تعذر تحديث مرتجع الشراء'
          : 'تعذر تحديث قائمة الشراء',
    );
    if (saved == null || !mounted) return;
    await _loadData(showLoading: false, selectEntityId: saved.id);
    if (!mounted) return;
    AppToast.showSuccess(
      context,
      saved.isReturn ? 'تم تحديث مرتجع الشراء' : 'تم تحديث قائمة الشراء',
    );
  }

  void _undo() {
    final selected = _selectedInvoice;
    setState(() {
      if (selected == null) {
        _setNewForm();
      } else {
        final stored = _purchaseInvoices.firstWhere(
          (invoice) => invoice.entityId == selected.entityId,
        );
        _loadInvoice(stored);
      }
    });
    AppToast.showWarning(context, 'تم التراجع عن التغييرات');
  }

  Future<void> _delete() async {
    if (!_allowsPurchaseAction(PermissionAction.delete)) return;
    final selected = _selectedInvoice;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مستند شراء لحذفه');
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: selected.source.isReturn
          ? 'حذف مرتجع الشراء'
          : 'حذف قائمة الشراء',
      message: selected.source.isReturn
          ? 'هل تريد حذف مرتجع الشراء رقم ${selected.documentNumber}؟'
          : 'هل تريد حذف قائمة الشراء رقم ${selected.documentNumber}؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted || !confirmed) return;

    final deleted = await _runRepositoryMutation(
      () async {
        await _store!.repositories.purchases
            .deleteInvoicePermanently(selected.entityId);
        return true;
      },
      failureMessage: selected.source.isReturn
          ? 'تعذر حذف مرتجع الشراء'
          : 'تعذر حذف قائمة الشراء',
    );
    if (deleted == null || !mounted) return;
    await _loadData(showLoading: false);
    if (!mounted) return;
    setState(_setNewForm);
    AppToast.showDanger(
      context,
      selected.source.isReturn
          ? 'تم حذف مرتجع الشراء'
          : 'تم حذف قائمة الشراء',
    );
  }

  Future<T?> _runRepositoryMutation<T>(
    Future<T> Function() operation, {
    required String failureMessage,
  }) async {
    final coordinator = _coordinator;
    if (coordinator == null || _isRepositoryBusy) return null;
    setState(() => _isRepositoryBusy = true);
    try {
      final result = await coordinator.mutate(operation);
      _store!.markDataChanged();
      return result;
    } on StateError catch (error) {
      if (mounted) {
        final message = error.message;
        AppToast.showError(
          context,
          message.isEmpty ? failureMessage : message,
        );
      }
    } on FormatException {
      if (mounted) AppToast.showError(context, 'تحقق من القيم الرقمية المدخلة');
    } catch (_) {
      if (mounted) AppToast.showError(context, failureMessage);
    } finally {
      if (mounted) setState(() => _isRepositoryBusy = false);
    }
    return null;
  }

  Future<void> _showPurchaseSearch() async {
    final result = await AppRecordSearchDialog.show<EntityId>(
      context,
      title: 'بحث قوائم الشراء',
      subtitle: 'ابحث عن قائمة شراء محفوظة ثم اخترها',
      searchLabel: 'بحث في قوائم الشراء',
      hint: 'رقم القائمة أو اسم المجهز أو اسم المادة',
      accentColor: AppModuleColors.purchases,
      records: _purchaseSearchRecords,
      emptyTitle: 'لا توجد قوائم شراء محفوظة',
      noResultsTitle: 'لا توجد قوائم شراء مطابقة',
      dialogKey: const Key('purchaseRecordSearchDialog'),
      searchFieldKey: const Key('purchaseRecordSearchField'),
      resultKeyPrefix: 'purchaseRecordSearchResult',
    );

    if (!mounted || result == null) return;
    final invoice = _purchaseInvoices.firstWhere(
      (candidate) => candidate.entityId == result,
    );
    if (!await _confirmDiscardChanges() || !mounted) return;
    setState(() => _loadInvoice(invoice));
    AppToast.showInfo(
      context,
      'تم اختيار قائمة الشراء رقم ${invoice.documentNumber}',
    );
  }

  void _openEmptyEditor() {
    setState(() {
      _invoiceState = AppDataState.ready(_purchaseInvoices);
      _setNewForm();
    });
  }

  @override
  void dispose() {
    for (final controller in _editableControllers) {
      controller.removeListener(_refreshUnsavedState);
    }
    _invoiceNumberController.dispose();
    _exchangeRateController.dispose();
    _originalInvoiceController.dispose();
    _supplierNameController.dispose();
    _notesController.dispose();
    _expensesController.dispose();
    _invoiceDiscountController.dispose();
    _discountPercentageController.dispose();
    _paidController.dispose();
    _totalController.dispose();
    _remainingController.dispose();
    _currentBalanceController.dispose();
    _expensesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPurchaseScreen(context);
}
