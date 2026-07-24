import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryBusinessDialogsSection extends StatelessWidget {
  const DesignGalleryBusinessDialogsSection({super.key});

  Future<void> _showStatement(BuildContext context) async {
    await AppStatementOptionsDialog.show(
      context,
      partyName: 'أسواق دجلة',
      firstTransactionDate: DateTime(2026, 1, 1),
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
                onPressed: () => _showStatement(context),
              ),
              AppButton(
                key: const Key('designTransferDialogButton'),
                label: 'النقل المخزني',
                icon: Icons.compare_arrows_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => _showManagement(
                  context,
                  _ManagementDialogSpec.transfer,
                ),
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

enum _ManagementDialogKind { transfer, dual }

@immutable
class _ManagementDialogSpec {
  const _ManagementDialogSpec({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.kind,
    this.primaryTitle = '',
    this.secondaryTitle = '',
    this.primaryFieldLabel = '',
    this.secondaryFieldLabel = '',
    this.primaryValues = const [],
    this.secondaryValues = const [],
  });

  static const transfer = _ManagementDialogSpec(
    keyName: 'designTransferDialog',
    title: 'النقل المخزني',
    subtitle: 'نقل المواد بين المخازن مع التحقق من الرصيد',
    icon: Icons.compare_arrows_rounded,
    accentColor: AppModuleColors.warehouses,
    kind: _ManagementDialogKind.transfer,
  );

  static const groupsAndTypes = _ManagementDialogSpec(
    keyName: 'designGroupsTypesDialog',
    title: 'المجموعات والأنواع',
    subtitle: 'تنظيم دليل المواد',
    icon: Icons.category_rounded,
    accentColor: AppModuleColors.warehouses,
    kind: _ManagementDialogKind.dual,
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
    kind: _ManagementDialogKind.dual,
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
    kind: _ManagementDialogKind.dual,
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
  final _ManagementDialogKind kind;
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
  final _notesController = TextEditingController();
  String _fromWarehouse = 'main';
  String _toWarehouse = 'secondary';
  String _parentValue = 'first';
  DateTime _transferDate = DateTime(2026, 12, 31);

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _notesController.dispose();
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
          label: spec.kind == _ManagementDialogKind.transfer
              ? 'تنفيذ النقل'
              : 'حفظ',
          icon: spec.kind == _ManagementDialogKind.transfer
              ? Icons.swap_horiz_rounded
              : Icons.save_rounded,
          width: 176,
          onPressed: _close,
        ),
      ],
      child: spec.kind == _ManagementDialogKind.transfer
          ? _buildTransfer(spec)
          : _buildDualManagement(spec),
    );
  }

  Widget _buildTransfer(_ManagementDialogSpec spec) {
    const warehouseOptions = [
      AppDropdownOption(value: 'main', label: 'المخزن الرئيسي'),
      AppDropdownOption(value: 'secondary', label: 'المخزن الفرعي'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDialogSection(
          title: 'بيانات النقل',
          icon: Icons.local_shipping_rounded,
          accentColor: spec.accentColor,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppDropdownField<String>(
                      label: 'من مخزن',
                      icon: Icons.warehouse_rounded,
                      accentColor: spec.accentColor,
                      value: _fromWarehouse,
                      options: warehouseOptions,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _fromWarehouse = value);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppDropdownField<String>(
                      label: 'إلى مخزن',
                      icon: Icons.warehouse_rounded,
                      accentColor: spec.accentColor,
                      value: _toWarehouse,
                      options: warehouseOptions,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _toWarehouse = value);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppDateField(
                      label: 'تاريخ النقل',
                      value: _transferDate,
                      accentColor: spec.accentColor,
                      onChanged: (value) =>
                          setState(() => _transferDate = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _notesController,
                label: 'الملاحظات',
                icon: Icons.notes_rounded,
                accentColor: spec.accentColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppDialogSection(
          title: 'مواد النقل',
          icon: Icons.inventory_2_rounded,
          accentColor: spec.accentColor,
          child: AppDataTable(
            height: 180,
            minimumColumnWidth: 130,
            accentColor: spec.accentColor,
            columns: const [
              AppTableColumn(label: 'رمز المادة'),
              AppTableColumn(label: 'اسم المادة'),
              AppTableColumn(label: 'الرصيد المتوفر', numeric: true),
              AppTableColumn(label: 'الكمية', numeric: true),
              AppTableColumn(label: 'الإجراء'),
            ],
            rows: const [
              AppTableRow(
                cells: [
                  Text('P-001'),
                  Text('دفتر ملاحظات'),
                  Text('1,000'),
                  Text('100'),
                  AppTableActionButton(
                    icon: Icons.delete_rounded,
                    tooltip: 'حذف السطر',
                    onPressed: _noop,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
                    if (value == null) return;
                    setState(() => _parentValue = value);
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
