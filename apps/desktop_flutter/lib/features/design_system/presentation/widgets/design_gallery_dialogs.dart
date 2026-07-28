import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../../warehouses/domain/warehouse.dart';
import '../../../warehouses/presentation/widgets/inventory_transfer_dialog.dart';
import 'design_gallery_management_dialog.dart';
import 'design_gallery_section.dart';

class DesignGalleryBusinessDialogsSection extends StatelessWidget {
  const DesignGalleryBusinessDialogsSection({super.key});

  static const _searchRecords = [
    AppSearchRecord(
      value: '102',
      title: 'قائمة شراء رقم 102',
      subtitle: 'مجهز الرافدين',
      details: '24/07/2026 • 3 مواد',
      searchTerms: ['102', 'الرافدين', 'دفتر ملاحظات'],
    ),
    AppSearchRecord(
      value: '101',
      title: 'قائمة شراء رقم 101',
      subtitle: 'شركة النخيل للتجارة',
      details: '23/07/2026 • مادتان',
      searchTerms: ['101', 'النخيل', 'قلم أزرق'],
    ),
    AppSearchRecord(
      value: '100',
      title: 'قائمة شراء رقم 100',
      subtitle: 'مجهز دجلة',
      details: '22/07/2026 • 5 مواد',
      searchTerms: ['100', 'دجلة', 'ورق طباعة'],
    ),
  ];

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

  static const _transferWarehouses = [
    Warehouse(
      id: 'main',
      number: 1,
      name: 'المخزن الرئيسي',
      location: 'بغداد',
      notes: '',
      isMain: true,
    ),
    Warehouse(
      id: 'secondary',
      number: 2,
      name: 'المخزن الفرعي',
      location: 'الكرادة',
      notes: '',
    ),
  ];

  static const _transferInventory = <String, List<WarehouseInventoryItem>>{
    'main': [
      WarehouseInventoryItem(
        id: 'main-p001',
        productCode: 'P-001',
        productName: 'دفتر ملاحظات',
        quantity: 1200,
      ),
      WarehouseInventoryItem(
        id: 'main-p002',
        productCode: 'P-002',
        productName: 'قلم أزرق',
        quantity: 450,
      ),
    ],
    'secondary': [
      WarehouseInventoryItem(
        id: 'secondary-p001',
        productCode: 'P-001',
        productName: 'دفتر ملاحظات',
        quantity: 80,
      ),
      WarehouseInventoryItem(
        id: 'secondary-p002',
        productCode: 'P-002',
        productName: 'قلم أزرق',
        quantity: 35,
      ),
    ],
  };

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

  Future<void> _showRecordSearch(BuildContext context) async {
    final result = await AppRecordSearchDialog.show<String>(
      context,
      title: 'بحث قوائم الشراء',
      hint: 'اسم المجهز أو رقم القائمة أو اسم المادة',
      accentColor: AppModuleColors.purchases,
      records: _searchRecords,
      dialogKey: const Key('designRecordSearchDialog'),
      searchFieldKey: const Key('designRecordSearchField'),
      resultKeyPrefix: 'designRecordSearchResult',
    );

    if (result != null && context.mounted) {
      AppToast.showInfo(context, 'تم اختيار قائمة الشراء رقم $result');
    }
  }

  Future<void> _showTransfer(BuildContext context) async {
    final transferred = await InventoryTransferDialog.show(
      context,
      warehouses: _transferWarehouses,
      inventoryFor: (warehouseId) =>
          _transferInventory[warehouseId] ?? const [],
      onTransfer: ({
        required String fromWarehouseId,
        required String toWarehouseId,
        required Map<String, int> quantitiesByProductCode,
      }) {
        return fromWarehouseId != toWarehouseId &&
            quantitiesByProductCode.isNotEmpty;
      },
      initialFromWarehouseId: 'main',
    );

    if (transferred && context.mounted) {
      AppToast.showInfo(
        context,
        'تم تنفيذ النقل المخزني مؤقتاً',
      );
    }
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
                key: const Key('designRecordSearchDialogButton'),
                label: 'نموذج البحث',
                icon: Icons.search_rounded,
                backgroundColor: AppModuleColors.purchases,
                onPressed: () => _showRecordSearch(context),
              ),
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
                onPressed: () => _showTransfer(context),
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
