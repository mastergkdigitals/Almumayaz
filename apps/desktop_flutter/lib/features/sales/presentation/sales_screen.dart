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
  var _warehouse = 'الرئيسي';
  var _saleType = 'نقدي';
  var _currency = 'IQD';

  @override
  void initState() {
    super.initState();
    _invoiceDateTime = DateTime.now();
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
    final tint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );

    return AppScreenShell(
      key: const Key('salesScreen'),
      title: 'المبيعات',
      backgroundColor: tint,
      onBack: () => Navigator.of(context).pop(),
      onSearch: () {},
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
                    textAlign: TextAlign.center,
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
                    textInputAction: TextInputAction.next,
                  ),
                  AppTextField(
                    fieldKey: const Key('salesNotesField'),
                    controller: _notesController,
                    label: 'الملاحظات',
                    icon: Icons.notes_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Expanded(
                child: AppSalesInvoiceTableTemplate(
                  key: Key('salesItemsTable'),
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
                    label: 'المجموع دينار',
                    icon: Icons.calculate_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('salesRemainingIqdField'),
                    controller: _remainingIqdController,
                    label: 'المتبقي دينار',
                    icon: Icons.pending_actions_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('salesCurrentBalanceIqdField'),
                    controller: _currentBalanceIqdController,
                    label: 'الرصيد الحالي دينار',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppActionBar(
                key: const Key('salesActionBar'),
                middle: const _SalesInvoiceButtons(),
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
  const _SalesInvoiceButtons();

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
          onPressed: () {},
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
          onPressed: () {},
        ),
        AppHeaderIconButton(
          key: const Key('salesStatementButton'),
          tooltipKey: const Key('salesStatementTooltip'),
          icon: Icons.receipt_long_rounded,
          tooltip: 'كشف الحساب',
          onPressed: () {},
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
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        AppMoneyInputFormatter(decimalPlaces: decimalPlaces),
      ],
      textInputAction: TextInputAction.next,
    );
  }
}
