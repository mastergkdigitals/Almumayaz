import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../../purchases/presentation/widgets/purchase_items_table.dart';
import 'design_gallery_section.dart';

class DesignGalleryInvoiceTablesSection extends StatefulWidget {
  const DesignGalleryInvoiceTablesSection({super.key});

  @override
  State<DesignGalleryInvoiceTablesSection> createState() =>
      _DesignGalleryInvoiceTablesSectionState();
}

class _DesignGalleryInvoiceTablesSectionState
    extends State<DesignGalleryInvoiceTablesSection> {
  late final PurchaseItemsController _purchaseItemsController;

  @override
  void initState() {
    super.initState();
    _purchaseItemsController = PurchaseItemsController(
      idPrefix: 'p',
      initialItems: const [
        PurchaseItemSeed(
          code: 'P-001',
          name: 'دفتر ملاحظات',
          warehouse: 'الرئيسي',
          quantity: '100',
          container: '10',
          purchasePrice: '2,500',
          discount: '5,000',
          salePrice: '3,000',
        ),
        PurchaseItemSeed(
          code: 'P-002',
          name: 'قلم أزرق',
          warehouse: 'الكرادة',
          quantity: '1,000',
          container: '20',
          purchasePrice: '1,250',
          discount: '0',
          salePrice: '1,500',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _purchaseItemsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      title: 'جدول المشتريات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInfoBanner(
            message:
                'تصميم الخلايا الناعمة المختار لجدول المشتريات. '
                'استخدم Enter أو Tab للتنقل، وEnter في آخر حقل لإضافة سطر.',
            icon: Icons.table_chart_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _PurchaseTableHeading(),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 340,
            child: PurchaseItemsTable(
              key: const Key('designPurchaseItemsTable'),
              keyPrefix: 'designPurchase',
              controller: _purchaseItemsController,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseTableHeading extends StatelessWidget {
  const _PurchaseTableHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppModulePalettes.purchases.light,
              Colors.white,
              0.72,
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: AppModuleColors.purchases.withAlpha(80),
            ),
          ),
          child: const Icon(
            Icons.shopping_cart_checkout_rounded,
            color: AppModuleColors.purchases,
            size: 23,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('جدول مواد المشتريات', style: AppTypography.sectionTitle),
            SizedBox(height: 2),
            Text(
              'جميع حقول مواد فاتورة المشتريات',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
