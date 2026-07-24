import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

enum _ActionBarPreviewState {
  newRecord,
  newDirty,
  savedRecord,
  savedDirty,
}

extension on _ActionBarPreviewState {
  String get label => switch (this) {
        _ActionBarPreviewState.newRecord => 'نموذج جديد',
        _ActionBarPreviewState.newDirty => 'جديد مع بيانات',
        _ActionBarPreviewState.savedRecord => 'سجل محفوظ',
        _ActionBarPreviewState.savedDirty => 'محفوظ مع تعديلات',
      };

  bool get isSaved => switch (this) {
        _ActionBarPreviewState.savedRecord ||
        _ActionBarPreviewState.savedDirty => true,
        _ => false,
      };

  bool get isDirty => switch (this) {
        _ActionBarPreviewState.newDirty ||
        _ActionBarPreviewState.savedDirty => true,
        _ => false,
      };
}

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
  _ActionBarPreviewState _actionBarState =
      _ActionBarPreviewState.newRecord;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل تريد حذف السجل المحدد؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );

    if (!mounted || !confirmed) return;
    AppToast.showDanger(context, 'تم الحذف بنجاح');
  }

  Future<void> _showUnsavedChangesConfirmation() async {
    await AppDialogs.confirm(
      context: context,
      title: 'تغييرات غير محفوظة',
      message: 'لديك بيانات أو تعديلات غير محفوظة. هل تريد تجاهلها؟',
      confirmLabel: 'تجاهل',
      cancelLabel: 'البقاء',
      isDanger: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_actionBarState.isSaved;
    final canUpdate =
        _actionBarState.isSaved && _actionBarState.isDirty;
    final canUndo = _actionBarState.isDirty;
    final canDelete = _actionBarState.isSaved;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: 320,
                  child: AppDropdownField<_ActionBarPreviewState>(
                    fieldKey: const Key('designActionBarStateDropdown'),
                    label: 'حالة النموذج',
                    icon: Icons.fact_check_rounded,
                    value: _actionBarState,
                    options: [
                      for (final state in _ActionBarPreviewState.values)
                        AppDropdownOption(
                          value: state,
                          label: state.label,
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _actionBarState = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppActionBar(
                key: const Key('designActionBar'),
                searchController: _searchController,
                searchFieldKey: const Key('designActionBarSearch'),
                searchClearButtonKey:
                    const Key('designActionBarSearchClear'),
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
                onSave: canSave
                    ? () => AppToast.showInfo(context, 'تم الحفظ بنجاح')
                    : null,
                onUpdate: canUpdate
                    ? () => AppToast.showSuccess(context, 'تم تحديث السجل')
                    : null,
                onUndo: canUndo
                    ? () => AppToast.showWarning(
                          context,
                          'تم التراجع عن التغييرات',
                        )
                    : null,
                onDelete:
                    canDelete ? _showDeleteConfirmation : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DesignGallerySection(
          title: 'نوافذ التأكيد',
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppButton(
                key: const Key('designDeleteDialogButton'),
                label: 'تأكيد الحذف',
                icon: Icons.delete_rounded,
                variant: AppButtonVariant.danger,
                onPressed: _showDeleteConfirmation,
              ),
              AppButton(
                key: const Key('designUnsavedDialogButton'),
                label: 'تغييرات غير محفوظة',
                icon: Icons.warning_amber_rounded,
                variant: AppButtonVariant.warning,
                onPressed: _showUnsavedChangesConfirmation,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
