import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

const _warehouseOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'main', label: 'المخزن الرئيسي'),
  AppDropdownOption(value: 'branch', label: 'مخزن الكرادة'),
];

const _purchaseTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'local', label: 'محلي'),
  AppDropdownOption(value: 'import', label: 'إستيراد'),
  AppDropdownOption(value: 'return', label: 'إرجاع'),
];

const _paymentTypeOptions = <AppDropdownOption<String>>[
  AppDropdownOption(value: 'cash', label: 'نقد'),
  AppDropdownOption(value: 'credit', label: 'آجل'),
];

class DesignGalleryPurchaseFieldComparisonSection extends StatefulWidget {
  const DesignGalleryPurchaseFieldComparisonSection({super.key});

  @override
  State<DesignGalleryPurchaseFieldComparisonSection> createState() =>
      _DesignGalleryPurchaseFieldComparisonSectionState();
}

class _DesignGalleryPurchaseFieldComparisonSectionState
    extends State<DesignGalleryPurchaseFieldComparisonSection> {
  final _oldInvoiceNumberController = TextEditingController(text: '1001');
  final _oldExchangeRateController =
      TextEditingController(text: '1,310.00');
  final _currentInvoiceNumberController =
      TextEditingController(text: '1001');
  final _currentExchangeRateController =
      TextEditingController(text: '1,310.00');

  String _oldWarehouse = 'main';
  String _oldPurchaseType = 'local';
  String _oldPaymentType = 'cash';
  String _currentWarehouse = 'main';
  String _currentPurchaseType = 'local';
  String _currentPaymentType = 'cash';

  @override
  void dispose() {
    _oldInvoiceNumberController.dispose();
    _oldExchangeRateController.dispose();
    _currentInvoiceNumberController.dispose();
    _currentExchangeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      key: const Key('designPurchaseFieldComparison'),
      title: 'مقارنة حقول وقوائم المشتريات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'حقول وقوائم تطبيق المشتريات القديم',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            key: const Key('designOldPurchaseFieldsRow'),
            children: [
              Expanded(
                child: _OldPurchaseTextField(
                  fieldKey: const Key('designOldPurchaseInvoiceField'),
                  controller: _oldInvoiceNumberController,
                  label: 'رقم القائمة',
                  icon: Icons.tag_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _purchaseDropdown(
                  fieldKey:
                      const Key('designOldPurchaseWarehouseDropdown'),
                  label: 'المخزن',
                  icon: Icons.warehouse_rounded,
                  value: _oldWarehouse,
                  options: _warehouseOptions,
                  visualStyle: AppDropdownVisualStyle.oldPurchase,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _oldWarehouse = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _purchaseDropdown(
                  fieldKey:
                      const Key('designOldPurchaseTypeDropdown'),
                  label: 'نوع الشراء',
                  icon: Icons.shopping_cart_checkout_rounded,
                  value: _oldPurchaseType,
                  options: _purchaseTypeOptions,
                  visualStyle: AppDropdownVisualStyle.oldPurchase,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _oldPurchaseType = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _purchaseDropdown(
                  fieldKey:
                      const Key('designOldPaymentTypeDropdown'),
                  label: 'نوع الدفع',
                  icon: Icons.payments_outlined,
                  value: _oldPaymentType,
                  options: _paymentTypeOptions,
                  visualStyle: AppDropdownVisualStyle.oldPurchase,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _oldPaymentType = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OldPurchaseTextField(
                  fieldKey:
                      const Key('designOldPurchaseExchangeRateField'),
                  controller: _oldExchangeRateController,
                  label: 'سعر الصرف',
                  icon: Icons.price_change_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'حقول وقوائم التطبيق الجديد الحالية',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            key: const Key('designCurrentPurchaseFieldsRow'),
            children: [
              Expanded(
                child: AppTextField(
                  fieldKey:
                      const Key('designCurrentPurchaseInvoiceField'),
                  controller: _currentInvoiceNumberController,
                  label: 'رقم القائمة',
                  icon: Icons.tag_rounded,
                  accentColor: AppModuleColors.purchases,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _purchaseDropdown(
                  fieldKey:
                      const Key('designCurrentPurchaseWarehouseDropdown'),
                  label: 'المخزن',
                  icon: Icons.warehouse_rounded,
                  value: _currentWarehouse,
                  options: _warehouseOptions,
                  visualStyle: AppDropdownVisualStyle.standard,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _currentWarehouse = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _purchaseDropdown(
                  fieldKey:
                      const Key('designCurrentPurchaseTypeDropdown'),
                  label: 'نوع الشراء',
                  icon: Icons.shopping_cart_checkout_rounded,
                  value: _currentPurchaseType,
                  options: _purchaseTypeOptions,
                  visualStyle: AppDropdownVisualStyle.standard,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _currentPurchaseType = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _purchaseDropdown(
                  fieldKey:
                      const Key('designCurrentPaymentTypeDropdown'),
                  label: 'نوع الدفع',
                  icon: Icons.payments_outlined,
                  value: _currentPaymentType,
                  options: _paymentTypeOptions,
                  visualStyle: AppDropdownVisualStyle.standard,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _currentPaymentType = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  fieldKey: const Key(
                    'designCurrentPurchaseExchangeRateField',
                  ),
                  controller: _currentExchangeRateController,
                  label: 'سعر الصرف',
                  icon: Icons.price_change_outlined,
                  accentColor: AppModuleColors.purchases,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _purchaseDropdown({
    required Key fieldKey,
    required String label,
    required IconData icon,
    required String value,
    required List<AppDropdownOption<String>> options,
    required AppDropdownVisualStyle visualStyle,
    required ValueChanged<String?> onChanged,
  }) {
    return AppDropdownField<String>(
      fieldKey: fieldKey,
      label: label,
      icon: icon,
      accentColor: AppModuleColors.purchases,
      useIntrinsicHeight: true,
      contentPadding: visualStyle == AppDropdownVisualStyle.oldPurchase
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
          : null,
      textAlign: visualStyle == AppDropdownVisualStyle.oldPurchase
          ? TextAlign.center
          : TextAlign.start,
      value: value,
      options: options,
      visualStyle: visualStyle,
      onChanged: onChanged,
    );
  }
}

class _OldPurchaseTextField extends StatelessWidget {
  const _OldPurchaseTextField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: Color(0xFF64748B),
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
    final borderRadius = BorderRadius.circular(14);

    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        floatingLabelStyle: labelStyle.copyWith(
          color: AppModuleColors.purchases,
        ),
        prefixIcon: Icon(
          icon,
          color: AppModuleColors.purchases,
          size: AppIconSizes.md,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: borderRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(
            color: AppModuleColors.purchases,
            width: 1.6,
          ),
        ),
      ),
    );
  }
}
