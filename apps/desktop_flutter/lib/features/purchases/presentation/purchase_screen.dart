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
import '../domain/purchase_invoice.dart';

const _purchaseWarehouseOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الرئيسي', label: 'الرئيسي'),
  AppDropdownOption(value: 'الرصافة', label: 'الرصافة'),
  AppDropdownOption(value: 'الكرادة', label: 'الكرادة'),
  AppDropdownOption(value: 'المنصور', label: 'المنصور'),
];

const _purchaseTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'محلي', label: 'محلي'),
  AppDropdownOption(value: 'إستيراد', label: 'إستيراد'),
  AppDropdownOption(value: 'إرجاع', label: 'إرجاع'),
];

const _purchasePaymentTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'نقدي', label: 'نقدي'),
  AppDropdownOption(value: 'آجل', label: 'آجل'),
];

const _purchaseCurrencyOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'IQD', label: 'دينار'),
  AppDropdownOption(value: 'USD', label: 'دولار'),
];

const _purchaseSupplierOptions = <String>[
  'شركة الرافدين للتجهيز',
  'شركة التجارة العالمية',
  'مجهز الكرادة',
  'مجهز الفرات',
  'شركة الموصل الحديثة',
];


class _DemoPurchaseInvoice {
  const _DemoPurchaseInvoice({
    required this.source,
    required this.id,
    required this.dateTime,
    required this.warehouse,
    required this.purchaseType,
    required this.paymentType,
    required this.currency,
    required this.exchangeRate,
    required this.supplierName,
    required this.notes,
    required this.expenses,
    required this.invoiceDiscount,
    required this.discountPercentage,
    required this.paid,
    required this.remaining,
    required this.currentBalance,
    required this.searchDetails,
    required this.searchTerms,
    required this.items,
  });

  final PurchaseInvoice source;
  final String id;
  final DateTime dateTime;
  final String warehouse;
  final String purchaseType;
  final String paymentType;
  final String currency;
  final String exchangeRate;
  final String supplierName;
  final String notes;
  final String expenses;
  final String invoiceDiscount;
  final String discountPercentage;
  final String paid;
  final String remaining;
  final String currentBalance;
  final String searchDetails;
  final List<String> searchTerms;
  final List<AppPurchaseInvoiceTableRowData> items;
}

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
          _purchaseInvoices.clear();
          _selectedInvoice = null;
        }
        return;
      }
      _purchaseInvoices
        ..clear()
        ..addAll(records);
      _DemoPurchaseInvoice? selected;
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

  Future<List<_DemoPurchaseInvoice>> _loadRepositoryInvoices() async {
    final repositories = _store!.repositories;
    final parties = await repositories.parties.getAll();
    final items = await repositories.items.getAll();
    final warehouses = await repositories.warehouses.getAll();
    final defaults = await repositories.businessSettings.loadOperationalDefaults();
    final policies = await repositories.businessSettings.loadBusinessPolicies();
    _repositoryNextInvoiceNumber =
        await repositories.purchases.nextDocumentNumber();
    final loadedInvoices = await repositories.purchases.getAll();
    final invoices = [...loadedInvoices]
      ..sort((left, right) => left.documentNumber.compareTo(right.documentNumber));

    final partiesById = {for (final party in parties) EntityId(party.id): party};
    final itemsById = {for (final item in items) EntityId(item.id): item};
    final warehousesById = {
      for (final warehouse in warehouses) EntityId(warehouse.id): warehouse,
    };

    _supplierIdsByName.clear();
    for (final party in parties.where(
      (party) =>
          party.type == PartyType.supplier ||
          party.type == PartyType.customerAndSupplier,
    )) {
      _supplierIdsByName[party.name] = EntityId(party.id);
    }
    _supplierOptions = List.unmodifiable(_supplierIdsByName.keys);
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

    _defaultWarehouse = _warehouseLabel(defaults.purchases.warehouseId);
    _defaultPurchaseType = _purchaseKindLabel(defaults.purchases.purchaseKind);
    _defaultPaymentType =
        defaults.purchases.paymentKind == PaymentKind.cash ? 'نقدي' : 'آجل';
    _defaultCurrency = defaults.purchases.currency.code;
    _defaultExchangeRate = _formatExchangeRate(
      policies.defaultExchangeRate,
    );

    final result = <_DemoPurchaseInvoice>[];
    for (final invoice in invoices) {
      final party = partiesById[invoice.supplierId];
      final warehouse = warehousesById[invoice.defaultWarehouseId];
      if (party == null || warehouse == null) {
        throw const InvoiceMissingReferenceException(
          'إحدى قوائم الشراء مرتبطة بمجهز أو مخزن غير موجود.',
        );
      }
      for (final line in invoice.lines) {
        if (itemsById[line.itemId] == null ||
            warehousesById[line.warehouseId] == null) {
          throw const InvoiceMissingReferenceException(
            'إحدى مواد قوائم الشراء مرتبطة بمادة أو مخزن غير موجود.',
          );
        }
      }
      result.add(
        _purchaseViewFromDomain(
          invoice,
          party: party,
          itemsById: itemsById,
          warehousesById: warehousesById,
        ),
      );
    }
    return result;
  }

  _DemoPurchaseInvoice _purchaseViewFromDomain(
    PurchaseInvoice invoice, {
    required Party party,
    required Map<EntityId, Item> itemsById,
    required Map<EntityId, Warehouse> warehousesById,
  }) {
    final currency = invoice.currency.code;
    final rows = <AppPurchaseInvoiceTableRowData>[
      for (final line in invoice.lines)
        AppPurchaseInvoiceTableRowData(
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
          container: '${line.containerQuantity.value}',
          purchasePrice: _formatMoney(line.purchasePrice),
          discount: _formatMoney(line.lineDiscount),
          salePrice: _formatMoney(line.salePrice),
        ),
    ];
    final supplierName = invoice.supplierNameSnapshot.isNotEmpty
        ? invoice.supplierNameSnapshot
        : party.name;
    final remaining = invoice.total - invoice.paid;
    final dateTime = invoice.date.atTime(
      hour: invoice.minuteOfDay ~/ 60,
      minute: invoice.minuteOfDay % 60,
    );
    final date =
        '${_twoDigits(dateTime.day)}/${_twoDigits(dateTime.month)}/${dateTime.year}';
    return _DemoPurchaseInvoice(
      source: invoice,
      id: '${invoice.documentNumber}',
      dateTime: dateTime,
      warehouse: _warehouseLabel(invoice.defaultWarehouseId),
      purchaseType: _purchaseTransactionLabel(invoice.purchaseKind),
      paymentType: invoice.settlementKind == PurchaseSettlementKind.cash
          ? 'نقدي'
          : 'آجل',
      currency: currency,
      exchangeRate: _formatExchangeRate(invoice.exchangeRate),
      supplierName: supplierName,
      notes: invoice.notes,
      expenses: _formatMoney(invoice.expenses),
      invoiceDiscount: _formatMoney(invoice.invoiceDiscount),
      discountPercentage: AppFormatters.money(
        invoice.invoiceDiscountPercentageValue,
        decimalPlaces: 2,
      ),
      paid: _formatMoney(invoice.paid),
      remaining: _formatMoney(remaining),
      currentBalance: _formatMoney(
        invoice.balanceAfterInvoice ?? remaining,
      ),
      searchDetails: invoice.searchDetailsSnapshot.isNotEmpty
          ? invoice.searchDetailsSnapshot
          : '$date • ${rows.length} مواد',
      searchTerms: List.unmodifiable([
        '${invoice.documentNumber}',
        supplierName,
        party.name,
        _purchaseTransactionLabel(invoice.purchaseKind),
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

  String _purchaseKindLabel(PurchaseKind kind) => switch (kind) {
        PurchaseKind.local => 'محلي',
        PurchaseKind.imported => 'إستيراد',
        PurchaseKind.returnPurchase => 'إرجاع',
      };

  String _purchaseTransactionLabel(PurchaseTransactionKind kind) =>
      switch (kind) {
        PurchaseTransactionKind.local => 'محلي',
        PurchaseTransactionKind.import => 'إستيراد',
        PurchaseTransactionKind.returnPurchase => 'إرجاع',
      };

  void _loadInvoice(_DemoPurchaseInvoice invoice) {
    _isApplyingFormState = true;
    _selectedInvoice = invoice;
    _invoiceNumberController.text = invoice.id;
    _invoiceDateTime = invoice.dateTime;
    _warehouse = invoice.warehouse;
    _purchaseType = invoice.purchaseType;
    _paymentType = invoice.paymentType;
    _currency = invoice.currency;
    _exchangeRateController.text = invoice.exchangeRate;
    _supplierNameController.text = invoice.supplierName;
    _notesController.text = invoice.notes;
    _expensesController.text = invoice.expenses;
    _invoiceDiscountController.text = invoice.invoiceDiscount;
    _discountPercentageController.text = invoice.discountPercentage;
    _discountInputSource = _PurchaseDiscountInputSource.amount;
    _balanceBeforeInvoice =
        (AppFormatters.parseNumber(invoice.currentBalance) ?? 0) -
            (AppFormatters.parseNumber(invoice.remaining) ?? 0);
    _nonCashPaidText =
        invoice.paymentType == 'نقدي' ? '0' : invoice.paid;
    _paidController.text = _nonCashPaidText;
    _activeItems = List<AppPurchaseInvoiceTableRowData>.unmodifiable(
      invoice.items,
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
    _purchaseType = _defaultPurchaseType;
    _paymentType = _defaultPaymentType;
    _currency = _defaultCurrency;
    _exchangeRateController.text = _defaultExchangeRate;
    _supplierNameController.clear();
    _notesController.clear();
    _expensesController.text = '0';
    _invoiceDiscountController.text = '0';
    _discountPercentageController.text = '0';
    _discountInputSource = _PurchaseDiscountInputSource.amount;
    _balanceBeforeInvoice = 0;
    _nonCashPaidText = '0';
    _paidController.text = '0';
    _activeItems = const [AppPurchaseInvoiceTableRowData()];
    _syncCalculatedFields();
    _tableDataVersion++;
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  _PurchaseFormSnapshot _currentSnapshot() => (
        invoiceDateTime: _invoiceDateTime,
        warehouse: _warehouse,
        purchaseType: _purchaseType,
        paymentType: _paymentType,
        currency: _currency,
        exchangeRate: _exchangeRateController.text,
        supplierName: _supplierNameController.text,
        notes: _notesController.text,
        expenses: _expensesController.text,
        invoiceDiscount: _invoiceDiscountController.text,
        discountPercentage: _discountPercentageController.text,
        paid: _paidController.text,
        itemsSignature: _itemsSignature(_activeItems),
      );

  String _itemsSignature(
    Iterable<AppPurchaseInvoiceTableRowData> items,
  ) {
    return items
        .map(
          (item) => [
            item.code,
            item.name,
            item.warehouse,
            item.quantity,
            item.container,
            item.purchasePrice,
            item.discount,
            item.priceAfterDiscount,
            item.total,
            item.cost,
            item.totalCost,
            item.salePrice,
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

  void _changePurchaseType(String value) {
    if (_purchaseType == value) return;
    setState(() {
      _purchaseType = value;
      _refreshSelectionState();
    });
  }

  void _changePaymentType(String value) {
    if (_paymentType == value) return;
    setState(() {
      if (_paymentType != 'نقدي' && value == 'نقدي') {
        _nonCashPaidText = _paidController.text;
      }
      _paymentType = value;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeCurrency(String value) {
    if (_currency == value) return;
    setState(() {
      _currency = value;
      _tableDataVersion++;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeItems(List<AppPurchaseInvoiceTableRowData> items) {
    setState(() {
      _activeItems = List<AppPurchaseInvoiceTableRowData>.unmodifiable(items);
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeExpenses(String _) {
    setState(() {
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeInvoiceDiscount(String _) {
    setState(() {
      _discountInputSource = _PurchaseDiscountInputSource.amount;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changeDiscountPercentage(String _) {
    setState(() {
      _discountInputSource = _PurchaseDiscountInputSource.percentage;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _changePaid(String value) {
    if (_paymentType == 'نقدي') return;
    setState(() {
      _nonCashPaidText = value;
      _syncCalculatedFields();
      _refreshSelectionState();
    });
  }

  void _syncCalculatedFields() {
    final wasApplyingFormState = _isApplyingFormState;
    _isApplyingFormState = true;
    try {
      var quantity = 0;
      num grossTotal = 0;
      num rowDiscount = 0;
      num lineBaseTotal = 0;
      for (final item in _activeItems) {
        quantity += item.quantityValue;
        grossTotal += item.grossTotalValue;
        rowDiscount += item.discountValue;
        lineBaseTotal += item.totalValue;
      }

      final expenses =
          AppFormatters.parseNumber(_expensesController.text) ?? 0;
      final discountBase = lineBaseTotal + expenses;
      late final num invoiceDiscount;
      if (_discountInputSource ==
          _PurchaseDiscountInputSource.percentage) {
        final percentage =
            AppFormatters.parseNumber(_discountPercentageController.text) ??
                0;
        invoiceDiscount = discountBase * percentage / 100;
        _setControllerText(
          _invoiceDiscountController,
          AppFormatters.moneyByCurrency(invoiceDiscount, _currency),
        );
      } else {
        invoiceDiscount =
            AppFormatters.parseNumber(_invoiceDiscountController.text) ?? 0;
        final percentage =
            discountBase == 0 ? 0 : invoiceDiscount * 100 / discountBase;
        _setControllerText(
          _discountPercentageController,
          AppFormatters.money(percentage, decimalPlaces: 2),
        );
      }

      _lineBaseTotal = lineBaseTotal;
      _invoiceAdjustment = expenses - invoiceDiscount;
      _activeItems = List<AppPurchaseInvoiceTableRowData>.unmodifiable(
        _activeItems.map(
          (item) => item.withCalculatedValues(
            _currency,
            lineBaseTotal: _lineBaseTotal,
            invoiceAdjustment: _invoiceAdjustment,
          ),
        ),
      );

      num totalCost = 0;
      for (final item in _activeItems) {
        totalCost += item.totalCostValue(
          lineBaseTotal: _lineBaseTotal,
          invoiceAdjustment: _invoiceAdjustment,
        );
      }
      _summaryQuantity = AppFormatters.quantity(quantity);
      _summaryDiscount = AppFormatters.moneyByCurrency(
        rowDiscount,
        _currency,
      );
      _summaryTotal = AppFormatters.moneyByCurrency(
        grossTotal,
        _currency,
      );
      _summaryTotalCost = AppFormatters.moneyByCurrency(
        totalCost,
        _currency,
      );

      final total = discountBase - invoiceDiscount;
      late final num paid;
      if (_paymentType == 'نقدي') {
        paid = total;
        _setControllerText(
          _paidController,
          AppFormatters.moneyByCurrency(paid, _currency),
        );
      } else {
        final requestedPaid =
            AppFormatters.parseNumber(_nonCashPaidText) ?? 0;
        paid = total < 0
            ? total
            : requestedPaid < 0
                ? 0
                : requestedPaid > total
                    ? total
                    : requestedPaid;
        if (paid != requestedPaid) {
          _nonCashPaidText = AppFormatters.moneyByCurrency(
            paid,
            _currency,
          );
        }
        _setControllerText(_paidController, _nonCashPaidText);
      }

      final remaining = _paymentType == 'نقدي' ? 0 : total - paid;
      final currentBalance = _balanceBeforeInvoice + remaining;
      _setControllerText(
        _totalController,
        AppFormatters.moneyByCurrency(total, _currency),
      );
      _setControllerText(
        _remainingController,
        AppFormatters.moneyByCurrency(remaining, _currency),
      );
      _setControllerText(
        _currentBalanceController,
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

  bool _validateForm() {
    final supplierName = _supplierNameController.text.trim();
    if (supplierName.isEmpty) {
      AppToast.showWarning(context, 'أدخل اسم المجهز أولاً');
      return false;
    }
    if (_resolveSupplierId(supplierName) == null) {
      AppToast.showWarning(context, 'اختر مجهزاً موجوداً من القائمة');
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

  PurchaseInvoice _domainInvoiceFromForm({required EntityId entityId}) {
    final items = List<AppPurchaseInvoiceTableRowData>.unmodifiable(
      _activeItems.where((item) => !item.isEmpty),
    );
    final currency = AppCurrency.parse(_currency);
    final supplierName = _supplierNameController.text.trim();
    final lines = <PurchaseInvoiceLine>[];
    final newLineNonce = DateTime.now().microsecondsSinceEpoch;
    for (var index = 0; index < items.length; index++) {
      final row = items[index];
      final lineId = row.lineId == null
          ? EntityId('${entityId.value}-line-$newLineNonce-${index + 1}')
          : EntityId(row.lineId!);
      lines.add(
        PurchaseInvoiceLine(
          id: lineId,
          itemId: _resolveItemId(
            row.code,
            row.name,
            itemId: row.itemId,
          )!,
          warehouseId: _warehouseIdsByLabel[row.warehouse]!,
          quantity: WholeQuantity(row.quantityValue),
          containerQuantity: WholeQuantity(
            AppFormatters.parseInteger(row.container) ?? 0,
          ),
          purchasePrice: Money.fromMajor(row.purchasePriceValue, currency),
          lineDiscount: Money.fromMajor(row.discountValue, currency),
          salePrice: Money.fromMajor(
            AppFormatters.parseNumber(row.salePrice) ?? 0,
            currency,
          ),
          itemCodeSnapshot: row.code.trim(),
          itemNameSnapshot: row.name.trim(),
          warehouseNameSnapshot: row.warehouse,
        ),
      );
    }
    return PurchaseInvoice(
      id: entityId,
      documentNumber: int.parse(_invoiceNumberController.text),
      date: BusinessDate.fromDateTime(_invoiceDateTime),
      minuteOfDay: _invoiceDateTime.hour * 60 + _invoiceDateTime.minute,
      supplierId: _resolveSupplierId(supplierName)!,
      supplierNameSnapshot: supplierName,
      defaultWarehouseId: _warehouseIdsByLabel[_warehouse]!,
      currency: currency,
      exchangeRate: ExchangeRate.parse(_exchangeRateController.text),
      purchaseKind: switch (_purchaseType) {
        'إستيراد' => PurchaseTransactionKind.import,
        'إرجاع' => PurchaseTransactionKind.returnPurchase,
        _ => PurchaseTransactionKind.local,
      },
      settlementKind: _paymentType == 'نقدي'
          ? PurchaseSettlementKind.cash
          : PurchaseSettlementKind.credit,
      lines: lines,
      expenses: Money.parse(_expensesController.text, currency),
      invoiceDiscount: Money.parse(_invoiceDiscountController.text, currency),
      paid: Money.parse(_paidController.text, currency),
      balanceAfterInvoice:
          Money.parse(_currentBalanceController.text, currency),
      notes: _notesController.text.trim(),
    );
  }

  EntityId? _resolveSupplierId(String name) {
    final normalized = normalizePartyName(name);
    for (final entry in _supplierIdsByName.entries) {
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
    final legacyId = _legacyPurchaseItemId(code, name);
    if (legacyId != null) return legacyId;
    final codeId = _itemIdsByLabel[_normalizedLookup(code)];
    final nameId = _itemIdsByLabel[_normalizedLookup(name)];
    return codeId != null && codeId == nameId ? codeId : null;
  }

  EntityId? _legacyPurchaseItemId(String code, String name) =>
      switch ('${code.trim()}|${_normalizedLookup(name)}') {
        'P1001|ورق طباعة a4' => EntityId('item-003'),
        'P1002|حبر طابعة' => EntityId('item-002'),
        'P2001|طابعة حرارية' => EntityId('item-007'),
        'P2002|ماسح باركود' => EntityId('item-008'),
        'P3001|حافظة مستندات' => EntityId('item-006'),
        _ => null,
      };

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

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

  DocumentOutputRequest _purchaseDocumentRequest() {
    final supplierName = _supplierNameController.text.trim();
    return DocumentOutputRequest(
      title: 'قائمة شراء رقم ${_invoiceNumberController.text}',
      subtitle: supplierName.isEmpty ? 'مجهز غير محدد' : supplierName,
      fileNameBase: 'قائمة شراء ${_invoiceNumberController.text}',
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
        DocumentField(label: 'نوع الشراء', value: _purchaseType),
        DocumentField(label: 'نوع الدفع', value: _paymentType),
        DocumentField(
          label: 'العملة',
          value: AppFormatters.currency(_currency),
        ),
        DocumentField(
          label: 'المصاريف',
          value: _expensesController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'خصم القائمة',
          value: _invoiceDiscountController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المجموع',
          value: _totalController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المدفوع',
          value: _paidController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المتبقي',
          value: _remainingController.text,
          isPrice: true,
        ),
      ],
      columns: const [
        DocumentColumn(label: 'الرمز'),
        DocumentColumn(label: 'المادة'),
        DocumentColumn(label: 'المخزن'),
        DocumentColumn(label: 'الكمية'),
        DocumentColumn(label: 'الحاوية'),
        DocumentColumn(label: 'سعر الشراء', isPrice: true),
        DocumentColumn(label: 'الخصم', isPrice: true),
        DocumentColumn(label: 'السعر بعد الخصم', isPrice: true),
        DocumentColumn(label: 'المجموع', isPrice: true),
        DocumentColumn(label: 'الكلفة', isPrice: true),
        DocumentColumn(label: 'إجمالي الكلفة', isPrice: true),
        DocumentColumn(label: 'سعر البيع', isPrice: true),
      ],
      rows: [
        for (final item in _activeItems.where((item) => !item.isEmpty))
          [
            item.code,
            item.name,
            item.warehouse,
            item.quantity,
            item.container,
            item.purchasePrice,
            item.discount.isEmpty ? '0' : item.discount,
            item.priceAfterDiscount,
            item.total,
            item.cost,
            item.totalCost,
            item.salePrice,
          ],
      ],
    );
  }

  void _printPurchaseInvoice({bool includePrices = true}) {
    unawaited(_runPurchasePrint(includePrices: includePrices));
  }

  Future<void> _runPurchasePrint({required bool includePrices}) async {
    if (_isDocumentActionRunning) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isDocumentActionRunning = true);
    try {
      final result = await widget.printService.createPreview(
        _purchaseDocumentRequest(),
        includePrices: includePrices,
      );
      if (!mounted) return;
      await AppDocumentOutputDialog.show(
        context,
        result: result,
        accentColor: AppModuleColors.purchases,
      );
    } on ServiceFailure catch (failure) {
      if (mounted) AppToast.showError(context, failure.message);
    } catch (_) {
      if (mounted) {
        AppToast.showError(context, 'تعذر تجهيز قائمة الشراء للطباعة');
      }
    } finally {
      if (mounted) setState(() => _isDocumentActionRunning = false);
    }
  }

  DateTime? _firstPurchaseTransactionDate(String supplierName) {
    DateTime? firstDate;
    for (final invoice in _purchaseInvoices) {
      if (invoice.supplierName != supplierName) continue;
      if (firstDate == null || invoice.dateTime.isBefore(firstDate)) {
        firstDate = invoice.dateTime;
      }
    }
    return firstDate;
  }

  num _purchaseInvoiceTotal(_DemoPurchaseInvoice invoice) {
    final lineTotal = invoice.items.fold<num>(
      0,
      (total, item) => total + item.totalValue,
    );
    final expenses = AppFormatters.parseNumber(invoice.expenses) ?? 0;
    final discount =
        AppFormatters.parseNumber(invoice.invoiceDiscount) ?? 0;
    return lineTotal + expenses - discount;
  }

  List<AppStatementReportEntry> _purchaseStatementEntries(
    String supplierName,
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
    final invoices = _purchaseInvoices.where((invoice) {
      return invoice.supplierName == supplierName &&
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
          credit: _purchaseInvoiceTotal(invoice),
          debit: AppFormatters.parseNumber(invoice.paid) ?? 0,
          type: 'قائمة شراء',
          quantity: invoice.items.fold<int>(
            0,
            (total, item) => total + item.quantityValue,
          ),
          details:
              'قائمة شراء رقم ${invoice.id} • ${invoice.purchaseType}',
        ),
    ];
  }

  Future<void> _showPurchaseStatement() async {
    final supplierName = _supplierNameController.text.trim();
    final displayName =
        supplierName.isEmpty ? 'مجهز غير محدد' : supplierName;
    final options = await AppStatementOptionsDialog.show(
      context,
      partyName: displayName,
      partyLabel: 'اسم المجهز',
      accentColor: AppModuleColors.purchases,
      firstTransactionDate: _firstPurchaseTransactionDate(displayName),
    );
    if (!mounted || options == null) return;

    await AppStatementReportDialog.show(
      context,
      partyName: displayName,
      options: options,
      entries: _purchaseStatementEntries(displayName, options),
      accentColor: AppModuleColors.purchases,
      printService: widget.printService,
      exportService: widget.exportService,
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
  Widget build(BuildContext context) {
    final hasSelectedInvoice = _selectedInvoice != null;
    final selectedInvoiceIndex = _selectedInvoiceIndex;
    final hasInvoices = _purchaseInvoices.isNotEmpty;
    final canMoveToFirstOrPrevious =
        hasInvoices && selectedInvoiceIndex != 0;
    final canMoveToNextOrLast =
        hasInvoices && selectedInvoiceIndex >= 0;
    final currencyName = _currency == 'USD' ? 'دولار' : 'دينار';
    final isEditorReady = _invoiceState.status == AppDataStatus.ready;
    final tint = Color.alphaBlend(
      AppModuleColors.purchases.withAlpha(12),
      AppColors.surface,
    );

    return PopScope(
      canPop: !_hasUnsavedChanges && !_isRepositoryBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isRepositoryBusy) _attemptBack();
      },
      child: AppScreenShell(
        key: const Key('purchaseScreen'),
        title: 'المشتريات',
        backgroundColor: tint,
        onBack: _attemptBack,
        onSearch: !isEditorReady || _isRepositoryBusy
            ? null
            : _showPurchaseSearch,
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
          key: const Key('purchaseTintBackground'),
          color: tint,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
              _PurchaseFieldRow(
                children: [
                  AppReadOnlyField(
                    fieldKey: const Key('purchaseInvoiceNumberField'),
                    controller: _invoiceNumberController,
                    label: 'رقم القائمة',
                    icon: Icons.receipt_long_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppDateField(
                    fieldKey: const Key('purchaseDateField'),
                    label: 'التاريخ',
                    value: _invoiceDateTime,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    onChanged: _changeDate,
                  ),
                  AppTimeField(
                    fieldKey: const Key('purchaseTimeField'),
                    label: 'الوقت',
                    value: TimeOfDay.fromDateTime(_invoiceDateTime),
                    accentColor: AppModuleColors.purchases,
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('purchaseWarehouseField'),
                    label: 'المخزن',
                    icon: Icons.warehouse_rounded,
                    accentColor: AppModuleColors.purchases,
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
                    fieldKey: const Key('purchaseTypeField'),
                    label: 'نوع الشراء',
                    icon: Icons.shopping_cart_checkout_rounded,
                    accentColor: AppModuleColors.purchases,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _purchaseType,
                    options: _purchaseTypeOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changePurchaseType(value);
                    },
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('purchasePaymentTypeField'),
                    label: 'نوع الدفع',
                    icon: Icons.payments_rounded,
                    accentColor: AppModuleColors.purchases,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _paymentType,
                    options: _purchasePaymentTypeOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changePaymentType(value);
                    },
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('purchaseCurrencyField'),
                    label: 'العملة',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: AppModuleColors.purchases,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _currency,
                    options: _purchaseCurrencyOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changeCurrency(value);
                    },
                  ),
                  AppMoneyField(
                    fieldKey: const Key('purchaseExchangeRateField'),
                    controller: _exchangeRateController,
                    label: 'سعر الصرف',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    enabled: _currency == 'USD',
                    readOnly: _currency != 'USD',
                    decimalPlaces: 4,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _PurchaseFieldRow(
                children: [
                  AppAutocompleteField<String>(
                    fieldKey: const Key('purchaseSupplierNameField'),
                    controller: _supplierNameController,
                    label: 'اسم المجهز',
                    icon: Icons.person_search_rounded,
                    accentColor: AppModuleColors.purchases,
                    options: _supplierOptions,
                    displayStringForOption: (value) => value,
                    onSelected: (_) {},
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppTextField(
                    fieldKey: const Key('purchaseNotesField'),
                    controller: _notesController,
                    label: 'الملاحظات',
                    icon: Icons.notes_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: AppPurchaseInvoiceTableTemplate(
                  key: const Key('purchaseItemsTable'),
                  initialRows: _activeItems,
                  dataVersion: _tableDataVersion,
                  summaryQuantity: _summaryQuantity,
                  summaryDiscount: _summaryDiscount,
                  summaryTotal: _summaryTotal,
                  summaryTotalCost: _summaryTotalCost,
                  currencyCode: _currency,
                  lineBaseTotal: _lineBaseTotal,
                  invoiceAdjustment: _invoiceAdjustment,
                  itemOptions: _itemOptions,
                  onRowsChanged: _changeItems,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PurchaseFieldRow(
                flexes: const [5, 4, 4, 4, 4, 4, 4, 4],
                children: [
                  AppRegularButton(
                    key: const Key('purchaseExpensesButton'),
                    label: 'المصاريف',
                    icon: Icons.receipt_long_rounded,
                    onPressed: () => _expensesFocusNode.requestFocus(),
                  ),
                  _PurchaseMoneyField(
                    fieldKey: const Key('purchaseExpensesField'),
                    controller: _expensesController,
                    focusNode: _expensesFocusNode,
                    label: 'المصاريف',
                    icon: Icons.payments_rounded,
                    decimalPlaces: _currency == 'USD' ? 2 : 0,
                    onChanged: _changeExpenses,
                  ),
                  _PurchaseMoneyField(
                    fieldKey: const Key('purchaseInvoiceDiscountField'),
                    controller: _invoiceDiscountController,
                    label: 'خصم القائمة',
                    icon: Icons.discount_rounded,
                    decimalPlaces: _currency == 'USD' ? 2 : 0,
                    onChanged: _changeInvoiceDiscount,
                  ),
                  _PurchaseMoneyField(
                    fieldKey: const Key('purchaseDiscountPercentageField'),
                    controller: _discountPercentageController,
                    label: 'نسبة الخصم',
                    icon: Icons.percent_rounded,
                    decimalPlaces: 2,
                    onChanged: _changeDiscountPercentage,
                  ),
                  _PurchaseMoneyField(
                    fieldKey: const Key('purchasePaidField'),
                    controller: _paidController,
                    label: 'المدفوع',
                    icon: Icons.payments_rounded,
                    decimalPlaces: _currency == 'USD' ? 2 : 0,
                    enabled: _paymentType != 'نقدي',
                    onChanged: _changePaid,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('purchaseTotalField'),
                    controller: _totalController,
                    label: 'المجموع $currencyName',
                    icon: Icons.calculate_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('purchaseRemainingField'),
                    controller: _remainingController,
                    label: 'المتبقي $currencyName',
                    icon: Icons.pending_actions_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('purchaseCurrentBalanceField'),
                    controller: _currentBalanceController,
                    label: 'الرصيد الحالي $currencyName',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppActionBar(
                key: const Key('purchaseActionBar'),
                middle: _PurchaseInvoiceButtons(
                  onSearch: !isEditorReady || _isRepositoryBusy
                      ? null
                      : _showPurchaseSearch,
                  onPrint: !isEditorReady || _isDocumentActionRunning
                      ? null
                      : () => _printPurchaseInvoice(),
                  onPrintWithoutPrices: isEditorReady &&
                          hasSelectedInvoice &&
                          !_isDocumentActionRunning
                      ? () => _printPurchaseInvoice(includePrices: false)
                      : null,
                  onStatement:
                      isEditorReady ? _showPurchaseStatement : null,
                ),
                firstButtonKey: const Key('purchaseFirstButton'),
                previousButtonKey: const Key('purchasePreviousButton'),
                nextButtonKey: const Key('purchaseNextButton'),
                lastButtonKey: const Key('purchaseLastButton'),
                saveButtonKey: const Key('purchaseSaveButton'),
                updateButtonKey: const Key('purchaseUpdateButton'),
                undoButtonKey: const Key('purchaseUndoButton'),
                deleteButtonKey: const Key('purchaseDeleteButton'),
                accentColor: AppModuleColors.purchases,
                onFirst: canMoveToFirstOrPrevious
                    ? () => _navigate(_PurchaseNavigation.first)
                    : null,
                onPrevious: canMoveToFirstOrPrevious
                    ? () => _navigate(_PurchaseNavigation.previous)
                    : null,
                onNext: canMoveToNextOrLast
                    ? () => _navigate(_PurchaseNavigation.next)
                    : null,
                onLast: canMoveToNextOrLast
                    ? () => _navigate(_PurchaseNavigation.last)
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
                child: AppDataStateView<List<_DemoPurchaseInvoice>>(
                  state: _invoiceState,
                  dataBuilder: (_, __) => const SizedBox.shrink(),
                  emptyTitle: 'لا توجد قوائم شراء',
                  emptyActionLabel: 'قائمة شراء جديدة',
                  onEmptyAction: _openEmptyEditor,
                  missingReferenceActionLabel: 'إعادة المحاولة',
                  onMissingReferenceAction: () => unawaited(_loadData()),
                  onRetry: () => unawaited(_loadData()),
                  loadingStateKey: const Key('purchaseLoadingState'),
                  emptyStateKey: const Key('purchaseEmptyState'),
                  missingReferenceStateKey:
                      const Key('purchaseMissingReferenceState'),
                  errorStateKey: const Key('purchaseErrorState'),
                ),
              ),
            if (_isRepositoryBusy)
              AbsorbPointer(
                child: ColoredBox(
                  key: const Key('purchaseBusyOverlay'),
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

class _PurchaseInvoiceButtons extends StatelessWidget {
  const _PurchaseInvoiceButtons({
    required this.onSearch,
    required this.onPrint,
    required this.onPrintWithoutPrices,
    required this.onStatement,
  });

  final VoidCallback? onSearch;
  final VoidCallback? onPrint;
  final VoidCallback? onPrintWithoutPrices;
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
          key: const Key('purchaseSearchButton'),
          tooltipKey: const Key('purchaseSearchTooltip'),
          icon: Icons.search_rounded,
          tooltip: 'بحث',
          onPressed: onSearch,
        ),
        AppHeaderIconButton(
          key: const Key('purchasePrintButton'),
          tooltipKey: const Key('purchasePrintTooltip'),
          icon: Icons.print_rounded,
          tooltip: 'طباعة',
          onPressed: onPrint,
        ),
        AppHeaderIconButton(
          key: const Key('purchasePrintWithoutPricesButton'),
          tooltipKey: const Key('purchasePrintWithoutPricesTooltip'),
          icon: Icons.money_off_rounded,
          tooltip: 'طباعة بدون سعر',
          onPressed: onPrintWithoutPrices,
        ),
        AppHeaderIconButton(
          key: const Key('purchaseStatementButton'),
          tooltipKey: const Key('purchaseStatementTooltip'),
          icon: Icons.receipt_long_rounded,
          tooltip: 'كشف الحساب',
          onPressed: onStatement,
        ),
      ],
    );
  }
}

class _PurchaseFieldRow extends StatelessWidget {
  const _PurchaseFieldRow({
    required this.children,
    this.flexes,
  }) : assert(
          flexes == null || flexes.length == children.length,
          'Provide one flex value for each child.',
        );

  final List<Widget> children;
  final List<int>? flexes;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: flexes?[index] ?? 1,
              child: children[index],
            ),
          ],
        ],
      ),
    );
  }
}

class _PurchaseMoneyField extends StatelessWidget {
  const _PurchaseMoneyField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    this.focusNode,
    this.decimalPlaces = 4,
    this.enabled = true,
    this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FocusNode? focusNode;
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
      accentColor: AppModuleColors.purchases,
      focusNode: focusNode,
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

enum _PurchaseNavigation { first, previous, next, last }

enum _PurchaseDiscountInputSource { amount, percentage }

typedef _PurchaseFormSnapshot = ({
  DateTime invoiceDateTime,
  String warehouse,
  String purchaseType,
  String paymentType,
  String currency,
  String exchangeRate,
  String supplierName,
  String notes,
  String expenses,
  String invoiceDiscount,
  String discountPercentage,
  String paid,
  String itemsSignature,
});
