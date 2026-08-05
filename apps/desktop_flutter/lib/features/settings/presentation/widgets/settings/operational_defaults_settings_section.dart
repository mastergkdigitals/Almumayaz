part of '../settings_sections.dart';

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

class _OperationalDefaultsSettingsData {
  const _OperationalDefaultsSettingsData({
    required this.defaults,
    required this.warehouses,
    required this.cashboxAccounts,
  });

  final OperationalDefaults defaults;
  final List<Warehouse> warehouses;
  final List<CashboxMainAccount> cashboxAccounts;
}

class _OperationalDefaultsSettingsSectionState
    extends State<OperationalDefaultsSettingsSection> {
  AppDataState<_OperationalDefaultsSettingsData> _state =
      const AppDataState.loading();
  AppStore? _store;
  BusinessSettingsRepository? _settingsRepository;
  WarehouseRepository? _warehouseRepository;
  CashboxRepository? _cashboxRepository;
  var _purchaseWarehouseId = '';
  var _purchaseType = PurchaseKind.values.first.name;
  var _purchasePaymentType = PaymentKind.cash.name;
  var _purchaseCurrency = AppCurrency.iqd.code;
  var _salesWarehouseId = '';
  var _saleType = SaleKind.cash.name;
  var _salesCurrency = AppCurrency.iqd.code;
  var _voucherType = CashboxMovementKind.receipt.name;
  var _cashboxAccountId = '';
  var _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settingsRepository != null) return;
    final store = AppStoreScope.of(context, listen: false);
    _store = store;
    _settingsRepository = store.repositories.businessSettings;
    _warehouseRepository = store.repositories.warehouses;
    _cashboxRepository = store.repositories.cashbox;
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const AppDataState.loading());
    try {
      final defaults = await _settingsRepository!.loadOperationalDefaults();
      final warehouses = await _warehouseRepository!.getAll();
      final cashboxAccounts = await _cashboxRepository!.getMainAccounts();
      if (!mounted) return;

      if (warehouses.isEmpty || cashboxAccounts.isEmpty) {
        setState(
          () => _state = const AppDataState.empty(
            message: 'أضف مخزناً وحساب صندوق قبل تحديد الإعدادات الافتراضية.',
          ),
        );
        return;
      }

      final purchaseWarehouseExists = warehouses.any(
        (warehouse) => warehouse.entityId == defaults.purchases.warehouseId,
      );
      final salesWarehouseExists = warehouses.any(
        (warehouse) => warehouse.entityId == defaults.sales.warehouseId,
      );
      final cashboxAccountExists = cashboxAccounts.any(
        (account) => account.entityId == defaults.cashbox.mainAccountId,
      );
      if (!purchaseWarehouseExists ||
          !salesWarehouseExists ||
          !cashboxAccountExists) {
        setState(
          () => _state = const AppDataState.missingReference(
            'أحد المخازن أو حسابات الصندوق المحفوظة لم يعد موجوداً.',
          ),
        );
        return;
      }

      _applyDefaults(defaults);
      setState(
        () => _state = AppDataState.ready(
          _OperationalDefaultsSettingsData(
            defaults: defaults,
            warehouses: warehouses,
            cashboxAccounts: cashboxAccounts,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _state = AppDataState.error(
          error,
          message: _settingsRepositoryMessage(error),
        ),
      );
    }
  }

  void _applyDefaults(OperationalDefaults defaults) {
    _purchaseWarehouseId = defaults.purchases.warehouseId.value;
    _purchaseType = defaults.purchases.purchaseKind.name;
    _purchasePaymentType = defaults.purchases.paymentKind.name;
    _purchaseCurrency = defaults.purchases.currency.code;
    _salesWarehouseId = defaults.sales.warehouseId.value;
    _saleType = defaults.sales.saleKind.name;
    _salesCurrency = defaults.sales.currency.code;
    _voucherType = defaults.cashbox.movementKind.name;
    _cashboxAccountId = defaults.cashbox.mainAccountId.value;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    try {
      final defaults = OperationalDefaults(
        purchases: PurchaseDefaults(
          warehouseId: EntityId(_purchaseWarehouseId),
          purchaseKind: PurchaseKind.values.firstWhere(
            (kind) => kind.name == _purchaseType,
          ),
          paymentKind: PaymentKind.values.firstWhere(
            (kind) => kind.name == _purchasePaymentType,
          ),
          currency: AppCurrency.parse(_purchaseCurrency),
        ),
        sales: SalesDefaults(
          warehouseId: EntityId(_salesWarehouseId),
          saleKind: SaleKind.values.firstWhere(
            (kind) => kind.name == _saleType,
          ),
          currency: AppCurrency.parse(_salesCurrency),
        ),
        cashbox: CashboxDefaults(
          movementKind: CashboxMovementKind.values.firstWhere(
            (kind) => kind.name == _voucherType,
          ),
          mainAccountId: EntityId(_cashboxAccountId),
        ),
      );

      setState(() => _isSaving = true);
      await _settingsRepository!.saveOperationalDefaults(defaults);
      _store!.markDataChanged();
      if (!mounted) return;
      AppToast.showInfo(context, 'تم حفظ الإعدادات الافتراضية');
      await _load();
    } catch (error) {
      if (!mounted) return;
      AppToast.showDanger(context, _settingsRepositoryMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDataStateView<_OperationalDefaultsSettingsData>(
      state: _state,
      loadingStateKey: const Key('operationalDefaultsLoadingState'),
      emptyStateKey: const Key('operationalDefaultsEmptyState'),
      missingReferenceStateKey:
          const Key('operationalDefaultsMissingReferenceState'),
      errorStateKey: const Key('operationalDefaultsErrorState'),
      onRetry: _load,
      missingReferenceActionLabel: 'إعادة المحاولة',
      onMissingReferenceAction: _load,
      dataBuilder: (context, data) => _buildContent(data),
    );
  }

  Widget _buildContent(_OperationalDefaultsSettingsData data) {
    final warehouseOptions = [
      for (final warehouse in data.warehouses)
        AppDropdownOption(
          value: warehouse.id,
          label: warehouse.name,
        ),
    ];
    final cashboxOptions = [
      for (final account in data.cashboxAccounts)
        AppDropdownOption(value: account.id, label: account.label),
    ];

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
                    value: _purchaseWarehouseId,
                    options: warehouseOptions,
                    onChanged: (value) {
                      setState(() => _purchaseWarehouseId = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsPurchaseDefaultType',
                    label: 'نوع الشراء الافتراضي',
                    icon: Icons.sell_outlined,
                    value: _purchaseType,
                    options: [
                      for (final kind in PurchaseKind.values)
                        AppDropdownOption(
                          value: kind.name,
                          label: _purchaseKindLabel(kind),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _purchaseType = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsPurchaseDefaultPayment',
                    label: 'نوع الدفع الافتراضي',
                    icon: Icons.payments_outlined,
                    value: _purchasePaymentType,
                    options: [
                      for (final kind in PaymentKind.values)
                        AppDropdownOption(
                          value: kind.name,
                          label: _paymentKindLabel(kind),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _purchasePaymentType = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsPurchaseDefaultCurrency',
                    label: 'العملة الافتراضية',
                    icon: Icons.currency_exchange_rounded,
                    value: _purchaseCurrency,
                    options: _currencyOptions,
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
                    value: _salesWarehouseId,
                    options: warehouseOptions,
                    onChanged: (value) {
                      setState(() => _salesWarehouseId = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsSalesDefaultType',
                    label: 'نوع البيع الافتراضي',
                    icon: Icons.sell_outlined,
                    value: _saleType,
                    options: [
                      for (final kind in SaleKind.values)
                        AppDropdownOption(
                          value: kind.name,
                          label: _saleKindLabel(kind),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _saleType = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsSalesDefaultCurrency',
                    label: 'العملة الافتراضية',
                    icon: Icons.currency_exchange_rounded,
                    value: _salesCurrency,
                    options: _currencyOptions,
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
                    value: _voucherType,
                    options: [
                      for (final kind in CashboxMovementKind.values)
                        AppDropdownOption(
                          value: kind.name,
                          label: _movementKindLabel(kind),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _voucherType = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _dropdown(
                    key: 'settingsCashboxDefaultAccount',
                    label: 'الحساب الرئيسي الافتراضي',
                    icon: Icons.account_tree_outlined,
                    value: _cashboxAccountId,
                    options: cashboxOptions,
                    onChanged: (value) {
                      setState(() => _cashboxAccountId = value);
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
            onPressed: _isSaving ? null : _save,
          ),
        ),
      ],
    );
  }

  List<AppDropdownOption<String>> get _currencyOptions => [
        for (final currency in AppCurrency.values)
          AppDropdownOption(
            value: currency.code,
            label: currency.arabicName,
          ),
      ];

  Widget _dropdown({
    required String key,
    required String label,
    required IconData icon,
    required String value,
    required List<AppDropdownOption<String>> options,
    required ValueChanged<String> onChanged,
  }) {
    return AppDropdownField<String>(
      fieldKey: Key(key),
      label: label,
      icon: icon,
      accentColor: widget.accentColor,
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

String _purchaseKindLabel(PurchaseKind kind) => switch (kind.index) {
      1 => 'إستيراد',
      2 => 'إرجاع',
      _ => 'محلي',
    };

String _paymentKindLabel(PaymentKind kind) =>
    kind == PaymentKind.cash ? 'نقدي' : 'آجل';

String _saleKindLabel(SaleKind kind) => switch (kind) {
      SaleKind.cash => 'نقدي',
      SaleKind.credit => 'آجل',
      SaleKind.installments => 'أقساط',
    };

String _movementKindLabel(CashboxMovementKind kind) =>
    kind == CashboxMovementKind.receipt ? 'قبض' : 'صرف';
