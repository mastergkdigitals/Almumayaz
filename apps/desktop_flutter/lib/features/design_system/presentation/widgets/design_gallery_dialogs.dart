import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_management_dialog.dart';
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
                onPressed: () =>
                    DesignGalleryTransferDialog.show(context),
              ),
              AppButton(
                key: const Key('designGroupsTypesDialogButton'),
                label: 'المجموعات والأنواع',
                icon: Icons.category_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => DesignGalleryManagementDialog.show(
                  context,
                  DesignGalleryManagementDialogSpec.groupsAndTypes,
                ),
              ),
              AppButton(
                key: const Key('designWorkplacesDialogButton'),
                label: 'جهات العمل',
                icon: Icons.business_center_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => DesignGalleryManagementDialog.show(
                  context,
                  DesignGalleryManagementDialogSpec.workplaces,
                ),
              ),
              AppButton(
                key: const Key('designCashboxTabsDialogButton'),
                label: 'تبويبات الصندوق',
                icon: Icons.account_balance_wallet_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => DesignGalleryManagementDialog.show(
                  context,
                  DesignGalleryManagementDialogSpec.cashboxTabs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
