import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryFeedbackGroup extends StatelessWidget {
  const DesignGalleryFeedbackGroup({super.key});

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
                  key: Key('designMissingReferenceState'),
                  type: AppStateType.missingReference,
                  title: 'مرجع البيانات غير متاح',
                  message: 'اختر سجلاً مرتبطاً متاحاً ثم حاول مرة أخرى.',
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
          title: 'رسائل التنبيه',
          child: Wrap(
            textDirection: TextDirection.rtl,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppRegularButton(
                key: const Key('designSaveToastButton'),
                label: 'رسالة الحفظ',
                icon: Icons.save_rounded,
                onPressed: () =>
                    AppToast.showInfo(context, 'تم الحفظ بنجاح'),
              ),
              AppRegularButton(
                key: const Key('designUpdateToastButton'),
                label: 'رسالة التحديث',
                icon: Icons.update_rounded,
                onPressed: () =>
                    AppToast.showSuccess(context, 'تم تحديث السجل'),
              ),
              AppRegularButton(
                key: const Key('designUndoToastButton'),
                label: 'رسالة التراجع',
                icon: Icons.undo_rounded,
                onPressed: () => AppToast.showWarning(
                  context,
                  'تم التراجع عن التغييرات',
                ),
              ),
              AppRegularButton(
                key: const Key('designDeleteToastButton'),
                label: 'رسالة الحذف',
                icon: Icons.delete_rounded,
                onPressed: () =>
                    AppToast.showDanger(context, 'تم حذف السجل'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const DesignGallerySection(
          title: 'طبقة التحميل',
          child: SizedBox(
            height: 180,
            child: AppLoadingOverlay(
              isLoading: true,
              message: 'جاري حفظ البيانات',
              child: AppInfoBanner(
                message: 'يتم تعطيل المحتوى أثناء العمليات المهمة.',
                icon: Icons.inventory_2_rounded,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
