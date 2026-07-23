import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

class DesignSystemGalleryScreen extends StatefulWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  State<DesignSystemGalleryScreen> createState() =>
      _DesignSystemGalleryScreenState();
}

class _DesignSystemGalleryScreenState
    extends State<DesignSystemGalleryScreen> {
  final _nameController = TextEditingController(text: 'مادة تجريبية');
  final _searchController = TextEditingController();
  final _actionBarSearchController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  final _moneyController = TextEditingController(text: '25000');

  String _currency = 'IQD';
  bool _allowNegativeStock = false;
  bool _isDarkThemePreview = false;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _actionBarSearchController.dispose();
    _quantityController.dispose();
    _moneyController.dispose();
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
    return AppScreenShell(
      key: const Key('designSystemGallery'),
      title: 'دليل نظام التصميم',
      subtitle: 'مرجع موحد لعناصر الواجهة وحالاتها',
      onBack: () => Navigator.of(context).pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _GallerySection(
              title: 'الألوان',
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _ColorSample(
                    name: 'الأساسي',
                    value: '#1D4ED8',
                    color: AppColors.primary,
                  ),
                  _ColorSample(
                    name: 'الأزرق الداكن',
                    value: '#102A56',
                    color: AppColors.primaryDark,
                  ),
                  _ColorSample(
                    name: 'النجاح',
                    value: '#0F7A4D',
                    color: AppColors.success,
                  ),
                  _ColorSample(
                    name: 'التنبيه',
                    value: '#B75C00',
                    color: AppColors.warning,
                  ),
                  _ColorSample(
                    name: 'الخطر',
                    value: '#B42318',
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _GallerySection(
              title: 'الأزرار',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      AppButton(
                        key: const Key('designPrimaryButton'),
                        label: 'حفظ',
                        icon: Icons.save_rounded,
                        onPressed: () =>
                            AppToast.showSuccess(context, 'تم الحفظ بنجاح'),
                      ),
                      AppButton(
                        label: 'إجراء ثانوي',
                        icon: Icons.tune_rounded,
                        variant: AppButtonVariant.secondary,
                        onPressed: () {},
                      ),
                      AppButton(
                        label: 'حذف',
                        icon: Icons.delete_rounded,
                        variant: AppButtonVariant.danger,
                        onPressed: _showConfirmation,
                      ),
                      AppButton(
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
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'أزرار التنقل بين السجلات',
                    style: AppTypography.fieldText.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppRecordNavigation(
                      firstButtonKey:
                          const Key('designNavigationFirst'),
                      previousButtonKey:
                          const Key('designNavigationPrevious'),
                      nextButtonKey:
                          const Key('designNavigationNext'),
                      lastButtonKey:
                          const Key('designNavigationLast'),
                      onFirst: () {},
                      onPrevious: () {},
                      onNext: () {},
                      onLast: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _GallerySection(
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
                    tooltipKey:
                        const Key('designHeaderNotificationsTooltip'),
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
            _GallerySection(
              title: 'شريط الإجراءات',
              child: AppActionBar(
                key: const Key('designActionBar'),
                searchController: _actionBarSearchController,
                searchFieldKey: const Key('designActionBarSearch'),
                searchClearButtonKey:
                    const Key('designActionBarSearchClear'),
                firstButtonKey: const Key('designActionBarFirst'),
                previousButtonKey:
                    const Key('designActionBarPrevious'),
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
                onSave: () =>
                    AppToast.showInfo(context, 'تم الحفظ بنجاح'),
                onUpdate: () =>
                    AppToast.showSuccess(context, 'تم تحديث السجل'),
                onUndo: () =>
                    AppToast.showWarning(context, 'تم التراجع عن التغييرات'),
                onDelete: _showConfirmation,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _GallerySection(
              title: 'حقول الإدخال',
              child: Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.md,
                children: [
                  SizedBox(
                    width: 320,
                    child: AppTextField(
                      controller: _nameController,
                      label: 'اسم المادة',
                      icon: Icons.inventory_2_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: AppSearchField(
                      controller: _searchController,
                      fieldKey: const Key('designSearchField'),
                      clearButtonKey: const Key('designSearchClearButton'),
                      label: 'البحث عن مادة',
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: AppIntegerField(
                      controller: _quantityController,
                      label: 'الكمية',
                      icon: Icons.numbers_rounded,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: AppMoneyField(
                      controller: _moneyController,
                      label: 'المبلغ',
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: AppDropdownField<String>(
                      fieldKey: const Key('designCurrencyDropdown'),
                      label: 'العملة',
                      icon: Icons.currency_exchange_rounded,
                      value: _currency,
                      options: const [
                        AppDropdownOption(value: 'IQD', label: 'دينار'),
                        AppDropdownOption(value: 'USD', label: 'دولار'),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _currency = value);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 420,
                    child: AppSwitchField(
                      title: 'السماح بالمخزون السالب',
                      subtitle: 'مغلق افتراضياً ويمكن تفعيله بصلاحية',
                      icon: Icons.inventory_rounded,
                      value: _allowNegativeStock,
                      onChanged: (value) =>
                          setState(() => _allowNegativeStock = value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _GallerySection(
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
            _GallerySection(
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
            _GallerySection(
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
                rows: const [
                  AppTableRow(
                    cells: [
                      Text('P-001'),
                      Text('دفتر ملاحظات'),
                      Text('100'),
                      AppStatusBadge(
                        label: 'متوفر',
                        tone: AppStatusTone.success,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      Text('P-002'),
                      Text('قلم'),
                      Text('0'),
                      AppStatusBadge(
                        label: 'نافد',
                        tone: AppStatusTone.danger,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      Text('P-003'),
                      Text('طابعة'),
                      Text('25'),
                      AppStatusBadge(
                        label: 'متوفر',
                        tone: AppStatusTone.success,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      Text('P-004'),
                      Text('شاشة'),
                      Text('12'),
                      AppStatusBadge(
                        label: 'متوفر',
                        tone: AppStatusTone.success,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      Text('P-005'),
                      Text('لوحة مفاتيح'),
                      Text('8'),
                      AppStatusBadge(
                        label: 'مخزون منخفض',
                        tone: AppStatusTone.warning,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      Text('P-006'),
                      Text('فأرة'),
                      Text('50'),
                      AppStatusBadge(
                        label: 'متوفر',
                        tone: AppStatusTone.success,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      Text('P-007'),
                      Text('حبر طابعة'),
                      Text('0'),
                      AppStatusBadge(
                        label: 'نافد',
                        tone: AppStatusTone.danger,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      Text('P-008'),
                      Text('قرص تخزين'),
                      Text('18'),
                      AppStatusBadge(
                        label: 'متوفر',
                        tone: AppStatusTone.success,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      Text('P-009'),
                      Text('ذاكرة'),
                      Text('7'),
                      AppStatusBadge(
                        label: 'مخزون منخفض',
                        tone: AppStatusTone.warning,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      Text('P-010'),
                      Text('ماسح ضوئي'),
                      Text('4'),
                      AppStatusBadge(
                        label: 'متوفر',
                        tone: AppStatusTone.success,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      Text('P-011'),
                      Text('راوتر'),
                      Text('0'),
                      AppStatusBadge(
                        label: 'نافد',
                        tone: AppStatusTone.danger,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                  AppTableRow(
                    cells: [
                      Text('P-012'),
                      Text('كابل شبكة'),
                      Text('120'),
                      AppStatusBadge(
                        label: 'متوفر',
                        tone: AppStatusTone.success,
                      ),
                      _StatementActionButton(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _StatementActionButton extends StatelessWidget {
  const _StatementActionButton();

  static void _handlePressed() {}

  @override
  Widget build(BuildContext context) {
    return AppHeaderIconButton(
      icon: Icons.receipt_long_rounded,
      tooltip: 'كشف',
      size: AppControlHeights.compact,
      onPressed: _handlePressed,
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _ColorSample extends StatelessWidget {
  const _ColorSample({
    required this.name,
    required this.value,
    required this.color,
  });

  final String name;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 92,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
