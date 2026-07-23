import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryFeedbackGroup extends StatelessWidget {
  const DesignGalleryFeedbackGroup({super.key});

  static const _materials = <_SampleMaterial>[
    _SampleMaterial('P-001', 'دفتر ملاحظات', 100, 'متوفر', AppStatusTone.success),
    _SampleMaterial('P-002', 'قلم', 0, 'نافد', AppStatusTone.danger),
    _SampleMaterial('P-003', 'طابعة', 25, 'متوفر', AppStatusTone.success),
    _SampleMaterial('P-004', 'شاشة', 12, 'متوفر', AppStatusTone.success),
    _SampleMaterial('P-005', 'لوحة مفاتيح', 8, 'مخزون منخفض', AppStatusTone.warning),
    _SampleMaterial('P-006', 'فأرة', 50, 'متوفر', AppStatusTone.success),
    _SampleMaterial('P-007', 'حبر طابعة', 0, 'نافد', AppStatusTone.danger),
    _SampleMaterial('P-008', 'قرص تخزين', 18, 'متوفر', AppStatusTone.success),
    _SampleMaterial('P-009', 'ذاكرة', 7, 'مخزون منخفض', AppStatusTone.warning),
    _SampleMaterial('P-010', 'ماسح ضوئي', 4, 'متوفر', AppStatusTone.success),
    _SampleMaterial('P-011', 'راوتر', 0, 'نافد', AppStatusTone.danger),
    _SampleMaterial('P-012', 'كابل شبكة', 120, 'متوفر', AppStatusTone.success),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DesignGallerySection(
          title: 'شارات الحالة',
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppStatusBadge(
                label: 'مكتمل',
                tone: AppStatusTone.success,
              ),
              AppStatusBadge(
                label: 'قيد المراجعة',
                tone: AppStatusTone.warning,
              ),
              AppStatusBadge(
                label: 'مرفوض',
                tone: AppStatusTone.danger,
              ),
              AppStatusBadge(
                label: 'معلومة',
                tone: AppStatusTone.info,
              ),
              AppStatusBadge(
                label: 'غير نشط',
                tone: AppStatusTone.neutral,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DesignGallerySection(
          title: 'الحالات والرسائل',
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              const SizedBox(
                width: 360,
                child: AppStatePanel(
                  type: AppStateType.empty,
                  title: 'لا توجد بيانات',
                  message: 'ستظهر السجلات هنا بعد إضافتها.',
                ),
              ),
              SizedBox(
                width: 360,
                child: AppStatePanel(
                  type: AppStateType.error,
                  title: 'تعذر تحميل البيانات',
                  message: 'تحقق من الاتصال ثم حاول مرة أخرى.',
                  actionLabel: 'إعادة المحاولة',
                  onAction: () =>
                      AppToast.showInfo(context, 'جاري إعادة المحاولة'),
                ),
              ),
              const SizedBox(
                width: 360,
                child: AppStatePanel(
                  type: AppStateType.loading,
                  title: 'جاري التحميل',
                  message: 'يرجى الانتظار قليلاً.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DesignGallerySection(
          title: 'الجدول',
          child: AppDataTable(
            key: const Key('designMaterialsTable'),
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
        ),
      ],
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
