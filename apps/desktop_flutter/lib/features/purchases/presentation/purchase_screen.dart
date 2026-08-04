import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

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

final _demoPurchaseInvoices = <_DemoPurchaseInvoice>[
  _DemoPurchaseInvoice(
    id: '103',
    dateTime: DateTime(2026, 7, 27, 11, 35),
    warehouse: 'الرئيسي',
    purchaseType: 'إرجاع',
    paymentType: 'نقدي',
    currency: 'IQD',
    exchangeRate: '1,310',
    supplierName: 'مجهز الكرادة',
    notes: 'إرجاع مواد واستبدالها ضمن القائمة',
    expenses: '0',
    invoiceDiscount: '10,000',
    discountPercentage: '0',
    paid: '90,000',
    remaining: '0',
    currentBalance: '80,000',
    searchDetails: '27/07/2026 • مادة واحدة • نقدي',
    searchTerms: const [
      '103',
      'مجهز الكرادة',
      'حافظة مستندات',
      'إرجاع',
      'نقدي',
    ],
    items: const [
      AppPurchaseInvoiceTableRowData(
        code: 'P3001',
        name: 'حافظة مستندات',
        warehouse: 'الرئيسي',
        quantity: '5',
        container: '0',
        purchasePrice: '20,000',
        salePrice: '27,000',
      ),
    ],
  ),
  _DemoPurchaseInvoice(
    id: '102',
    dateTime: DateTime(2026, 7, 26, 13, 20),
    warehouse: 'المنصور',
    purchaseType: 'إستيراد',
    paymentType: 'آجل',
    currency: 'USD',
    exchangeRate: '1,310',
    supplierName: 'شركة التجارة العالمية',
    notes: 'أجور الشحن مضافة إلى مصاريف القائمة',
    expenses: '100',
    invoiceDiscount: '50',
    discountPercentage: '0',
    paid: '500',
    remaining: '1,000',
    currentBalance: '1,250',
    searchDetails: '26/07/2026 • مادتان • إستيراد',
    searchTerms: const [
      '102',
      'شركة التجارة العالمية',
      'طابعة حرارية',
      'ماسح باركود',
      'إستيراد',
      'دولار',
    ],
    items: const [
      AppPurchaseInvoiceTableRowData(
        code: 'P2001',
        name: 'طابعة حرارية',
        warehouse: 'المنصور',
        quantity: '2',
        container: '1',
        purchasePrice: '600',
        discount: '50',
        salePrice: '900',
      ),
      AppPurchaseInvoiceTableRowData(
        code: 'P2002',
        name: 'ماسح باركود',
        warehouse: 'المنصور',
        quantity: '3',
        container: '1',
        purchasePrice: '100',
        salePrice: '200',
      ),
    ],
  ),
  _DemoPurchaseInvoice(
    id: '101',
    dateTime: DateTime(2026, 7, 25, 9, 45),
    warehouse: 'الرصافة',
    purchaseType: 'محلي',
    paymentType: 'آجل',
    currency: 'IQD',
    exchangeRate: '1,310',
    supplierName: 'شركة الرافدين للتجهيز',
    notes: 'تضاف إلى حساب المجهز',
    expenses: '5,000',
    invoiceDiscount: '0',
    discountPercentage: '0',
    paid: '0',
    remaining: '150,000',
    currentBalance: '450,000',
    searchDetails: '25/07/2026 • مادتان • محلي',
    searchTerms: const [
      '101',
      'شركة الرافدين للتجهيز',
      'ورق طباعة A4',
      'حبر طابعة',
      'محلي',
      'آجل',
    ],
    items: const [
      AppPurchaseInvoiceTableRowData(
        code: 'P1001',
        name: 'ورق طباعة A4',
        warehouse: 'الرصافة',
        quantity: '10',
        container: '0',
        purchasePrice: '8,000',
        salePrice: '12,000',
      ),
      AppPurchaseInvoiceTableRowData(
        code: 'P1002',
        name: 'حبر طابعة',
        warehouse: 'الرصافة',
        quantity: '2',
        container: '0',
        purchasePrice: '35,000',
        discount: '5,000',
        salePrice: '45,000',
      ),
    ],
  ),
].reversed.toList(growable: false);

class _DemoPurchaseInvoice {
  const _DemoPurchaseInvoice({
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
  const PurchaseScreen({super.key});

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

  late final List<_DemoPurchaseInvoice> _purchaseInvoices;
  late DateTime _invoiceDateTime;
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
    var highestNumber = 0;
    for (final invoice in _purchaseInvoices) {
      final number = int.tryParse(invoice.id) ?? 0;
      if (number > highestNumber) highestNumber = number;
    }
    return highestNumber + 1;
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
    _purchaseInvoices = [..._demoPurchaseInvoices];
    _loadInvoice(_purchaseInvoices.first);
    for (final controller in _editableControllers) {
      controller.addListener(_refreshUnsavedState);
    }
  }

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
    _warehouse = _purchaseWarehouseOptions.first.value;
    _purchaseType = _purchaseTypeOptions.first.value;
    _paymentType = _purchasePaymentTypeOptions.first.value;
    _currency = _purchaseCurrencyOptions.first.value;
    _exchangeRateController.text = '1,310';
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
        _setControllerText(_paidController, _nonCashPaidText);
        paid = AppFormatters.parseNumber(_paidController.text) ?? 0;
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
    if (_supplierNameController.text.trim().isNotEmpty) return true;
    AppToast.showWarning(context, 'أدخل اسم المجهز أولاً');
    return false;
  }

  _DemoPurchaseInvoice _invoiceFromForm({
    required String id,
  }) {
    final items = List<AppPurchaseInvoiceTableRowData>.unmodifiable(
      _activeItems.where((item) => !item.isEmpty),
    );
    final meaningfulItemCount = items.length;
    final date =
        '${_twoDigits(_invoiceDateTime.day)}/'
        '${_twoDigits(_invoiceDateTime.month)}/'
        '${_invoiceDateTime.year}';
    final supplierName = _supplierNameController.text.trim();

    return _DemoPurchaseInvoice(
      id: id,
      dateTime: _invoiceDateTime,
      warehouse: _warehouse,
      purchaseType: _purchaseType,
      paymentType: _paymentType,
      currency: _currency,
      exchangeRate: _exchangeRateController.text,
      supplierName: supplierName,
      notes: _notesController.text.trim(),
      expenses: _expensesController.text,
      invoiceDiscount: _invoiceDiscountController.text,
      discountPercentage: _discountPercentageController.text,
      paid: _paidController.text,
      remaining: _remainingController.text,
      currentBalance: _currentBalanceController.text,
      searchDetails: '$date • $meaningfulItemCount مواد',
      searchTerms: List<String>.unmodifiable([
        id,
        supplierName,
        _purchaseType,
        _paymentType,
        _currency == 'USD' ? 'دولار' : 'دينار',
        for (final item in items) ...[item.code, item.name],
      ]),
      items: items,
    );
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  void _save() {
    if (!_validateForm()) return;
    if (_selectedInvoice != null) {
      AppToast.showWarning(
        context,
        'استخدم زر تحديث لتعديل قائمة الشراء المحددة',
      );
      return;
    }

    final invoice = _invoiceFromForm(
      id: _invoiceNumberController.text,
    );
    setState(() {
      _purchaseInvoices.add(invoice);
      _loadInvoice(invoice);
    });
    AppToast.showInfo(context, 'تم حفظ قائمة الشراء مؤقتاً');
  }

  void _update() {
    final selected = _selectedInvoice;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر قائمة شراء لتحديثها');
      return;
    }
    if (!_validateForm()) return;

    final updated = _invoiceFromForm(id: selected.id);
    final index = _purchaseInvoices.indexWhere(
      (invoice) => invoice.id == selected.id,
    );
    if (index < 0) return;

    setState(() {
      _purchaseInvoices[index] = updated;
      _loadInvoice(updated);
    });
    AppToast.showSuccess(context, 'تم تحديث قائمة الشراء مؤقتاً');
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

    setState(() {
      _purchaseInvoices.removeWhere(
        (invoice) => invoice.id == selected.id,
      );
      _setNewForm();
    });
    AppToast.showDanger(context, 'تم حذف قائمة الشراء مؤقتاً');
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

  Future<void> _showPurchaseStatement() async {
    final supplierName = _supplierNameController.text.trim();
    final displayName =
        supplierName.isEmpty ? 'مجهز غير محدد' : supplierName;
    final options = await AppStatementOptionsDialog.show(
      context,
      partyName: displayName,
      partyLabel: 'اسم المجهز',
      accentColor: AppModuleColors.purchases,
    );
    if (!mounted || options == null) return;

    await AppStatementReportDialog.show(
      context,
      partyName: displayName,
      options: options,
      entries: const <AppStatementReportEntry>[],
      accentColor: AppModuleColors.purchases,
    );
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
    final tint = Color.alphaBlend(
      AppModuleColors.purchases.withAlpha(12),
      AppColors.surface,
    );

    return AppScreenShell(
      key: const Key('purchaseScreen'),
      title: 'المشتريات',
      backgroundColor: tint,
      onBack: _attemptBack,
      onSearch: _showPurchaseSearch,
      onSave: hasSelectedInvoice
          ? _hasUnsavedChanges
              ? _update
              : null
          : _save,
      body: ColoredBox(
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
                    options: _purchaseWarehouseOptions,
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
                  AppTextField(
                    fieldKey: const Key('purchaseExchangeRateField'),
                    controller: _exchangeRateController,
                    label: 'سعر الصرف',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    enabled: _currency == 'USD',
                    readOnly: _currency != 'USD',
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
              _PurchaseFieldRow(
                children: [
                  AppAutocompleteField<String>(
                    fieldKey: const Key('purchaseSupplierNameField'),
                    controller: _supplierNameController,
                    label: 'اسم المجهز',
                    icon: Icons.person_search_rounded,
                    accentColor: AppModuleColors.purchases,
                    options: _purchaseSupplierOptions,
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
                  onSearch: _showPurchaseSearch,
                  onPrint: () {},
                  onPrintWithoutPrices:
                      hasSelectedInvoice ? () {} : null,
                  onStatement: _showPurchaseStatement,
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

class _PurchaseInvoiceButtons extends StatelessWidget {
  const _PurchaseInvoiceButtons({
    required this.onSearch,
    required this.onPrint,
    required this.onPrintWithoutPrices,
    required this.onStatement,
  });

  final VoidCallback onSearch;
  final VoidCallback onPrint;
  final VoidCallback? onPrintWithoutPrices;
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
    return AppTextField(
      fieldKey: fieldKey,
      controller: controller,
      label: label,
      icon: icon,
      accentColor: AppModuleColors.purchases,
      focusNode: focusNode,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        AppMoneyInputFormatter(decimalPlaces: decimalPlaces),
      ],
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
