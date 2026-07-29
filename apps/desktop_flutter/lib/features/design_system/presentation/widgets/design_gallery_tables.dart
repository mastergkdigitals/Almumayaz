import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryTablesSection extends StatelessWidget {
  const DesignGalleryTablesSection({super.key});

  static const _materials = <_SampleMaterial>[
    _SampleMaterial(
      'P-001',
      'دفتر ملاحظات',
      100,
      'متوفر',
      AppStatusTone.success,
    ),
    _SampleMaterial('P-002', 'قلم', 0, 'نافد', AppStatusTone.danger),
    _SampleMaterial(
      'P-003',
      'طابعة',
      25,
      'متوفر',
      AppStatusTone.success,
    ),
    _SampleMaterial(
      'P-004',
      'شاشة',
      12,
      'متوفر',
      AppStatusTone.success,
    ),
    _SampleMaterial(
      'P-005',
      'لوحة مفاتيح',
      8,
      'مخزون منخفض',
      AppStatusTone.warning,
    ),
    _SampleMaterial(
      'P-006',
      'فأرة',
      50,
      'متوفر',
      AppStatusTone.success,
    ),
    _SampleMaterial(
      'P-007',
      'حبر طابعة',
      0,
      'نافد',
      AppStatusTone.danger,
    ),
    _SampleMaterial(
      'P-008',
      'قرص تخزين',
      18,
      'متوفر',
      AppStatusTone.success,
    ),
    _SampleMaterial(
      'P-009',
      'ذاكرة',
      7,
      'مخزون منخفض',
      AppStatusTone.warning,
    ),
    _SampleMaterial(
      'P-010',
      'ماسح ضوئي',
      4,
      'متوفر',
      AppStatusTone.success,
    ),
    _SampleMaterial('P-011', 'راوتر', 0, 'نافد', AppStatusTone.danger),
    _SampleMaterial(
      'P-012',
      'كابل شبكة',
      120,
      'متوفر',
      AppStatusTone.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      title: 'جداول التطبيق',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'جداول القوائم والسجلات',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'يتبع رأس الجدول وحدوده لون القسم مع الحفاظ على صفوف بيضاء واضحة.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: const Key('designMaterialsTable'),
            accentColor: AppModuleColors.parties,
            columns: const [
              AppTableColumn(label: 'رمز المادة'),
              AppTableColumn(label: 'اسم المادة'),
              AppTableColumn(label: 'الكمية', numeric: true),
              AppTableColumn(label: 'الحالة'),
              AppTableColumn(label: 'الإجراء'),
            ],
            rows: [
              for (final material in _materials)
                AppTableRow(
                  cells: [
                    Text(material.code),
                    Text(material.name),
                    Text(material.quantity.toString()),
                    AppStatusBadge(
                      label: material.status,
                      tone: material.tone,
                    ),
                    const AppTableActionButton(
                      icon: Icons.receipt_long_rounded,
                      tooltip: 'كشف',
                      onPressed: _handleStatementPressed,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'جداول إدخال الفواتير',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'جدول المبيعات',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          const SizedBox(
            height: 360,
            child: AppSalesInvoiceTableTemplate(
              key: Key('designSalesInvoiceTable'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'جدول المشتريات',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          const SizedBox(
            height: 360,
            child: AppPurchaseInvoiceTableTemplate(
              key: Key('designPurchaseInvoiceTable'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleMaterial {
  const _SampleMaterial(
    this.code,
    this.name,
    this.quantity,
    this.status,
    this.tone,
  );

  final String code;
  final String name;
  final int quantity;
  final String status;
  final AppStatusTone tone;
}

void _handleStatementPressed() {}
