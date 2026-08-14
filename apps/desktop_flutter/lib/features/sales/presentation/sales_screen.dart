import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/app_state/feature_action_permissions.dart';
import '../../../core/application/invoice_editor_coordinator.dart';
import '../../../core/data/app_repository.dart';
import '../../../core/design/app_design_system.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/printing/document_output_service.dart';
import '../../../core/services/service_failure.dart';
import '../../items/domain/item.dart';
import '../../items/domain/item_repository.dart';
import '../../parties/application/party_statement_service.dart';
import '../../parties/domain/party.dart';
import '../../parties/domain/party_repository.dart';
import '../../permissions/domain/permission_models.dart';
import '../../sales_returns/presentation/sales_return_screen.dart';
import '../../settings/domain/settings_models.dart';
import '../../warehouses/domain/warehouse.dart';
import '../domain/sales_invoice.dart';

part 'sales_screen_calculations_part.dart';
part 'sales_screen_data_part.dart';
part 'sales_screen_output_part.dart';
part 'sales_screen_view_part.dart';
part 'sales_screen_widgets_part.dart';

const _salesTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'نقدي', label: 'نقدي'),
  AppDropdownOption(value: 'آجل', label: 'آجل'),
  AppDropdownOption(value: 'أقساط', label: 'أقساط'),
];

const _salesCurrencyOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'IQD', label: 'دينار'),
  AppDropdownOption(value: 'USD', label: 'دولار'),
];

class _SalesInvoiceViewData {
  const _SalesInvoiceViewData({
    required this.source,
    required this.documentNumber,
    required this.dateTime,
    required this.warehouseId,
    required this.warehouse,
    required this.saleType,
    required this.currency,
    required this.exchangeRate,
    required this.customerName,
    required this.notes,
    required this.driverName,
    required this.invoiceDiscount,
    required this.discountPercentage,
    required this.received,
    required this.total,
    required this.remaining,
    required this.currentBalance,
    required this.searchDetails,
    required this.searchTerms,
    required this.items,
    required this.summaryQuantity,
    required this.summaryDiscount,
    required this.summaryTotal,
  });

  final SalesInvoice source;
  final int documentNumber;

  EntityId get entityId => source.id;

  final DateTime dateTime;
  final EntityId warehouseId;
  final String warehouse;
  final String saleType;
  final String currency;
  final String exchangeRate;
  final String customerName;
  final String notes;
  final String driverName;
  final String invoiceDiscount;
  final String discountPercentage;
  final String received;
  final String total;
  final String remaining;
  final String currentBalance;
  final String searchDetails;
  final List<String> searchTerms;
  final List<AppSalesInvoiceTableRowData> items;
  final String summaryQuantity;
  final String summaryDiscount;
  final String summaryTotal;
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({
    super.key,
    this.printService = const DemoDocumentOutputService(),
    this.exportService = const DemoDocumentOutputService(),
  });

  final DocumentPrintService printService;
  final DocumentExportService exportService;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  void _setSalesState(VoidCallback callback) => setState(callback);

  final _invoiceNumberController = TextEditingController(text: '1');
  final _exchangeRateController = TextEditingController(text: '1,310');
  final _customerNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _invoiceDiscountController = TextEditingController(text: '0');
  final _discountPercentageController = TextEditingController(text: '0');
  final _receivedController = TextEditingController(text: '0');
  final _totalIqdController = TextEditingController(text: '0');
  final _remainingIqdController = TextEditingController(text: '0');
  final _currentBalanceIqdController = TextEditingController(text: '0');

  final List<_SalesInvoiceViewData> _salesInvoices = [];
  DateTime _invoiceDateTime = DateTime.now();
  _SalesInvoiceViewData? _selectedInvoice;
  List<AppSalesInvoiceTableRowData> _activeItems = const [];
  var _warehouseId = '';
  var _saleType = 'نقدي';
  var _currency = 'IQD';
  var _summaryQuantity = '0';
  var _summaryDiscount = '0';
  var _summaryTotal = '0';
  var _tableDataVersion = 0;
  var _discountInputSource = _InvoiceDiscountInputSource.amount;
  num _balanceBeforeInvoice = 0;
  var _nonCashReceivedText = '0';
  late final InvoiceEditorDirtyTracker<_SalesFormSnapshot> _dirtyTracker;
  var _isApplyingFormState = false;
  var _hasUnsavedChanges = false;
  var _isDocumentActionRunning = false;
  Future<bool>? _pendingDiscardConfirmation;
  AppStore? _store;
  late PartyStatementService _statementService;
  final DateTime Function() _installmentPaymentClock = DateTime.now;
  InvoiceEditorCoordinator<_SalesInvoiceViewData>? _coordinator;
  AppDataState<List<_SalesInvoiceViewData>> _invoiceState =
      const AppDataState.loading();
  var _didStartLoading = false;
  var _isRepositoryBusy = false;
  List<Party> _customerOptions = const [];
  EntityId? _selectedCustomerId;
  List<AppDropdownOption<String>> _warehouseOptions = const [];
  var _defaultWarehouseId = '';
  var _defaultWarehouseName = '';
  var _defaultSaleType = 'نقدي';
  var _defaultCurrency = 'IQD';
  var _defaultExchangeRate = '1,310';
  var _repositoryNextInvoiceNumber = 1;
  final Set<EntityId> _knownItemIds = {};
  final Map<String, String> _warehouseNamesById = {};
  List<AppInvoiceItemOption> _itemOptions = const [];

  bool _allowsSalesAction(PermissionAction action) =>
      _store?.allowsFeatureAction('sales', action) ?? true;

  bool _allowsPartyCreate() =>
      _store?.allowsFeatureAction('parties', PermissionAction.create) ?? false;

  bool _allowsItemCreate() =>
      _store?.allowsFeatureAction('items', PermissionAction.create) ?? false;

  bool get _hasSettledInstallments =>
      _selectedInvoice?.source.installmentReceived.isPositive ?? false;

  Future<void> _createCustomer() async {
    final store = _store;
    if (store == null || !_allowsPartyCreate()) return;
    final values = await AppQuickCreateDialog.showParty<PartyType>(
      context: context,
      title: 'إضافة زبون جديد',
      prompt: 'هذا الزبون غير موجود، هل تود إضافته؟',
      icon: Icons.person_add_alt_1_rounded,
      accentColor: AppModuleColors.sales,
      keyPrefix: 'salesQuickCustomer',
      initialName: _customerNameController.text,
      initialType: PartyType.customer,
      typeOptions: const [
        AppDropdownOption(value: PartyType.customer, label: 'زبون'),
      ],
    );
    if (!mounted || values == null) return;
    final repository = store.repositories.parties;
    try {
      final created = await repository.quickCreate(
        PartyQuickCreateRequest(
          name: values.name,
          type: values.type,
          phone: values.phone,
          alternatePhone: values.alternatePhone,
          city: values.city,
          address: values.address,
          notes: values.notes,
        ),
      );
      final refreshed = await repository.getAll();
      if (!mounted) return;
      setState(() {
        _customerOptions = List.unmodifiable(
          refreshed.where(
            (party) =>
                party.type == PartyType.customer ||
                party.type == PartyType.customerAndSupplier,
          ),
        );
        _customerNameController.text = created.name;
        _selectedCustomerId = created.entityId;
      });
      store.markDataChanged();
      AppToast.showSuccess(context, 'تمت إضافة الزبون');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, error.message);
    }
  }

  Future<AppInvoiceItemOption?> _createItem({
    required String code,
    required String name,
  }) async {
    final store = _store;
    if (store == null || !_allowsItemCreate()) return null;
    final repository = store.repositories.items;
    try {
      final groups = await repository.getGroups();
      final types = await repository.getTypes();
      if (!mounted) return null;
      if (groups.isEmpty || types.isEmpty) {
        AppToast.showWarning(context, 'يجب تسجيل مجموعة ونوع للمادة أولاً');
        return null;
      }
      final values = await AppQuickCreateDialog.showItem(
        context: context,
        title: 'إضافة مادة جديدة',
        prompt: 'هذه المادة غير موجودة، هل تود إضافتها؟',
        accentColor: AppModuleColors.sales,
        keyPrefix: 'salesQuickItem',
        initialCode: code,
        initialName: name,
        groups: [
          for (final group in groups)
            AppQuickCreateReferenceOption(
              id: group.id,
              name: group.name,
              number: group.number,
            ),
        ],
        types: [
          for (final type in types)
            AppQuickCreateReferenceOption(
              id: type.id,
              name: type.name,
              number: type.number,
              parentId: type.groupId,
            ),
        ],
      );
      if (!mounted || values == null) return null;
      final created = await repository.quickCreate(
        ItemQuickCreateRequest(
          code: values.code,
          name: values.name,
          groupId: EntityId(values.groupId),
          typeId: EntityId(values.typeId),
        ),
      );
      final refreshed = await repository.getAll();
      if (!mounted) return null;
      final option = AppInvoiceItemOption(
        id: created.id,
        code: created.code,
        name: created.name,
      );
      setState(() {
        _knownItemIds
          ..clear()
          ..addAll(refreshed.map((item) => item.entityId));
        _itemOptions = List.unmodifiable(
          refreshed.map(
            (item) => AppInvoiceItemOption(
              id: item.id,
              code: item.code,
              name: item.name,
            ),
          ),
        );
      });
      store.markDataChanged();
      AppToast.showSuccess(context, 'تمت إضافة المادة');
      return option;
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, error.message);
      return null;
    }
  }

  Iterable<TextEditingController> get _editableControllers => [
        _exchangeRateController,
        _customerNameController,
        _notesController,
        _driverNameController,
        _invoiceDiscountController,
        _discountPercentageController,
        _receivedController,
      ];

  int get _nextInvoiceNumber {
    return _repositoryNextInvoiceNumber;
  }

  List<AppSearchRecord<EntityId>> get _salesSearchRecords => [
        for (final invoice in _salesInvoices)
          AppSearchRecord(
            value: invoice.entityId,
            title: 'قائمة بيع رقم ${invoice.documentNumber}',
            subtitle: invoice.customerName,
            details: invoice.searchDetails,
            searchTerms: invoice.searchTerms,
            icon: Icons.point_of_sale_rounded,
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
    _coordinator = InvoiceEditorCoordinator<_SalesInvoiceViewData>(
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

    if (_salesInvoices.isEmpty) {
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

  bool _validateForm() {
    final customerName = _customerNameController.text.trim();
    if (customerName.isEmpty) {
      AppToast.showWarning(context, 'أدخل اسم الزبون أولاً');
      return false;
    }
    _selectedCustomerId ??= _uniqueCustomerIdForText(customerName);
    if (_selectedCustomerId == null ||
        !_customerOptions.any(
          (party) => party.entityId == _selectedCustomerId,
        )) {
      AppToast.showWarning(context, 'اختر زبوناً موجوداً من القائمة');
      return false;
    }
    if (!_warehouseNamesById.containsKey(_warehouseId)) {
      AppToast.showWarning(context, 'اختر مخزناً موجوداً');
      return false;
    }

    final meaningfulItems = _activeItems
        .where(
          (item) =>
              !item.isEmptyForDefaultWarehouse(_defaultWarehouseId),
        )
        .toList();
    if (meaningfulItems.any((item) => !item.hasRequiredValues)) {
      AppToast.showWarning(
        context,
        'أكمل بيانات سطر المادة: رمز المادة واسم المادة والكمية',
      );
      return false;
    }
    if (meaningfulItems.isEmpty) {
      AppToast.showWarning(context, 'أضف مادة واحدة مكتملة على الأقل');
      return false;
    }
    if (meaningfulItems.any(
      (item) => _resolveItemId(
        item.code,
        item.name,
        itemId: item.itemId,
      ) == null,
    )) {
      AppToast.showWarning(context, 'اختر مادة موجودة لكل سطر');
      return false;
    }
    if (meaningfulItems.any(
      (item) =>
          item.warehouseId == null ||
          !_warehouseNamesById.containsKey(item.warehouseId),
    )) {
      AppToast.showWarning(context, 'اختر مخزناً موجوداً لكل سطر');
      return false;
    }
    return true;
  }

  EntityId? _uniqueCustomerIdForText(String value) {
    final normalized = normalizePartyName(value);
    if (normalized.isEmpty) return null;
    final matches = _customerOptions.where(
      (party) => normalizePartyName(party.name) == normalized,
    );
    if (matches.length != 1) return null;
    return matches.single.entityId;
  }

  SalesInvoice _domainInvoiceFromForm({required EntityId entityId}) {
    final items = List<AppSalesInvoiceTableRowData>.unmodifiable(
      _activeItems.where(
        (item) =>
            !item.isEmptyForDefaultWarehouse(_defaultWarehouseId),
      ),
    );
    final currency = AppCurrency.parse(_currency);
    final customerName = _customerNameController.text.trim();
    final lines = <SalesInvoiceLine>[];
    final newLineNonce = DateTime.now().microsecondsSinceEpoch;
    for (var index = 0; index < items.length; index++) {
      final row = items[index];
      final lineId = row.lineId == null
          ? EntityId('${entityId.value}-line-$newLineNonce-${index + 1}')
          : EntityId(row.lineId!);
      lines.add(
        SalesInvoiceLine(
          id: lineId,
          itemId: _resolveItemId(
            row.code,
            row.name,
            itemId: row.itemId,
          )!,
          warehouseId: EntityId(row.warehouseId!),
          quantity: WholeQuantity(row.quantityValue),
          unitPrice: Money.fromMajor(row.salePriceValue, currency),
          discountPerUnit: Money.fromMajor(row.discountValue, currency),
          itemCodeSnapshot: row.code.trim(),
          itemNameSnapshot: row.name.trim(),
          warehouseNameSnapshot: row.warehouse,
        ),
      );
    }
    final selectedSource = _selectedInvoice?.entityId == entityId
        ? _selectedInvoice!.source
        : null;
    final installmentReceived =
        selectedSource?.installmentReceived ?? Money.zero(currency);
    final aggregateReceived = Money.parse(
      _receivedController.text,
      currency,
    );
    if (selectedSource != null && installmentReceived.isPositive) {
      if (currency != selectedSource.currency ||
          aggregateReceived != selectedSource.received) {
        throw StateError(
          'لا يمكن تغيير المقبوض بعد تسديد قسط من القائمة',
        );
      }
    }
    final receivedAtSale = installmentReceived.isPositive
        ? selectedSource!.receivedAtSale
        : aggregateReceived - installmentReceived;
    return SalesInvoice(
      id: entityId,
      documentNumber: int.parse(_invoiceNumberController.text),
      date: BusinessDate.fromDateTime(_invoiceDateTime),
      minuteOfDay: _invoiceDateTime.hour * 60 + _invoiceDateTime.minute,
      customerId: _selectedCustomerId!,
      customerNameSnapshot: customerName,
      defaultWarehouseId: EntityId(_warehouseId),
      currency: currency,
      exchangeRate: ExchangeRate.parse(_exchangeRateController.text),
      settlementKind: switch (_saleType) {
        'نقدي' => SalesSettlementKind.cash,
        'أقساط' => SalesSettlementKind.installments,
        _ => SalesSettlementKind.credit,
      },
      lines: lines,
      invoiceDiscount: Money.parse(_invoiceDiscountController.text, currency),
      received: aggregateReceived,
      receivedAtSale: receivedAtSale,
      installmentReceived: installmentReceived,
      balanceAfterInvoice:
          Money.parse(_currentBalanceIqdController.text, currency),
      driverName: _driverNameController.text.trim(),
      notes: _notesController.text.trim(),
    );
  }

  EntityId? _resolveItemId(
    String code,
    String name, {
    String? itemId,
  }) {
    if (itemId != null) {
      final resolvedId = EntityId(itemId);
      return _knownItemIds.contains(resolvedId) ? resolvedId : null;
    }
    final normalizedCode = _normalizedLookup(code);
    final normalizedName = _normalizedLookup(name);
    final matches = _itemOptions.where(
      (option) =>
          _normalizedLookup(option.code) == normalizedCode &&
          _normalizedLookup(option.name) == normalizedName,
    );
    if (matches.length != 1) return null;
    return EntityId(matches.single.id);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Future<void> _save() async {
    if (!_allowsSalesAction(PermissionAction.create)) return;
    if (!_validateForm()) return;
    if (_selectedInvoice != null) {
      AppToast.showWarning(
        context,
        'استخدم زر تحديث لتعديل قائمة البيع المحددة',
      );
      return;
    }

    final entityId = EntityId(
      'sales-invoice-${_invoiceNumberController.text}-${DateTime.now().microsecondsSinceEpoch}',
    );
    late final SalesInvoice invoice;
    try {
      invoice = _domainInvoiceFromForm(entityId: entityId);
    } catch (_) {
      AppToast.showError(context, 'تحقق من قيم قائمة البيع المدخلة');
      return;
    }
    final saved = await _runRepositoryMutation(
      () => _store!.repositories.sales.createInvoice(invoice),
      failureMessage: 'تعذر حفظ قائمة البيع',
    );
    if (saved == null || !mounted) return;
    await _loadData(showLoading: false, selectEntityId: saved.id);
    if (!mounted) return;
    AppToast.showInfo(context, 'تم حفظ قائمة البيع');
  }

  Future<void> _update() async {
    if (!_allowsSalesAction(PermissionAction.update)) return;
    final selected = _selectedInvoice;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر قائمة بيع لتحديثها');
      return;
    }
    if (!_validateForm()) return;

    late final SalesInvoice updated;
    try {
      updated = _domainInvoiceFromForm(entityId: selected.entityId);
    } catch (_) {
      AppToast.showError(context, 'تحقق من قيم قائمة البيع المدخلة');
      return;
    }
    final saved = await _runRepositoryMutation(
      () => _store!.repositories.sales.replaceInvoice(updated),
      failureMessage: 'تعذر تحديث قائمة البيع',
    );
    if (saved == null || !mounted) return;
    await _loadData(showLoading: false, selectEntityId: saved.id);
    if (!mounted) return;
    AppToast.showSuccess(context, 'تم تحديث قائمة البيع');
  }

  void _undo() {
    final selected = _selectedInvoice;
    setState(() {
      if (selected == null) {
        _setNewForm();
      } else {
        final stored = _salesInvoices.firstWhere(
          (invoice) => invoice.entityId == selected.entityId,
        );
        _loadInvoice(stored);
      }
    });
    AppToast.showWarning(context, 'تم التراجع عن التغييرات');
  }

  Future<void> _delete() async {
    if (!_allowsSalesAction(PermissionAction.delete)) return;
    final selected = _selectedInvoice;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر قائمة بيع لحذفها');
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف قائمة البيع',
      message: 'هل تريد حذف قائمة البيع رقم ${selected.documentNumber}؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted || !confirmed) return;

    final deleted = await _runRepositoryMutation(
      () async {
        await _store!.repositories.sales
            .deleteInvoicePermanently(selected.entityId);
        return true;
      },
      failureMessage: 'تعذر حذف قائمة البيع',
    );
    if (deleted == null || !mounted) return;
    await _loadData(showLoading: false);
    if (!mounted) return;
    setState(_setNewForm);
    AppToast.showDanger(context, 'تم حذف قائمة البيع');
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

  @override
  void dispose() {
    for (final controller in _editableControllers) {
      controller.removeListener(_refreshUnsavedState);
    }
    _invoiceNumberController.dispose();
    _exchangeRateController.dispose();
    _customerNameController.dispose();
    _notesController.dispose();
    _driverNameController.dispose();
    _invoiceDiscountController.dispose();
    _discountPercentageController.dispose();
    _receivedController.dispose();
    _totalIqdController.dispose();
    _remainingIqdController.dispose();
    _currentBalanceIqdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildSalesScreen(context);
}
