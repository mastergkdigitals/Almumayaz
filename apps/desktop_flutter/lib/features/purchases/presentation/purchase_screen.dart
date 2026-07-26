import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

const _purchaseTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'local', label: 'محلي'),
  AppDropdownOption(value: 'import', label: 'استيراد'),
  AppDropdownOption(value: 'return', label: 'إرجاع'),
];

const _paymentTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'cash', label: 'نقد'),
  AppDropdownOption(value: 'credit', label: 'آجل'),
];

const _currencyOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'IQD', label: 'دينار'),
  AppDropdownOption(value: 'USD', label: 'دولار'),
];

const _warehouseOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الرئيسي', label: 'الرئيسي'),
  AppDropdownOption(value: 'الرصافة', label: 'الرصافة'),
  AppDropdownOption(value: 'الكرادة', label: 'الكرادة'),
  AppDropdownOption(value: 'المنصور', label: 'المنصور'),
];

const _supplierOptions = <_PurchaseSupplierOption>[
  _PurchaseSupplierOption(number: 1, name: 'شركة النخيل للتجارة'),
  _PurchaseSupplierOption(number: 3, name: 'مجهز الرافدين'),
  _PurchaseSupplierOption(number: 6, name: 'شركة الموصل الحديثة'),
  _PurchaseSupplierOption(number: 9, name: 'مجهز الفرات'),
];

class _PurchaseSupplierOption {
  const _PurchaseSupplierOption({
    required this.number,
    required this.name,
  });

  final int number;
  final String name;
}

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _invoiceNumberController = TextEditingController(text: '1');
  final _exchangeRateController = TextEditingController(text: '1');
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();
  final _expensesController = TextEditingController(text: '0');
  final _invoiceDiscountController = TextEditingController(text: '0');
  final _discountPercentController = TextEditingController(text: '0');
  final _paidAmountController = TextEditingController(text: '0');
  final _totalController = TextEditingController();
  final _remainingController = TextEditingController();
  final _supplierBalanceController = TextEditingController();
  final _savedInvoices = <_PurchaseFormData>[];

  late DateTime _invoiceDate;
  late TimeOfDay _invoiceTime;
  late _PurchaseFormData _baseline;
  String _warehouse = _warehouseOptions.first.value;
  String _purchaseType = 'local';
  String _paymentType = 'cash';
  String _currency = 'IQD';
  int? _selectedInvoiceIndex;
  bool _isApplyingData = false;
  bool _hasUnsavedChanges = false;

  Iterable<TextEditingController> get _editableControllers => [
        _invoiceNumberController,
        _exchangeRateController,
        _supplierController,
        _notesController,
        _expensesController,
        _invoiceDiscountController,
        _discountPercentController,
        _paidAmountController,
      ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _invoiceDate = DateTime(now.year, now.month, now.day);
    _invoiceTime = TimeOfDay.fromDateTime(now);
    for (final controller in _editableControllers) {
      controller.addListener(_handleDataChanged);
    }
    _refreshTotals();
    _baseline = _captureData();
  }

  @override
  void dispose() {
    for (final controller in _editableControllers) {
      controller.removeListener(_handleDataChanged);
    }
    _invoiceNumberController.dispose();
    _exchangeRateController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    _expensesController.dispose();
    _invoiceDiscountController.dispose();
    _discountPercentController.dispose();
    _paidAmountController.dispose();
    _totalController.dispose();
    _remainingController.dispose();
    _supplierBalanceController.dispose();
    super.dispose();
  }

  void _handleDataChanged() {
    if (_isApplyingData || !mounted) return;
    _refreshTotals();
    setState(() {
      _hasUnsavedChanges =
          _captureData().fingerprint != _baseline.fingerprint;
    });
  }

  void _refreshTotals() {
    _setComputedText(_totalController, _formatMoney(0));
    _setComputedText(_remainingController, _formatMoney(0));
    _setComputedText(_supplierBalanceController, _formatMoney(0));
  }

  void _setComputedText(
    TextEditingController controller,
    String value,
  ) {
    if (controller.text == value) return;
    controller.text = value;
  }

  String _formatMoney(double value) {
    return _currency == 'USD'
        ? AppFormatters.usd(value)
        : AppFormatters.iqd(value);
  }

  _PurchaseFormData _captureData() {
    return _PurchaseFormData(
      invoiceNumber: _invoiceNumberController.text,
      date: _invoiceDate,
      time: _invoiceTime,
      warehouse: _warehouse,
      purchaseType: _purchaseType,
      paymentType: _paymentType,
      currency: _currency,
      exchangeRate: _exchangeRateController.text,
      supplier: _supplierController.text,
      notes: _notesController.text,
      expenses: _expensesController.text,
      invoiceDiscount: _invoiceDiscountController.text,
      discountPercent: _discountPercentController.text,
      paidAmount: _paidAmountController.text,
    );
  }

  void _applyData(
    _PurchaseFormData data, {
    required bool markClean,
  }) {
    _isApplyingData = true;
    _invoiceNumberController.text = data.invoiceNumber;
    _invoiceDate = data.date;
    _invoiceTime = data.time;
    _warehouse = data.warehouse;
    _purchaseType = data.purchaseType;
    _paymentType = data.paymentType;
    _currency = data.currency;
    _exchangeRateController.text = data.exchangeRate;
    _supplierController.text = data.supplier;
    _notesController.text = data.notes;
    _expensesController.text = data.expenses;
    _invoiceDiscountController.text = data.invoiceDiscount;
    _discountPercentController.text = data.discountPercent;
    _paidAmountController.text = data.paidAmount;
    _isApplyingData = false;
    _refreshTotals();

    setState(() {
      if (markClean) _baseline = data;
      _hasUnsavedChanges =
          _captureData().fingerprint != _baseline.fingerprint;
    });
  }

  void _changeDate(DateTime value) {
    setState(() {
      _invoiceDate = value;
      _hasUnsavedChanges =
          _captureData().fingerprint != _baseline.fingerprint;
    });
  }

  void _changeWarehouse(String? value) {
    if (value == null || value == _warehouse) return;
    setState(() {
      _warehouse = value;
      _hasUnsavedChanges =
          _captureData().fingerprint != _baseline.fingerprint;
    });
  }

  void _changePurchaseType(String? value) {
    if (value == null || value == _purchaseType) return;
    setState(() {
      _purchaseType = value;
      _hasUnsavedChanges =
          _captureData().fingerprint != _baseline.fingerprint;
    });
  }

  void _changePaymentType(String? value) {
    if (value == null || value == _paymentType) return;
    setState(() {
      _paymentType = value;
      _hasUnsavedChanges =
          _captureData().fingerprint != _baseline.fingerprint;
    });
  }

  void _changeCurrency(String? value) {
    if (value == null || value == _currency) return;
    _isApplyingData = true;
    _currency = value;
    if (_currency == 'IQD') {
      _exchangeRateController.text = '1';
    }
    _isApplyingData = false;
    _refreshTotals();
    setState(() {
      _hasUnsavedChanges =
          _captureData().fingerprint != _baseline.fingerprint;
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

  void _newInvoice() {
    unawaited(_newInvoiceAfterConfirmation());
  }

  Future<void> _newInvoiceAfterConfirmation() async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    _selectedInvoiceIndex = null;
    _applyData(_newInvoiceData(), markClean: true);
  }

  _PurchaseFormData _newInvoiceData() {
    final now = DateTime.now();
    return _PurchaseFormData(
      invoiceNumber: _nextInvoiceNumber.toString(),
      date: DateTime(now.year, now.month, now.day),
      time: TimeOfDay.fromDateTime(now),
      warehouse: _warehouseOptions.first.value,
      purchaseType: 'local',
      paymentType: 'cash',
      currency: 'IQD',
      exchangeRate: '1',
      supplier: '',
      notes: '',
      expenses: '0',
      invoiceDiscount: '0',
      discountPercent: '0',
      paidAmount: '0',
    );
  }

  int get _nextInvoiceNumber {
    var greatest = 0;
    for (final invoice in _savedInvoices) {
      final number = AppFormatters.parseInteger(invoice.invoiceNumber) ?? 0;
      if (number > greatest) greatest = number;
    }
    return greatest + 1;
  }

  bool _validateInvoice() {
    if (_supplierController.text.trim().isEmpty) {
      AppToast.showWarning(context, 'اختر اسم المجهز أولاً');
      return false;
    }
    return true;
  }

  void _save() {
    if (!_validateInvoice()) return;
    final data = _captureData();
    setState(() {
      _savedInvoices.add(data);
      _selectedInvoiceIndex = _savedInvoices.length - 1;
      _baseline = data;
      _hasUnsavedChanges = false;
    });
    AppToast.showSuccess(context, 'تم حفظ بيانات فاتورة الشراء مؤقتاً');
  }

  void _update() {
    final selectedIndex = _selectedInvoiceIndex;
    if (selectedIndex == null || !_validateInvoice()) return;

    final data = _captureData();
    setState(() {
      _savedInvoices[selectedIndex] = data;
      _baseline = data;
      _hasUnsavedChanges = false;
    });
    AppToast.showSuccess(context, 'تم تحديث بيانات فاتورة الشراء مؤقتاً');
  }

  void _undo() {
    _applyData(_baseline, markClean: true);
    AppToast.showWarning(context, 'تم التراجع عن التغييرات');
  }

  Future<void> _delete() async {
    final selectedIndex = _selectedInvoiceIndex;
    if (selectedIndex == null) return;

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف فاتورة الشراء',
      message: 'هل تريد حذف فاتورة الشراء المحددة؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted || !confirmed) return;

    _savedInvoices.removeAt(selectedIndex);
    _selectedInvoiceIndex = null;
    _applyData(_newInvoiceData(), markClean: true);
    AppToast.showDanger(context, 'تم حذف فاتورة الشراء مؤقتاً');
  }

  List<int> get _visibleInvoiceIndexes {
    return [
      for (var index = 0; index < _savedInvoices.length; index++) index,
    ];
  }

  int get _selectedVisiblePosition {
    final selectedIndex = _selectedInvoiceIndex;
    if (selectedIndex == null) return -1;
    return _visibleInvoiceIndexes.indexOf(selectedIndex);
  }

  void _loadInvoice(int index) {
    unawaited(_loadInvoiceAfterConfirmation(index));
  }

  Future<void> _loadInvoiceAfterConfirmation(int index) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    _selectedInvoiceIndex = index;
    _applyData(_savedInvoices[index], markClean: true);
  }

  void _first() {
    final indexes = _visibleInvoiceIndexes;
    if (indexes.isNotEmpty) _loadInvoice(indexes.first);
  }

  void _previous() {
    final indexes = _visibleInvoiceIndexes;
    final position = _selectedVisiblePosition;
    if (indexes.isEmpty) return;
    _loadInvoice(indexes[position <= 0 ? 0 : position - 1]);
  }

  void _next() {
    final indexes = _visibleInvoiceIndexes;
    final position = _selectedVisiblePosition;
    if (position >= 0 && position < indexes.length - 1) {
      _loadInvoice(indexes[position + 1]);
    }
  }

  void _last() {
    final indexes = _visibleInvoiceIndexes;
    if (indexes.isNotEmpty) _loadInvoice(indexes.last);
  }

  Future<void> _openInvoiceSearchDialog() async {
    final invoice = await AppRecordSearchDialog.show<_PurchaseFormData>(
      context,
      title: 'بحث قوائم الشراء',
      hint: 'اسم المجهز أو رقم القائمة أو الملاحظات',
      accentColor: AppModuleColors.purchases,
      records: [
        for (final savedInvoice in _savedInvoices)
          AppSearchRecord(
            value: savedInvoice,
            title: 'قائمة شراء رقم ${savedInvoice.invoiceNumber}',
            subtitle: savedInvoice.supplier.trim().isEmpty
                ? 'بدون مجهز'
                : savedInvoice.supplier,
            details:
                '${AppFormatters.date(savedInvoice.date)} • '
                '${savedInvoice.warehouse}',
            searchTerms: [
              savedInvoice.invoiceNumber,
              savedInvoice.supplier,
              savedInvoice.notes,
            ],
          ),
      ],
      emptyTitle: 'لا توجد قوائم شراء محفوظة',
      noResultsTitle: 'لا توجد قوائم شراء مطابقة',
      dialogKey: const Key('purchaseSearchDialog'),
      searchFieldKey: const Key('purchaseSearchField'),
      resultKeyPrefix: 'purchaseSearchResult',
    );

    if (!mounted || invoice == null) return;
    final index = _savedInvoices.indexOf(invoice);
    if (index >= 0) _loadInvoice(index);
  }

  void _showPrintMessage({required bool withoutPrices}) {
    if (_selectedInvoiceIndex == null) {
      AppToast.showWarning(context, 'احفظ فاتورة الشراء قبل الطباعة');
      return;
    }
    AppToast.showInfo(
      context,
      withoutPrices
          ? 'سيتم ربط الطباعة بدون أسعار لاحقاً'
          : 'سيتم ربط طباعة فاتورة الشراء لاحقاً',
    );
  }

  void _showSupplierStatement() {
    final supplier = _supplierController.text.trim();
    if (supplier.isEmpty) {
      AppToast.showWarning(context, 'اختر مجهزاً لعرض كشف الحساب');
      return;
    }
    AppToast.showInfo(context, 'سيتم ربط كشف حساب $supplier لاحقاً');
  }

  @override
  Widget build(BuildContext context) {
    final visibleIndexes = _visibleInvoiceIndexes;
    final selectedPosition = _selectedVisiblePosition;
    final hasSelectedInvoice = _selectedInvoiceIndex != null;
    final canMoveBackward =
        visibleIndexes.isNotEmpty && selectedPosition != 0;
    final canMoveForward =
        selectedPosition >= 0 && selectedPosition < visibleIndexes.length - 1;
    final currencyName = AppFormatters.currency(_currency);

    return AppScreenShell(
      key: const Key('purchaseScreen'),
      title: 'المشتريات',
      subtitle: 'إدارة فواتير الشراء من المجهزين',
      backgroundColor: Color.alphaBlend(
        AppModuleColors.purchases.withAlpha(12),
        AppColors.surface,
      ),
      onBack: _attemptBack,
      onSearch: _openInvoiceSearchDialog,
      onSave: hasSelectedInvoice
          ? _hasUnsavedChanges
              ? _update
              : null
          : _save,
      onNew: _newInvoice,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PurchaseHeaderPanel(
              invoiceNumberController: _invoiceNumberController,
              invoiceDate: _invoiceDate,
              invoiceTime: _invoiceTime,
              warehouse: _warehouse,
              purchaseType: _purchaseType,
              paymentType: _paymentType,
              currency: _currency,
              exchangeRateController: _exchangeRateController,
              supplierController: _supplierController,
              notesController: _notesController,
              onDateChanged: _changeDate,
              onWarehouseChanged: _changeWarehouse,
              onPurchaseTypeChanged: _changePurchaseType,
              onPaymentTypeChanged: _changePaymentType,
              onCurrencyChanged: _changeCurrency,
            ),
            const Expanded(
              child: SizedBox(
                key: Key('purchaseFutureTableSpace'),
              ),
            ),
            _PurchaseTotalsPanel(
              expensesController: _expensesController,
              invoiceDiscountController: _invoiceDiscountController,
              discountPercentController: _discountPercentController,
              paidAmountController: _paidAmountController,
              totalController: _totalController,
              remainingController: _remainingController,
              supplierBalanceController: _supplierBalanceController,
              currencyName: currencyName,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppActionBar(
              key: const Key('purchaseActionBar'),
              navigationButtonWidth: 92,
              buttonWidth: 92,
              middle: _PurchaseUtilityButtons(
                onSearch: _openInvoiceSearchDialog,
                onPrint: hasSelectedInvoice
                    ? () => _showPrintMessage(withoutPrices: false)
                    : null,
                onPrintWithoutPrices: hasSelectedInvoice
                    ? () => _showPrintMessage(withoutPrices: true)
                    : null,
                onSupplierStatement:
                    _supplierController.text.trim().isNotEmpty
                        ? _showSupplierStatement
                        : null,
              ),
              firstButtonKey: const Key('purchaseFirstButton'),
              previousButtonKey: const Key('purchasePreviousButton'),
              nextButtonKey: const Key('purchaseNextButton'),
              lastButtonKey: const Key('purchaseLastButton'),
              saveButtonKey: const Key('purchaseSaveButton'),
              updateButtonKey: const Key('purchaseUpdateButton'),
              undoButtonKey: const Key('purchaseUndoButton'),
              deleteButtonKey: const Key('purchaseDeleteButton'),
              onFirst: canMoveBackward ? _first : null,
              onPrevious: canMoveBackward ? _previous : null,
              onNext: canMoveForward ? _next : null,
              onLast: canMoveForward ? _last : null,
              onSave: hasSelectedInvoice ? null : _save,
              onUpdate:
                  hasSelectedInvoice && _hasUnsavedChanges ? _update : null,
              onUndo: _hasUnsavedChanges ? _undo : null,
              onDelete: hasSelectedInvoice ? _delete : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseHeaderPanel extends StatelessWidget {
  const _PurchaseHeaderPanel({
    required this.invoiceNumberController,
    required this.invoiceDate,
    required this.invoiceTime,
    required this.warehouse,
    required this.purchaseType,
    required this.paymentType,
    required this.currency,
    required this.exchangeRateController,
    required this.supplierController,
    required this.notesController,
    required this.onDateChanged,
    required this.onWarehouseChanged,
    required this.onPurchaseTypeChanged,
    required this.onPaymentTypeChanged,
    required this.onCurrencyChanged,
  });

  final TextEditingController invoiceNumberController;
  final DateTime invoiceDate;
  final TimeOfDay invoiceTime;
  final String warehouse;
  final String purchaseType;
  final String paymentType;
  final String currency;
  final TextEditingController exchangeRateController;
  final TextEditingController supplierController;
  final TextEditingController notesController;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String?> onWarehouseChanged;
  final ValueChanged<String?> onPurchaseTypeChanged;
  final ValueChanged<String?> onPaymentTypeChanged;
  final ValueChanged<String?> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return _PurchasePanel(
      panelKey: const Key('purchaseHeaderPanel'),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  fieldKey: const Key('purchaseInvoiceNumberField'),
                  controller: invoiceNumberController,
                  label: 'رقم القائمة',
                  icon: Icons.tag_rounded,
                  accentColor: AppModuleColors.purchases,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [AppIntegerInputFormatter()],
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppDateField(
                  fieldKey: const Key('purchaseDateField'),
                  label: 'التاريخ',
                  value: invoiceDate,
                  accentColor: AppModuleColors.purchases,
                  onChanged: onDateChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTimeField(
                  fieldKey: const Key('purchaseTimeField'),
                  label: 'الوقت',
                  value: invoiceTime,
                  accentColor: AppModuleColors.purchases,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppDropdownField<String>(
                  fieldKey: const Key('purchaseWarehouseField'),
                  label: 'المخزن',
                  icon: Icons.warehouse_rounded,
                  accentColor: AppModuleColors.purchases,
                  value: warehouse,
                  options: _warehouseOptions,
                  onChanged: onWarehouseChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppDropdownField<String>(
                  fieldKey: const Key('purchaseTypeField'),
                  label: 'نوع الشراء',
                  icon: Icons.shopping_cart_checkout_rounded,
                  accentColor: AppModuleColors.purchases,
                  value: purchaseType,
                  options: _purchaseTypeOptions,
                  onChanged: onPurchaseTypeChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppDropdownField<String>(
                  fieldKey: const Key('purchasePaymentTypeField'),
                  label: 'نوع الدفع',
                  icon: Icons.payments_outlined,
                  accentColor: AppModuleColors.purchases,
                  value: paymentType,
                  options: _paymentTypeOptions,
                  onChanged: onPaymentTypeChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppDropdownField<String>(
                  fieldKey: const Key('purchaseCurrencyField'),
                  label: 'العملة',
                  icon: Icons.currency_exchange_rounded,
                  accentColor: AppModuleColors.purchases,
                  value: currency,
                  options: _currencyOptions,
                  onChanged: onCurrencyChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  fieldKey: const Key('purchaseExchangeRateField'),
                  controller: exchangeRateController,
                  label: 'سعر الصرف',
                  icon: Icons.price_change_outlined,
                  accentColor: AppModuleColors.purchases,
                  enabled: currency == 'USD',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const [AppMoneyInputFormatter()],
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppSearchableDropdownField<_PurchaseSupplierOption>(
                  fieldKey: const Key('purchaseSupplierField'),
                  controller: supplierController,
                  label: 'اسم المجهز',
                  hint: 'اكتب اسم أو رقم المجهز',
                  icon: Icons.person_search_rounded,
                  accentColor: AppModuleColors.purchases,
                  options: _supplierOptions,
                  displayStringForOption: (supplier) => supplier.name,
                  searchTermsForOption: (supplier) => [
                    supplier.name,
                    supplier.number.toString(),
                  ],
                  optionSubtitle: (supplier) =>
                      'رقم المجهز: ${supplier.number}',
                  onSelected: (_) {},
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: AppTextField(
                  fieldKey: const Key('purchaseNotesField'),
                  controller: notesController,
                  label: 'الملاحظات',
                  icon: Icons.notes_rounded,
                  accentColor: AppModuleColors.purchases,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseUtilityButtons extends StatelessWidget {
  const _PurchaseUtilityButtons({
    required this.onSearch,
    required this.onPrint,
    required this.onPrintWithoutPrices,
    required this.onSupplierStatement,
  });

  static const _textStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  final VoidCallback onSearch;
  final VoidCallback? onPrint;
  final VoidCallback? onPrintWithoutPrices;
  final VoidCallback? onSupplierStatement;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        AppButton(
          key: const Key('purchaseSearchButton'),
          label: 'بحث',
          icon: Icons.search_rounded,
          variant: AppButtonVariant.navigation,
          minWidth: 78,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          iconSize: 18,
          iconSpacing: AppSpacing.xs,
          textStyle: _textStyle,
          onPressed: onSearch,
        ),
        AppButton(
          key: const Key('purchasePrintButton'),
          label: 'طباعة',
          icon: Icons.print_rounded,
          variant: AppButtonVariant.navigation,
          minWidth: 84,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          iconSize: 18,
          iconSpacing: AppSpacing.xs,
          textStyle: _textStyle,
          onPressed: onPrint,
        ),
        AppButton(
          key: const Key('purchasePrintWithoutPricesButton'),
          label: 'طباعة بدون الأسعار',
          icon: Icons.money_off_rounded,
          variant: AppButtonVariant.navigation,
          minWidth: 176,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          iconSize: 18,
          iconSpacing: AppSpacing.xs,
          textStyle: _textStyle,
          onPressed: onPrintWithoutPrices,
        ),
        AppButton(
          key: const Key('purchaseStatementButton'),
          label: 'كشف حساب المجهز',
          icon: Icons.receipt_long_outlined,
          variant: AppButtonVariant.navigation,
          minWidth: 182,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          iconSize: 18,
          iconSpacing: AppSpacing.xs,
          textStyle: _textStyle,
          onPressed: onSupplierStatement,
        ),
      ],
    );
  }
}

class _PurchaseTotalsPanel extends StatelessWidget {
  const _PurchaseTotalsPanel({
    required this.expensesController,
    required this.invoiceDiscountController,
    required this.discountPercentController,
    required this.paidAmountController,
    required this.totalController,
    required this.remainingController,
    required this.supplierBalanceController,
    required this.currencyName,
  });

  final TextEditingController expensesController;
  final TextEditingController invoiceDiscountController;
  final TextEditingController discountPercentController;
  final TextEditingController paidAmountController;
  final TextEditingController totalController;
  final TextEditingController remainingController;
  final TextEditingController supplierBalanceController;
  final String currencyName;

  @override
  Widget build(BuildContext context) {
    return _PurchasePanel(
      panelKey: const Key('purchaseTotalsPanel'),
      child: Row(
        children: [
          Expanded(
            child: _moneyField(
              key: const Key('purchaseExpensesField'),
              controller: expensesController,
              label: 'المصاريف',
              icon: Icons.payments_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _moneyField(
              key: const Key('purchaseInvoiceDiscountField'),
              controller: invoiceDiscountController,
              label: 'خصم الفاتورة',
              icon: Icons.local_offer_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _moneyField(
              key: const Key('purchaseDiscountPercentField'),
              controller: discountPercentController,
              label: 'نسبة الخصم',
              icon: Icons.percent_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _moneyField(
              key: const Key('purchasePaidAmountField'),
              controller: paidAmountController,
              label: 'الواصل',
              icon: Icons.south_west_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppReadOnlyField(
              fieldKey: const Key('purchaseTotalField'),
              controller: totalController,
              label: 'المجموع $currencyName',
              icon: Icons.account_balance_wallet_outlined,
              accentColor: AppModuleColors.purchases,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppReadOnlyField(
              fieldKey: const Key('purchaseRemainingField'),
              controller: remainingController,
              label: 'المتبقي $currencyName',
              icon: Icons.pending_actions_rounded,
              accentColor: AppModuleColors.purchases,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppReadOnlyField(
              fieldKey: const Key('purchaseSupplierBalanceField'),
              controller: supplierBalanceController,
              label: 'الرصيد الحالي $currencyName',
              icon: Icons.account_balance_rounded,
              accentColor: AppModuleColors.purchases,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _moneyField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return AppTextField(
      fieldKey: key,
      controller: controller,
      label: label,
      icon: icon,
      accentColor: AppModuleColors.purchases,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: const [AppMoneyInputFormatter()],
      textInputAction: TextInputAction.next,
    );
  }
}

class _PurchasePanel extends StatelessWidget {
  const _PurchasePanel({
    required this.panelKey,
    required this.child,
  });

  final Key panelKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderColor = Color.alphaBlend(
      AppModuleColors.purchases.withAlpha(96),
      AppColors.border,
    );
    final backgroundColor = Color.alphaBlend(
      AppModuleColors.purchases.withAlpha(8),
      AppColors.surface,
    );

    return Container(
      key: panelKey,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _PurchaseFormData {
  const _PurchaseFormData({
    required this.invoiceNumber,
    required this.date,
    required this.time,
    required this.warehouse,
    required this.purchaseType,
    required this.paymentType,
    required this.currency,
    required this.exchangeRate,
    required this.supplier,
    required this.notes,
    required this.expenses,
    required this.invoiceDiscount,
    required this.discountPercent,
    required this.paidAmount,
  });

  final String invoiceNumber;
  final DateTime date;
  final TimeOfDay time;
  final String warehouse;
  final String purchaseType;
  final String paymentType;
  final String currency;
  final String exchangeRate;
  final String supplier;
  final String notes;
  final String expenses;
  final String invoiceDiscount;
  final String discountPercent;
  final String paidAmount;

  String get fingerprint => [
        invoiceNumber,
        date.millisecondsSinceEpoch,
        time.hour,
        time.minute,
        warehouse,
        purchaseType,
        paymentType,
        currency,
        exchangeRate,
        supplier,
        notes,
        expenses,
        invoiceDiscount,
        discountPercent,
        paidAmount,
      ].join('\u001e');
}
