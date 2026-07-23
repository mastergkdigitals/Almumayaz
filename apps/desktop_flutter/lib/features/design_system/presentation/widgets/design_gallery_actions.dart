import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryActionsGroup extends StatefulWidget {
  const DesignGalleryActionsGroup({super.key});

  @override
  State<DesignGalleryActionsGroup> createState() =>
      _DesignGalleryActionsGroupState();
}

class _DesignGalleryActionsGroupState
    extends State<DesignGalleryActionsGroup> {
  final _searchController = TextEditingController();
  bool _isDarkThemePreview = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showConfirmation() async {
    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'تأكيد العملية',
      message: 'هذا مثال لشكل نافذة التأكيد الموحدة.',
      confirmLabel: 'موافق',
      isDanger: true,
    );

    if (!mounted || !confirmed) return;
    AppToast.showDanger(context, 'تم الحذف بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignGallerySection(
          title: 'الأزرار',
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton(
                key: const Key('designSecondaryButton'),
                label: 'إجراء ثانوي',
                icon: Icons.tune_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                key: const Key('designGhostButton'),
                label: 'زر نصي',
                icon: Icons.open_in_new_rounded,
                variant: AppButtonVariant.ghost,
                onPressed: () {},
              ),
              AppButton(
                label: 'جاري الحفظ',
                isLoading: true,
                onPressed: () {},
              ),
              const AppButton(
                label: 'غير متاح',
                onPressed: null,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DesignGallerySection(
          title: 'أزرار رأس التطبيق والتلميحات',
          child: Wrap(
            textDirection: TextDirection.rtl,
            alignment: WrapAlignment.start,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppHeaderIconButton(
                key: const Key('designHeaderBackButton'),
                tooltipKey: const Key('designHeaderBackTooltip'),
                icon: Icons.arrow_back_rounded,
                tooltip: 'رجوع',
                onPressed: () {},
              ),
              AppHeaderIconButton(
                key: const Key('designHeaderThemeButton'),
                tooltipKey: const Key('designHeaderThemeTooltip'),
                icon: _isDarkThemePreview
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                tooltip: _isDarkThemePreview ? 'فاتح' : 'داكن',
                onPressed: () => setState(
                  () => _isDarkThemePreview = !_isDarkThemePreview,
                ),
              ),
              AppHeaderIconButton(
                key: const Key('designHeaderNotificationsButton'),
                tooltipKey: const Key('designHeaderNotificationsTooltip'),
                icon: Icons.notifications_rounded,
                tooltip: 'الإشعارات',
                onPressed: () {},
              ),
              AppHeaderIconButton(
                key: const Key('designHeaderUsersButton'),
                tooltipKey: const Key('designHeaderUsersTooltip'),
                icon: Icons.groups_rounded,
                tooltip: 'المستخدمون',
                onPressed: () {},
              ),
              AppHeaderIconButton(
                key: const Key('designHeaderLogoutButton'),
                tooltipKey: const Key('designHeaderLogoutTooltip'),
                icon: Icons.logout_rounded,
                tooltip: 'تسجيل الخروج',
                flipIconHorizontally: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DesignGallerySection(
          title: 'شريط الإجراءات',
          child: AppActionBar(
            key: const Key('designActionBar'),
            searchController: _searchController,
            searchFieldKey: const Key('designActionBarSearch'),
            searchClearButtonKey: const Key('designActionBarSearchClear'),
            firstButtonKey: const Key('designActionBarFirst'),
            previousButtonKey: const Key('designActionBarPrevious'),
            nextButtonKey: const Key('designActionBarNext'),
            lastButtonKey: const Key('designActionBarLast'),
            saveButtonKey: const Key('designActionBarSave'),
            updateButtonKey: const Key('designActionBarUpdate'),
            undoButtonKey: const Key('designActionBarUndo'),
            deleteButtonKey: const Key('designActionBarDelete'),
            searchHint: 'ابحث في السجلات',
            onFirst: () {},
            onPrevious: () {},
            onNext: () {},
            onLast: () {},
            onSave: () => AppToast.showInfo(context, 'تم الحفظ بنجاح'),
            onUpdate: () => AppToast.showSuccess(context, 'تم تحديث السجل'),
            onUndo: () =>
                AppToast.showWarning(context, 'تم التراجع عن التغييرات'),
            onDelete: _showConfirmation,
          ),
        ),
      ],
    );
  }
}
