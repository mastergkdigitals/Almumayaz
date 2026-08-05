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

  Future<void> _loadData({
    bool showLoading = true,
    EntityId? selectEntityId,
  }) async {
    final coordinator = _coordinator;
    if (coordinator == null) return;
    if (showLoading && mounted) {
      setState(() => _invoiceState = const AppDataState.loading());
    }
    final selectedEntityId = selectEntityId ?? _selectedInvoice?.source.id;
    final state = await coordinator.load();
    if (!mounted) return;
    setState(() {
      _invoiceState = state;
      final records = state.data;
      if (records == null) {
        if (state.status == AppDataStatus.empty) {
          _salesInvoices.clear();
          _selectedInvoice = null;
        }
        return;
      }
      _salesInvoices
        ..clear()
        ..addAll(records);
      _DemoSalesInvoice? selected;
      if (selectedEntityId != null) {
        for (final candidate in records) {
          if (candidate.source.id == selectedEntityId) {
            selected = candidate;
            break;
          }
        }
      }
      _loadInvoice(selected ?? records.first);
    });
  }

  Future<List<_DemoSalesInvoice>> _loadRepositoryInvoices() async {
    final repositories = _store!.repositories;
    final parties = await repositories.parties.getAll();
    final items = await repositories.items.getAll();
    final warehouses = await repositories.warehouses.getAll();
    final defaults = await repositories.businessSettings.loadOperationalDefaults();
    final policies = await repositories.businessSettings.loadBusinessPolicies();
    _repositoryNextInvoiceNumber =
        await repositories.sales.nextDocumentNumber();
    final loadedInvoices = await repositories.sales.getAll();
    final invoices = [...loadedInvoices]
      ..sort((left, right) => left.documentNumber.compareTo(right.documentNumber));

    final partiesById = {for (final party in parties) EntityId(party.id): party};
    final itemsById = {for (final item in items) EntityId(item.id): item};
    final warehousesById = {
      for (final warehouse in warehouses) EntityId(warehouse.id): warehouse,
    };

    _customerIdsByName
      ..clear()
      ..addEntries(
        parties
            .where(
              (party) =>
                  party.type == PartyType.customer ||
                  party.type == PartyType.customerAndSupplier,
            )
            .map((party) => MapEntry(party.name, EntityId(party.id))),
      );
    _customerOptions = List.unmodifiable(_customerIdsByName.keys);
    _itemIdsByLabel.clear();
    _knownItemIds.clear();
    for (final item in items) {
      final itemId = EntityId(item.id);
      _knownItemIds.add(itemId);
      _itemIdsByLabel[_normalizedLookup(item.code)] = itemId;
      _itemIdsByLabel[_normalizedLookup(item.name)] = itemId;
    }
    _itemOptions = List.unmodifiable(
      items.map(
        (item) => AppInvoiceItemOption(
          id: item.id,
          code: item.code,
          name: item.name,
        ),
      ),
    );
    _warehouseIdsByLabel.clear();
    final orderedWarehouses = [...warehouses]
      ..sort(
        (left, right) => _warehouseOrder(EntityId(left.id))
            .compareTo(_warehouseOrder(EntityId(right.id))),
      );
    for (final warehouse in orderedWarehouses) {
      _warehouseIdsByLabel[_warehouseLabel(EntityId(warehouse.id))] =
          EntityId(warehouse.id);
    }
    _warehouseOptions = List.unmodifiable(
      orderedWarehouses.map((warehouse) {
        final label = _warehouseLabel(EntityId(warehouse.id));
        return AppDropdownOption(value: label, label: label);
      }),
    );

    _defaultWarehouse = _warehouseLabel(defaults.sales.warehouseId);
    _defaultSaleType = _saleKindLabel(defaults.sales.saleKind);
    _defaultCurrency = defaults.sales.currency.code;
    _defaultExchangeRate = _formatExchangeRate(
      policies.defaultExchangeRate,
    );

    final result = <_DemoSalesInvoice>[];
    for (final invoice in invoices) {
      final party = partiesById[invoice.customerId];
      final warehouse = warehousesById[invoice.defaultWarehouseId];
      if (party == null || warehouse == null) {
        throw const InvoiceMissingReferenceException(
          'إحدى قوائم البيع مرتبطة بزبون أو مخزن غير موجود.',
        );
      }
      for (final line in invoice.lines) {
        if (itemsById[line.itemId] == null ||
            warehousesById[line.warehouseId] == null) {
          throw const InvoiceMissingReferenceException(
            'إحدى مواد قوائم البيع مرتبطة بمادة أو مخزن غير موجود.',
          );
        }
      }
      result.add(
        _salesViewFromDomain(
          invoice,
          party: party,
          itemsById: itemsById,
          warehousesById: warehousesById,
        ),
      );
    }
    return result;
  }

  _DemoSalesInvoice _salesViewFromDomain(
    SalesInvoice invoice, {
    required Party party,
    required Map<EntityId, Item> itemsById,
    required Map<EntityId, Warehouse> warehousesById,
  }) {
    final currency = invoice.currency.code;
    final rows = <AppSalesInvoiceTableRowData>[
      for (final line in invoice.lines)
        AppSalesInvoiceTableRowData(
          lineId: line.id.value,
          itemId: line.itemId.value,
          code: line.itemCodeSnapshot.isNotEmpty
              ? line.itemCodeSnapshot
              : itemsById[line.itemId]!.code,
          name: line.itemNameSnapshot.isNotEmpty
              ? line.itemNameSnapshot
              : itemsById[line.itemId]!.name,
          warehouse: line.warehouseNameSnapshot.isNotEmpty
              ? line.warehouseNameSnapshot
              : _warehouseLabel(EntityId(warehousesById[line.warehouseId]!.id)),
          quantity: '${line.quantity.value}',
          salePrice: _formatMoney(line.unitPrice),
          discount: _formatMoney(line.discountPerUnit),
        ).withCalculatedValues(currency),
    ];
    final customerName = invoice.customerNameSnapshot.isNotEmpty
        ? invoice.customerNameSnapshot
        : party.name;
    final remaining = invoice.total - invoice.received;
    final dateTime = invoice.date.atTime(
      hour: invoice.minuteOfDay ~/ 60,
      minute: invoice.minuteOfDay % 60,
    );
    final date =
        '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/${dateTime.year}';
    return _DemoSalesInvoice(
      source: invoice,
      id: '${invoice.documentNumber}',
      dateTime: dateTime,
      warehouse: _warehouseLabel(invoice.defaultWarehouseId),
      saleType: _salesSettlementLabel(invoice.settlementKind),
      currency: currency,
      exchangeRate: _formatExchangeRate(invoice.exchangeRate),
      customerName: customerName,
      notes: invoice.notes,
      driverName: invoice.driverName,
      invoiceDiscount: _formatMoney(invoice.invoiceDiscount),
      discountPercentage: invoice.invoiceDiscountPercentage.toPlainString(),
      received: _formatMoney(invoice.received),
      total: _formatMoney(invoice.total),
      remaining: _formatMoney(remaining),
      currentBalance: _formatMoney(
        invoice.balanceAfterInvoice ?? remaining,
      ),
      searchDetails: invoice.searchDetailsSnapshot.isNotEmpty
          ? invoice.searchDetailsSnapshot
          : '$date • ${rows.length} مواد',
      searchTerms: List.unmodifiable([
        '${invoice.documentNumber}',
        customerName,
        party.name,
        _salesSettlementLabel(invoice.settlementKind),
        currency,
        AppFormatters.currency(currency),
        for (var index = 0; index < rows.length; index++) ...[
          rows[index].code,
          rows[index].name,
          itemsById[invoice.lines[index].itemId]!.code,
          itemsById[invoice.lines[index].itemId]!.name,
        ],
      ]),
      items: List.unmodifiable(rows),
      summaryQuantity: AppFormatters.quantity(
        rows.fold<int>(0, (total, row) => total + row.quantityValue),
      ),
      summaryDiscount: AppFormatters.moneyByCurrency(
        rows.fold<num>(0, (total, row) => total + row.discountValue),
        currency,
      ),
      summaryTotal: AppFormatters.moneyByCurrency(
        rows.fold<num>(0, (total, row) => total + row.totalValue),
        currency,
      ),
    );
  }

  String _normalizedLookup(String value) => value.trim().toLowerCase();

  String _formatMoney(Money value) {
    final scale = value.currency.scale;
    final hasFraction = value.minorUnits.abs() % scale != 0;
    return AppFormatters.money(
      value.majorUnits,
      decimalPlaces: hasFraction ? value.currency.decimalPlaces : 0,
    );
  }

  String _formatExchangeRate(ExchangeRate value) => AppFormatters.money(
        value.value,
        decimalPlaces: value.tenThousandths % 10000 == 0 ? 0 : 4,
      );

  String _warehouseLabel(EntityId id) => switch (id.value) {
        'warehouse-001' => 'الرئيسي',
        'warehouse-002' => 'الكرادة',
        'warehouse-003' => 'الرصافة',
        'warehouse-004' => 'المنصور',
        _ => id.value,
      };

  int _warehouseOrder(EntityId id) => switch (id.value) {
        'warehouse-001' => 0,
        'warehouse-003' => 1,
        'warehouse-002' => 2,
        'warehouse-004' => 3,
        _ => 100,
      };

  String _saleKindLabel(SaleKind kind) => switch (kind) {
        SaleKind.cash => 'نقدي',
        SaleKind.credit => 'آجل',
        SaleKind.installments => 'أقساط',
      };

  String _salesSettlementLabel(SalesSettlementKind kind) => switch (kind) {
        SalesSettlementKind.cash => 'نقدي',
        SalesSettlementKind.credit => 'آجل',
        SalesSettlementKind.installments => 'أقساط',
      };

  void _loadInvoice(_DemoSalesInvoice invoice) {
    _isApplyingFormState = true;
    _selectedInvoice = invoice;
    _invoiceNumberController.text = invoice.id;
    _invoiceDateTime = invoice.dateTime;
    _warehouse = invoice.warehouse;
    _saleType = invoice.saleType;
    _currency = invoice.currency;
    _exchangeRateController.text = invoice.exchangeRate;
    _customerNameController.text = invoice.customerName;
    _notesController.text = invoice.notes;
    _driverNameController.text = invoice.driverName;
    _invoiceDiscountController.text = invoice.invoiceDiscount;
    _discountPercentageController.text = invoice.discountPercentage;
    _discountInputSource = _InvoiceDiscountInputSource.amount;
    _balanceBeforeInvoice =
        (AppFormatters.parseNumber(invoice.currentBalance) ?? 0) -
            (AppFormatters.parseNumber(invoice.remaining) ?? 0);
    _nonCashReceivedText =
        invoice.saleType == 'نقدي' ? '0' : invoice.received;
    _receivedController.text = _nonCashReceivedText;
    _activeItems = List<AppSalesInvoiceTableRowData>.unmodifiable(
      invoice.items.map(
        (item) => item.withCalculatedValues(_currency),
      ),
    );
    _syncCalculatedFields();
    _tableDataVersion++;
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  void _setNewForm() {
    _isApplyingFormState = true;
    _selectedInvoice = null;
    _invoiceNumberController.text = '$_nextInvoiceNumber';
    _invoiceDateTime = DateTime.now();
    _warehouse = _defaultWarehouse;
    _saleType = _defaultSaleType;
    _currency = _defaultCurrency;
    _exchangeRateController.text = _defaultExchangeRate;
    _customerNameController.clear();
    _notesController.clear();
    _driverNameController.clear();
    _invoiceDiscountController.text = '0';
    _discountPercentageController.text = '0';
    _discountInputSource = _InvoiceDiscountInputSource.amount;
    _balanceBeforeInvoice = 0;
    _nonCashReceivedText = '0';
    _receivedController.text = '0';
    _activeItems = List<AppSalesInvoiceTableRowData>.unmodifiable([
      const AppSalesInvoiceTableRowData().withCalculatedValues(_currency),
    ]);
    _syncCalculatedFields();
    _tableDataVersion++;
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  _SalesFormSnapshot _currentSnapshot() => (
        invoiceDateTime: _invoiceDateTime,
        warehouse: _warehouse,
        saleType: _saleType,
        currency: _currency,
        exchangeRate: _exchangeRateController.text,
        customerName: _customerNameController.text,
        notes: _notesController.text,
        driverName: _driverNameController.text,
        invoiceDiscount: _invoiceDiscountController.text,
        discountPercentage: _discountPercentageController.text,
        received: _receivedController.text,
        itemsSignature: _itemsSignature(_activeItems),
      );

  String _itemsSignature(
    Iterable<AppSalesInvoiceTableRowData> items,
  ) {
    return items
        .map(
          (item) => [
            item.code,
            item.name,
            item.warehouse,
            item.quantity,
            item.salePrice,
            item.discount,
            item.priceAfterDiscount,
            item.total,
          ].join('\u001f'),
        )
        .join('\u001e');
  }

  void _refreshUnsavedState() {
    if (_isApplyingFormState || !mounted) return;
    final hasUnsavedChanges = _currentSnapshot() != _baseline;
    if (_hasUnsavedChanges == hasUnsavedChanges) return;
    setState(() => _hasUnsavedChanges = hasUnsavedChanges);
  }

  void _refreshSelectionState() {
    _hasUnsavedChanges = _currentSnapshot() != _baseline;
  }

  void _changeDate(DateTime value) {
    setState(() {
      _invoiceDateTime = DateTime(
        value.year,
        value.month,
        value.day,
        _invoiceDateTime.hour,
        _invoiceDateTime.minute,
      );
      _refreshSelectionState();
    });
  }

  void _changeWarehouse(String value) {
    if (_warehouse == value) return;
    setState(() {
      _warehouse = value;
      _refreshSelectionState();
    });
  }

  void _changeSaleType(String value) {
    if (_saleType == value) return;
    setState(() {
      if (_saleType != 'نقدي' && value == 'نقدي') {
        _nonCashReceivedText = _receivedController.text;
      }
      _saleType = value;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeCurrency(String value) {
    if (_currency == value) return;
    setState(() {
      _currency = value;
      _activeItems = List<AppSalesInvoiceTableRowData>.unmodifiable(
        _activeItems.map(
          (item) => item.withCalculatedValues(_currency),
        ),
      );
      _tableDataVersion++;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeItems(List<AppSalesInvoiceTableRowData> items) {
    setState(() {
      _activeItems = List<AppSalesInvoiceTableRowData>.unmodifiable(
        items.map(
          (item) => item.withCalculatedValues(_currency),
        ),
      );
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeInvoiceDiscount(String _) {
    setState(() {
      _discountInputSource = _InvoiceDiscountInputSource.amount;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeDiscountPercentage(String _) {
    setState(() {
      _discountInputSource = _InvoiceDiscountInputSource.percentage;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeReceived(String value) {
    if (_saleType == 'نقدي') return;
    setState(() {
      _nonCashReceivedText = value;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _syncCalculatedFields() {
    final wasApplyingFormState = _isApplyingFormState;
    _isApplyingFormState = true;
    try {
      var quantity = 0;
      num rowDiscount = 0;
      num subtotal = 0;
      for (final item in _activeItems) {
        quantity += item.quantityValue;
        rowDiscount += item.discountValue;
        subtotal += item.totalValue;
      }

      _summaryQuantity = AppFormatters.quantity(quantity);
      _summaryDiscount = AppFormatters.moneyByCurrency(
        rowDiscount,
        _currency,
      );
      _summaryTotal = AppFormatters.moneyByCurrency(
        subtotal,
        _currency,
      );

      late final num invoiceDiscount;
      if (_discountInputSource ==
          _InvoiceDiscountInputSource.percentage) {
        final percentage =
            AppFormatters.parseNumber(_discountPercentageController.text) ??
                0;
        invoiceDiscount = subtotal * percentage / 100;
        _setControllerText(
          _invoiceDiscountController,
          AppFormatters.moneyByCurrency(invoiceDiscount, _currency),
        );
      } else {
        invoiceDiscount =
            AppFormatters.parseNumber(_invoiceDiscountController.text) ?? 0;
        final percentage =
            subtotal == 0 ? 0 : invoiceDiscount * 100 / subtotal;
        _setControllerText(
          _discountPercentageController,
          AppFormatters.money(percentage, decimalPlaces: 2),
        );
      }

      final discountedTotal = subtotal - invoiceDiscount;
      final total = discountedTotal < 0 ? 0 : discountedTotal;
      late final num received;
      if (_saleType == 'نقدي') {
        received = total;
        _setControllerText(
          _receivedController,
          AppFormatters.moneyByCurrency(received, _currency),
        );
      } else {
        final requestedReceived =
            AppFormatters.parseNumber(_nonCashReceivedText) ?? 0;
        received = requestedReceived < 0
            ? 0
            : requestedReceived > total
                ? total
                : requestedReceived;
        if (received != requestedReceived) {
          _nonCashReceivedText = AppFormatters.moneyByCurrency(
            received,
            _currency,
          );
        }
        _setControllerText(
          _receivedController,
          _nonCashReceivedText,
        );
      }

      final unpaid = total - received;
      final remaining = unpaid < 0 ? 0 : unpaid;
      final currentBalance = _balanceBeforeInvoice + remaining;
      _setControllerText(
        _totalIqdController,
        AppFormatters.moneyByCurrency(total, _currency),
      );
      _setControllerText(
        _remainingIqdController,
        AppFormatters.moneyByCurrency(remaining, _currency),
      );
      _setControllerText(
        _currentBalanceIqdController,
        AppFormatters.moneyByCurrency(currentBalance, _currency),
      );
    } finally {
      _isApplyingFormState = wasApplyingFormState;
    }
  }

  void _setControllerText(
    TextEditingController controller,
    String value,
  ) {
    if (controller.text == value) return;
    controller.text = value;
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

  Future<void> _showSalesSearch() async {
    final result = await AppRecordSearchDialog.show<String>(
      context,
      title: 'بحث قوائم البيع',
      subtitle: 'ابحث عن قائمة بيع محفوظة ثم اخترها',
      searchLabel: 'بحث في قوائم البيع',
      hint: 'رقم القائمة أو اسم الزبون أو اسم المادة',
      accentColor: AppModuleColors.sales,
      records: _salesSearchRecords,
      emptyTitle: 'لا توجد قوائم بيع محفوظة',
      noResultsTitle: 'لا توجد قوائم بيع مطابقة',
      dialogKey: const Key('salesRecordSearchDialog'),
      searchFieldKey: const Key('salesRecordSearchField'),
      resultKeyPrefix: 'salesRecordSearchResult',
    );

    if (!mounted || result == null) return;
    final invoice = _salesInvoices.firstWhere(
      (candidate) => candidate.id == result,
    );
    if (!await _confirmDiscardChanges() || !mounted) return;
    setState(() => _loadInvoice(invoice));
    AppToast.showInfo(context, 'تم اختيار قائمة البيع رقم $result');
  }

  DocumentOutputRequest _salesDocumentRequest() {
    final customerName = _customerNameController.text.trim();
    final currencyName = AppFormatters.currency(_currency);
    return DocumentOutputRequest(
      title: 'قائمة بيع رقم ${_invoiceNumberController.text}',
      subtitle: customerName.isEmpty ? 'زبون غير محدد' : customerName,
      fileNameBase: 'قائمة بيع ${_invoiceNumberController.text}',
      fields: [
        DocumentField(
          label: 'التاريخ',
          value: AppFormatters.date(_invoiceDateTime),
        ),
        DocumentField(
          label: 'الوقت',
          value: AppFormatters.time(TimeOfDay.fromDateTime(_invoiceDateTime)),
        ),
        DocumentField(label: 'المخزن', value: _warehouse),
        DocumentField(label: 'نوع البيع', value: _saleType),
        DocumentField(label: 'العملة', value: currencyName),
        DocumentField(
          label: 'خصم القائمة',
          value: _invoiceDiscountController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المقبوض',
          value: _receivedController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المجموع',
          value: _totalIqdController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المتبقي',
          value: _remainingIqdController.text,
          isPrice: true,
        ),
      ],
      columns: const [
        DocumentColumn(label: 'الرمز'),
        DocumentColumn(label: 'المادة'),
        DocumentColumn(label: 'المخزن'),
        DocumentColumn(label: 'الكمية'),
        DocumentColumn(label: 'سعر البيع', isPrice: true),
        DocumentColumn(label: 'الخصم', isPrice: true),
        DocumentColumn(label: 'السعر بعد الخصم', isPrice: true),
        DocumentColumn(label: 'المجموع', isPrice: true),
      ],
      rows: [
        for (final item in _activeItems.where((item) => !item.isEmpty))
          [
            item.code,
            item.name,
            item.warehouse,
            item.quantity,
            item.salePrice,
            item.discount.isEmpty ? '0' : item.discount,
            item.priceAfterDiscount,
            item.total,
          ],
      ],
    );
  }

  void _printSalesInvoice() {
    unawaited(_runSalesPrint());
  }

  Future<void> _runSalesPrint() async {
    if (_isDocumentActionRunning) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isDocumentActionRunning = true);
    try {
      final result = await widget.printService.createPreview(
        _salesDocumentRequest(),
      );
      if (!mounted) return;
      await AppDocumentOutputDialog.show(
        context,
        result: result,
        accentColor: AppModuleColors.sales,
      );
    } on ServiceFailure catch (failure) {
      if (mounted) AppToast.showError(context, failure.message);
    } catch (_) {
      if (mounted) {
        AppToast.showError(context, 'تعذر تجهيز قائمة البيع للطباعة');
      }
    } finally {
      if (mounted) setState(() => _isDocumentActionRunning = false);
    }
  }

  DateTime? _firstSalesTransactionDate(String customerName) {
    DateTime? firstDate;
    for (final invoice in _salesInvoices) {
      if (invoice.customerName != customerName) continue;
      if (firstDate == null || invoice.dateTime.isBefore(firstDate)) {
        firstDate = invoice.dateTime;
      }
    }
    return firstDate;
  }

  List<AppStatementReportEntry> _salesStatementEntries(
    String customerName,
    AppStatementOptions options,
  ) {
    final fromDate = DateTime(
      options.fromDate.year,
      options.fromDate.month,
      options.fromDate.day,
    );
    final toDateExclusive = DateTime(
      options.toDate.year,
      options.toDate.month,
      options.toDate.day + 1,
    );
    final invoices = _salesInvoices.where((invoice) {
      return invoice.customerName == customerName &&
          invoice.currency == options.currencyCode &&
          !invoice.dateTime.isBefore(fromDate) &&
          invoice.dateTime.isBefore(toDateExclusive);
    }).toList()
      ..sort((left, right) => left.dateTime.compareTo(right.dateTime));

    return [
      for (final invoice in invoices)
        AppStatementReportEntry(
          date: invoice.dateTime,
          balance: AppFormatters.parseNumber(invoice.currentBalance) ?? 0,
          credit: AppFormatters.parseNumber(invoice.received) ?? 0,
          debit: AppFormatters.parseNumber(invoice.total) ?? 0,
          type: 'قائمة بيع',
          quantity: invoice.items.fold<int>(
            0,
            (total, item) => total + item.quantityValue,
          ),
          details: 'قائمة بيع رقم ${invoice.id} • ${invoice.saleType}',
        ),
    ];
  }

  void _openInstallments() {
    unawaited(_showInstallments());
  }

  Future<void> _showInstallments() async {
    if (_saleType != 'أقساط') {
      AppToast.showWarning(context, 'جدول الأقساط متاح للبيع بالأقساط فقط');
      return;
    }
    final remaining =
        AppFormatters.parseNumber(_remainingIqdController.text) ?? 0;
    if (remaining <= 0) {
      AppToast.showInfo(context, 'لا يوجد مبلغ متبقٍ لإنشاء جدول أقساط');
      return;
    }

    final schedule = InstallmentScheduleBuilder.build(
      remaining: remaining,
      currencyCode: _currency,
      invoiceDate: _invoiceDateTime,
    );
    final entries = <AppInstallmentScheduleEntry>[
      for (final installment in schedule)
        AppInstallmentScheduleEntry(
          number: installment.number,
          dueDate: installment.dueDate,
          amount: installment.amount,
          status: 'غير مسدد',
        ),
    ];
    final customerName = _customerNameController.text.trim();
    await AppInstallmentScheduleDialog.show(
      context,
      invoiceNumber: _invoiceNumberController.text,
      customerName:
          customerName.isEmpty ? 'زبون غير محدد' : customerName,
      currencyCode: _currency,
      entries: entries,
      accentColor: AppModuleColors.sales,
    );
  }

  Future<void> _showSalesStatement() async {
    final customerName = _customerNameController.text.trim();
    final displayName =
        customerName.isEmpty ? 'زبون غير محدد' : customerName;
    final options = await AppStatementOptionsDialog.show(
      context,
      partyName: displayName,
      partyLabel: 'اسم الزبون',
      accentColor: AppModuleColors.sales,
      firstTransactionDate: _firstSalesTransactionDate(displayName),
    );
    if (!mounted || options == null) return;

    await AppStatementReportDialog.show(
      context,
      partyName: displayName,
      options: options,
      entries: _salesStatementEntries(displayName, options),
      accentColor: AppModuleColors.sales,
      printService: widget.printService,
      exportService: widget.exportService,
    );
  }

  void _openEmptyEditor() {
    setState(() {
      _invoiceState = AppDataState.ready(_salesInvoices);
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
  Widget build(BuildContext context) {
    final hasSelectedInvoice = _selectedInvoice != null;
    final selectedInvoiceIndex = _selectedInvoiceIndex;
    final hasInvoices = _salesInvoices.isNotEmpty;
    final canMoveToFirstOrPrevious =
        hasInvoices && selectedInvoiceIndex != 0;
    final canMoveToNextOrLast =
        hasInvoices && selectedInvoiceIndex >= 0;
    final currencyName = _currency == 'USD' ? 'دولار' : 'دينار';
    final isEditorReady = _invoiceState.status == AppDataStatus.ready;
    final tint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );

    return PopScope(
      canPop: !_hasUnsavedChanges && !_isRepositoryBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isRepositoryBusy) _attemptBack();
      },
      child: AppScreenShell(
        key: const Key('salesScreen'),
        title: 'المبيعات',
        backgroundColor: tint,
        onBack: _attemptBack,
        onSearch: !isEditorReady || _isRepositoryBusy
            ? null
            : _showSalesSearch,
        onSave: !isEditorReady || _isRepositoryBusy
            ? null
            : hasSelectedInvoice
            ? _hasUnsavedChanges
                ? _update
                : null
            : _save,
        body: Stack(
          fit: StackFit.expand,
          children: [
        ColoredBox(
          key: const Key('salesTintBackground'),
          color: tint,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
              _SalesFieldRow(
                children: [
                  AppReadOnlyField(
                    fieldKey: const Key('salesInvoiceNumberField'),
                    controller: _invoiceNumberController,
                    label: 'رقم القائمة',
                    icon: Icons.receipt_long_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppDateField(
                    fieldKey: const Key('salesDateField'),
                    label: 'التاريخ',
                    value: _invoiceDateTime,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    onChanged: _changeDate,
                  ),
                  AppTimeField(
                    fieldKey: const Key('salesTimeField'),
                    label: 'الوقت',
                    value: TimeOfDay.fromDateTime(_invoiceDateTime),
                    accentColor: AppModuleColors.sales,
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('salesWarehouseField'),
                    label: 'المخزن',
                    icon: Icons.warehouse_rounded,
                    accentColor: AppModuleColors.sales,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _warehouse,
                    options: _warehouseOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changeWarehouse(value);
                    },
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('salesTypeField'),
                    label: 'نوع البيع',
                    icon: Icons.point_of_sale_rounded,
                    accentColor: AppModuleColors.sales,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _saleType,
                    options: _salesTypeOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changeSaleType(value);
                    },
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('salesCurrencyField'),
                    label: 'العملة',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: AppModuleColors.sales,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _currency,
                    options: _salesCurrencyOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changeCurrency(value);
                    },
                  ),
                  AppMoneyField(
                    fieldKey: const Key('salesExchangeRateField'),
                    controller: _exchangeRateController,
                    label: 'سعر الصرف',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decimalPlaces: 4,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SalesFieldRow(
                children: [
                  AppAutocompleteField<String>(
                    fieldKey: const Key('salesCustomerNameField'),
                    controller: _customerNameController,
                    label: 'اسم الزبون',
                    icon: Icons.person_rounded,
                    accentColor: AppModuleColors.sales,
                    options: _customerOptions,
                    displayStringForOption: (value) => value,
                    onSelected: (_) {},
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppTextField(
                    fieldKey: const Key('salesNotesField'),
                    controller: _notesController,
                    label: 'الملاحظات',
                    icon: Icons.notes_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: AppSalesInvoiceTableTemplate(
                  key: const Key('salesItemsTable'),
                  initialRows: _activeItems,
                  dataVersion: _tableDataVersion,
                  summaryQuantity: _summaryQuantity,
                  summaryDiscount: _summaryDiscount,
                  summaryTotal: _summaryTotal,
                  currencyCode: _currency,
                  itemOptions: _itemOptions,
                  onRowsChanged: _changeItems,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SalesFieldRow(
                children: [
                  AppTextField(
                    fieldKey: const Key('salesDriverNameField'),
                    controller: _driverNameController,
                    label: 'اسم السائق',
                    icon: Icons.local_shipping_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.next,
                  ),
                  _SalesMoneyField(
                    fieldKey: const Key('salesInvoiceDiscountField'),
                    controller: _invoiceDiscountController,
                    label: 'خصم القائمة',
                    icon: Icons.discount_rounded,
                    decimalPlaces: _currency == 'USD' ? 2 : 0,
                    onChanged: _changeInvoiceDiscount,
                  ),
                  _SalesMoneyField(
                    fieldKey: const Key('salesDiscountPercentageField'),
                    controller: _discountPercentageController,
                    label: 'نسبة الخصم',
                    icon: Icons.percent_rounded,
                    decimalPlaces: 2,
                    onChanged: _changeDiscountPercentage,
                  ),
                  _SalesMoneyField(
                    fieldKey: const Key('salesReceivedField'),
                    controller: _receivedController,
                    label: 'المقبوض',
                    icon: Icons.payments_rounded,
                    decimalPlaces: _currency == 'USD' ? 2 : 0,
                    enabled: _saleType != 'نقدي',
                    onChanged: _changeReceived,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('salesTotalIqdField'),
                    controller: _totalIqdController,
                    label: 'المجموع $currencyName',
                    icon: Icons.calculate_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('salesRemainingIqdField'),
                    controller: _remainingIqdController,
                    label: 'المتبقي $currencyName',
                    icon: Icons.pending_actions_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('salesCurrentBalanceIqdField'),
                    controller: _currentBalanceIqdController,
                    label: 'الرصيد الحالي $currencyName',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppActionBar(
                key: const Key('salesActionBar'),
                middle: _SalesInvoiceButtons(
                  onSearch: !isEditorReady || _isRepositoryBusy
                      ? null
                      : _showSalesSearch,
                  onPrint: !isEditorReady || _isDocumentActionRunning
                      ? null
                      : _printSalesInvoice,
                  onInstallments:
                      isEditorReady && _saleType == 'أقساط'
                          ? _openInstallments
                          : null,
                  onStatement:
                      isEditorReady ? _showSalesStatement : null,
                ),
                firstButtonKey: const Key('salesFirstButton'),
                previousButtonKey: const Key('salesPreviousButton'),
                nextButtonKey: const Key('salesNextButton'),
                lastButtonKey: const Key('salesLastButton'),
                saveButtonKey: const Key('salesSaveButton'),
                updateButtonKey: const Key('salesUpdateButton'),
                undoButtonKey: const Key('salesUndoButton'),
                deleteButtonKey: const Key('salesDeleteButton'),
                accentColor: AppModuleColors.sales,
                onFirst: canMoveToFirstOrPrevious
                    ? () => _navigate(_SalesNavigation.first)
                    : null,
                onPrevious: canMoveToFirstOrPrevious
                    ? () => _navigate(_SalesNavigation.previous)
                    : null,
                onNext: canMoveToNextOrLast
                    ? () => _navigate(_SalesNavigation.next)
                    : null,
                onLast: canMoveToNextOrLast
                    ? () => _navigate(_SalesNavigation.last)
                    : null,
                onSave: !isEditorReady ||
                        _isRepositoryBusy ||
                        hasSelectedInvoice
                    ? null
                    : _save,
                onUpdate: isEditorReady &&
                        hasSelectedInvoice &&
                        _hasUnsavedChanges &&
                        !_isRepositoryBusy
                    ? _update
                    : null,
                onUndo:
                    isEditorReady && _hasUnsavedChanges ? _undo : null,
                onDelete: isEditorReady &&
                        hasSelectedInvoice &&
                        !_isRepositoryBusy
                    ? _delete
                    : null,
              ),
              ],
            ),
          ),
        ),
            if (_invoiceState.status != AppDataStatus.ready)
              ColoredBox(
                color: tint,
                child: AppDataStateView<List<_DemoSalesInvoice>>(
                  state: _invoiceState,
                  dataBuilder: (_, __) => const SizedBox.shrink(),
                  emptyTitle: 'لا توجد قوائم بيع',
                  emptyActionLabel: 'قائمة بيع جديدة',
                  onEmptyAction: _openEmptyEditor,
                  missingReferenceActionLabel: 'إعادة المحاولة',
                  onMissingReferenceAction: () => unawaited(_loadData()),
                  onRetry: () => unawaited(_loadData()),
                  loadingStateKey: const Key('salesLoadingState'),
                  emptyStateKey: const Key('salesEmptyState'),
                  missingReferenceStateKey:
                      const Key('salesMissingReferenceState'),
                  errorStateKey: const Key('salesErrorState'),
                ),
              ),
            if (_isRepositoryBusy)
              AbsorbPointer(
                child: ColoredBox(
                  key: const Key('salesBusyOverlay'),
                  color: AppColors.textPrimary.withAlpha(20),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SalesInvoiceButtons extends StatelessWidget {
  const _SalesInvoiceButtons({
    required this.onSearch,
    required this.onPrint,
    required this.onInstallments,
    required this.onStatement,
  });

  final VoidCallback? onSearch;
  final VoidCallback? onPrint;
  final VoidCallback? onInstallments;
  final VoidCallback? onStatement;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        AppHeaderIconButton(
          key: const Key('salesSearchButton'),
          tooltipKey: const Key('salesSearchTooltip'),
          icon: Icons.search_rounded,
          tooltip: 'بحث',
          onPressed: onSearch,
        ),
        AppHeaderIconButton(
          key: const Key('salesPrintButton'),
          tooltipKey: const Key('salesPrintTooltip'),
          icon: Icons.print_rounded,
          tooltip: 'طباعة',
          onPressed: onPrint,
        ),
        AppHeaderIconButton(
          key: const Key('salesInstallmentsButton'),
          tooltipKey: const Key('salesInstallmentsTooltip'),
          icon: Icons.table_chart_rounded,
          tooltip: 'جدول الأقساط',
          onPressed: onInstallments,
        ),
        AppHeaderIconButton(
          key: const Key('salesStatementButton'),
          tooltipKey: const Key('salesStatementTooltip'),
          icon: Icons.receipt_long_rounded,
          tooltip: 'كشف الحساب',
          onPressed: onStatement,
        ),
      ],
    );
  }
}

class _SalesFieldRow extends StatelessWidget {
  const _SalesFieldRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.md),
            Expanded(child: children[index]),
          ],
        ],
      ),
    );
  }
}

class _SalesMoneyField extends StatelessWidget {
  const _SalesMoneyField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    this.decimalPlaces = 4,
    this.enabled = true,
    this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int decimalPlaces;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return AppMoneyField(
      fieldKey: fieldKey,
      controller: controller,
      label: label,
      icon: icon,
      accentColor: AppModuleColors.sales,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      decimalPlaces: decimalPlaces,
      enabled: enabled,
      readOnly: !enabled,
      onChanged: onChanged,
      textInputAction: TextInputAction.next,
    );
  }
}

enum _SalesNavigation { first, previous, next, last }

enum _InvoiceDiscountInputSource { amount, percentage }

typedef _SalesFormSnapshot = ({
  DateTime invoiceDateTime,
  String warehouse,
  String saleType,
  String currency,
  String exchangeRate,
  String customerName,
  String notes,
  String driverName,
  String invoiceDiscount,
  String discountPercentage,
  String received,
  String itemsSignature,
});
