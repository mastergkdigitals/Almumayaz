import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryInvoiceTablesSection extends StatelessWidget {
  const DesignGalleryInvoiceTablesSection({super.key});

  static final _purchaseRows = <AppTableRow>[
    AppTableRow(
      cells: [
        const Text('1'),
        const Text('P-001'),
        const Text('دفتر ملاحظات'),
        const Text('الرئيسي'),
        Text(AppFormatters.quantity(100)),
        Text(AppFormatters.quantity(1)),
        Text(AppFormatters.iqd(2500)),
        Text(AppFormatters.iqd(0)),
        Text(AppFormatters.iqd(2500)),
        Text(AppFormatters.iqd(250000)),
        Text(AppFormatters.iqd(150)),
        Text(AppFormatters.iqd(265000)),
        Text(AppFormatters.iqd(3000)),
        const AppTableActionButton(
          icon: Icons.delete_rounded,
          tooltip: 'حذف السطر',
          onPressed: _noop,
        ),
      ],
    ),
    AppTableRow(
      cells: [
        const Text('2'),
        const Text('P-002'),
        const Text('قلم أزرق'),
        const Text('الفرعي'),
        Text(AppFormatters.quantity(1000)),
        Text(AppFormatters.quantity(10)),
        Text(AppFormatters.usd(1.25)),
        Text(AppFormatters.usd(0)),
        Text(AppFormatters.usd(1.25)),
        Text(AppFormatters.usd(1250)),
        Text(AppFormatters.usd(0.05)),
        Text(AppFormatters.usd(1300)),
        Text(AppFormatters.usd(1.75)),
        const AppTableActionButton(
          icon: Icons.delete_rounded,
          tooltip: 'حذف السطر',
          onPressed: _noop,
        ),
      ],
    ),
  ];

  static final _salesRows = <AppTableRow>[
    AppTableRow(
      cells: [
        const Text('1'),
        const Text('P-001'),
        const Text('دفتر ملاحظات'),
        const Text('الرئيسي'),
        Text(AppFormatters.quantity(5)),
        Text(AppFormatters.iqd(3000)),
        Text(AppFormatters.iqd(0)),
        Text(AppFormatters.iqd(3000)),
        Text(AppFormatters.iqd(15000)),
        const AppTableActionButton(
          icon: Icons.delete_rounded,
          tooltip: 'حذف السطر',
          onPressed: _noop,
        ),
      ],
    ),
    AppTableRow(
      cells: [
        const Text('2'),
        const Text('P-003'),
        const Text('طابعة مكتبية'),
        const Text('الرئيسي'),
        Text(AppFormatters.quantity(1)),
        Text(AppFormatters.usd(175)),
        Text(AppFormatters.usd(5)),
        Text(AppFormatters.usd(170)),
        Text(AppFormatters.usd(170)),
        const AppTableActionButton(
          icon: Icons.delete_rounded,
          tooltip: 'حذف السطر',
          onPressed: _noop,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      title: 'جداول المشتريات والمبيعات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInfoBanner(
            message:
                'الجداول متطابقة في الأساس، وتختلف في لون القسم والأعمدة الخاصة بكل مستند.',
            icon: Icons.table_chart_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _TableTitle(
            label: 'جدول مواد المشتريات',
            color: AppModuleColors.purchases,
            icon: Icons.shopping_cart_checkout_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInvoiceItemsTable.purchase(
            key: const Key('designPurchaseItemsTable'),
            tableKey: const Key('designPurchaseItemsDataTable'),
            rows: _purchaseRows,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _TableTitle(
            label: 'جدول مواد المبيعات',
            color: AppModuleColors.sales,
            icon: Icons.point_of_sale_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInvoiceItemsTable.sale(
            key: const Key('designSalesItemsTable'),
            tableKey: const Key('designSalesItemsDataTable'),
            rows: _salesRows,
          ),
        ],
      ),
    );
  }
}

class _TableTitle extends StatelessWidget {
  const _TableTitle({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.sectionTitle),
      ],
    );
  }
}

void _noop() {}
