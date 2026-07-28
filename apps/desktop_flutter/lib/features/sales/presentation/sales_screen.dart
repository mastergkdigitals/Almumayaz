import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

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

final _demoSalesInvoices = <_DemoSalesInvoice>[
  _DemoSalesInvoice(
    id: '103',
    dateTime: DateTime(2026, 7, 27, 10, 25),
    warehouse: 'الرئيسي',
    saleType: 'نقدي',
    currency: 'IQD',
    exchangeRate: '1,310',
    customerName: 'أسواق دجلة',
    notes: 'تسليم الطلب إلى فرع الكرادة',
    driverName: 'مصطفى علي',
    invoiceDiscount: '5,000',
    discountPercentage: '0',
    received: '250,000',
    total: '310,000',
    remaining: '60,000',
    currentBalance: '120,000',
    searchDetails: '27/07/2026 • 3 مواد',
    searchTerms: const [
      '103',
      'أسواق دجلة',
      'دفتر ملاحظات',
      'قلم أزرق',
      'حاسبة مكتبية',
    ],
    items: const [
      AppSalesInvoiceTableRowData(
        code: '1001',
        name: 'دفتر ملاحظات',
        warehouse: 'الرئيسي',
        quantity: '4',
        salePrice: '35,000',
        priceAfterDiscount: '35,000',
        total: '140,000',
      ),
      AppSalesInvoiceTableRowData(
        code: '1002',
        name: 'قلم أزرق',
        warehouse: 'الرئيسي',
        quantity: '10',
        salePrice: '5,000',
        priceAfterDiscount: '5,000',
        total: '50,000',
      ),
      AppSalesInvoiceTableRowData(
        code: '1003',
        name: 'حاسبة مكتبية',
        warehouse: 'الكرادة',
        quantity: '1',
        salePrice: '130,000',
        discount: '5,000',
        priceAfterDiscount: '125,000',
        total: '125,000',
      ),
    ],
    summaryQuantity: '15',
    summaryDiscount: '5,000',
    summaryTotal: '315,000',
  ),
  _DemoSalesInvoice(
    id: '102',
    dateTime: DateTime(2026, 7, 26, 12, 40),
    warehouse: 'المنصور',
    saleType: 'أقساط',
    currency: 'USD',
    exchangeRate: '1,310',
    customerName: 'أحمد كريم',
    notes: 'تسديد القسط الأول عند التسليم',
    driverName: 'حيدر سالم',
    invoiceDiscount: '0',
    discountPercentage: '0',
    received: '250',
    total: '1,250',
    remaining: '1,000',
    currentBalance: '1,500',
    searchDetails: '26/07/2026 • مادتان • أقساط',
    searchTerms: const [
      '102',
      'أحمد كريم',
      'طابعة حرارية',
      'ماسح باركود',
      'أقساط',
      'دولار',
    ],
    items: const [
      AppSalesInvoiceTableRowData(
        code: '2001',
        name: 'طابعة حرارية',
        warehouse: 'المنصور',
        quantity: '1',
        salePrice: '900',
        discount: '50',
        priceAfterDiscount: '850',
        total: '850',
      ),
      AppSalesInvoiceTableRowData(
        code: '2002',
        name: 'ماسح باركود',
        warehouse: 'المنصور',
        quantity: '2',
        salePrice: '200',
        priceAfterDiscount: '200',
        total: '400',
      ),
    ],
    summaryQuantity: '3',
    summaryDiscount: '50',
    summaryTotal: '1,250',
  ),
  _DemoSalesInvoice(
    id: '101',
    dateTime: DateTime(2026, 7, 25, 9, 15),
    warehouse: 'الرصافة',
    saleType: 'آجل',
    currency: 'IQD',
    exchangeRate: '1,310',
    customerName: 'شركة النخيل للتجارة',
    notes: 'تضاف إلى حساب الزبون',
    driverName: 'كرار مهدي',
    invoiceDiscount: '0',
    discountPercentage: '0',
    received: '0',
    total: '177,000',
    remaining: '177,000',
    currentBalance: '625,000',
    searchDetails: '25/07/2026 • 3 مواد • آجل',
    searchTerms: const [
      '101',
      'شركة النخيل للتجارة',
      'ورق طباعة',
      'حبر طابعة',
      'دباسة',
      'آجل',
    ],
    items: const [
      AppSalesInvoiceTableRowData(
        code: '3001',
        name: 'ورق طباعة',
        warehouse: 'الرصافة',
        quantity: '5',
        salePrice: '12,000',
        priceAfterDiscount: '12,000',
        total: '60,000',
      ),
      AppSalesInvoiceTableRowData(
        code: '3002',
        name: 'حبر طابعة',
        warehouse: 'الرصافة',
        quantity: '2',
        salePrice: '45,000',
        priceAfterDiscount: '45,000',
        total: '90,000',
      ),
      AppSalesInvoiceTableRowData(
        code: '3003',
        name: 'دباسة',
        warehouse: 'الرئيسي',
        quantity: '3',
        salePrice: '10,000',
        discount: '1,000',
        priceAfterDiscount: '9,000',
        total: '27,000',
      ),
    ],
    summaryQuantity: '10',
    summaryDiscount: '1,000',
    summaryTotal: '177,000',
  ),
].reversed.toList(growable: false);

class _DemoSalesInvoice {
  const _DemoSalesInvoice({
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
  const SalesScreen({super.key});

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

  late final List<_DemoSalesInvoice> _salesInvoices;
  late DateTime _invoiceDateTime;
  _DemoSalesInvoice? _selectedInvoice;
  List<AppSalesInvoiceTableRowData> _activeItems = const [];
  var _warehouse = 'الرئيسي';
  var _saleType = 'نقدي';
  var _currency = 'IQD';
  var _summaryQuantity = '0';
  var _summaryDiscount = '0';
  var _summaryTotal = '0';
  var _tableDataVersion = 0;
  late _SalesFormSnapshot _baseline;
  var _isApplyingFormState = false;
  var _hasUnsavedChanges = false;

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
    var highestNumber = 0;
    for (final invoice in _salesInvoices) {
      final number = int.tryParse(invoice.id) ?? 0;
      if (number > highestNumber) highestNumber = number;
    }
    return highestNumber + 1;
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
    _salesInvoices = [..._demoSalesInvoices];
    _loadInvoice(_salesInvoices.first);
    for (final controller in _editableControllers) {
      controller.addListener(_refreshUnsavedState);
    }
  }

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
    _receivedController.text = invoice.received;
    _totalIqdController.text = invoice.total;
    _remainingIqdController.text = invoice.remaining;
    _currentBalanceIqdController.text = invoice.currentBalance;
    _activeItems = List<AppSalesInvoiceTableRowData>.unmodifiable(
      invoice.items,
    );
    _summaryQuantity = invoice.summaryQuantity;
    _summaryDiscount = invoice.summaryDiscount;
    _summaryTotal = invoice.summaryTotal;
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
    _warehouse = _salesWarehouseOptions.first.value;
    _saleType = _salesTypeOptions.first.value;
    _currency = _salesCurrencyOptions.first.value;
    _exchangeRateController.text = '1,310';
    _customerNameController.clear();
    _notesController.clear();
    _driverNameController.clear();
    _invoiceDiscountController.text = '0';
    _discountPercentageController.text = '0';
    _receivedController.text = '0';
    _totalIqdController.text = '0';
    _remainingIqdController.text = '0';
    _currentBalanceIqdController.text = '0';
    _activeItems = const [AppSalesInvoiceTableRowData()];
    _summaryQuantity = '0';
    _summaryDiscount = '0';
    _summaryTotal = '0';
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
      _saleType = value;
      _refreshSelectionState();
    });
  }

  void _changeCurrency(String value) {
    if (_currency == value) return;
    setState(() {
      _currency = value;
      _refreshSelectionState();
    });
  }

  void _changeItems(List<AppSalesInvoiceTableRowData> items) {
    setState(() {
      _activeItems = List<AppSalesInvoiceTableRowData>.unmodifiable(items);
      _refreshSelectionState();
    });
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    return AppDialogs.confirm(
      context: context,
      title: 'تغييرات غير محفوظة',
      message: 'لديك بيانات أو تعديلات غير محفوظة. هل تريد تجاهلها؟',
      confirmLabel: 'تجاهل',
      cancelLabel: 'البقاء',
      isDanger: true,
    );
  }

  void _attemptBack() {
    unawaited(_leaveAfterConfirmation());
  }

  Future<void> _leaveAfterConfirmation() async {
    if (!await _confirmDiscardChanges() || !mounted) return;
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
    if (_customerNameController.text.trim().isNotEmpty) return true;
    AppToast.showWarning(context, 'أدخل اسم الزبون أولاً');
    return false;
  }

  _DemoSalesInvoice _invoiceFromForm({
    required String id,
  }) {
    final meaningfulItemCount = _activeItems.where((item) {
      return item.code.trim().isNotEmpty || item.name.trim().isNotEmpty;
    }).length;
    final date =
        '${_twoDigits(_invoiceDateTime.day)}/'
        '${_twoDigits(_invoiceDateTime.month)}/'
        '${_invoiceDateTime.year}';
    final customerName = _customerNameController.text.trim();
    final items = List<AppSalesInvoiceTableRowData>.unmodifiable(
      _activeItems,
    );

    return _DemoSalesInvoice(
      id: id,
      dateTime: _invoiceDateTime,
      warehouse: _warehouse,
      saleType: _saleType,
      currency: _currency,
      exchangeRate: _exchangeRateController.text,
      customerName: customerName,
      notes: _notesController.text.trim(),
      driverName: _driverNameController.text.trim(),
      invoiceDiscount: _invoiceDiscountController.text,
      discountPercentage: _discountPercentageController.text,
      received: _receivedController.text,
      total: _totalIqdController.text,
      remaining: _remainingIqdController.text,
      currentBalance: _currentBalanceIqdController.text,
      searchDetails: '$date • $meaningfulItemCount مواد',
      searchTerms: List<String>.unmodifiable([
        id,
        customerName,
        _saleType,
        _currency == 'USD' ? 'دولار' : 'دينار',
        for (final item in items) ...[item.code, item.name],
      ]),
      items: items,
      summaryQuantity: _summaryQuantity,
      summaryDiscount: _summaryDiscount,
      summaryTotal: _summaryTotal,
    );
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  void _save() {
    if (!_validateForm()) return;
    if (_selectedInvoice != null) {
      AppToast.showWarning(
        context,
        'استخدم زر تحديث لتعديل قائمة البيع المحددة',
      );
      return;
    }

    final invoice = _invoiceFromForm(
      id: _invoiceNumberController.text,
    );
    setState(() {
      _salesInvoices.add(invoice);
      _loadInvoice(invoice);
    });
    AppToast.showInfo(context, 'تم حفظ قائمة البيع مؤقتاً');
  }

  void _update() {
    final selected = _selectedInvoice;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر قائمة بيع لتحديثها');
      return;
    }
    if (!_validateForm()) return;

    final updated = _invoiceFromForm(id: selected.id);
    final index = _salesInvoices.indexWhere(
      (invoice) => invoice.id == selected.id,
    );
    if (index < 0) return;

    setState(() {
      _salesInvoices[index] = updated;
      _loadInvoice(updated);
    });
    AppToast.showSuccess(context, 'تم تحديث قائمة البيع مؤقتاً');
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

    setState(() {
      _salesInvoices.removeWhere((invoice) => invoice.id == selected.id);
      _setNewForm();
    });
    AppToast.showDanger(context, 'تم حذف قائمة البيع مؤقتاً');
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

  Future<void> _showSalesStatement() async {
    final customerName = _customerNameController.text.trim();
    final displayName =
        customerName.isEmpty ? 'زبون غير محدد' : customerName;
    final options = await AppStatementOptionsDialog.show(
      context,
      partyName: displayName,
      partyLabel: 'اسم الزبون',
      accentColor: AppModuleColors.sales,
    );
    if (!mounted || options == null) return;

    await AppStatementReportDialog.show(
      context,
      partyName: displayName,
      options: options,
      entries: const <AppStatementReportEntry>[],
      accentColor: AppModuleColors.sales,
    );
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
    final tint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );

    return AppScreenShell(
      key: const Key('salesScreen'),
      title: 'المبيعات',
      backgroundColor: tint,
      onBack: _attemptBack,
      onSearch: _showSalesSearch,
      onSave: hasSelectedInvoice
          ? _hasUnsavedChanges
              ? _update
              : null
          : _save,
      body: ColoredBox(
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
                    options: _salesWarehouseOptions,
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
                  AppTextField(
                    fieldKey: const Key('salesExchangeRateField'),
                    controller: _exchangeRateController,
                    label: 'سعر الصرف',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [
                      AppMoneyInputFormatter(decimalPlaces: 4),
                    ],
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SalesFieldRow(
                children: [
                  AppTextField(
                    fieldKey: const Key('salesCustomerNameField'),
                    controller: _customerNameController,
                    label: 'اسم الزبون',
                    icon: Icons.person_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.next,
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
                    label: 'خصم الفاتورة',
                    icon: Icons.discount_rounded,
                  ),
                  _SalesMoneyField(
                    fieldKey: const Key('salesDiscountPercentageField'),
                    controller: _discountPercentageController,
                    label: 'نسبة الخصم',
                    icon: Icons.percent_rounded,
                    decimalPlaces: 2,
                  ),
                  _SalesMoneyField(
                    fieldKey: const Key('salesReceivedField'),
                    controller: _receivedController,
                    label: 'المقبوض',
                    icon: Icons.payments_rounded,
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
                  onSearch: _showSalesSearch,
                  onInstallments: _saleType == 'أقساط' ? () {} : null,
                  onStatement: _showSalesStatement,
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
                onSave: hasSelectedInvoice ? null : _save,
                onUpdate: hasSelectedInvoice && _hasUnsavedChanges
                    ? _update
                    : null,
                onUndo: _hasUnsavedChanges ? _undo : null,
                onDelete: hasSelectedInvoice ? _delete : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesInvoiceButtons extends StatelessWidget {
  const _SalesInvoiceButtons({
    required this.onSearch,
    required this.onInstallments,
    required this.onStatement,
  });

  final VoidCallback onSearch;
  final VoidCallback? onInstallments;
  final VoidCallback onStatement;

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
          onPressed: () {},
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
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int decimalPlaces;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      fieldKey: fieldKey,
      controller: controller,
      label: label,
      icon: icon,
      accentColor: AppModuleColors.sales,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        AppMoneyInputFormatter(decimalPlaces: decimalPlaces),
      ],
      textInputAction: TextInputAction.next,
    );
  }
}

enum _SalesNavigation { first, previous, next, last }

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
