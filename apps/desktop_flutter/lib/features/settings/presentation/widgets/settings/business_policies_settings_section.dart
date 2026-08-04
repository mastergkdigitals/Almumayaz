part of '../settings_sections.dart';

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
