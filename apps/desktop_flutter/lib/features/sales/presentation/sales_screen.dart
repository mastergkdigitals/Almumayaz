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
];

final _salesSearchRecords = <AppSearchRecord<String>>[
  for (final invoice in _demoSalesInvoices)
    AppSearchRecord(
      value: invoice.id,
      title: 'قائمة بيع رقم ${invoice.id}',
      subtitle: invoice.customerName,
      details: invoice.searchDetails,
      searchTerms: invoice.searchTerms,
      icon: Icons.point_of_sale_rounded,
    ),
];

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

  late DateTime _invoiceDateTime;
  late _DemoSalesInvoice _selectedDemoInvoice;
  var _warehouse = 'الرئيسي';
  var _saleType = 'نقدي';
  var _currency = 'IQD';
  var _tableDataVersion = 0;

  @override
  void initState() {
    super.initState();
    _applyDemoInvoice(_demoSalesInvoices.first);
  }

  void _applyDemoInvoice(_DemoSalesInvoice invoice) {
    _selectedDemoInvoice = invoice;
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
    _tableDataVersion++;
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
    });
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
    final invoice = _demoSalesInvoices.firstWhere(
      (candidate) => candidate.id == result,
    );
    setState(() => _applyDemoInvoice(invoice));
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
    final currencyName = _currency == 'USD' ? 'دولار' : 'دينار';
    final tint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );

    return AppScreenShell(
      key: const Key('salesScreen'),
      title: 'المبيعات',
      backgroundColor: tint,
      onBack: () => Navigator.of(context).pop(),
      onSearch: _showSalesSearch,
      onSave: () {},
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
                      setState(() => _warehouse = value);
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
                      setState(() => _saleType = value);
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
                      setState(() => _currency = value);
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
                  initialRows: _selectedDemoInvoice.items,
                  dataVersion: _tableDataVersion,
                  summaryQuantity: _selectedDemoInvoice.summaryQuantity,
                  summaryDiscount: _selectedDemoInvoice.summaryDiscount,
                  summaryTotal: _selectedDemoInvoice.summaryTotal,
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
                onFirst: () {},
                onPrevious: () {},
                onNext: () {},
                onLast: () {},
                onSave: () {},
                onUpdate: () {},
                onUndo: () {},
                onDelete: () {},
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
