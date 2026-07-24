import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';
import 'design_gallery_transfer_dialog.dart';

class DesignGalleryBusinessDialogsSection extends StatelessWidget {
  const DesignGalleryBusinessDialogsSection({super.key});

  static final _statementEntries = [
    AppStatementReportEntry(
      date: DateTime(2026, 1, 1),
      balance: 250000,
      credit: 250000,
      debit: 0,
      type: 'رصيد افتتاحي',
      details: 'الرصيد الافتتاحي للطرف',
    ),
    AppStatementReportEntry(
      date: DateTime(2026, 1, 8),
      balance: 325000,
      credit: 75000,
      debit: 0,
      type: 'فاتورة بيع',
      quantity: 25,
      details: 'دفاتر وأقلام مكتبية',
    ),
    AppStatementReportEntry(
      date: DateTime(2026, 1, 12),
      balance: 225000,
      credit: 0,
      debit: 100000,
      type: 'قبض',
      details: 'سند قبض رقم 15',
    ),
    AppStatementReportEntry(
      date: DateTime(2026, 1, 20),
      balance: 265000,
      credit: 40000,
      debit: 0,
      type: 'فاتورة بيع',
      quantity: 2,
      details: 'طابعتان مكتبيتان',
    ),
  ];

  Future<void> _showStatement(BuildContext context) async {
    final options = await AppStatementOptionsDialog.show(
      context,
      partyName: 'أسواق دجلة',
      firstTransactionDate: DateTime(2026, 1, 1),
    );
    if (!context.mounted || options == null) return;

    await AppStatementReportDialog.show(
      context,
      partyName: 'أسواق دجلة',
      options: options,
      entries: _statementEntries,
    );
  }

  Future<void> _showManagement(
    BuildContext context,
    _ManagementDialogSpec spec,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _ManagementPreviewDialog(spec: spec),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      title: 'النوافذ المتخصصة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInfoBanner(
            message:
                'كل النوافذ تستخدم نفس الهيكل، مع لون وأيقونة القسم ومحتوى يناسب العملية.',
            icon: Icons.dashboard_customize_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton(
                key: const Key('designStatementDialogButton'),
                label: 'كشف الحساب',
                icon: Icons.receipt_long_rounded,
                backgroundColor: AppModuleColors.parties,
                onPressed: () => _showStatement(context),
              ),
              AppButton(
                key: const Key('designTransferDialogButton'),
                label: 'النقل المخزني',
                icon: Icons.compare_arrows_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => DesignGalleryTransferDialog.show(context),
              ),
              AppButton(
                key: const Key('designGroupsTypesDialogButton'),
                label: 'المجموعات والأنواع',
                icon: Icons.category_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => _showManagement(
                  context,
                  _ManagementDialogSpec.groupsAndTypes,
                ),
              ),
              AppButton(
                key: const Key('designWorkplacesDialogButton'),
                label: 'جهات العمل',
                icon: Icons.business_center_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => _showManagement(
                  context,
                  _ManagementDialogSpec.workplaces,
                ),
              ),
              AppButton(
                key: const Key('designCashboxTabsDialogButton'),
                label: 'تبويبات الصندوق',
                icon: Icons.account_balance_wallet_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => _showManagement(
                  context,
                  _ManagementDialogSpec.cashboxTabs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

@immutable
class _ManagementDialogSpec {
  const _ManagementDialogSpec({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.primaryTitle,
    required this.secondaryTitle,
    required this.primaryFieldLabel,
    required this.secondaryFieldLabel,
    required this.primaryValues,
    required this.secondaryValues,
  });

  static const groupsAndTypes = _ManagementDialogSpec(
    keyName: 'designGroupsTypesDialog',
    title: 'المجموعات والأنواع',
    subtitle: 'تنظيم دليل المواد',
    icon: Icons.category_rounded,
    accentColor: AppModuleColors.warehouses,
    primaryTitle: 'المجموعات',
    secondaryTitle: 'الأنواع',
    primaryFieldLabel: 'اسم المجموعة',
    secondaryFieldLabel: 'اسم النوع',
    primaryValues: ['قرطاسية', 'أجهزة مكتبية'],
    secondaryValues: ['أقلام', 'طابعات'],
  );

  static const workplaces = _ManagementDialogSpec(
    keyName: 'designWorkplacesDialog',
    title: 'جهات العمل',
    subtitle: 'إدارة جهات العمل والفروع المرتبطة بها',
    icon: Icons.business_center_rounded,
    accentColor: AppModuleColors.parties,
    primaryTitle: 'جهات العمل',
    secondaryTitle: 'الفروع',
    primaryFieldLabel: 'اسم جهة العمل',
    secondaryFieldLabel: 'اسم الفرع',
    primaryValues: ['شركة النور', 'أسواق دجلة'],
    secondaryValues: ['الفرع الرئيسي', 'فرع الكرادة'],
  );

  static const cashboxTabs = _ManagementDialogSpec(
    keyName: 'designCashboxTabsDialog',
    title: 'تبويبات الصندوق',
    subtitle: 'إدارة الحسابات الرئيسية والفرعية',
    icon: Icons.account_balance_wallet_rounded,
    accentColor: AppModuleColors.cashbox,
    primaryTitle: 'الحسابات الرئيسية',
    secondaryTitle: 'الحسابات الفرعية',
    primaryFieldLabel: 'اسم الحساب الرئيسي',
    secondaryFieldLabel: 'اسم الحساب الفرعي',
    primaryValues: ['الأطراف', 'المصاريف'],
    secondaryValues: ['نقل', 'صيانة'],
  );

  final String keyName;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String primaryTitle;
  final String secondaryTitle;
  final String primaryFieldLabel;
  final String secondaryFieldLabel;
  final List<String> primaryValues;
  final List<String> secondaryValues;
}

class _ManagementPreviewDialog extends StatefulWidget {
  const _ManagementPreviewDialog({required this.spec});

  final _ManagementDialogSpec spec;

  @override
  State<_ManagementPreviewDialog> createState() =>
      _ManagementPreviewDialogState();
}

class _ManagementPreviewDialogState
    extends State<_ManagementPreviewDialog> {
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();
  String _parentValue = 'first';

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    return AppModuleDialog(
      key: Key(spec.keyName),
      title: spec.title,
      subtitle: spec.subtitle,
      icon: spec.icon,
      accentColor: spec.accentColor,
      onClose: _close,
      actionsKey: Key('${spec.keyName}Actions'),
      actions: [
        AppButton(
          key: Key('${spec.keyName}Cancel'),
          label: 'إغلاق',
          variant: AppButtonVariant.secondary,
          width: 144,
          onPressed: _close,
        ),
        AppButton(
          key: Key('${spec.keyName}Confirm'),
          label: 'حفظ',
          icon: Icons.save_rounded,
          width: 176,
          backgroundColor: spec.accentColor,
          onPressed: _close,
        ),
      ],
      child: _buildDualManagement(spec),
    );
  }

  Widget _buildDualManagement(_ManagementDialogSpec spec) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppDialogSection(
            title: spec.primaryTitle,
            icon: Icons.folder_rounded,
            accentColor: spec.accentColor,
            child: Column(
              children: [
                AppTextField(
                  controller: _primaryController,
                  label: spec.primaryFieldLabel,
                  icon: Icons.add_rounded,
                  accentColor: spec.accentColor,
                ),
                const SizedBox(height: AppSpacing.md),
                _PreviewEntries(
                  values: spec.primaryValues,
                  accentColor: spec.accentColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppDialogSection(
            title: spec.secondaryTitle,
            icon: Icons.account_tree_rounded,
            accentColor: spec.accentColor,
            child: Column(
              children: [
                AppDropdownField<String>(
                  label: spec.primaryTitle,
                  icon: Icons.link_rounded,
                  accentColor: spec.accentColor,
                  value: _parentValue,
                  options: [
                    AppDropdownOption(
                      value: 'first',
                      label: spec.primaryValues.first,
                    ),
                    AppDropdownOption(
                      value: 'second',
                      label: spec.primaryValues.last,
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _parentValue = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _secondaryController,
                  label: spec.secondaryFieldLabel,
                  icon: Icons.add_rounded,
                  accentColor: spec.accentColor,
                ),
                const SizedBox(height: AppSpacing.md),
                _PreviewEntries(
                  values: spec.secondaryValues,
                  accentColor: spec.accentColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewEntries extends StatelessWidget {
  const _PreviewEntries({
    required this.values,
    required this.accentColor,
  });

  final List<String> values;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 9, color: accentColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    values[index],
                    style: AppTypography.tableCell,
                  ),
                ),
                const AppTableActionButton(
                  icon: Icons.edit_rounded,
                  tooltip: 'تعديل',
                  onPressed: _noop,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

void _noop() {}
