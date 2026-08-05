import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/application/invoice_editor_coordinator.dart';
import '../../../core/data/app_repository.dart';
import '../../../core/design/app_design_system.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/printing/document_output_service.dart';
import '../../../core/services/service_failure.dart';
import '../../items/domain/item.dart';
import '../../parties/domain/party.dart';
import '../../settings/domain/settings_models.dart';
import '../../warehouses/domain/warehouse.dart';
import '../application/installment_schedule_builder.dart';
import '../domain/sales_invoice.dart';

part 'sales_screen_calculations_part.dart';
part 'sales_screen_data_part.dart';
part 'sales_screen_output_part.dart';
part 'sales_screen_view_part.dart';
part 'sales_screen_widgets_part.dart';

const _salesWarehouseOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الرئيسي', label: 'الرئيسي'),
  AppDropdownOption(value: 'الرصافة', label: 'الرصافة'),
  AppDropdownOption(value: 'الكرادة', label: 'الكرادة'),
  AppDropdownOption(value: 'المنصور', label: 'المنصور'),
];

const _salesTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'نقدي', label: 'نقدي'),
  AppDropdownOption(value: 'آجل', label: 'آجل'),
  AppDropdownOption(value: 'أقساط', label: 'أقساط'),
];

const _salesCurrencyOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'IQD', label: 'دينار'),
  AppDropdownOption(value: 'USD', label: 'دولار'),
];

const _salesCustomerOptions = <String>[
  'شركة النخيل للتجارة',
  'أحمد كريم',
  'أسواق دجلة',
  'مكتب البصرة',
  'علي حسن',
];


class _DemoSalesInvoice {
  const _DemoSalesInvoice({
    required this.source,
    required this.id,
    required this.dateTime,
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
  final String id;
  final DateTime dateTime;
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

  final List<_DemoSalesInvoice> _salesInvoices = [];
  DateTime _invoiceDateTime = DateTime.now();
  _DemoSalesInvoice? _selectedInvoice;
  List<AppSalesInvoiceTableRowData> _activeItems = const [];
  var _warehouse = 'الرئيسي';
  var _saleType = 'نقدي';
  var _currency = 'IQD';
  var _summaryQuantity = '0';
  var _summaryDiscount = '0';
  var _summaryTotal = '0';
  var _tableDataVersion = 0;
  var _discountInputSource = _InvoiceDiscountInputSource.amount;
  num _balanceBeforeInvoice = 0;
  var _nonCashReceivedText = '0';
  late _SalesFormSnapshot _baseline;
  var _isApplyingFormState = false;
  var _hasUnsavedChanges = false;
  var _isDocumentActionRunning = false;
  Future<bool>? _pendingDiscardConfirmation;
  AppStore? _store;
  InvoiceEditorCoordinator<_DemoSalesInvoice>? _coordinator;
  AppDataState<List<_DemoSalesInvoice>> _invoiceState =
      const AppDataState.loading();
  var _didStartLoading = false;
  var _isRepositoryBusy = false;
  var _customerOptions = _salesCustomerOptions;
  var _warehouseOptions = _salesWarehouseOptions;
  var _defaultWarehouse = 'الرئيسي';
  var _defaultSaleType = 'نقدي';
  var _defaultCurrency = 'IQD';
  var _defaultExchangeRate = '1,310';
  var _repositoryNextInvoiceNumber = 1;
  final Map<String, EntityId> _customerIdsByName = {};
  final Map<String, EntityId> _itemIdsByLabel = {};
  final Set<EntityId> _knownItemIds = {};
  final Map<String, EntityId> _warehouseIdsByLabel = {};
  List<AppInvoiceItemOption> _itemOptions = const [];

  Iterable<TextEditingController> get _editableControllers => [
        _exchangeRateController,
        _customerNameController,
        _notesController,
        _driverNameController,
        _invoiceDiscountController,
        _discountPercentageController,
        _receivedController,
      ];

  int get _selectedInvoiceIndex {
    final selectedId = _selectedInvoice?.id;
    if (selectedId == null) return -1;
    return _salesInvoices.indexWhere((invoice) => invoice.id == selectedId);
  }

  int get _nextInvoiceNumber {
    return _repositoryNextInvoiceNumber;
  }

  List<AppSearchRecord<String>> get _salesSearchRecords => [
        for (final invoice in _salesInvoices)
          AppSearchRecord(
            value: invoice.id,
            title: 'قائمة بيع رقم ${invoice.id}',
            subtitle: invoice.customerName,
            details: invoice.searchDetails,
            searchTerms: invoice.searchTerms,
            icon: Icons.point_of_sale_rounded,
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
    _coordinator = InvoiceEditorCoordinator<_DemoSalesInvoice>(
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

  void _navigate(_SalesNavigation destination) {
    unawaited(_navigateAfterConfirmation(destination));
  }

  Future<void> _navigateAfterConfirmation(
    _SalesNavigation destination,
  ) async {
    if (!await _confirmDiscardChanges() || !mounted) return;

    if (_salesInvoices.isEmpty) {
      setState(_setNewForm);
      return;
    }

    final selectedIndex = _selectedInvoiceIndex;
    final target = switch (destination) {
      _SalesNavigation.first => _salesInvoices.first,
      _SalesNavigation.previous => selectedIndex < 0
          ? _salesInvoices.last
          : _salesInvoices[selectedIndex <= 0 ? 0 : selectedIndex - 1],
      _SalesNavigation.next => selectedIndex < 0
          ? _salesInvoices.first
          : selectedIndex >= _salesInvoices.length - 1
              ? null
              : _salesInvoices[selectedIndex + 1],
      _SalesNavigation.last => selectedIndex == _salesInvoices.length - 1
          ? null
          : _salesInvoices.last,
    };

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
    if (_resolveCustomerId(customerName) == null) {
      AppToast.showWarning(context, 'اختر زبوناً موجوداً من القائمة');
      return false;
    }

    final meaningfulItems = _activeItems.where((item) => !item.isEmpty).toList();
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
      (item) => !_warehouseIdsByLabel.containsKey(item.warehouse),
    )) {
      AppToast.showWarning(context, 'اختر مخزناً موجوداً لكل سطر');
      return false;
    }
    return true;
  }

  SalesInvoice _domainInvoiceFromForm({required EntityId entityId}) {
    final items = List<AppSalesInvoiceTableRowData>.unmodifiable(
      _activeItems.where((item) => !item.isEmpty),
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
          warehouseId: _warehouseIdsByLabel[row.warehouse]!,
          quantity: WholeQuantity(row.quantityValue),
          unitPrice: Money.fromMajor(row.salePriceValue, currency),
          discountPerUnit: Money.fromMajor(row.discountValue, currency),
          itemCodeSnapshot: row.code.trim(),
          itemNameSnapshot: row.name.trim(),
          warehouseNameSnapshot: row.warehouse,
        ),
      );
    }
    return SalesInvoice(
      id: entityId,
      documentNumber: int.parse(_invoiceNumberController.text),
      date: BusinessDate.fromDateTime(_invoiceDateTime),
      minuteOfDay: _invoiceDateTime.hour * 60 + _invoiceDateTime.minute,
      customerId: _resolveCustomerId(customerName)!,
      customerNameSnapshot: customerName,
      defaultWarehouseId: _warehouseIdsByLabel[_warehouse]!,
      currency: currency,
      exchangeRate: ExchangeRate.parse(_exchangeRateController.text),
      settlementKind: switch (_saleType) {
        'نقدي' => SalesSettlementKind.cash,
        'أقساط' => SalesSettlementKind.installments,
        _ => SalesSettlementKind.credit,
      },
      lines: lines,
      invoiceDiscount: Money.parse(_invoiceDiscountController.text, currency),
      received: Money.parse(_receivedController.text, currency),
      balanceAfterInvoice:
          Money.parse(_currentBalanceIqdController.text, currency),
      driverName: _driverNameController.text.trim(),
      notes: _notesController.text.trim(),
    );
  }

  EntityId? _resolveCustomerId(String name) {
    final normalized = normalizePartyName(name);
    for (final entry in _customerIdsByName.entries) {
      if (normalizePartyName(entry.key) == normalized) return entry.value;
    }
    return null;
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
    final legacyId = _legacySalesItemId(code, name);
    if (legacyId != null) return legacyId;
    final codeId = _itemIdsByLabel[_normalizedLookup(code)];
    final nameId = _itemIdsByLabel[_normalizedLookup(name)];
    return codeId != null && codeId == nameId ? codeId : null;
  }

  EntityId? _legacySalesItemId(String code, String name) =>
      switch ('${code.trim()}|${_normalizedLookup(name)}') {
        '3001|ورق طباعة' => EntityId('item-003'),
        '3002|حبر طابعة' => EntityId('item-002'),
        '3003|دباسة' => EntityId('item-009'),
        '2001|طابعة حرارية' => EntityId('item-007'),
        '2002|ماسح باركود' => EntityId('item-008'),
        '1001|دفتر ملاحظات' => EntityId('item-010'),
        '1002|قلم أزرق' => EntityId('item-005'),
        '1003|حاسبة مكتبية' => EntityId('item-004'),
        _ => null,
      };

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Future<void> _save() async {
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
    final selected = _selectedInvoice;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر قائمة بيع لتحديثها');
      return;
    }
    if (!_validateForm()) return;

    late final SalesInvoice updated;
    try {
      updated = _domainInvoiceFromForm(entityId: selected.source.id);
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
      AppToast.showWarning(context, 'اختر قائمة بيع لحذفها');
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف قائمة البيع',
      message: 'هل تريد حذف قائمة البيع رقم ${selected.id}؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted || !confirmed) return;

    final deleted = await _runRepositoryMutation(
      () async {
        await _store!.repositories.sales
            .deleteInvoicePermanently(selected.source.id);
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
        final message = '${error.message}';
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
