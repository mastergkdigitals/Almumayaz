import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

const _currencyOptions = [
  AppDropdownOption(value: 'IQD', label: 'دينار'),
  AppDropdownOption(value: 'USD', label: 'دولار'),
];

class DesignGalleryFieldsGroup extends StatefulWidget {
  const DesignGalleryFieldsGroup({super.key});

  @override
  State<DesignGalleryFieldsGroup> createState() =>
      _DesignGalleryFieldsGroupState();
}

class _DesignGalleryFieldsGroupState extends State<DesignGalleryFieldsGroup> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  final _moneyController = TextEditingController(text: '25000');

  late final List<_ModulePreviewData> _modules;
  String _currency = 'IQD';
  bool _allowNegativeStock = false;

  @override
  void initState() {
    super.initState();
    _modules = [
      _ModulePreviewData(
        title: 'الأطراف',
        icon: Icons.groups_rounded,
        accentColor: AppModuleColors.parties,
      ),
      _ModulePreviewData(
        title: 'المشتريات',
        icon: Icons.shopping_cart_checkout_rounded,
        accentColor: AppModuleColors.purchases,
      ),
      _ModulePreviewData(
        title: 'المبيعات',
        icon: Icons.point_of_sale_rounded,
        accentColor: AppModuleColors.sales,
      ),
      _ModulePreviewData(
        title: 'الصندوق',
        icon: Icons.account_balance_wallet_rounded,
        accentColor: AppModuleColors.cashbox,
      ),
      _ModulePreviewData(
        title: 'المخازن',
        icon: Icons.warehouse_rounded,
        accentColor: AppModuleColors.warehouses,
      ),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    _moneyController.dispose();
    for (final module in _modules) {
      module.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignGallerySection(
          title: 'حقول الإدخال',
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              SizedBox(
                width: 320,
                child: AppTextField(
                  controller: _nameController,
                  label: 'اسم المادة',
                  icon: Icons.inventory_2_rounded,
                  textInputAction: TextInputAction.next,
                ),
              ),
              SizedBox(
                width: 320,
                child: AppSearchField(
                  controller: _searchController,
                  fieldKey: const Key('designSearchField'),
                  clearButtonKey: const Key('designSearchClearButton'),
                  label: 'البحث عن مادة',
                ),
              ),
              SizedBox(
                width: 320,
                child: AppIntegerField(
                  controller: _quantityController,
                  label: 'الكمية',
                  icon: Icons.numbers_rounded,
                ),
              ),
              SizedBox(
                width: 320,
                child: AppMoneyField(
                  controller: _moneyController,
                  label: 'المبلغ',
                ),
              ),
              SizedBox(
                width: 320,
                child: AppDropdownField<String>(
                  fieldKey: const Key('designCurrencyDropdown'),
                  label: 'العملة',
                  icon: Icons.currency_exchange_rounded,
                  value: _currency,
                  options: _currencyOptions,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _currency = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: AppSwitchField(
                  title: 'السماح بالمخزون السالب',
                  subtitle: 'مغلق افتراضياً ويمكن تفعيله بصلاحية',
                  icon: Icons.inventory_rounded,
                  value: _allowNegativeStock,
                  onChanged: (value) =>
                      setState(() => _allowNegativeStock = value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DesignGallerySection(
          title: 'حقول الأقسام',
          child: Column(
            children: [
              for (var index = 0; index < _modules.length; index++) ...[
                if (index > 0) const SizedBox(height: AppSpacing.md),
                _ModuleFieldsPreview(
                  data: _modules[index],
                  onCurrencyChanged: (value) {
                    if (value == null) return;
                    setState(() => _modules[index].currency = value);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ModulePreviewData {
  _ModulePreviewData({
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final TextEditingController nameController = TextEditingController();
  String currency = 'IQD';

  void dispose() => nameController.dispose();
}

class _ModuleFieldsPreview extends StatelessWidget {
  const _ModuleFieldsPreview({
    required this.data,
    required this.onCurrencyChanged,
  });

  final _ModulePreviewData data;
  final ValueChanged<String?> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor = Color.alphaBlend(
      data.accentColor.withAlpha(96),
      AppColors.border,
    );
    final backgroundColor = Color.alphaBlend(
      data.accentColor.withAlpha(8),
      AppColors.surface,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 24,
                decoration: BoxDecoration(
                  color: data.accentColor,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(data.title, style: AppTypography.sectionTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: data.nameController,
                  label: 'الاسم',
                  icon: data.icon,
                  accentColor: data.accentColor,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: AppDropdownField<String>(
                  label: 'العملة',
                  icon: Icons.currency_exchange_rounded,
                  accentColor: data.accentColor,
                  value: data.currency,
                  options: _currencyOptions,
                  onChanged: onCurrencyChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
