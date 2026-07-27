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
                'أزرار التنقل',
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                textDirection: TextDirection.rtl,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _OldPartyButton.navigation(
                    key: const Key('designNavigationFirst'),
                    label: 'الأول',
                    icon: Icons.first_page_rounded,
                    onPressed: _previewAction,
                  ),
                  _OldPartyButton.navigation(
                    key: const Key('designNavigationPrevious'),
                    label: 'السابق',
                    icon: Icons.chevron_left_rounded,
                    onPressed: _previewAction,
                  ),
                  _OldPartyButton.navigation(
                    key: const Key('designNavigationNext'),
                    label: 'التالي',
                    icon: Icons.chevron_right_rounded,
                    onPressed: _previewAction,
                  ),
                  _OldPartyButton.navigation(
                    key: const Key('designNavigationLast'),
                    label: 'الأخير',
                    icon: Icons.last_page_rounded,
                    onPressed: _previewAction,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'أزرار الإجراءات',
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                textDirection: TextDirection.rtl,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _OldPartyButton.filled(
                    key: const Key('designActionSave'),
                    label: 'حفظ',
                    icon: Icons.add_rounded,
                    color: Color(0xFF16A34A),
                    onPressed: _previewAction,
                  ),
                  _OldPartyButton.filled(
                    key: const Key('designActionUndo'),
                    label: 'تراجع',
                    icon: Icons.close_rounded,
                    color: AppColors.legacyGrey,
                    onPressed: _previewAction,
                  ),
                  _OldPartyButton.filled(
                    key: const Key('designActionUpdate'),
                    label: 'تحديث',
                    icon: Icons.save_rounded,
                    color: AppColors.legacyBlue,
                    onPressed: _previewAction,
                  ),
                  _OldPartyButton.filled(
                    key: const Key('designActionDelete'),
                    label: 'حذف',
                    icon: Icons.delete_rounded,
                    color: AppColors.legacyRed,
                    onPressed: _previewAction,
                  ),
                ],
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

void _previewAction() {}

enum _OldPartyButtonType { navigation, filled }

class _OldPartyButton extends StatefulWidget {
  const _OldPartyButton.navigation({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  })  : type = _OldPartyButtonType.navigation,
        color = null,
        minWidth = 104,
        padding = const EdgeInsets.symmetric(horizontal: 14),
        showShadow = false;

  const _OldPartyButton.filled({
    required this.label,
    required this.icon,
    required Color this.color,
    required this.onPressed,
    super.key,
  })  : type = _OldPartyButtonType.filled,
        minWidth = 108,
        padding = const EdgeInsets.symmetric(horizontal: 16),
        showShadow = true;

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final _OldPartyButtonType type;
  final Color? color;
  final double minWidth;
  final EdgeInsetsGeometry padding;
  final bool showShadow;

  @override
  State<_OldPartyButton> createState() => _OldPartyButtonState();
}

class _OldPartyButtonState extends State<_OldPartyButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _showFocusHighlight = false;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);
    final background = _pressed
        ? colors.pressedBackground
        : _hovered
            ? colors.hoverBackground
            : colors.background;
    final foreground = _pressed
        ? colors.pressedForeground
        : _hovered
            ? colors.hoverForeground
            : colors.foreground;
    final border = _showFocusHighlight
        ? _focusRingColor(context)
        : _pressed
            ? colors.pressedBorder
            : _hovered
                ? colors.hoverBorder
                : colors.border;
    final scale = _pressed
        ? 0.94
        : _hovered
            ? 1.04
            : 1.0;

    return Semantics(
      button: true,
      enabled: true,
      label: widget.label,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) {
          if (_showFocusHighlight == value) return;
          setState(() => _showFocusHighlight = value);
        },
        onShowHoverHighlight: (value) {
          if (_hovered == value) return;
          setState(() {
            _hovered = value;
            if (!value) _pressed = false;
          });
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              height: 52,
              constraints: BoxConstraints(minWidth: widget.minWidth),
              padding: widget.padding,
              decoration: BoxDecoration(
                color: background,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  if (widget.showShadow && (_hovered || _pressed))
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: _pressed ? 8 : 14,
                      offset: Offset(0, _pressed ? 3 : 7),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: foreground, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _OldPartyButtonColors _colors(BuildContext context) {
    if (widget.type == _OldPartyButtonType.filled) {
      final color = widget.color!;
      return _OldPartyButtonColors(
        background: color,
        hoverBackground: Color.lerp(color, Colors.white, 0.10)!,
        pressedBackground: Color.lerp(color, Colors.black, 0.10)!,
        foreground: Colors.white,
        hoverForeground: Colors.white,
        pressedForeground: Colors.white,
        border: Colors.transparent,
        hoverBorder: Colors.transparent,
        pressedBorder: Colors.transparent,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark
        ? const Color(0xFFF9FAFB)
        : const Color(0xFF111827);
    final border = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFD1D5DB);
    final background = isDark ? const Color(0xFF111827) : Colors.white;
    final pressedBackground = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFF8FAFC);
    final outline = isDark
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF111827);

    return _OldPartyButtonColors(
      background: background,
      hoverBackground: background,
      pressedBackground: pressedBackground,
      foreground: foreground,
      hoverForeground: foreground,
      pressedForeground: foreground,
      border: border,
      hoverBorder: outline,
      pressedBorder: outline,
    );
  }

  Color _focusRingColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60A5FA)
        : AppColors.legacyBlue;
  }
}

class _OldPartyButtonColors {
  const _OldPartyButtonColors({
    required this.background,
    required this.hoverBackground,
    required this.pressedBackground,
    required this.foreground,
    required this.hoverForeground,
    required this.pressedForeground,
    required this.border,
    required this.hoverBorder,
    required this.pressedBorder,
  });

  final Color background;
  final Color hoverBackground;
  final Color pressedBackground;
  final Color foreground;
  final Color hoverForeground;
  final Color pressedForeground;
  final Color border;
  final Color hoverBorder;
  final Color pressedBorder;
}
