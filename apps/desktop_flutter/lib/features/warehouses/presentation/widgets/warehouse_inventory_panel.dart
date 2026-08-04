import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/warehouse.dart';

class WarehouseInventoryPanel extends StatelessWidget {
  const WarehouseInventoryPanel({
    required this.warehouse,
    required this.items,
    required this.materialCount,
    required this.totalQuantity,
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenProducts,
    required this.onOpenTransfer,
    required this.height,
    super.key,
  });

  final Warehouse? warehouse;
  final List<WarehouseInventoryItem> items;
  final int materialCount;
  final int totalQuantity;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenProducts;
  final VoidCallback? onOpenTransfer;
  final double height;

  @override
  Widget build(BuildContext context) {
    final warehouseName = warehouse?.name;

    return Column(
      key: const Key('warehouseInventoryPanel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    warehouseName == null
                        ? 'المخزون'
                        : 'مخزون $warehouseName',
                    style: AppTypography.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    warehouseName == null
                        ? 'اختر مخزناً لعرض أرصدته الحالية'
                        : 'عدد المواد: $materialCount  •  '
                            'إجمالي الكمية: $totalQuantity',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14 * AppDensity.scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppRegularButton(
                  key: const Key('warehouseProductsButton'),
                  label: 'المواد',
                  icon: Icons.inventory_2_outlined,
                  onPressed: onOpenProducts,
                ),
                AppRegularButton(
                  key: const Key('warehouseTransferButton'),
                  label: 'النقل المخزني',
                  icon: Icons.compare_arrows_rounded,
                  onPressed: onOpenTransfer,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppSearchField(
          controller: searchController,
          fieldKey: const Key('warehouseInventorySearchField'),
          clearButtonKey:
              const Key('warehouseInventorySearchClearButton'),
          label: 'بحث في المخزون',
          hint: 'رمز المادة أو اسم المادة أو الكمية',
          accentColor: AppModuleColors.warehouses,
          enabled: warehouse != null,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppDataTable(
            key: const Key('warehouseInventoryTable'),
            height: height,
            rowHeight: 56 * AppDensity.scale,
            minimumColumnWidth: 150 * AppDensity.scale,
            accentColor: AppModuleColors.warehouses,
            columns: const [
              AppTableColumn(label: 'رمز المادة', flex: 2),
              AppTableColumn(label: 'اسم المادة', flex: 4),
              AppTableColumn(label: 'الكمية', numeric: true, flex: 2),
            ],
            rows: [
              for (final item in items)
                AppTableRow(
                  rowKey: Key('warehouseInventoryRow_${item.id}'),
                  cells: [
                    Text(
                      item.productCode,
                      textDirection: TextDirection.ltr,
                    ),
                    Text(item.productName),
                    Text(
                      item.quantity.toString(),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
            ],
            emptyState: AppStatePanel(
              type: AppStateType.empty,
              title: warehouse == null
                  ? 'اختر مخزناً من القائمة'
                  : materialCount == 0
                      ? 'لا توجد أرصدة لهذا المخزن'
                      : 'لا توجد مواد مطابقة',
              message: warehouse == null
                  ? 'سيظهر مخزون المخزن المحدد هنا.'
                  : materialCount == 0
                      ? warehouseName!
                      : 'غيّر كلمات البحث.',
            ),
          ),
        ),
      ],
    );
  }
}
