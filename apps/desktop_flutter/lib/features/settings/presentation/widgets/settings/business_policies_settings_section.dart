part of '../settings_sections.dart';

const _settingsDeviceId = 'demo-windows-device';
const _settingsPrinterOptions = <AppDropdownOption<String>>[
  AppDropdownOption(
    value: 'Microsoft Print to PDF',
    label: 'Microsoft Print to PDF',
  ),
  AppDropdownOption(value: 'HP LaserJet Pro', label: 'HP LaserJet Pro'),
  AppDropdownOption(
    value: 'Canon Office Printer',
    label: 'Canon Office Printer',
  ),
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

class _BusinessPoliciesSettingsData {
  const _BusinessPoliciesSettingsData({
    required this.policies,
    required this.device,
  });

  final BusinessPolicySettings policies;
  final DeviceSettings device;
}

class _BusinessPoliciesSettingsSectionState
    extends State<BusinessPoliciesSettingsSection> {
  final _exchangeRateController = TextEditingController();
  final _customerDebtLimitController = TextEditingController();
  final _debtDueDaysController = TextEditingController();
  final _copiesController = TextEditingController();

  AppDataState<_BusinessPoliciesSettingsData> _state =
      const AppDataState.loading();
  BusinessSettingsRepository? _businessRepository;
  DeviceSettingsRepository? _deviceRepository;
  AppStore? _store;
  var _allowInsufficientStockSale = false;
  var _overdueDebtAlerts = true;
  var _printer = _settingsPrinterOptions.first.value;
  var _paperSize = PrintPaperSize.a4;
  var _previewEnabled = true;
  var _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_businessRepository != null) return;
    final store = AppStoreScope.of(context, listen: false);
    _store = store;
    _businessRepository = store.repositories.businessSettings;
    _deviceRepository = store.repositories.deviceSettings;
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const AppDataState.loading());
    try {
      final policies = await _businessRepository!.loadBusinessPolicies();
      final device =
          await _deviceRepository!.loadDeviceSettings(_settingsDeviceId);
      if (!mounted) return;
      _applyLoadedValues(policies, device);
      setState(
        () => _state = AppDataState.ready(
          _BusinessPoliciesSettingsData(
            policies: policies,
            device: device,
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

  void _applyLoadedValues(
    BusinessPolicySettings policies,
    DeviceSettings device,
  ) {
    _exchangeRateController.text = _formatSettingsNumber(
      policies.defaultExchangeRate.toPlainString(),
    );
    _customerDebtLimitController.text = _formatSettingsNumber(
      policies.defaultCustomerDebtLimit.toPlainString(),
    );
    _debtDueDaysController.text = '${policies.defaultDebtDueDays}';
    _copiesController.text = '${device.printCopies}';
    _allowInsufficientStockSale = policies.allowSaleWithInsufficientStock;
    _overdueDebtAlerts = policies.overdueDebtAlertsEnabled;
    _printer = _settingsPrinterOptions.any(
      (option) => option.value == device.defaultPrinterName,
    )
        ? device.defaultPrinterName!
        : _settingsPrinterOptions.first.value;
    _paperSize = device.paperSize;
    _previewEnabled = device.printPreviewEnabled;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    try {
      final policies = BusinessPolicySettings(
        defaultExchangeRate: ExchangeRate.parse(
          _exchangeRateController.text,
        ),
        allowSaleWithInsufficientStock: _allowInsufficientStockSale,
        defaultCustomerDebtLimit: Money.parse(
          _customerDebtLimitController.text,
          AppCurrency.iqd,
        ),
        defaultDebtDueDays: int.parse(
          _debtDueDaysController.text.replaceAll(',', ''),
        ),
        overdueDebtAlertsEnabled: _overdueDebtAlerts,
      );
      final device = DeviceSettings(
        deviceId: _settingsDeviceId,
        defaultPrinterName: _printer,
        paperSize: _paperSize,
        printCopies: int.parse(_copiesController.text.replaceAll(',', '')),
        printPreviewEnabled: _previewEnabled,
      );

      setState(() => _isSaving = true);
      await _businessRepository!.saveBusinessPolicies(policies);
      await _deviceRepository!.saveDeviceSettings(device);
      _store!.markDataChanged();
      if (!mounted) return;
      _applyLoadedValues(policies, device);
      setState(
        () => _state = AppDataState.ready(
          _BusinessPoliciesSettingsData(
            policies: policies,
            device: device,
          ),
        ),
      );
      AppToast.showInfo(context, 'تم حفظ سياسات العمل والطباعة');
    } catch (error) {
      if (!mounted) return;
      AppToast.showDanger(context, _settingsRepositoryMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
    return AppDataStateView<_BusinessPoliciesSettingsData>(
      state: _state,
      loadingStateKey: const Key('businessPoliciesLoadingState'),
      errorStateKey: const Key('businessPoliciesErrorState'),
      onRetry: _load,
      dataBuilder: (context, _) => _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      key: const Key('businessPoliciesSettingsContent'),
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppResponsiveGrid(
          preferredColumns: 2,
          minimumChildHeight: 330,
          children: [
            AppSectionPanel(
              key: const Key('settingsPricingInventoryPanel'),
              title: 'الأسعار والمخزون',
              icon: Icons.currency_exchange_rounded,
              accentColor: widget.accentColor,
              child: Column(
                children: [
                  AppMoneyField(
                    fieldKey:
                        const Key('settingsDefaultExchangeRateField'),
                    controller: _exchangeRateController,
                    label: 'سعر الصرف الافتراضي',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: widget.accentColor,
                    decimalPlaces: ExchangeRate.decimalPlaces,
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
            AppSectionPanel(
              key: const Key('settingsDebtInstallmentsPanel'),
              title: 'الديون والأقساط',
              icon: Icons.account_balance_wallet_outlined,
              accentColor: widget.accentColor,
              child: Column(
                children: [
                  AppMoneyField(
                    fieldKey:
                        const Key('settingsDefaultCustomerDebtLimitField'),
                    controller: _customerDebtLimitController,
                    label: 'حد الدين الافتراضي للزبون',
                    icon: Icons.credit_score_rounded,
                    accentColor: widget.accentColor,
                    decimalPlaces: 0,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppIntegerField(
                    fieldKey: const Key('settingsDefaultDebtDueDaysField'),
                    controller: _debtDueDaysController,
                    label: 'مدة استحقاق الدين الافتراضية بالأيام',
                    icon: Icons.event_repeat_rounded,
                    accentColor: widget.accentColor,
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
            onPressed: _isSaving ? null : _save,
          ),
        ),
      ],
    );
  }

  Widget _buildPrintingPanel() {
    return AppSectionPanel(
      key: const Key('settingsPrintingPanel'),
      title: 'الطباعة',
      icon: Icons.print_rounded,
      accentColor: widget.accentColor,
      child: AppResponsiveGrid(
        preferredColumns: 2,
        children: [
          AppDropdownField<String>(
            fieldKey: const Key('settingsDefaultPrinterField'),
            label: 'الطابعة الافتراضية',
            icon: Icons.print_outlined,
            accentColor: widget.accentColor,
            value: _printer,
            options: _settingsPrinterOptions,
            useIntrinsicHeight: true,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            menuTextDirection: TextDirection.rtl,
            onChanged: (value) {
              if (value == null || value == _printer) return;
              setState(() => _printer = value);
            },
          ),
          AppDropdownField<PrintPaperSize>(
            fieldKey: const Key('settingsPaperSizeField'),
            label: 'حجم الورق',
            icon: Icons.description_outlined,
            accentColor: widget.accentColor,
            value: _paperSize,
            options: const [
              AppDropdownOption(value: PrintPaperSize.a4, label: 'A4'),
              AppDropdownOption(value: PrintPaperSize.a5, label: 'A5'),
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
          AppIntegerField(
            fieldKey: const Key('settingsPrintCopiesField'),
            controller: _copiesController,
            label: 'عدد النسخ',
            icon: Icons.copy_all_outlined,
            accentColor: widget.accentColor,
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
