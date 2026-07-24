import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryInvoiceTablesSection extends StatefulWidget {
  const DesignGalleryInvoiceTablesSection({super.key});

  @override
  State<DesignGalleryInvoiceTablesSection> createState() =>
      _DesignGalleryInvoiceTablesSectionState();
}

class _DesignGalleryInvoiceTablesSectionState
    extends State<DesignGalleryInvoiceTablesSection> {
  var _purchaseSeed = 3;
  var _saleSeed = 3;

  final List<_DemoInvoiceRow> _purchaseItems = [
    _DemoInvoiceRow(
      id: 'p1',
      values: [
        'P-001',
        'دفتر ملاحظات',
        'الرئيسي',
        AppFormatters.quantity(100),
        AppFormatters.quantity(1),
        AppFormatters.iqd(2500),
        AppFormatters.iqd(0),
        AppFormatters.iqd(2500),
        AppFormatters.iqd(250000),
        AppFormatters.iqd(150),
        AppFormatters.iqd(265000),
        AppFormatters.iqd(3000),
      ],
    ),
    _DemoInvoiceRow(
      id: 'p2',
      values: [
        'P-002',
        'قلم أزرق',
        'الفرعي',
        AppFormatters.quantity(1000),
        AppFormatters.quantity(10),
        AppFormatters.usd(1.25),
        AppFormatters.usd(0),
        AppFormatters.usd(1.25),
        AppFormatters.usd(1250),
        AppFormatters.usd(0.05),
        AppFormatters.usd(1300),
        AppFormatters.usd(1.75),
      ],
    ),
  ];

  final List<_DemoInvoiceRow> _saleItems = [
    _DemoInvoiceRow(
      id: 's1',
      values: [
        'P-001',
        'دفتر ملاحظات',
        'الرئيسي',
        AppFormatters.quantity(5),
        AppFormatters.iqd(3000),
        AppFormatters.iqd(0),
        AppFormatters.iqd(3000),
        AppFormatters.iqd(15000),
      ],
    ),
    _DemoInvoiceRow(
      id: 's2',
      values: [
        'P-003',
        'طابعة مكتبية',
        'الرئيسي',
        AppFormatters.quantity(1),
        AppFormatters.usd(175),
        AppFormatters.usd(5),
        AppFormatters.usd(170),
        AppFormatters.usd(170),
      ],
    ),
  ];

  void _addPurchaseItem() {
    final seed = _purchaseSeed++;
    setState(() {
      _purchaseItems.add(
        _DemoInvoiceRow(
          id: 'p$seed',
          values: [
            'P-${100 + seed}',
            'ورق A4 تجريبي',
            'الرئيسي',
            AppFormatters.quantity(20),
            AppFormatters.quantity(1),
            AppFormatters.iqd(6000),
            AppFormatters.iqd(500),
            AppFormatters.iqd(5500),
            AppFormatters.iqd(110000),
            AppFormatters.iqd(100),
            AppFormatters.iqd(112000),
            AppFormatters.iqd(7500),
          ],
        ),
      );
    });
  }

  void _addSaleItem() {
    final seed = _saleSeed++;
    setState(() {
      _saleItems.add(
        _DemoInvoiceRow(
          id: 's$seed',
          values: [
            'P-${200 + seed}',
            'حبر طابعة تجريبي',
            'الفرعي',
            AppFormatters.quantity(2),
            AppFormatters.iqd(18000),
            AppFormatters.iqd(1000),
            AppFormatters.iqd(17000),
            AppFormatters.iqd(34000),
          ],
        ),
      );
    });
  }

  List<AppTableRow> _purchaseRows() {
    return [
      for (var index = 0; index < _purchaseItems.length; index++)
        AppTableRow(
          rowKey: Key('designPurchaseRow-${_purchaseItems[index].id}'),
          cells: [
            Text('${index + 1}'),
            for (final value in _purchaseItems[index].values) Text(value),
            AppTableActionButton(
              key: Key(
                'designPurchaseDelete-${_purchaseItems[index].id}',
              ),
              icon: Icons.delete_rounded,
              tooltip: 'حذف السطر',
              onPressed: () {
                setState(() => _purchaseItems.removeAt(index));
              },
            ),
          ],
        ),
    ];
  }

  List<AppTableRow> _saleRows() {
    return [
      for (var index = 0; index < _saleItems.length; index++)
        AppTableRow(
          rowKey: Key('designSaleRow-${_saleItems[index].id}'),
          cells: [
            Text('${index + 1}'),
            for (final value in _saleItems[index].values) Text(value),
            AppTableActionButton(
              key: Key('designSaleDelete-${_saleItems[index].id}'),
              icon: Icons.delete_rounded,
              tooltip: 'حذف السطر',
              onPressed: () {
                setState(() => _saleItems.removeAt(index));
              },
            ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      title: 'جداول المشتريات والمبيعات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInfoBanner(
            message:
                'الجداول متطابقة في الأساس، وتختلف في لون القسم والأعمدة الخاصة بكل مستند. أضف واحذف صفوفاً لتجربة السلوك.',
            icon: Icons.table_chart_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          _TableTitle(
            label: 'جدول مواد المشتريات',
            color: AppModuleColors.purchases,
            icon: Icons.shopping_cart_checkout_rounded,
            buttonKey: const Key('designPurchaseAddRow'),
            onAdd: _addPurchaseItem,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInvoiceItemsTable.purchase(
            key: const Key('designPurchaseItemsTable'),
            tableKey: const Key('designPurchaseItemsDataTable'),
            rows: _purchaseRows(),
          ),
          const SizedBox(height: AppSpacing.lg),
          _TableTitle(
            label: 'جدول مواد المبيعات',
            color: AppModuleColors.sales,
            icon: Icons.point_of_sale_rounded,
            buttonKey: const Key('designSaleAddRow'),
            onAdd: _addSaleItem,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInvoiceItemsTable.sale(
            key: const Key('designSalesItemsTable'),
            tableKey: const Key('designSalesItemsDataTable'),
            rows: _saleRows(),
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
    required this.buttonKey,
    required this.onAdd,
  });

  final String label;
  final Color color;
  final IconData icon;
  final Key buttonKey;
  final VoidCallback onAdd;

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
        Expanded(
          child: Text(label, style: AppTypography.sectionTitle),
        ),
        AppButton(
          key: buttonKey,
          label: 'إضافة سطر',
          icon: Icons.add_rounded,
          width: 144,
          backgroundColor: color,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

@immutable
class _DemoInvoiceRow {
  const _DemoInvoiceRow({
    required this.id,
    required this.values,
  });

  final String id;
  final List<String> values;
}
