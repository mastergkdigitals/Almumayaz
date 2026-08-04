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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'الأزرار العادية',
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppRegularButton(
                    key: const Key('designRegularButton'),
                    label: 'زر عادي',
                    icon: Icons.touch_app_rounded,
                    onPressed: _previewAction,
                  ),
                  AppRegularButton(
                    key: const Key('designRegularTextButton'),
                    label: 'بدون أيقونة',
                    onPressed: _previewAction,
                  ),
                  const AppRegularButton(
                    key: Key('designRegularDisabledButton'),
                    label: 'غير متاح',
                    icon: Icons.block_rounded,
                    onPressed: null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'أزرار التنقل',
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              AppRecordNavigation(
                firstButtonKey: const Key('designNavigationFirst'),
                previousButtonKey:
                    const Key('designNavigationPrevious'),
                nextButtonKey: const Key('designNavigationNext'),
                lastButtonKey: const Key('designNavigationLast'),
                onFirst: _previewAction,
                onPrevious: _previewAction,
                onNext: _previewAction,
                onLast: _previewAction,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'أزرار الإجراءات',
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              const AppActionButtons(
                saveButtonKey: Key('designActionSave'),
                updateButtonKey: Key('designActionUpdate'),
                undoButtonKey: Key('designActionUndo'),
                deleteButtonKey: Key('designActionDelete'),
                onSave: _previewAction,
                onUpdate: _previewAction,
                onUndo: _previewAction,
                onDelete: _previewAction,
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
          title: 'أزرار القوائم والتلميحات',
          child: Wrap(
            textDirection: TextDirection.rtl,
            alignment: WrapAlignment.start,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              AppHeaderIconButton(
                key: const Key('designInvoicePrintButton'),
                tooltipKey: const Key('designInvoicePrintTooltip'),
                icon: Icons.print_rounded,
                tooltip: 'طباعة',
                onPressed: () {},
              ),
              AppHeaderIconButton(
                key: const Key('designInvoicePrintWithoutPriceButton'),
                tooltipKey:
                    const Key('designInvoicePrintWithoutPriceTooltip'),
                icon: Icons.print_disabled_rounded,
                tooltip: 'طباعة بدون سعر',
                onPressed: () {},
              ),
              AppHeaderIconButton(
                key: const Key('designInvoiceSearchButton'),
                tooltipKey: const Key('designInvoiceSearchTooltip'),
                icon: Icons.search_rounded,
                tooltip: 'بحث',
                onPressed: () {},
              ),
              AppHeaderIconButton(
                key: const Key('designInvoiceInstallmentsButton'),
                tooltipKey:
                    const Key('designInvoiceInstallmentsTooltip'),
                icon: Icons.table_chart_rounded,
                tooltip: 'جدول الأقساط',
                onPressed: () {},
              ),
              AppHeaderIconButton(
                key: const Key('designInvoiceStatementButton'),
                tooltipKey: const Key('designInvoiceStatementTooltip'),
                icon: Icons.receipt_long_rounded,
                tooltip: 'كشف حساب',
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
                    useIntrinsicHeight: true,
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
              AppRegularButton(
                key: const Key('designDeleteDialogButton'),
                label: 'تأكيد الحذف',
                icon: Icons.delete_rounded,
                onPressed: _showDeleteConfirmation,
              ),
              AppRegularButton(
                key: const Key('designUnsavedDialogButton'),
                label: 'تغييرات غير محفوظة',
                icon: Icons.warning_amber_rounded,
                onPressed: _showUnsavedChangesConfirmation,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _previewAction() {}
