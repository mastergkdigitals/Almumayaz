import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';

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

class BusinessPoliciesSettingsSection extends StatefulWidget {
  const BusinessPoliciesSettingsSection({
    required this.accentColor,
    super.key,
  });

  final Color accentColor;

  @override
  State<BusinessPoliciesSettingsSection> createState() =>
      _BusinessPoliciesSettingsSectionState();
}

class _BusinessPoliciesSettingsSectionState
    extends State<BusinessPoliciesSettingsSection> {
  final _exchangeRateController = TextEditingController(text: '1,310');
  final _customerDebtLimitController =
      TextEditingController(text: '5,000,000');
  final _debtDueDaysController = TextEditingController(text: '30');
  final _copiesController = TextEditingController(text: '1');
  var _allowInsufficientStockSale = false;
  var _overdueDebtAlerts = true;
  var _printer = 'Microsoft Print to PDF';
  var _paperSize = 'A4';
  var _previewEnabled = true;

  @override
  void dispose() {
    _exchangeRateController.dispose();
    _customerDebtLimitController.dispose();
    _debtDueDaysController.dispose();
    _copiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('businessPoliciesSettingsContent'),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SettingsResponsiveGrid(
          preferredColumns: 2,
          minimumChildHeight: 330,
          children: [
            SettingsTemplatePanel(
              key: const Key('settingsPricingInventoryPanel'),
              title: 'الأسعار والمخزون',
              icon: Icons.currency_exchange_rounded,
              accentColor: widget.accentColor,
              child: Column(
                children: [
                  AppTextField(
                    fieldKey:
                        const Key('settingsDefaultExchangeRateField'),
                    controller: _exchangeRateController,
                    label: 'سعر الصرف الافتراضي',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: widget.accentColor,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [
                      AppMoneyInputFormatter(decimalPlaces: 4),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSwitchField(
                    key: const Key('settingsAllowInsufficientStockSale'),
                    title: 'السماح بالبيع عند عدم كفاية المخزون',
                    subtitle:
                        'يظهر تنبيه قبل إكمال البيع عندما تكون الكمية غير كافية',
                    icon: Icons.inventory_2_outlined,
                    accentColor: widget.accentColor,
                    value: _allowInsufficientStockSale,
                    onChanged: (value) {
                      setState(() => _allowInsufficientStockSale = value);
                    },
                  ),
                ],
              ),
            ),
            SettingsTemplatePanel(
              key: const Key('settingsDebtInstallmentsPanel'),
              title: 'الديون والأقساط',
              icon: Icons.account_balance_wallet_outlined,
              accentColor: widget.accentColor,
              child: Column(
                children: [
                  AppTextField(
                    fieldKey:
                        const Key('settingsDefaultCustomerDebtLimitField'),
                    controller: _customerDebtLimitController,
                    label: 'حد الدين الافتراضي للزبون',
                    icon: Icons.credit_score_rounded,
                    accentColor: widget.accentColor,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [
                      AppMoneyInputFormatter(decimalPlaces: 0),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    fieldKey: const Key('settingsDefaultDebtDueDaysField'),
                    controller: _debtDueDaysController,
                    label: 'مدة استحقاق الدين الافتراضية بالأيام',
                    icon: Icons.event_repeat_rounded,
                    accentColor: widget.accentColor,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [AppIntegerInputFormatter()],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSwitchField(
                    key: const Key('settingsOverdueDebtAlerts'),
                    title: 'تنبيه الديون أو الأقساط المتأخرة',
                    subtitle: 'إظهار تنبيه عند تجاوز تاريخ الاستحقاق',
                    icon: Icons.notifications_active_outlined,
                    accentColor: widget.accentColor,
                    value: _overdueDebtAlerts,
                    onChanged: (value) {
                      setState(() => _overdueDebtAlerts = value);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildPrintingPanel(),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            key: const Key('settingsSaveBusinessPolicies'),
            label: 'حفظ السياسات والطباعة',
            icon: Icons.save_outlined,
            variant: AppButtonVariant.primary,
            minWidth: 215,
            onPressed: () {
              AppToast.showInfo(
                context,
                'تم حفظ سياسات العمل والطباعة مؤقتاً',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrintingPanel() {
    return SettingsTemplatePanel(
      key: const Key('settingsPrintingPanel'),
      title: 'الطباعة',
      icon: Icons.print_rounded,
      accentColor: widget.accentColor,
      child: SettingsResponsiveGrid(
        preferredColumns: 2,
        children: [
          AppDropdownField<String>(
            fieldKey: const Key('settingsDefaultPrinterField'),
            label: 'الطابعة الافتراضية',
            icon: Icons.print_outlined,
            accentColor: widget.accentColor,
            value: _printer,
            options: const [
              AppDropdownOption(
                value: 'Microsoft Print to PDF',
                label: 'Microsoft Print to PDF',
              ),
              AppDropdownOption(
                value: 'HP LaserJet Pro',
                label: 'HP LaserJet Pro',
              ),
              AppDropdownOption(
                value: 'Canon Office Printer',
                label: 'Canon Office Printer',
              ),
            ],
            useIntrinsicHeight: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            menuTextDirection: TextDirection.rtl,
            onChanged: (value) {
              if (value == null || value == _printer) return;
              setState(() => _printer = value);
            },
          ),
          AppDropdownField<String>(
            fieldKey: const Key('settingsPaperSizeField'),
            label: 'حجم الورق',
            icon: Icons.description_outlined,
            accentColor: widget.accentColor,
            value: _paperSize,
            options: const [
              AppDropdownOption(value: 'A4', label: 'A4'),
              AppDropdownOption(value: 'A5', label: 'A5'),
            ],
            useIntrinsicHeight: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            menuTextDirection: TextDirection.rtl,
            onChanged: (value) {
              if (value == null || value == _paperSize) return;
              setState(() => _paperSize = value);
            },
          ),
          AppTextField(
            fieldKey: const Key('settingsPrintCopiesField'),
            controller: _copiesController,
            label: 'عدد النسخ',
            icon: Icons.copy_all_outlined,
            accentColor: widget.accentColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            inputFormatters: const [AppIntegerInputFormatter()],
          ),
          AppSwitchField(
            key: const Key('settingsPrintPreviewSwitch'),
            title: 'تشغيل معاينة الطباعة',
            subtitle: 'عرض القائمة قبل إرسالها إلى الطابعة',
            icon: Icons.preview_outlined,
            accentColor: widget.accentColor,
            value: _previewEnabled,
            onChanged: (value) {
              setState(() => _previewEnabled = value);
            },
          ),
        ],
      ),
    );
  }
}

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

class MasterDataSettingsSection extends StatefulWidget {
  const MasterDataSettingsSection({
    required this.accentColor,
    super.key,
  });

  final Color accentColor;

  @override
  State<MasterDataSettingsSection> createState() =>
      _MasterDataSettingsSectionState();
}

class _MasterDataSettingsSectionState
    extends State<MasterDataSettingsSection> {
  var _selectedTab = 'groupsTypes';
  var _itemGroups = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(id: 1, name: 'المواد الغذائية'),
    const _SettingsNamedEntry(id: 2, name: 'الأجهزة الكهربائية'),
    const _SettingsNamedEntry(id: 3, name: 'القرطاسية'),
  ];
  var _itemTypes = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(
      id: 1,
      name: 'مشروبات',
      parent: 'المواد الغذائية',
    ),
    const _SettingsNamedEntry(
      id: 2,
      name: 'مواد جافة',
      parent: 'المواد الغذائية',
    ),
    const _SettingsNamedEntry(
      id: 3,
      name: 'أجهزة منزلية',
      parent: 'الأجهزة الكهربائية',
    ),
  ];
  var _workplaces = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(id: 1, name: 'شركة المميز'),
    const _SettingsNamedEntry(id: 2, name: 'السوق المحلي'),
    const _SettingsNamedEntry(id: 3, name: 'المبيعات المباشرة'),
  ];
  var _branches = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(
      id: 1,
      name: 'الفرع الرئيسي',
      parent: 'شركة المميز',
    ),
    const _SettingsNamedEntry(
      id: 2,
      name: 'فرع الكرادة',
      parent: 'السوق المحلي',
    ),
    const _SettingsNamedEntry(
      id: 3,
      name: 'فرع المنصور',
      parent: 'المبيعات المباشرة',
    ),
  ];
  var _cashboxMainAccounts = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(
      id: 1,
      name: 'الصندوق الرئيسي',
      isProtected: true,
    ),
    const _SettingsNamedEntry(id: 2, name: 'المصاريف العامة'),
    const _SettingsNamedEntry(id: 3, name: 'حساب الأطراف'),
  ];
  var _cashboxSubAccounts = <_SettingsNamedEntry>[
    const _SettingsNamedEntry(
      id: 1,
      name: 'النقدية اليومية',
      parent: 'الصندوق الرئيسي',
    ),
    const _SettingsNamedEntry(
      id: 2,
      name: 'أجور النقل',
      parent: 'المصاريف العامة',
    ),
    const _SettingsNamedEntry(
      id: 3,
      name: 'مصروفات المكتب',
      parent: 'المصاريف العامة',
    ),
  ];

  int get _selectedTabIndex => switch (_selectedTab) {
        'workplacesBranches' => 1,
        'cashboxAccounts' => 2,
        _ => 0,
      };

  List<_SettingsNamedEntry> _cascadeParentChanges({
    required List<_SettingsNamedEntry> previousParents,
    required List<_SettingsNamedEntry> nextParents,
    required List<_SettingsNamedEntry> children,
  }) {
    final nextNamesById = {
      for (final entry in nextParents) entry.id: entry.name,
    };
    final previousIdsByName = {
      for (final entry in previousParents) entry.name: entry.id,
    };
    return [
      for (final child in children)
        if (child.parent == null)
          child
        else
          _cascadeChildParent(
            child: child,
            previousIdsByName: previousIdsByName,
            nextNamesById: nextNamesById,
            nextParents: nextParents,
          ),
    ];
  }

  _SettingsNamedEntry _cascadeChildParent({
    required _SettingsNamedEntry child,
    required Map<String, int> previousIdsByName,
    required Map<int, String> nextNamesById,
    required List<_SettingsNamedEntry> nextParents,
  }) {
    final renamedParent =
        nextNamesById[previousIdsByName[child.parent]];
    final unchangedParent = nextParents.any(
      (entry) => entry.name == child.parent,
    )
        ? child.parent
        : null;
    final nextParent = renamedParent ?? unchangedParent;

    return child.copyWith(
      parent: nextParent,
      clearParent: nextParent == null,
    );
  }

  void _replaceItemGroups(List<_SettingsNamedEntry> entries) {
    setState(() {
      _itemTypes = _cascadeParentChanges(
        previousParents: _itemGroups,
        nextParents: entries,
        children: _itemTypes,
      );
      _itemGroups = entries;
    });
  }

  void _replaceWorkplaces(List<_SettingsNamedEntry> entries) {
    setState(() {
      _branches = _cascadeParentChanges(
        previousParents: _workplaces,
        nextParents: entries,
        children: _branches,
      );
      _workplaces = entries;
    });
  }

  void _replaceCashboxMainAccounts(
    List<_SettingsNamedEntry> entries,
  ) {
    setState(() {
      _cashboxSubAccounts = _cascadeParentChanges(
        previousParents: _cashboxMainAccounts,
        nextParents: entries,
        children: _cashboxSubAccounts,
      );
      _cashboxMainAccounts = entries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('masterDataSettingsContent'),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SettingsTemplateTabs<String>(
          keyPrefix: 'masterDataTab_',
          accentColor: widget.accentColor,
          selected: _selectedTab,
          onChanged: (value) => setState(() => _selectedTab = value),
          items: const [
            (
              value: 'groupsTypes',
              label: 'المجموعات والأنواع',
              icon: Icons.category_outlined,
            ),
            (
              value: 'workplacesBranches',
              label: 'جهات العمل والفروع',
              icon: Icons.account_tree_outlined,
            ),
            (
              value: 'cashboxAccounts',
              label: 'حسابات الصندوق',
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        IndexedStack(
          key: const Key('settingsMasterDataTemplates'),
          index: _selectedTabIndex,
          children: [
            _GroupsTypesTemplate(
              accentColor: widget.accentColor,
              groups: _itemGroups,
              types: _itemTypes,
              onGroupsChanged: _replaceItemGroups,
              onTypesChanged: (entries) {
                setState(() => _itemTypes = entries);
              },
            ),
            _WorkplacesBranchesTemplate(
              accentColor: widget.accentColor,
              workplaces: _workplaces,
              branches: _branches,
              onWorkplacesChanged: _replaceWorkplaces,
              onBranchesChanged: (entries) {
                setState(() => _branches = entries);
              },
            ),
            _CashboxAccountsTemplate(
              accentColor: widget.accentColor,
              mainAccounts: _cashboxMainAccounts,
              subAccounts: _cashboxSubAccounts,
              onMainAccountsChanged: _replaceCashboxMainAccounts,
              onSubAccountsChanged: (entries) {
                setState(() => _cashboxSubAccounts = entries);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _GroupsTypesTemplate extends StatelessWidget {
  const _GroupsTypesTemplate({
    required this.accentColor,
    required this.groups,
    required this.types,
    required this.onGroupsChanged,
    required this.onTypesChanged,
  });

  final Color accentColor;
  final List<_SettingsNamedEntry> groups;
  final List<_SettingsNamedEntry> types;
  final ValueChanged<List<_SettingsNamedEntry>> onGroupsChanged;
  final ValueChanged<List<_SettingsNamedEntry>> onTypesChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsResponsiveGrid(
      key: const Key('settingsGroupsTypesTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 620,
      children: [
        _SettingsManagementPanel(
          keyPrefix: 'settingsItemGroups',
          title: 'مجموعات المواد',
          fieldLabel: 'اسم المجموعة',
          icon: Icons.folder_copy_outlined,
          accentColor: accentColor,
          entries: groups,
          onEntriesChanged: onGroupsChanged,
        ),
        _SettingsManagementPanel(
          keyPrefix: 'settingsItemTypes',
          title: 'أنواع المواد',
          fieldLabel: 'اسم النوع',
          parentLabel: 'المجموعة',
          parentOptions: [for (final entry in groups) entry.name],
          icon: Icons.account_tree_outlined,
          accentColor: accentColor,
          entries: types,
          onEntriesChanged: onTypesChanged,
        ),
      ],
    );
  }
}

class _WorkplacesBranchesTemplate extends StatelessWidget {
  const _WorkplacesBranchesTemplate({
    required this.accentColor,
    required this.workplaces,
    required this.branches,
    required this.onWorkplacesChanged,
    required this.onBranchesChanged,
  });

  final Color accentColor;
  final List<_SettingsNamedEntry> workplaces;
  final List<_SettingsNamedEntry> branches;
  final ValueChanged<List<_SettingsNamedEntry>> onWorkplacesChanged;
  final ValueChanged<List<_SettingsNamedEntry>> onBranchesChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsResponsiveGrid(
      key: const Key('settingsWorkplacesBranchesTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 620,
      children: [
        _SettingsManagementPanel(
          keyPrefix: 'settingsWorkplaces',
          title: 'جهات العمل',
          fieldLabel: 'اسم جهة العمل',
          icon: Icons.business_center_outlined,
          accentColor: accentColor,
          entries: workplaces,
          onEntriesChanged: onWorkplacesChanged,
        ),
        _SettingsManagementPanel(
          keyPrefix: 'settingsWorkplaceBranches',
          title: 'الفروع',
          fieldLabel: 'اسم الفرع',
          parentLabel: 'جهة العمل',
          parentOptions: [for (final entry in workplaces) entry.name],
          icon: Icons.fork_right_outlined,
          accentColor: accentColor,
          entries: branches,
          onEntriesChanged: onBranchesChanged,
        ),
      ],
    );
  }
}

class _CashboxAccountsTemplate extends StatelessWidget {
  const _CashboxAccountsTemplate({
    required this.accentColor,
    required this.mainAccounts,
    required this.subAccounts,
    required this.onMainAccountsChanged,
    required this.onSubAccountsChanged,
  });

  final Color accentColor;
  final List<_SettingsNamedEntry> mainAccounts;
  final List<_SettingsNamedEntry> subAccounts;
  final ValueChanged<List<_SettingsNamedEntry>> onMainAccountsChanged;
  final ValueChanged<List<_SettingsNamedEntry>> onSubAccountsChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsResponsiveGrid(
      key: const Key('settingsCashboxAccountsTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 620,
      children: [
        _SettingsManagementPanel(
          keyPrefix: 'settingsCashboxMainAccounts',
          title: 'الحسابات الرئيسية',
          fieldLabel: 'اسم الحساب الرئيسي',
          icon: Icons.account_balance_wallet_outlined,
          accentColor: accentColor,
          entries: mainAccounts,
          onEntriesChanged: onMainAccountsChanged,
        ),
        _SettingsManagementPanel(
          keyPrefix: 'settingsCashboxSubAccounts',
          title: 'الحسابات الفرعية',
          fieldLabel: 'اسم الحساب الفرعي',
          parentLabel: 'الحساب الرئيسي',
          parentOptions: [for (final entry in mainAccounts) entry.name],
          icon: Icons.segment_outlined,
          accentColor: accentColor,
          entries: subAccounts,
          onEntriesChanged: onSubAccountsChanged,
        ),
      ],
    );
  }
}

class _SettingsNamedEntry {
  const _SettingsNamedEntry({
    required this.id,
    required this.name,
    this.isProtected = false,
    this.parent,
  });

  final int id;
  final String name;
  final bool isProtected;
  final String? parent;

  _SettingsNamedEntry copyWith({
    String? name,
    String? parent,
    bool clearParent = false,
  }) {
    return _SettingsNamedEntry(
      id: id,
      name: name ?? this.name,
      isProtected: isProtected,
      parent: clearParent ? null : parent ?? this.parent,
    );
  }
}

class _SettingsManagementPanel extends StatefulWidget {
  const _SettingsManagementPanel({
    required this.keyPrefix,
    required this.title,
    required this.fieldLabel,
    required this.icon,
    required this.accentColor,
    required this.entries,
    required this.onEntriesChanged,
    this.parentLabel,
    this.parentOptions = const [],
  });

  final String keyPrefix;
  final String title;
  final String fieldLabel;
  final IconData icon;
  final Color accentColor;
  final List<_SettingsNamedEntry> entries;
  final ValueChanged<List<_SettingsNamedEntry>> onEntriesChanged;
  final String? parentLabel;
  final List<String> parentOptions;

  @override
  State<_SettingsManagementPanel> createState() =>
      _SettingsManagementPanelState();
}

class _SettingsManagementPanelState
    extends State<_SettingsManagementPanel> {
  final _nameController = TextEditingController();
  int? _selectedId;
  String? _selectedParent;

  @override
  void initState() {
    super.initState();
    _selectedParent =
        widget.parentOptions.isEmpty ? null : widget.parentOptions.first;
  }

  @override
  void didUpdateWidget(covariant _SettingsManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selectedId = _selectedId;
    if (selectedId != null) {
      final selectedIndex =
          widget.entries.indexWhere((entry) => entry.id == selectedId);
      if (selectedIndex < 0) {
        _selectedId = null;
        _nameController.clear();
      } else {
        final selectedEntry = widget.entries[selectedIndex];
        _selectedParent = selectedEntry.parent;
      }
    } else if (_selectedParent == null ||
        !widget.parentOptions.contains(_selectedParent)) {
      _selectedParent =
          widget.parentOptions.isEmpty ? null : widget.parentOptions.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedId = null;
      _nameController.clear();
      _selectedParent =
          widget.parentOptions.isEmpty ? null : widget.parentOptions.first;
    });
  }

  void _addEntry() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.showWarning(context, 'اكتب ${widget.fieldLabel} أولاً');
      return;
    }
    if (widget.entries.any(
      (entry) => entry.name.trim().toLowerCase() == name.toLowerCase(),
    )) {
      AppToast.showWarning(context, 'هذا الاسم مستخدم مسبقاً');
      return;
    }
    if (widget.parentLabel != null && _selectedParent == null) {
      AppToast.showWarning(context, 'اختر ${widget.parentLabel} أولاً');
      return;
    }

    final nextId = widget.entries.fold<int>(
          0,
          (largest, entry) => entry.id > largest ? entry.id : largest,
        ) +
        1;
    final nextEntries = [
      ...widget.entries,
      _SettingsNamedEntry(
        id: nextId,
        name: name,
        parent: widget.parentLabel == null ? null : _selectedParent,
      ),
    ];
    setState(() {
      _selectedId = nextId;
    });
    widget.onEntriesChanged(nextEntries);
    AppToast.showInfo(context, 'تمت الإضافة إلى نموذج ${widget.title}');
  }

  void _updateEntry() {
    final selectedId = _selectedId;
    final name = _nameController.text.trim();
    if (selectedId == null || name.isEmpty) {
      AppToast.showWarning(context, 'اختر سجلاً واكتب الاسم الجديد');
      return;
    }
    if (widget.entries.any(
      (entry) =>
          entry.id != selectedId &&
          entry.name.trim().toLowerCase() == name.toLowerCase(),
    )) {
      AppToast.showWarning(context, 'هذا الاسم مستخدم مسبقاً');
      return;
    }
    if (widget.parentLabel != null && _selectedParent == null) {
      AppToast.showWarning(context, 'اختر ${widget.parentLabel} أولاً');
      return;
    }

    final nextEntries = List<_SettingsNamedEntry>.of(widget.entries);
    final index =
        nextEntries.indexWhere((entry) => entry.id == selectedId);
    if (index < 0) return;
    nextEntries[index] = nextEntries[index].copyWith(
      name: name,
      parent: widget.parentLabel == null ? null : _selectedParent,
      clearParent: widget.parentLabel == null,
    );
    widget.onEntriesChanged(nextEntries);
    AppToast.showSuccess(context, 'تم تحديث السجل التجريبي');
  }

  Future<void> _deleteEntry(_SettingsNamedEntry entry) async {
    if (entry.isProtected) {
      AppToast.showWarning(context, 'لا يمكن حذف الحساب النظامي');
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف السجل',
      message: 'هل تريد حذف «${entry.name}» من النموذج؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!confirmed || !mounted) return;

    final nextEntries = [
      for (final candidate in widget.entries)
        if (candidate.id != entry.id) candidate,
    ];
    setState(() {
      if (_selectedId == entry.id) {
        _selectedId = null;
        _nameController.clear();
      }
    });
    widget.onEntriesChanged(nextEntries);
    AppToast.showDanger(context, 'تم حذف السجل التجريبي');
  }

  void _selectEntry(_SettingsNamedEntry entry) {
    setState(() {
      _selectedId = entry.id;
      _selectedParent = entry.parent;
      _nameController.text = entry.name;
      _nameController.selection = TextSelection.collapsed(
        offset: _nameController.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.keyPrefix;

    return SettingsTemplatePanel(
      key: Key('${prefix}Panel'),
      title: widget.title,
      icon: widget.icon,
      accentColor: widget.accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.parentLabel != null) ...[
            AppDropdownField<String>(
              fieldKey: Key('${prefix}ParentField'),
              label: widget.parentLabel!,
              icon: Icons.account_tree_outlined,
              accentColor: widget.accentColor,
              value: _selectedParent,
              enabled: widget.parentOptions.isNotEmpty,
              options: [
                for (final option in widget.parentOptions)
                  AppDropdownOption(value: option, label: option),
              ],
              useIntrinsicHeight: true,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              menuTextDirection: TextDirection.rtl,
              onChanged: (value) {
                if (value != null) setState(() => _selectedParent = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTextField(
            fieldKey: Key('${prefix}NameField'),
            controller: _nameController,
            label: widget.fieldLabel,
            icon: Icons.edit_outlined,
            accentColor: widget.accentColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _selectedId == null
                ? _addEntry()
                : _updateEntry(),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            textDirection: TextDirection.rtl,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                key: Key('${prefix}AddButton'),
                label: 'إضافة',
                icon: Icons.add_rounded,
                backgroundColor: widget.accentColor,
                minWidth: 115,
                onPressed: widget.parentLabel != null &&
                        _selectedParent == null
                    ? null
                    : _addEntry,
              ),
              AppButton(
                key: Key('${prefix}UpdateButton'),
                label: 'تحديث',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.success,
                minWidth: 115,
                onPressed: _selectedId == null ||
                        (widget.parentLabel != null &&
                            _selectedParent == null)
                    ? null
                    : _updateEntry,
              ),
              AppButton(
                key: Key('${prefix}ClearButton'),
                label: 'تراجع',
                icon: Icons.undo_rounded,
                variant: AppButtonVariant.warning,
                minWidth: 115,
                onPressed: _selectedId == null &&
                        _nameController.text.isEmpty
                    ? null
                    : _clearSelection,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: Key('${prefix}Table'),
            height: 270,
            rowHeight: 54,
            minimumColumnWidth: 115,
            accentColor: widget.accentColor,
            showShadow: false,
            columns: [
              const AppTableColumn(
                label: 'ت',
                flex: 0.45,
                numeric: true,
              ),
              const AppTableColumn(label: 'الاسم', flex: 1.8),
              if (widget.parentLabel != null)
                AppTableColumn(
                  label: widget.parentLabel!,
                  flex: 1.35,
                ),
              const AppTableColumn(label: 'الحالة', flex: 1),
              const AppTableColumn(label: 'الإجراءات', flex: 0.8),
            ],
            rows: [
              for (final entry in widget.entries)
                AppTableRow(
                  rowKey: Key('${prefix}Row_${entry.id}'),
                  selected: entry.id == _selectedId,
                  onTap: () => _selectEntry(entry),
                  cells: [
                    Text('${entry.id}', textAlign: TextAlign.center),
                    Text(entry.name, overflow: TextOverflow.ellipsis),
                    if (widget.parentLabel != null)
                      Text(
                        entry.parent ?? 'غير محدد',
                        overflow: TextOverflow.ellipsis,
                      ),
                    Center(
                      child: AppStatusBadge(
                        label: entry.isProtected ? 'نظامي' : 'نشط',
                        tone: entry.isProtected
                            ? AppStatusTone.info
                            : AppStatusTone.success,
                      ),
                    ),
                    Center(
                      child: AppTableActionButton(
                        key: Key('${prefix}Delete_${entry.id}'),
                        icon: Icons.delete_outline_rounded,
                        tooltip: entry.isProtected
                            ? 'حساب نظامي'
                            : 'حذف',
                        variant: AppButtonVariant.danger,
                        onPressed: () => _deleteEntry(entry),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class BackupDataSettingsSection extends StatefulWidget {
  const BackupDataSettingsSection({
    required this.accentColor,
    super.key,
  });

  final Color accentColor;

  @override
  State<BackupDataSettingsSection> createState() =>
      _BackupDataSettingsSectionState();
}

class _BackupDataSettingsSectionState
    extends State<BackupDataSettingsSection> {
  final _localPathController = TextEditingController(
    text: r'D:\Almumayaz\Backups',
  );
  final _driveFolderController = TextEditingController(
    text: 'Almumayaz ERP Backups',
  );
  var _automaticBackup = true;
  var _backupFrequency = 'يومياً';
  var _driveConnected = false;
  var _nextBackupId = 4;
  final _history = <_BackupHistoryEntry>[
    const _BackupHistoryEntry(
      id: 1,
      createdAt: '2026/07/29 09:15 ص',
      destination: 'محلي',
      size: '18.4 MB',
      status: 'مكتملة',
      isSuccessful: true,
    ),
    const _BackupHistoryEntry(
      id: 2,
      createdAt: '2026/07/28 06:00 م',
      destination: 'محلي + Google Drive',
      size: '18.1 MB',
      status: 'مكتملة',
      isSuccessful: true,
    ),
    const _BackupHistoryEntry(
      id: 3,
      createdAt: '2026/07/27 06:00 م',
      destination: 'Google Drive',
      size: '17.9 MB',
      status: 'تعذر الرفع',
      isSuccessful: false,
    ),
  ];

  @override
  void dispose() {
    _localPathController.dispose();
    _driveFolderController.dispose();
    super.dispose();
  }

  void _toggleDriveConnection() {
    setState(() => _driveConnected = !_driveConnected);
    if (_driveConnected) {
      AppToast.showSuccess(context, 'تم ربط Google Drive تجريبياً');
    } else {
      AppToast.showWarning(context, 'تم فصل Google Drive تجريبياً');
    }
  }

  void _createBackup() {
    setState(() {
      _history.insert(
        0,
        _BackupHistoryEntry(
          id: _nextBackupId++,
          createdAt: '2026/07/29 10:30 ص',
          destination:
              _driveConnected ? 'محلي + Google Drive' : 'محلي',
          size: '18.6 MB',
          status: 'مكتملة',
          isSuccessful: true,
        ),
      );
    });
    AppToast.showInfo(context, 'تم إنشاء نسخة احتياطية تجريبية');
  }

  Future<void> _restoreBackup([_BackupHistoryEntry? entry]) async {
    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'استعادة نسخة احتياطية',
      message: entry == null
          ? 'سيتم اختيار ملف نسخة احتياطية ثم استعادته. هل تريد المتابعة؟'
          : 'هل تريد استعادة نسخة ${entry.createdAt}؟',
      confirmLabel: 'استعادة',
      cancelLabel: 'إلغاء',
      isDanger: true,
      size: AppDialogSize.medium,
    );
    if (!confirmed || !mounted) return;
    AppToast.showWarning(context, 'تمت محاكاة استعادة النسخة الاحتياطية');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('backupDataSettingsContent'),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppInfoBanner(
          key: const Key('settingsBackupPolicyBanner'),
          message:
              'يُنشأ النسخ التلقائي محلياً دائماً، وتُرفع نسخة إضافية إلى Google Drive عند ربط الحساب.',
          icon: Icons.shield_outlined,
          foregroundColor: widget.accentColor,
          backgroundColor: Color.alphaBlend(
            widget.accentColor.withAlpha(18),
            AppColors.surface,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsResponsiveGrid(
          preferredColumns: 2,
          minimumChildHeight: 360,
          children: [
            SettingsTemplatePanel(
              key: const Key('settingsLocalBackupPanel'),
              title: 'النسخ المحلي والتلقائي',
              icon: Icons.save_alt_rounded,
              accentColor: widget.accentColor,
              child: Column(
                children: [
                  AppTextField(
                    fieldKey: const Key('settingsLocalBackupPathField'),
                    controller: _localPathController,
                    label: 'مسار النسخ المحلي',
                    icon: Icons.folder_outlined,
                    suffixIcon: AppFieldIconButton(
                      buttonKey:
                          const Key('settingsBrowseLocalBackupPath'),
                      icon: Icons.folder_open_rounded,
                      tooltip: 'اختيار مجلد',
                      color: widget.accentColor,
                      onPressed: () {
                        _localPathController.text =
                            r'D:\Almumayaz\Backups\Local';
                        AppToast.showInfo(
                          context,
                          'تم اختيار مسار تجريبي',
                        );
                      },
                    ),
                    accentColor: widget.accentColor,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSwitchField(
                    key: const Key('settingsAutomaticBackupSwitch'),
                    title: 'النسخ التلقائي',
                    subtitle: 'إنشاء النسخة حسب التكرار المحدد',
                    icon: Icons.autorenew_rounded,
                    accentColor: widget.accentColor,
                    value: _automaticBackup,
                    onChanged: (value) {
                      setState(() => _automaticBackup = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdownField<String>(
                    fieldKey:
                        const Key('settingsBackupFrequencyField'),
                    label: 'تكرار النسخ',
                    icon: Icons.schedule_rounded,
                    accentColor: widget.accentColor,
                    value: _backupFrequency,
                    enabled: _automaticBackup,
                    options: const [
                      AppDropdownOption(
                        value: 'عند إغلاق التطبيق',
                        label: 'عند إغلاق التطبيق',
                      ),
                      AppDropdownOption(value: 'يومياً', label: 'يومياً'),
                      AppDropdownOption(
                        value: 'أسبوعياً',
                        label: 'أسبوعياً',
                      ),
                    ],
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    onChanged: (value) {
                      if (value == null || value == _backupFrequency) return;
                      setState(() => _backupFrequency = value);
                    },
                  ),
                ],
              ),
            ),
            SettingsTemplatePanel(
              key: const Key('settingsDriveBackupPanel'),
              title: 'Google Drive',
              icon: Icons.cloud_outlined,
              accentColor: widget.accentColor,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _driveConnected
                          ? AppColors.successSurface
                          : AppColors.neutralSurface,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: Color.lerp(
                          widget.accentColor,
                          AppColors.surface,
                          0.62,
                        )!,
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _driveConnected
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          color: _driveConnected
                              ? AppColors.green
                              : AppColors.grey,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _driveConnected
                                ? 'الحساب مرتبط وجاهز للنسخ'
                                : 'لم يتم ربط حساب Google Drive',
                            style: AppTypography.fieldText,
                          ),
                        ),
                        AppRegularButton(
                          key: const Key(
                            'settingsToggleDriveConnectionButton',
                          ),
                          label: _driveConnected ? 'فصل' : 'ربط',
                          icon: _driveConnected
                              ? Icons.link_off_rounded
                              : Icons.link_rounded,
                          onPressed: _toggleDriveConnection,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    fieldKey:
                        const Key('settingsDriveFolderField'),
                    controller: _driveFolderController,
                    label: 'مجلد Google Drive',
                    icon: Icons.drive_folder_upload_outlined,
                    accentColor: widget.accentColor,
                    enabled: _driveConnected,
                    readOnly: !_driveConnected,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppInfoBanner(
                    message: _driveConnected
                        ? 'سيتم رفع النسخة المحلية الجديدة إلى المجلد المحدد.'
                        : 'اربط الحساب لتفعيل مجلد Google Drive والرفع السحابي.',
                    icon: Icons.info_outline_rounded,
                    foregroundColor: _driveConnected
                        ? widget.accentColor
                        : AppColors.grey,
                    backgroundColor: _driveConnected
                        ? Color.alphaBlend(
                            widget.accentColor.withAlpha(18),
                            AppColors.surface,
                          )
                        : AppColors.neutralSurface,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsTemplatePanel(
          key: const Key('settingsBackupActionsPanel'),
          title: 'الإجراءات',
          icon: Icons.settings_backup_restore_rounded,
          accentColor: widget.accentColor,
          child: Wrap(
            textDirection: TextDirection.rtl,
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton(
                key: const Key('settingsSaveBackupConfigurationButton'),
                label: 'حفظ إعدادات النسخ',
                icon: Icons.save_outlined,
                minWidth: 200,
                onPressed: () {
                  AppToast.showInfo(
                    context,
                    'تم حفظ إعدادات النسخ مؤقتاً',
                  );
                },
              ),
              AppButton(
                key: const Key('settingsRunBackupButton'),
                label: 'إنشاء نسخة الآن',
                icon: Icons.backup_rounded,
                minWidth: 190,
                onPressed: _createBackup,
              ),
              AppButton(
                key: const Key('settingsRestoreBackupButton'),
                label: 'استعادة نسخة',
                icon: Icons.restore_rounded,
                variant: AppButtonVariant.warning,
                minWidth: 190,
                onPressed: _restoreBackup,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsTemplatePanel(
          key: const Key('settingsBackupHistoryPanel'),
          title: 'سجل النسخ وآخر حالة',
          icon: Icons.history_rounded,
          accentColor: widget.accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'آخر نسخة ناجحة:',
                    style: AppTypography.fieldText,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _latestSuccessfulBackup?.createdAt ?? 'لا توجد',
                    style: AppTypography.fieldText.copyWith(
                      color: AppColors.green,
                    ),
                  ),
                  const Spacer(),
                  AppStatusBadge(
                    label: _latestSuccessfulBackup == null
                        ? 'غير متوفر'
                        : 'مكتملة',
                    tone: _latestSuccessfulBackup == null
                        ? AppStatusTone.neutral
                        : AppStatusTone.success,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppDataTable(
                key: const Key('settingsBackupHistoryTable'),
                height: 300,
                rowHeight: 56,
                minimumColumnWidth: 150,
                accentColor: widget.accentColor,
                showShadow: false,
                columns: const [
                  AppTableColumn(label: 'التاريخ والوقت', flex: 1.5),
                  AppTableColumn(label: 'الوجهة', flex: 1.3),
                  AppTableColumn(label: 'الحجم', flex: 0.8),
                  AppTableColumn(label: 'الحالة', flex: 0.9),
                  AppTableColumn(label: 'الإجراء', flex: 0.65),
                ],
                rows: [
                  for (final entry in _history)
                    AppTableRow(
                      rowKey: Key('settingsBackupHistoryRow_${entry.id}'),
                      cells: [
                        Text(entry.createdAt),
                        Text(entry.destination),
                        Text(entry.size, textDirection: TextDirection.ltr),
                        Center(
                          child: AppStatusBadge(
                            label: entry.status,
                            tone: entry.isSuccessful
                                ? AppStatusTone.success
                                : AppStatusTone.danger,
                          ),
                        ),
                        Center(
                          child: AppTableActionButton(
                            key: Key(
                              'settingsRestoreHistory_${entry.id}',
                            ),
                            icon: Icons.restore_rounded,
                            tooltip: 'استعادة هذه النسخة',
                            variant: AppButtonVariant.warning,
                            onPressed: entry.isSuccessful
                                ? () => _restoreBackup(entry)
                                : null,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  _BackupHistoryEntry? get _latestSuccessfulBackup {
    for (final entry in _history) {
      if (entry.isSuccessful) return entry;
    }
    return null;
  }
}

class _BackupHistoryEntry {
  const _BackupHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.destination,
    required this.size,
    required this.status,
    required this.isSuccessful,
  });

  final int id;
  final String createdAt;
  final String destination;
  final String size;
  final String status;
  final bool isSuccessful;
}

class UsersSecuritySettingsSection extends StatefulWidget {
  const UsersSecuritySettingsSection({
    required this.accentColor,
    super.key,
  });

  final Color accentColor;

  @override
  State<UsersSecuritySettingsSection> createState() =>
      _UsersSecuritySettingsSectionState();
}

class _UsersSecuritySettingsSectionState
    extends State<UsersSecuritySettingsSection> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _logSearchController = TextEditingController();
  final _logSearchFocusNode = FocusNode();
  var _selectedTab = 'users';
  var _idleLockEnabled = true;
  var _idleLockDuration = '15 دقيقة';
  var _logType = 'الكل';
  var _nextUserId = 4;
  var _nextRoleId = 5;
  final _users = <_SettingsUser>[
    const _SettingsUser(
      id: 1,
      fullName: 'مدير النظام',
      username: 'admin',
      role: 'مدير النظام',
      isEnabled: true,
      isLocked: false,
      lastLogin: '2026/07/29 09:02 ص',
    ),
    const _SettingsUser(
      id: 2,
      fullName: 'أحمد كريم',
      username: 'ahmed',
      role: 'المبيعات',
      isEnabled: true,
      isLocked: false,
      lastLogin: '2026/07/28 05:40 م',
    ),
    const _SettingsUser(
      id: 3,
      fullName: 'سارة علي',
      username: 'sara',
      role: 'الحسابات',
      isEnabled: true,
      isLocked: true,
      lastLogin: '2026/07/26 11:20 ص',
    ),
  ];

  final _roles = <_SettingsRole>[
    _SettingsRole(
      id: 1,
      name: 'مدير النظام',
      permissions: _allSettingsRolePermissions(),
    ),
    _SettingsRole(
      id: 2,
      name: 'المبيعات',
      permissions: _settingsRolePermissions(
        sales: _allPermissionActionIds,
        parties: {'view', 'edit'},
        reports: {'view', 'print'},
      ),
    ),
    _SettingsRole(
      id: 3,
      name: 'الحسابات',
      permissions: _settingsRolePermissions(
        cashbox: _allPermissionActionIds,
        parties: {'view'},
        reports: {'view', 'print'},
      ),
    ),
    _SettingsRole(
      id: 4,
      name: 'عرض فقط',
      permissions: _viewOnlySettingsRolePermissions(),
    ),
  ];

  static const _auditEntries = <_SettingsAuditEntry>[
    _SettingsAuditEntry(
      id: 1,
      createdAt: '2026/07/29 09:02 ص',
      username: 'admin',
      type: 'تسجيل الدخول',
      details: 'تسجيل دخول ناجح من جهاز المكتب الرئيسي',
      status: 'ناجح',
    ),
    _SettingsAuditEntry(
      id: 2,
      createdAt: '2026/07/29 09:18 ص',
      username: 'admin',
      type: 'تعديل',
      details: 'تعديل بيانات المادة: ورق A4',
      status: 'مكتمل',
    ),
    _SettingsAuditEntry(
      id: 3,
      createdAt: '2026/07/29 09:27 ص',
      username: 'ahmed',
      type: 'حذف',
      details: 'حذف قائمة بيع تجريبية رقم 1042',
      status: 'مكتمل',
    ),
    _SettingsAuditEntry(
      id: 4,
      createdAt: '2026/07/29 09:31 ص',
      username: 'admin',
      type: 'استعادة',
      details: 'استعادة قائمة البيع رقم 1042',
      status: 'مكتمل',
    ),
    _SettingsAuditEntry(
      id: 5,
      createdAt: '2026/07/28 04:12 م',
      username: 'sara',
      type: 'تسجيل الدخول',
      details: 'محاولة دخول بكلمة مرور غير صحيحة',
      status: 'فشل',
    ),
  ];

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _logSearchController.dispose();
    _logSearchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openAddUserDialog() async {
    final roleNames = _roles.map((role) => role.name).toList();
    final draft = await showDialog<_SettingsUserDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _SettingsUserDialog(
          accentColor: widget.accentColor,
          roleNames: roleNames,
          existingUsernames: {
            for (final user in _users) user.username.toLowerCase(),
          },
        ),
      ),
    );
    if (draft == null || !mounted) return;

    final normalizedUsername = draft.username.toLowerCase();
    if (_users.any(
      (user) => user.username.toLowerCase() == normalizedUsername,
    )) {
      AppToast.showWarning(context, 'اسم المستخدم مستخدم مسبقاً');
      return;
    }

    setState(() {
      _users.add(
        _SettingsUser(
          id: _nextUserId++,
          fullName: draft.fullName,
          username: draft.username,
          role: draft.role,
          isEnabled: true,
          isLocked: false,
          lastLogin: 'لم يسجل الدخول',
        ),
      );
    });
    AppToast.showInfo(context, 'تمت إضافة مستخدم تجريبي');
  }

  void _toggleUserEnabled(_SettingsUser user) {
    final index = _users.indexWhere((entry) => entry.id == user.id);
    if (index < 0) return;
    final isEnabled = !user.isEnabled;
    setState(() {
      _users[index] = user.copyWith(isEnabled: isEnabled);
    });
    if (isEnabled) {
      AppToast.showSuccess(context, 'تم تفعيل الحساب');
    } else {
      AppToast.showWarning(context, 'تم تعطيل الحساب');
    }
  }

  void _toggleUserLock(_SettingsUser user) {
    final index = _users.indexWhere((entry) => entry.id == user.id);
    if (index < 0) return;
    final isLocked = !user.isLocked;
    setState(() {
      _users[index] = user.copyWith(isLocked: isLocked);
    });
    AppToast.showWarning(
      context,
      isLocked ? 'تم قفل الحساب' : 'تم فتح قفل الحساب',
    );
  }

  Future<void> _openUserPasswordDialog(_SettingsUser user) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _SettingsUserPasswordDialog(
          user: user,
          accentColor: widget.accentColor,
        ),
      ),
    );
    if (changed != true || !mounted) return;
    AppToast.showSuccess(
      context,
      'تم تغيير كلمة مرور ${user.fullName} تجريبياً',
    );
  }

  Future<void> _openRoleDialog({_SettingsRole? role}) async {
    final draft = await showDialog<_SettingsRoleDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _SettingsRoleDialog(
          accentColor: widget.accentColor,
          initialRole: role,
          existingRoleNames: {
            for (final entry in _roles)
              if (entry.id != role?.id) entry.name.trim().toLowerCase(),
          },
        ),
      ),
    );
    if (draft == null || !mounted) return;

    final duplicate = _roles.any(
      (entry) =>
          entry.id != role?.id &&
          entry.name.trim().toLowerCase() ==
              draft.name.trim().toLowerCase(),
    );
    if (duplicate) {
      AppToast.showWarning(context, 'اسم الدور مستخدم مسبقاً');
      return;
    }

    if (role == null) {
      setState(() {
        _roles.add(
          _SettingsRole(
            id: _nextRoleId++,
            name: draft.name,
            permissions: draft.permissions,
          ),
        );
      });
      AppToast.showInfo(context, 'تمت إضافة دور تجريبي');
      return;
    }

    final index = _roles.indexWhere((entry) => entry.id == role.id);
    if (index < 0) return;
    setState(() {
      _roles[index] = _SettingsRole(
        id: role.id,
        name: draft.name,
        permissions: draft.permissions,
      );
      if (role.name != draft.name) {
        for (var userIndex = 0;
            userIndex < _users.length;
            userIndex++) {
          final user = _users[userIndex];
          if (user.role == role.name) {
            _users[userIndex] = user.copyWith(role: draft.name);
          }
        }
      }
    });
    AppToast.showSuccess(context, 'تم تحديث الدور والصلاحيات');
  }

  int _roleUsersCount(String roleName) {
    return _users.where((user) => user.role == roleName).length;
  }

  void _focusLogSearch() {
    setState(() => _selectedTab = 'logs');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _logSearchFocusNode.requestFocus();
    });
  }

  void _savePassword() {
    final current = _currentPasswordController.text;
    final password = _newPasswordController.text;
    final confirmation = _confirmPasswordController.text;
    if (current.isEmpty || password.isEmpty || confirmation.isEmpty) {
      AppToast.showWarning(context, 'أكمل حقول كلمة المرور');
      return;
    }
    if (password != confirmation) {
      AppToast.showError(context, 'كلمتا المرور الجديدتان غير متطابقتين');
      return;
    }
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    AppToast.showSuccess(context, 'تم تغيير كلمة المرور تجريبياً');
  }

  @override
  Widget build(BuildContext context) {
    final selectedTabIndex = switch (_selectedTab) {
      'roles' => 1,
      'security' => 2,
      'logs' => 3,
      _ => 0,
    };
    final content = ListView(
      key: const Key('usersSecuritySettingsContent'),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SettingsTemplateTabs<String>(
          keyPrefix: 'usersSecurityTab_',
          accentColor: widget.accentColor,
          selected: _selectedTab,
          onChanged: (value) => setState(() => _selectedTab = value),
          items: const [
            (
              value: 'users',
              label: 'المستخدمون',
              icon: Icons.manage_accounts_outlined,
            ),
            (
              value: 'roles',
              label: 'الأدوار والصلاحيات',
              icon: Icons.admin_panel_settings_outlined,
            ),
            (
              value: 'security',
              label: 'كلمة المرور والقفل',
              icon: Icons.lock_outline_rounded,
            ),
            (
              value: 'logs',
              label: 'السجلات',
              icon: Icons.receipt_long_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        IndexedStack(
          key: const Key('settingsUsersSecurityTabStack'),
          index: selectedTabIndex,
          children: [
            _buildUsersTemplate(),
            _buildRolesTemplate(),
            _buildSecurityTemplate(),
            _buildLogsTemplate(),
          ],
        ),
      ],
    );
    return AppShortcutScope(
      onSearch: _focusLogSearch,
      child: content,
    );
  }

  Widget _buildUsersTemplate() {
    return SettingsTemplatePanel(
      key: const Key('settingsUsersPanel'),
      title: 'المستخدمون',
      icon: Icons.people_alt_outlined,
      accentColor: widget.accentColor,
      actions: [
        AppRegularButton(
          key: const Key('settingsAddUserButton'),
          label: 'مستخدم جديد',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: _openAddUserDialog,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInfoBanner(
            message:
                'يمكن تفعيل الحساب أو تعطيله أو قفله، وتغيير كلمة مروره من قائمة المستخدمين.',
            icon: Icons.info_outline_rounded,
            foregroundColor: widget.accentColor,
            backgroundColor: Color.alphaBlend(
              widget.accentColor.withAlpha(18),
              AppColors.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: const Key('settingsUsersTable'),
            height: 430,
            rowHeight: 58,
            minimumColumnWidth: 150,
            accentColor: widget.accentColor,
            showShadow: false,
            columns: const [
              AppTableColumn(label: 'الاسم الكامل', flex: 1.3),
              AppTableColumn(label: 'اسم المستخدم', flex: 1),
              AppTableColumn(label: 'الدور', flex: 1),
              AppTableColumn(label: 'الحالة', flex: 0.8),
              AppTableColumn(label: 'آخر دخول', flex: 1.35),
              AppTableColumn(label: 'الإجراءات', flex: 1.15),
            ],
            rows: [
              for (final user in _users)
                AppTableRow(
                  rowKey: Key('settingsUserRow_${user.id}'),
                  cells: [
                    Text(user.fullName),
                    Text(user.username, textDirection: TextDirection.ltr),
                    Text(user.role),
                    Center(
                      key: Key('settingsUserStatus_${user.id}'),
                      child: _userStatusBadge(user),
                    ),
                    Text(user.lastLogin),
                    Center(
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          AppTableActionButton(
                            key: Key('settingsUserEnable_${user.id}'),
                            icon: user.isEnabled
                                ? Icons.person_off_outlined
                                : Icons.person_outline_rounded,
                            tooltip: user.isEnabled
                                ? 'تعطيل الحساب'
                                : 'تفعيل الحساب',
                            variant: user.isEnabled
                                ? AppButtonVariant.warning
                                : AppButtonVariant.success,
                            onPressed: user.username == 'admin'
                                ? null
                                : () => _toggleUserEnabled(user),
                          ),
                          AppTableActionButton(
                            key: Key('settingsUserLock_${user.id}'),
                            icon: user.isLocked
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            tooltip: user.isLocked
                                ? 'فتح القفل'
                                : 'قفل الحساب',
                            variant: AppButtonVariant.warning,
                            onPressed: user.username == 'admin'
                                ? null
                                : () => _toggleUserLock(user),
                          ),
                          AppTableActionButton(
                            key: Key('settingsUserPassword_${user.id}'),
                            icon: Icons.password_rounded,
                            tooltip: 'تغيير كلمة المرور',
                            onPressed: () =>
                                _openUserPasswordDialog(user),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolesTemplate() {
    return SettingsTemplatePanel(
      key: const Key('settingsRolesPanel'),
      title: 'الأدوار والصلاحيات',
      icon: Icons.admin_panel_settings_outlined,
      accentColor: widget.accentColor,
      actions: [
        AppRegularButton(
          key: const Key('settingsAddRoleButton'),
          label: 'دور جديد',
          icon: Icons.add_moderator_outlined,
          onPressed: _openRoleDialog,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInfoBanner(
            message:
                'هذا نموذج لتجميع صلاحيات الشاشات والإضافة والتعديل والحذف والطباعة ضمن أدوار واضحة.',
            icon: Icons.verified_user_outlined,
            foregroundColor: widget.accentColor,
            backgroundColor: Color.alphaBlend(
              widget.accentColor.withAlpha(18),
              AppColors.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: const Key('settingsRolesTable'),
            height: 390,
            rowHeight: 62,
            minimumColumnWidth: 160,
            accentColor: widget.accentColor,
            showShadow: false,
            columns: const [
              AppTableColumn(label: 'ت', flex: 0.4, numeric: true),
              AppTableColumn(label: 'الدور', flex: 1.1),
              AppTableColumn(label: 'عدد المستخدمين', flex: 0.9),
              AppTableColumn(label: 'ملخص الصلاحيات', flex: 2),
              AppTableColumn(label: 'الإجراءات', flex: 0.7),
            ],
            rows: [
              for (final role in _roles)
                AppTableRow(
                  rowKey: Key('settingsRoleRow_${role.id}'),
                  cells: [
                    Text('${role.id}', textAlign: TextAlign.center),
                    Text(role.name),
                    Text(
                      '${_roleUsersCount(role.name)}',
                      key: Key('settingsRoleUserCount_${role.id}'),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _rolePermissionSummary(role.permissions),
                      key: Key('settingsRoleSummary_${role.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Center(
                      child: AppTableActionButton(
                        key: Key('settingsRolePermissions_${role.id}'),
                        icon: Icons.rule_rounded,
                        tooltip: 'تعديل الصلاحيات',
                        onPressed: () => _openRoleDialog(role: role),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTemplate() {
    return SettingsResponsiveGrid(
      key: const Key('settingsPasswordLockTemplate'),
      preferredColumns: 2,
      minimumChildHeight: 430,
      children: [
        SettingsTemplatePanel(
          key: const Key('settingsChangePasswordPanel'),
          title: 'تغيير كلمة المرور',
          icon: Icons.password_rounded,
          accentColor: widget.accentColor,
          child: Column(
            children: [
              AppTextField(
                fieldKey: const Key('settingsCurrentPasswordField'),
                controller: _currentPasswordController,
                label: 'كلمة المرور الحالية',
                icon: Icons.lock_outline_rounded,
                accentColor: widget.accentColor,
                obscureText: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                fieldKey: const Key('settingsNewPasswordField'),
                controller: _newPasswordController,
                label: 'كلمة المرور الجديدة',
                icon: Icons.key_rounded,
                accentColor: widget.accentColor,
                obscureText: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                fieldKey: const Key('settingsConfirmPasswordField'),
                controller: _confirmPasswordController,
                label: 'تأكيد كلمة المرور الجديدة',
                icon: Icons.verified_user_outlined,
                accentColor: widget.accentColor,
                obscureText: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                onSubmitted: (_) => _savePassword(),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  key: const Key('settingsSavePasswordButton'),
                  label: 'تغيير كلمة المرور',
                  icon: Icons.save_outlined,
                  minWidth: 190,
                  onPressed: _savePassword,
                ),
              ),
            ],
          ),
        ),
        SettingsTemplatePanel(
          key: const Key('settingsIdleLockPanel'),
          title: 'القفل التلقائي',
          icon: Icons.lock_clock_outlined,
          accentColor: widget.accentColor,
          child: Column(
            children: [
              AppSwitchField(
                key: const Key('settingsIdleLockSwitch'),
                title: 'قفل التطبيق بعد الخمول',
                subtitle:
                    'يعيد المستخدم إلى شاشة الدخول بعد مدة دون استخدام',
                icon: Icons.timer_outlined,
                accentColor: widget.accentColor,
                value: _idleLockEnabled,
                onChanged: (value) {
                  setState(() => _idleLockEnabled = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdownField<String>(
                fieldKey: const Key('settingsIdleLockDurationField'),
                label: 'مدة الخمول',
                icon: Icons.schedule_rounded,
                accentColor: widget.accentColor,
                value: _idleLockDuration,
                enabled: _idleLockEnabled,
                options: const [
                  AppDropdownOption(value: '5 دقائق', label: '5 دقائق'),
                  AppDropdownOption(
                    value: '15 دقيقة',
                    label: '15 دقيقة',
                  ),
                  AppDropdownOption(
                    value: '30 دقيقة',
                    label: '30 دقيقة',
                  ),
                  AppDropdownOption(value: '60 دقيقة', label: '60 دقيقة'),
                ],
                useIntrinsicHeight: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                menuTextDirection: TextDirection.rtl,
                onChanged: (value) {
                  if (value == null || value == _idleLockDuration) return;
                  setState(() => _idleLockDuration = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppInfoBanner(
                message:
                    'القفل لا يغلق التطبيق ولا يفقد العمل المحفوظ؛ يطلب تسجيل الدخول فقط.',
                icon: Icons.security_rounded,
                foregroundColor: widget.accentColor,
                backgroundColor: Color.alphaBlend(
                  widget.accentColor.withAlpha(18),
                  AppColors.surface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  key: const Key('settingsSaveIdleLockButton'),
                  label: 'حفظ إعداد القفل',
                  icon: Icons.save_outlined,
                  minWidth: 180,
                  onPressed: () {
                    AppToast.showInfo(
                      context,
                      'تم حفظ إعداد القفل مؤقتاً',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogsTemplate() {
    final query = _logSearchController.text.trim().toLowerCase();
    final filteredEntries = _auditEntries.where((entry) {
      final matchesType = _logType == 'الكل' || entry.type == _logType;
      final haystack =
          '${entry.createdAt} ${entry.username} ${entry.type} '
          '${entry.details} ${entry.status}'
              .toLowerCase();
      return matchesType && (query.isEmpty || haystack.contains(query));
    }).toList();

    return SettingsTemplatePanel(
      key: const Key('settingsSecurityLogsPanel'),
      title: 'سجل الدخول والنشاط والتعديلات',
      icon: Icons.receipt_long_outlined,
      accentColor: widget.accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsResponsiveGrid(
            preferredColumns: 2,
            children: [
              AppSearchField(
                fieldKey: const Key('settingsSecurityLogSearchField'),
                controller: _logSearchController,
                label: 'بحث في السجل',
                hint: 'المستخدم أو العملية أو التفاصيل',
                accentColor: widget.accentColor,
                focusNode: _logSearchFocusNode,
                onChanged: (_) => setState(() {}),
              ),
              AppDropdownField<String>(
                fieldKey: const Key('settingsSecurityLogTypeField'),
                label: 'نوع العملية',
                icon: Icons.filter_alt_outlined,
                accentColor: widget.accentColor,
                value: _logType,
                options: const [
                  AppDropdownOption(value: 'الكل', label: 'الكل'),
                  AppDropdownOption(
                    value: 'تسجيل الدخول',
                    label: 'تسجيل الدخول',
                  ),
                  AppDropdownOption(value: 'تعديل', label: 'تعديل'),
                  AppDropdownOption(value: 'حذف', label: 'حذف'),
                  AppDropdownOption(value: 'استعادة', label: 'استعادة'),
                ],
                useIntrinsicHeight: true,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                menuTextDirection: TextDirection.rtl,
                onChanged: (value) {
                  if (value != null) setState(() => _logType = value);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: const Key('settingsSecurityLogsTable'),
            height: 430,
            rowHeight: 58,
            minimumColumnWidth: 155,
            accentColor: widget.accentColor,
            showShadow: false,
            emptyState: const AppStatePanel(
              type: AppStateType.empty,
              title: 'لا توجد نتائج',
              message: 'غيّر عبارة البحث أو نوع العملية.',
            ),
            columns: const [
              AppTableColumn(label: 'التاريخ والوقت', flex: 1.4),
              AppTableColumn(label: 'المستخدم', flex: 0.8),
              AppTableColumn(label: 'العملية', flex: 0.9),
              AppTableColumn(label: 'التفاصيل', flex: 2.2),
              AppTableColumn(label: 'الحالة', flex: 0.75),
            ],
            rows: [
              for (final entry in filteredEntries)
                AppTableRow(
                  rowKey: Key('settingsAuditRow_${entry.id}'),
                  cells: [
                    Text(entry.createdAt),
                    Text(
                      entry.username,
                      textDirection: TextDirection.ltr,
                    ),
                    Text(entry.type),
                    Text(entry.details, overflow: TextOverflow.ellipsis),
                    Center(
                      child: AppStatusBadge(
                        label: entry.status,
                        tone: entry.status == 'فشل'
                            ? AppStatusTone.danger
                            : AppStatusTone.success,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userStatusBadge(_SettingsUser user) {
    final (label, tone) = switch ((user.isEnabled, user.isLocked)) {
      (false, true) => ('معطل ومقفل', AppStatusTone.danger),
      (true, true) => ('مقفل', AppStatusTone.danger),
      (false, false) => ('معطل', AppStatusTone.warning),
      (true, false) => ('نشط', AppStatusTone.success),
    };
    return AppStatusBadge(
      label: label,
      tone: tone,
    );
  }
}

class _SettingsUser {
  const _SettingsUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.isEnabled,
    required this.isLocked,
    required this.lastLogin,
  });

  final int id;
  final String fullName;
  final String username;
  final String role;
  final bool isEnabled;
  final bool isLocked;
  final String lastLogin;

  _SettingsUser copyWith({
    String? role,
    bool? isEnabled,
    bool? isLocked,
  }) {
    return _SettingsUser(
      id: id,
      fullName: fullName,
      username: username,
      role: role ?? this.role,
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      lastLogin: lastLogin,
    );
  }
}

class _SettingsRole {
  _SettingsRole({
    required this.id,
    required this.name,
    required this.permissions,
  });

  final int id;
  final String name;
  final Map<String, Set<String>> permissions;
}

const _settingsPermissionScreens = <({String id, String label})>[
  (id: 'sales', label: 'المبيعات'),
  (id: 'purchases', label: 'المشتريات'),
  (id: 'parties', label: 'الأطراف'),
  (id: 'cashbox', label: 'الصندوق'),
  (id: 'warehouses', label: 'المخازن'),
  (id: 'items', label: 'المواد'),
  (id: 'reports', label: 'التقارير'),
  (id: 'settings', label: 'الإعدادات'),
];

const _settingsPermissionActions = <({String id, String label})>[
  (id: 'view', label: 'عرض'),
  (id: 'add', label: 'إضافة'),
  (id: 'edit', label: 'تعديل'),
  (id: 'delete', label: 'حذف'),
  (id: 'print', label: 'طباعة'),
];

const _allPermissionActionIds = <String>{
  'view',
  'add',
  'edit',
  'delete',
  'print',
};

Map<String, Set<String>> _settingsRolePermissions({
  Set<String> sales = const {},
  Set<String> purchases = const {},
  Set<String> parties = const {},
  Set<String> cashbox = const {},
  Set<String> warehouses = const {},
  Set<String> items = const {},
  Set<String> reports = const {},
  Set<String> settings = const {},
}) {
  return {
    'sales': {...sales},
    'purchases': {...purchases},
    'parties': {...parties},
    'cashbox': {...cashbox},
    'warehouses': {...warehouses},
    'items': {...items},
    'reports': {...reports},
    'settings': {...settings},
  };
}

Map<String, Set<String>> _allSettingsRolePermissions() {
  return {
    for (final screen in _settingsPermissionScreens)
      screen.id: {..._allPermissionActionIds},
  };
}

Map<String, Set<String>> _viewOnlySettingsRolePermissions() {
  return {
    for (final screen in _settingsPermissionScreens) screen.id: {'view'},
  };
}

Map<String, Set<String>> _copySettingsRolePermissions(
  Map<String, Set<String>> source,
) {
  return {
    for (final screen in _settingsPermissionScreens)
      screen.id: {...?source[screen.id]},
  };
}

String _rolePermissionSummary(Map<String, Set<String>> permissions) {
  final hasAllPermissions = _settingsPermissionScreens.every(
    (screen) =>
        permissions[screen.id]?.containsAll(_allPermissionActionIds) ??
        false,
  );
  if (hasAllPermissions) return 'كامل الصلاحيات';

  final summaries = <String>[];
  for (final screen in _settingsPermissionScreens) {
    final selected = permissions[screen.id] ?? const <String>{};
    if (selected.isEmpty) continue;
    final actionLabels = [
      for (final action in _settingsPermissionActions)
        if (selected.contains(action.id)) action.label,
    ];
    summaries.add('${screen.label}: ${actionLabels.join('، ')}');
  }
  return summaries.isEmpty ? 'بدون صلاحيات' : summaries.join(' | ');
}

class _SettingsAuditEntry {
  const _SettingsAuditEntry({
    required this.id,
    required this.createdAt,
    required this.username,
    required this.type,
    required this.details,
    required this.status,
  });

  final int id;
  final String createdAt;
  final String username;
  final String type;
  final String details;
  final String status;
}

class _SettingsUserDraft {
  const _SettingsUserDraft({
    required this.fullName,
    required this.username,
    required this.role,
  });

  final String fullName;
  final String username;
  final String role;
}

class _SettingsUserPasswordDialog extends StatefulWidget {
  const _SettingsUserPasswordDialog({
    required this.user,
    required this.accentColor,
  });

  final _SettingsUser user;
  final Color accentColor;

  @override
  State<_SettingsUserPasswordDialog> createState() =>
      _SettingsUserPasswordDialogState();
}

class _SettingsUserPasswordDialogState
    extends State<_SettingsUserPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  String? get _confirmationError {
    final confirmation = _confirmationController.text;
    if (confirmation.isEmpty || confirmation == _passwordController.text) {
      return null;
    }
    return 'كلمتا المرور غير متطابقتين';
  }

  bool get _canSave =>
      _passwordController.text.isNotEmpty &&
      _confirmationController.text.isNotEmpty &&
      _confirmationError == null;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (_canSave) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.user.id;
    return AppModuleDialog(
      key: Key('settingsUserPasswordDialog_$userId'),
      title: 'تغيير كلمة مرور المستخدم',
      subtitle: '${widget.user.fullName} — ${widget.user.username}',
      icon: Icons.password_rounded,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 620,
      actions: [
        AppButton(
          key: Key('settingsUserPasswordCancel_$userId'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _close,
        ),
        AppButton(
          key: Key('settingsUserPasswordConfirm_$userId'),
          label: 'تحديث',
          icon: Icons.refresh_rounded,
          variant: AppButtonVariant.success,
          width: 145,
          onPressed: _canSave ? _save : null,
        ),
      ],
      child: Column(
        children: [
          AppTextField(
            fieldKey: Key('settingsUserPasswordNewField_$userId'),
            controller: _passwordController,
            label: 'كلمة المرور الجديدة',
            icon: Icons.key_rounded,
            accentColor: widget.accentColor,
            obscureText: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: Key('settingsUserPasswordConfirmField_$userId'),
            controller: _confirmationController,
            label: 'تأكيد كلمة المرور',
            icon: Icons.verified_user_outlined,
            accentColor: widget.accentColor,
            obscureText: true,
            errorText: _confirmationError,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
    );
  }
}

class _SettingsRoleDraft {
  const _SettingsRoleDraft({
    required this.name,
    required this.permissions,
  });

  final String name;
  final Map<String, Set<String>> permissions;
}

class _SettingsRoleDialog extends StatefulWidget {
  const _SettingsRoleDialog({
    required this.accentColor,
    required this.existingRoleNames,
    this.initialRole,
  });

  final Color accentColor;
  final Set<String> existingRoleNames;
  final _SettingsRole? initialRole;

  @override
  State<_SettingsRoleDialog> createState() =>
      _SettingsRoleDialogState();
}

class _SettingsRoleDialogState extends State<_SettingsRoleDialog> {
  late final TextEditingController _nameController;
  late final Map<String, Set<String>> _permissions;

  bool get _isEditing => widget.initialRole != null;

  String? get _nameError {
    final name = _nameController.text.trim().toLowerCase();
    if (name.isEmpty) return null;
    return widget.existingRoleNames.contains(name)
        ? 'اسم الدور مستخدم مسبقاً'
        : null;
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _nameError == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialRole?.name ?? '',
    );
    _permissions = widget.initialRole == null
        ? _settingsRolePermissions()
        : _copySettingsRolePermissions(
            widget.initialRole!.permissions,
          );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      _SettingsRoleDraft(
        name: _nameController.text.trim(),
        permissions: _copySettingsRolePermissions(_permissions),
      ),
    );
  }

  void _setAllPermissions(bool selected) {
    setState(() {
      for (final screen in _settingsPermissionScreens) {
        _permissions[screen.id] = selected
            ? {..._allPermissionActionIds}
            : <String>{};
      }
    });
  }

  void _togglePermission(
    String screenId,
    String actionId,
    bool selected,
  ) {
    setState(() {
      final actions = _permissions.putIfAbsent(
        screenId,
        () => <String>{},
      );
      if (selected) {
        actions.add(actionId);
      } else {
        actions.remove(actionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roleId = widget.initialRole?.id;
    return AppModuleDialog(
      key: Key(
        roleId == null
            ? 'settingsRoleDialog_new'
            : 'settingsRoleDialog_$roleId',
      ),
      title: _isEditing ? 'تعديل الدور والصلاحيات' : 'إضافة دور',
      subtitle: 'حدد صلاحيات كل شاشة وإجراء بشكل مستقل',
      icon: Icons.admin_panel_settings_outlined,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 980,
      maxHeightFactor: 0.94,
      actions: [
        AppButton(
          key: const Key('settingsRoleDialogCancelButton'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _close,
        ),
        AppButton(
          key: const Key('settingsRoleDialogConfirmButton'),
          label: _isEditing ? 'تحديث' : 'إضافة',
          icon: _isEditing ? Icons.refresh_rounded : Icons.add_rounded,
          variant: _isEditing
              ? AppButtonVariant.success
              : AppButtonVariant.primary,
          width: 145,
          onPressed: _canSave ? _save : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            fieldKey: const Key('settingsRoleNameField'),
            controller: _nameController,
            label: 'اسم الدور',
            icon: Icons.badge_outlined,
            accentColor: widget.accentColor,
            errorText: _nameError,
            autofocus: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'مصفوفة صلاحيات الشاشات والإجراءات',
                  style: AppTypography.sectionTitle,
                ),
              ),
              AppRegularButton(
                key: const Key('settingsRoleSelectAllButton'),
                label: 'تحديد الكل',
                icon: Icons.done_all_rounded,
                onPressed: () => _setAllPermissions(true),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppRegularButton(
                key: const Key('settingsRoleClearAllButton'),
                label: 'إلغاء الكل',
                icon: Icons.remove_done_rounded,
                onPressed: () => _setAllPermissions(false),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPermissionMatrix(),
        ],
      ),
    );
  }

  Widget _buildPermissionMatrix() {
    final borderColor = Color.lerp(
      widget.accentColor,
      AppColors.surface,
      0.62,
    )!;
    final headerColor = Color.alphaBlend(
      widget.accentColor.withAlpha(18),
      AppColors.surface,
    );

    Widget cell(Widget child, {double height = 46}) {
      return SizedBox(
        height: height,
        child: Center(child: child),
      );
    }

    return ClipRRect(
      key: const Key('settingsRolePermissionMatrix'),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 860,
          child: Table(
            textDirection: TextDirection.rtl,
            border: TableBorder.all(color: borderColor),
            columnWidths: const {
              0: FixedColumnWidth(190),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
              4: FlexColumnWidth(),
              5: FlexColumnWidth(),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: headerColor),
                children: [
                  cell(
                    const Text(
                      'الشاشة',
                      style: AppTypography.tableHeader,
                    ),
                    height: 50,
                  ),
                  for (final action in _settingsPermissionActions)
                    cell(
                      Text(
                        action.label,
                        style: AppTypography.tableHeader,
                      ),
                      height: 50,
                    ),
                ],
              ),
              for (final screen in _settingsPermissionScreens)
                TableRow(
                  children: [
                    cell(
                      Text(
                        screen.label,
                        style: AppTypography.fieldText,
                      ),
                    ),
                    for (final action in _settingsPermissionActions)
                      cell(
                        Checkbox(
                          key: Key(
                            'settingsRolePermission_'
                            '${screen.id}_${action.id}',
                          ),
                          value: _permissions[screen.id]?.contains(
                                action.id,
                              ) ??
                              false,
                          activeColor: widget.accentColor,
                          onChanged: (value) => _togglePermission(
                            screen.id,
                            action.id,
                            value ?? false,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsUserDialog extends StatefulWidget {
  const _SettingsUserDialog({
    required this.accentColor,
    required this.roleNames,
    required this.existingUsernames,
  }) : assert(roleNames.length > 0);

  final Color accentColor;
  final List<String> roleNames;
  final Set<String> existingUsernames;

  @override
  State<_SettingsUserDialog> createState() =>
      _SettingsUserDialogState();
}

class _SettingsUserDialogState extends State<_SettingsUserDialog> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  late String _role;

  String? get _usernameError {
    final username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty) return null;
    return widget.existingUsernames.contains(username)
        ? 'اسم المستخدم مستخدم مسبقاً'
        : null;
  }

  bool get _canSave =>
      _fullNameController.text.trim().isNotEmpty &&
      _usernameController.text.trim().isNotEmpty &&
      _usernameError == null;

  @override
  void initState() {
    super.initState();
    _role = widget.roleNames.contains('المبيعات')
        ? 'المبيعات'
        : widget.roleNames.first;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      _SettingsUserDraft(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        role: _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('settingsAddUserDialog'),
      title: 'إضافة مستخدم',
      subtitle: 'نموذج تجريبي لبيانات الحساب الأساسية',
      icon: Icons.person_add_alt_1_rounded,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 620,
      actions: [
        AppButton(
          key: const Key('settingsAddUserCancelButton'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _close,
        ),
        AppButton(
          key: const Key('settingsAddUserConfirmButton'),
          label: 'إضافة',
          icon: Icons.add_rounded,
          width: 145,
          onPressed: _canSave ? _save : null,
        ),
      ],
      child: Column(
        children: [
          AppTextField(
            fieldKey: const Key('settingsAddUserFullNameField'),
            controller: _fullNameController,
            label: 'الاسم الكامل',
            icon: Icons.badge_outlined,
            accentColor: widget.accentColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const Key('settingsAddUserUsernameField'),
            controller: _usernameController,
            label: 'اسم المستخدم',
            icon: Icons.alternate_email_rounded,
            accentColor: widget.accentColor,
            errorText: _usernameError,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField<String>(
            fieldKey: const Key('settingsAddUserRoleField'),
            label: 'الدور',
            icon: Icons.admin_panel_settings_outlined,
            accentColor: widget.accentColor,
            value: _role,
            options: [
              for (final roleName in widget.roleNames)
                AppDropdownOption(value: roleName, label: roleName),
            ],
            useIntrinsicHeight: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            menuTextDirection: TextDirection.rtl,
            onChanged: (value) {
              if (value != null) setState(() => _role = value);
            },
          ),
        ],
      ),
    );
  }
}

class ElectronicArchiveSettingsSection extends StatefulWidget {
  const ElectronicArchiveSettingsSection({
    required this.accentColor,
    super.key,
  });

  final Color accentColor;

  @override
  State<ElectronicArchiveSettingsSection> createState() =>
      _ElectronicArchiveSettingsSectionState();
}

class _ElectronicArchiveSettingsSectionState
    extends State<ElectronicArchiveSettingsSection> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'settingsArchiveSearch');
  var _nextDocumentId = 4;
  final _documents = <_ArchiveDocument>[
    const _ArchiveDocument(
      id: 1,
      name: 'عقد تجهيز شركة النور',
      type: 'PDF',
      fileName: 'noor_contract.pdf',
      size: '1.8 MB',
      createdAt: '2026/07/29',
    ),
    const _ArchiveDocument(
      id: 2,
      name: 'وصل استلام المخزن الرئيسي',
      type: 'PNG',
      fileName: 'warehouse_receipt.png',
      size: '640 KB',
      createdAt: '2026/07/28',
    ),
    const _ArchiveDocument(
      id: 3,
      name: 'اتفاقية الزبون أحمد كريم',
      type: 'PDF',
      fileName: 'customer_agreement.pdf',
      size: '2.1 MB',
      createdAt: '2026/07/26',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openUploadDialog() async {
    final draft = await showDialog<_ArchiveDocumentDraft>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _ArchiveUploadDialog(accentColor: widget.accentColor),
      ),
    );
    if (draft == null || !mounted) return;

    setState(() {
      _documents.insert(
        0,
        _ArchiveDocument(
          id: _nextDocumentId++,
          name: draft.name,
          type: draft.type,
          fileName: draft.fileName,
          size: draft.type == 'PDF' ? '1.2 MB' : '720 KB',
          createdAt: '2026/07/29',
        ),
      );
    });
    AppToast.showInfo(context, 'تمت إضافة ملف تجريبي إلى الأرشيف');
  }

  Future<void> _renameDocument(_ArchiveDocument document) async {
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _ArchiveRenameDialog(
          initialName: document.name,
          accentColor: widget.accentColor,
        ),
      ),
    );
    if (name == null || !mounted) return;

    final index =
        _documents.indexWhere((entry) => entry.id == document.id);
    if (index < 0) return;
    setState(() {
      _documents[index] = document.copyWith(name: name);
    });
    AppToast.showSuccess(context, 'تم تعديل اسم الملف');
  }

  Future<void> _deleteDocument(_ArchiveDocument document) async {
    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف ملف من الأرشيف',
      message: 'هل تريد حذف «${document.name}»؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _documents.removeWhere((entry) => entry.id == document.id);
    });
    AppToast.showDanger(context, 'تم حذف الملف التجريبي');
  }

  void _viewDocument(_ArchiveDocument document) {
    AppToast.showInfo(
      context,
      'معاينة ${document.fileName} (${document.type})',
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredDocuments = _documents.where((document) {
      final haystack =
          '${document.name} ${document.fileName} ${document.type} '
          '${document.createdAt}'
              .toLowerCase();
      return query.isEmpty || haystack.contains(query);
    }).toList();

    final content = ListView(
      key: const Key('electronicArchiveSettingsContent'),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppInfoBanner(
          key: const Key('settingsArchiveInfoBanner'),
          message:
              'الأرشيف مخصص لملفات PDF وPNG، مع التسمية والبحث والمعاينة وإعادة التسمية والحذف.',
          icon: Icons.inventory_2_outlined,
          foregroundColor: widget.accentColor,
          backgroundColor: Color.alphaBlend(
            widget.accentColor.withAlpha(18),
            AppColors.surface,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsTemplatePanel(
          key: const Key('settingsArchivePanel'),
          title: 'ملفات الأرشيف',
          icon: Icons.folder_copy_outlined,
          accentColor: widget.accentColor,
          actions: [
            AppRegularButton(
              key: const Key('settingsArchiveUploadButton'),
              label: 'رفع ملف',
              icon: Icons.upload_file_rounded,
              onPressed: _openUploadDialog,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                fieldKey: const Key('settingsArchiveSearchField'),
                clearButtonKey:
                    const Key('settingsArchiveSearchClearButton'),
                controller: _searchController,
                focusNode: _searchFocusNode,
                label: 'بحث في الأرشيف',
                hint: 'اسم المستند أو الملف أو النوع أو التاريخ',
                accentColor: widget.accentColor,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              AppDataTable(
                key: const Key('settingsArchiveTable'),
                height: 440,
                rowHeight: 62,
                minimumColumnWidth: 155,
                accentColor: widget.accentColor,
                showShadow: false,
                emptyState: const AppStatePanel(
                  type: AppStateType.empty,
                  title: 'لا توجد ملفات',
                  message:
                      'ارفع ملف PDF أو PNG أو غيّر عبارة البحث الحالية.',
                ),
                columns: const [
                  AppTableColumn(label: 'اسم المستند', flex: 1.8),
                  AppTableColumn(label: 'اسم الملف', flex: 1.5),
                  AppTableColumn(label: 'النوع', flex: 0.65),
                  AppTableColumn(label: 'الحجم', flex: 0.7),
                  AppTableColumn(label: 'تاريخ الإضافة', flex: 1),
                  AppTableColumn(label: 'الإجراءات', flex: 1.15),
                ],
                rows: [
                  for (final document in filteredDocuments)
                    AppTableRow(
                      rowKey:
                          Key('settingsArchiveRow_${document.id}'),
                      onTap: () => _viewDocument(document),
                      cells: [
                        Text(
                          document.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          document.fileName,
                          textDirection: TextDirection.ltr,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Center(
                          child: AppStatusBadge(
                            label: document.type,
                            tone: document.type == 'PDF'
                                ? AppStatusTone.danger
                                : AppStatusTone.info,
                          ),
                        ),
                        Text(
                          document.size,
                          textDirection: TextDirection.ltr,
                        ),
                        Text(document.createdAt),
                        Center(
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            children: [
                              AppTableActionButton(
                                key: Key(
                                  'settingsArchiveView_${document.id}',
                                ),
                                icon: Icons.visibility_outlined,
                                tooltip: 'معاينة',
                                onPressed: () =>
                                    _viewDocument(document),
                              ),
                              AppTableActionButton(
                                key: Key(
                                  'settingsArchiveRename_${document.id}',
                                ),
                                icon: Icons.drive_file_rename_outline,
                                tooltip: 'تعديل الاسم',
                                variant: AppButtonVariant.success,
                                onPressed: () =>
                                    _renameDocument(document),
                              ),
                              AppTableActionButton(
                                key: Key(
                                  'settingsArchiveDelete_${document.id}',
                                ),
                                icon: Icons.delete_outline_rounded,
                                tooltip: 'حذف',
                                variant: AppButtonVariant.danger,
                                onPressed: () =>
                                    _deleteDocument(document),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    return AppShortcutScope(
      onSearch: _searchFocusNode.requestFocus,
      child: content,
    );
  }
}

class _ArchiveDocument {
  const _ArchiveDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.fileName,
    required this.size,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String type;
  final String fileName;
  final String size;
  final String createdAt;

  _ArchiveDocument copyWith({String? name}) {
    return _ArchiveDocument(
      id: id,
      name: name ?? this.name,
      type: type,
      fileName: fileName,
      size: size,
      createdAt: createdAt,
    );
  }
}

class _ArchiveDocumentDraft {
  const _ArchiveDocumentDraft({
    required this.name,
    required this.type,
    required this.fileName,
  });

  final String name;
  final String type;
  final String fileName;
}

class _ArchiveUploadDialog extends StatefulWidget {
  const _ArchiveUploadDialog({required this.accentColor});

  final Color accentColor;

  @override
  State<_ArchiveUploadDialog> createState() =>
      _ArchiveUploadDialogState();
}

class _ArchiveUploadDialogState extends State<_ArchiveUploadDialog> {
  final _nameController = TextEditingController();
  final _fileController =
      TextEditingController(text: 'لم يتم اختيار ملف');
  var _type = 'PDF';
  var _fileName = '';

  bool get _canUpload =>
      _nameController.text.trim().isNotEmpty && _fileName.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _fileController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _chooseFile() {
    setState(() {
      _fileName = _type == 'PDF'
          ? 'document_example.pdf'
          : 'image_example.png';
      _fileController.text = _fileName;
    });
  }

  void _upload() {
    if (!_canUpload) return;
    Navigator.of(context).pop(
      _ArchiveDocumentDraft(
        name: _nameController.text.trim(),
        type: _type,
        fileName: _fileName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('settingsArchiveUploadDialog'),
      title: 'رفع ملف إلى الأرشيف',
      subtitle: 'اختر ملف PDF أو PNG واكتب اسماً واضحاً له',
      icon: Icons.upload_file_rounded,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 680,
      actions: [
        AppButton(
          key: const Key('settingsArchiveUploadCancelButton'),
          label: 'إلغاء',
          icon: Icons.close_rounded,
          variant: AppButtonVariant.secondary,
          width: 145,
          onPressed: _close,
        ),
        AppButton(
          key: const Key('settingsArchiveUploadConfirmButton'),
          label: 'رفع',
          icon: Icons.upload_rounded,
          backgroundColor: widget.accentColor,
          width: 145,
          onPressed: _canUpload ? _upload : null,
        ),
      ],
      child: Column(
        children: [
          AppTextField(
            fieldKey: const Key('settingsArchiveDocumentNameField'),
            controller: _nameController,
            label: 'اسم المستند',
            icon: Icons.title_rounded,
            accentColor: widget.accentColor,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDropdownField<String>(
            fieldKey: const Key('settingsArchiveFileTypeField'),
            label: 'نوع الملف',
            icon: Icons.description_outlined,
            accentColor: widget.accentColor,
            value: _type,
            options: const [
              AppDropdownOption(value: 'PDF', label: 'PDF'),
              AppDropdownOption(value: 'PNG', label: 'PNG'),
            ],
            useIntrinsicHeight: true,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            menuTextDirection: TextDirection.ltr,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _type = value;
                _fileName = '';
                _fileController.text = 'لم يتم اختيار ملف';
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: const Key('settingsArchiveSelectedFileField'),
            controller: _fileController,
            label: 'الملف المحدد',
            icon: Icons.attach_file_rounded,
            accentColor: widget.accentColor,
            readOnly: true,
            enabled: false,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: AppRegularButton(
              key: const Key('settingsArchiveChooseFileButton'),
              label: 'اختيار ملف',
              icon: Icons.folder_open_rounded,
              onPressed: _chooseFile,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveRenameDialog extends StatefulWidget {
  const _ArchiveRenameDialog({
    required this.initialName,
    required this.accentColor,
  });

  final String initialName;
  final Color accentColor;

  @override
  State<_ArchiveRenameDialog> createState() =>
      _ArchiveRenameDialogState();
}

class _ArchiveRenameDialogState extends State<_ArchiveRenameDialog> {
  late final TextEditingController _nameController;

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _save() {
    if (_canSave) Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('settingsArchiveRenameDialog'),
      title: 'تعديل اسم المستند',
      icon: Icons.drive_file_rename_outline,
      accentColor: widget.accentColor,
      onClose: _close,
      width: 580,
      actions: [
        AppButton(
          key: const Key('settingsArchiveRenameCancelButton'),
          label: 'إلغاء',
          variant: AppButtonVariant.secondary,
          width: 140,
          onPressed: _close,
        ),
        AppButton(
          key: const Key('settingsArchiveRenameConfirmButton'),
          label: 'تحديث',
          icon: Icons.refresh_rounded,
          variant: AppButtonVariant.success,
          width: 140,
          onPressed: _canSave ? _save : null,
        ),
      ],
      child: AppTextField(
        fieldKey: const Key('settingsArchiveRenameField'),
        controller: _nameController,
        label: 'اسم المستند',
        icon: Icons.title_rounded,
        accentColor: widget.accentColor,
        autofocus: true,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _save(),
      ),
    );
  }
}

class SettingsTemplatePanel extends StatelessWidget {
  const SettingsTemplatePanel({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
    super.key,
    this.expandChild = false,
    this.actions = const [],
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;
  final bool expandChild;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    final borderRadius = BorderRadius.circular(AppRadii.lg);
    final borderColor = Color.lerp(
      accentColor,
      AppColors.surface,
      0.62,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: borderRadius,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: Color.alphaBlend(
                  accentColor.withAlpha(14),
                  AppColors.surface,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          accentColor.withAlpha(24),
                          AppColors.surface,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border:
                            Border.all(color: accentColor.withAlpha(90)),
                      ),
                      child: Icon(icon, color: accentColor),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.sectionTitle,
                      ),
                    ),
                    if (actions.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: actions,
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              if (expandChild) Expanded(child: body) else body,
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsResponsiveGrid extends StatelessWidget {
  const SettingsResponsiveGrid({
    required this.children,
    super.key,
    this.preferredColumns = 2,
    this.spacing = AppSpacing.md,
    this.minimumChildHeight,
  });

  final List<Widget> children;
  final int preferredColumns;
  final double spacing;
  final double? minimumChildHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = 1;
        if (constraints.maxWidth >= 1060 && preferredColumns >= 3) {
          columns = 3;
        } else if (constraints.maxWidth >= 650 && preferredColumns >= 2) {
          columns = 2;
        }
        if (columns > children.length) columns = children.length;

        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: width,
                child: minimumChildHeight == null
                    ? child
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: minimumChildHeight!,
                        ),
                        child: child,
                      ),
              ),
          ],
        );
      },
    );
  }
}

class SettingsTemplateTabs<T> extends StatelessWidget {
  const SettingsTemplateTabs({
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.keyPrefix,
    required this.accentColor,
    super.key,
  });

  final List<({T value, String label, IconData icon})> items;
  final T selected;
  final ValueChanged<T> onChanged;
  final String keyPrefix;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection: TextDirection.rtl,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          AppButton(
            key: Key('$keyPrefix${item.value}'),
            label: item.label,
            icon: item.icon,
            variant: item.value == selected
                ? AppButtonVariant.primary
                : AppButtonVariant.navigation,
            backgroundColor:
                item.value == selected ? accentColor : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
            ),
            minWidth: 160,
            onPressed: item.value == selected
                ? () {}
                : () => onChanged(item.value),
          ),
      ],
    );
  }
}
