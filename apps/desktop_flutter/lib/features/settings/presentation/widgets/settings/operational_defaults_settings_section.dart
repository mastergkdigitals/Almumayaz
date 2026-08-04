part of '../settings_sections.dart';

const _settingsWarehouseOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الرئيسي', label: 'الرئيسي'),
  AppDropdownOption(value: 'الرصافة', label: 'الرصافة'),
  AppDropdownOption(value: 'الكرادة', label: 'الكرادة'),
  AppDropdownOption(value: 'المنصور', label: 'المنصور'),
];

const _settingsCurrencyOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'IQD', label: 'دينار'),
  AppDropdownOption(value: 'USD', label: 'دولار'),
];

const _settingsPurchaseTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'محلي', label: 'محلي'),
  AppDropdownOption(value: 'إستيراد', label: 'إستيراد'),
  AppDropdownOption(value: 'إرجاع', label: 'إرجاع'),
];

const _settingsPaymentTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'نقدي', label: 'نقدي'),
  AppDropdownOption(value: 'آجل', label: 'آجل'),
];

const _settingsSaleTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'نقدي', label: 'نقدي'),
  AppDropdownOption(value: 'آجل', label: 'آجل'),
  AppDropdownOption(value: 'أقساط', label: 'أقساط'),
];

const _settingsVoucherTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'قبض', label: 'قبض'),
  AppDropdownOption(value: 'صرف', label: 'صرف'),
];

const _settingsCashboxAccountOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'الصندوق الرئيسي', label: 'الصندوق الرئيسي'),
  AppDropdownOption(value: 'المصاريف العامة', label: 'المصاريف العامة'),
  AppDropdownOption(value: 'حساب الأطراف', label: 'حساب الأطراف'),
];

class OperationalDefaultsSettingsSection extends StatefulWidget {
  const OperationalDefaultsSettingsSection({
    required this.accentColor,
    super.key,
  });

  final Color accentColor;

  @override
  State<OperationalDefaultsSettingsSection> createState() =>
      _OperationalDefaultsSettingsSectionState();
}
class _OperationalDefaultsSettingsSectionState
    extends State<OperationalDefaultsSettingsSection> {
  var _purchaseWarehouse = 'الرئيسي';
  var _purchaseType = 'محلي';
  var _purchasePaymentType = 'نقدي';
  var _purchaseCurrency = 'IQD';
  var _salesWarehouse = 'الرئيسي';
  var _saleType = 'نقدي';
  var _salesCurrency = 'IQD';
  var _voucherType = 'قبض';
  var _cashboxAccount = 'الصندوق الرئيسي';

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('operationalDefaultsSettingsContent'),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SettingsResponsiveGrid(
          preferredColumns: 3,
          minimumChildHeight: 480,
          children: [
            SettingsTemplatePanel(
              key: const Key('settingsPurchaseDefaultsPanel'),
              title: 'المشتريات',
              icon: Icons.shopping_cart_checkout_rounded,
              accentColor: widget.accentColor,
              child: Column(
                children: [
                  _dropdown(
                    key: 'settingsPurchaseDefaultWarehouse',
                    label: 'المخزن الافتراضي',
                    icon: Icons.warehouse_rounded,
                    accentColor: widget.accentColor,
                    value: _purchaseWarehouse,
                    options: _settingsWarehouseOptions,
                    onChanged: (value) {
                      setState(() => _purchaseWarehouse = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsPurchaseDefaultType',
                    label: 'نوع الشراء الافتراضي',
                    icon: Icons.sell_outlined,
                    accentColor: widget.accentColor,
                    value: _purchaseType,
                    options: _settingsPurchaseTypeOptions,
                    onChanged: (value) {
                      setState(() => _purchaseType = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsPurchaseDefaultPayment',
                    label: 'نوع الدفع الافتراضي',
                    icon: Icons.payments_outlined,
                    accentColor: widget.accentColor,
                    value: _purchasePaymentType,
                    options: _settingsPaymentTypeOptions,
                    onChanged: (value) {
                      setState(() => _purchasePaymentType = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsPurchaseDefaultCurrency',
                    label: 'العملة الافتراضية',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: widget.accentColor,
                    value: _purchaseCurrency,
                    options: _settingsCurrencyOptions,
                    onChanged: (value) {
                      setState(() => _purchaseCurrency = value);
                    },
                  ),
                ],
              ),
            ),
            SettingsTemplatePanel(
              key: const Key('settingsSalesDefaultsPanel'),
              title: 'المبيعات',
              icon: Icons.point_of_sale_rounded,
              accentColor: widget.accentColor,
              child: Column(
                children: [
                  _dropdown(
                    key: 'settingsSalesDefaultWarehouse',
                    label: 'المخزن الافتراضي',
                    icon: Icons.warehouse_rounded,
                    accentColor: widget.accentColor,
                    value: _salesWarehouse,
                    options: _settingsWarehouseOptions,
                    onChanged: (value) {
                      setState(() => _salesWarehouse = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsSalesDefaultType',
                    label: 'نوع البيع الافتراضي',
                    icon: Icons.sell_outlined,
                    accentColor: widget.accentColor,
                    value: _saleType,
                    options: _settingsSaleTypeOptions,
                    onChanged: (value) {
                      setState(() => _saleType = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsSalesDefaultCurrency',
                    label: 'العملة الافتراضية',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: widget.accentColor,
                    value: _salesCurrency,
                    options: _settingsCurrencyOptions,
                    onChanged: (value) {
                      setState(() => _salesCurrency = value);
                    },
                  ),
                ],
              ),
            ),
            SettingsTemplatePanel(
              key: const Key('settingsCashboxDefaultsPanel'),
              title: 'الصندوق',
              icon: Icons.account_balance_wallet_rounded,
              accentColor: widget.accentColor,
              child: Column(
                children: [
                  _dropdown(
                    key: 'settingsCashboxDefaultVoucherType',
                    label: 'نوع الحركة الافتراضي',
                    icon: Icons.swap_vert_circle_outlined,
                    accentColor: widget.accentColor,
                    value: _voucherType,
                    options: _settingsVoucherTypeOptions,
                    onChanged: (value) {
                      setState(() => _voucherType = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsCashboxDefaultAccount',
                    label: 'الحساب الرئيسي الافتراضي',
                    icon: Icons.account_tree_outlined,
                    accentColor: widget.accentColor,
                    value: _cashboxAccount,
                    options: _settingsCashboxAccountOptions,
                    onChanged: (value) {
                      setState(() => _cashboxAccount = value);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            key: const Key('settingsSaveOperationalDefaults'),
            label: 'حفظ الإعدادات',
            icon: Icons.save_outlined,
            variant: AppButtonVariant.primary,
            minWidth: 170,
            onPressed: () {
              AppToast.showInfo(
                context,
                'تم حفظ الإعدادات الافتراضية مؤقتاً',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String key,
    required String label,
    required IconData icon,
    required Color accentColor,
    required String value,
    required List<AppDropdownOption<String>> options,
    required ValueChanged<String> onChanged,
  }) {
    return AppDropdownField<String>(
      fieldKey: Key(key),
      label: label,
      icon: icon,
      accentColor: accentColor,
      value: value,
      options: options,
      useIntrinsicHeight: true,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      menuTextDirection: TextDirection.rtl,
      onChanged: (selected) {
        if (selected == null || selected == value) return;
        onChanged(selected);
      },
    );
  }
}
