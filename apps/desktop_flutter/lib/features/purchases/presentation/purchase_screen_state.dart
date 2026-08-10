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

  final List<_DemoPurchaseInvoice> _purchaseInvoices = [];
  DateTime _invoiceDateTime = DateTime.now();
  _DemoPurchaseInvoice? _selectedInvoice;
  List<AppPurchaseInvoiceTableRowData> _activeItems = const [];
  var _warehouse = 'الرئيسي';
  var _purchaseType = 'محلي';
  var _paymentType = 'نقدي';
  var _currency = 'IQD';
  var _summaryQuantity = '0';
  var _summaryDiscount = '0';
  var _summaryTotal = '0';
  var _summaryTotalCost = '0';
  num _lineBaseTotal = 0;
  num _invoiceAdjustment = 0;
  var _tableDataVersion = 0;
  var _discountInputSource = _PurchaseDiscountInputSource.amount;
  num _balanceBeforeInvoice = 0;
  var _nonCashPaidText = '0';
  late _PurchaseFormSnapshot _baseline;
  var _isApplyingFormState = false;
  var _hasUnsavedChanges = false;
  var _isDocumentActionRunning = false;
  Future<bool>? _pendingDiscardConfirmation;
  AppStore? _store;
  InvoiceEditorCoordinator<_DemoPurchaseInvoice>? _coordinator;
  AppDataState<List<_DemoPurchaseInvoice>> _invoiceState =
      const AppDataState.loading();
  var _didStartLoading = false;
  var _isRepositoryBusy = false;
  var _supplierOptions = _purchaseSupplierOptions;
  var _warehouseOptions = _purchaseWarehouseOptions;
  var _defaultWarehouse = 'الرئيسي';
  var _defaultPurchaseType = 'محلي';
  var _defaultPaymentType = 'نقدي';
  var _defaultCurrency = 'IQD';
  var _defaultExchangeRate = '1,310';
  var _repositoryNextInvoiceNumber = 1;
  final Map<String, EntityId> _supplierIdsByName = {};
  final Map<String, EntityId> _itemIdsByLabel = {};
  final Set<EntityId> _knownItemIds = {};
  final Map<String, EntityId> _warehouseIdsByLabel = {};
  List<AppInvoiceItemOption> _itemOptions = const [];

  void _setPurchaseState(VoidCallback callback) => setState(callback);

  Iterable<TextEditingController> get _editableControllers => [
        _exchangeRateController,
        _supplierNameController,
        _notesController,
        _expensesController,
        _invoiceDiscountController,
        _discountPercentageController,
        _paidController,
      ];

  int get _selectedInvoiceIndex {
    final selectedId = _selectedInvoice?.id;
    if (selectedId == null) return -1;
    return _purchaseInvoices.indexWhere(
      (invoice) => invoice.id == selectedId,
    );
  }

  int get _nextInvoiceNumber {
    return _repositoryNextInvoiceNumber;
  }

  List<AppSearchRecord<String>> get _purchaseSearchRecords => [
        for (final invoice in _purchaseInvoices)
          AppSearchRecord(
            value: invoice.id,
            title: 'قائمة شراء رقم ${invoice.id}',
            subtitle: invoice.supplierName,
            details: invoice.searchDetails,
            searchTerms: invoice.searchTerms,
            icon: Icons.shopping_cart_checkout_rounded,
          ),
      ];

  @override
  void initState() {
    super.initState();
    _baseline = _currentSnapshot();
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
    _coordinator = InvoiceEditorCoordinator<_DemoPurchaseInvoice>(
      loadRecords: _loadRepositoryInvoices,
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

  void _navigate(_PurchaseNavigation destination) {
    unawaited(_navigateAfterConfirmation(destination));
  }

  Future<void> _navigateAfterConfirmation(
    _PurchaseNavigation destination,
  ) async {
    if (!await _confirmDiscardChanges() || !mounted) return;

    if (_purchaseInvoices.isEmpty) {
      setState(_setNewForm);
      return;
    }

    final selectedIndex = _selectedInvoiceIndex;
    final target = switch (destination) {
      _PurchaseNavigation.first => _purchaseInvoices.first,
      _PurchaseNavigation.previous => selectedIndex < 0
          ? _purchaseInvoices.last
          : _purchaseInvoices[selectedIndex <= 0 ? 0 : selectedIndex - 1],
      _PurchaseNavigation.next => selectedIndex < 0
          ? _purchaseInvoices.first
          : selectedIndex >= _purchaseInvoices.length - 1
              ? null
              : _purchaseInvoices[selectedIndex + 1],
      _PurchaseNavigation.last =>
        selectedIndex == _purchaseInvoices.length - 1
            ? null
            : _purchaseInvoices.last,
    };

    setState(() {
      if (target == null) {
        _setNewForm();
      } else {
        _loadInvoice(target);
      }
    });
  }

  Future<void> _save() async {
    if (!_validateForm()) return;
    if (_selectedInvoice != null) {
      AppToast.showWarning(
        context,
        'استخدم زر تحديث لتعديل قائمة الشراء المحددة',
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
      failureMessage: 'تعذر حفظ قائمة الشراء',
    );
    if (saved == null || !mounted) return;
    await _loadData(showLoading: false, selectEntityId: saved.id);
    if (!mounted) return;
    AppToast.showInfo(context, 'تم حفظ قائمة الشراء');
  }

  Future<void> _update() async {
    final selected = _selectedInvoice;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر قائمة شراء لتحديثها');
      return;
    }
    if (!_validateForm()) return;

    late final PurchaseInvoice updated;
    try {
      updated = _domainInvoiceFromForm(entityId: selected.source.id);
    } catch (_) {
      AppToast.showError(context, 'تحقق من قيم قائمة الشراء المدخلة');
      return;
    }
    final saved = await _runRepositoryMutation(
      () => _store!.repositories.purchases.replaceInvoice(updated),
      failureMessage: 'تعذر تحديث قائمة الشراء',
    );
    if (saved == null || !mounted) return;
    await _loadData(showLoading: false, selectEntityId: saved.id);
    if (!mounted) return;
    AppToast.showSuccess(context, 'تم تحديث قائمة الشراء');
  }

  void _undo() {
    final selected = _selectedInvoice;
    setState(() {
      if (selected == null) {
        _setNewForm();
      } else {
        final stored = _purchaseInvoices.firstWhere(
          (invoice) => invoice.id == selected.id,
        );
        _loadInvoice(stored);
      }
    });
    AppToast.showWarning(context, 'تم التراجع عن التغييرات');
  }

  Future<void> _delete() async {
    final selected = _selectedInvoice;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر قائمة شراء لحذفها');
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف قائمة الشراء',
      message: 'هل تريد حذف قائمة الشراء رقم ${selected.id}؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted || !confirmed) return;

    final deleted = await _runRepositoryMutation(
      () async {
        await _store!.repositories.purchases
            .deleteInvoicePermanently(selected.source.id);
        return true;
      },
      failureMessage: 'تعذر حذف قائمة الشراء',
    );
    if (deleted == null || !mounted) return;
    await _loadData(showLoading: false);
    if (!mounted) return;
    setState(_setNewForm);
    AppToast.showDanger(context, 'تم حذف قائمة الشراء');
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
    final result = await AppRecordSearchDialog.show<String>(
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
      (candidate) => candidate.id == result,
    );
    if (!await _confirmDiscardChanges() || !mounted) return;
    setState(() => _loadInvoice(invoice));
    AppToast.showInfo(context, 'تم اختيار قائمة الشراء رقم $result');
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
