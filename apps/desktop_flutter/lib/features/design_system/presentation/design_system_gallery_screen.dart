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
  final _quantityController = TextEditingController(text: '100');
  final _moneyController = TextEditingController(text: '25000');

  String _currency = 'IQD';
  bool _allowNegativeStock = false;

  @override
  void dispose() {
    _nameController.dispose();
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
    );

    if (!mounted || !confirmed) return;
    AppToast.showSuccess(context, 'تم تأكيد العملية');
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
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  AppButton(
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
              title: 'الجدول والترقيم',
              child: AppDataTable(
                title: 'مواد تجريبية',
                currentPage: 1,
                totalPages: 3,
                onNextPage: () {},
                columns: const [
                  DataColumn(label: Text('رمز المادة')),
                  DataColumn(label: Text('اسم المادة')),
                  DataColumn(label: Text('الكمية')),
                  DataColumn(label: Text('الحالة')),
                ],
                rows: const [
                  DataRow(
                    cells: [
                      DataCell(Text('P-001')),
                      DataCell(Text('مادة أولى')),
                      DataCell(Text('100')),
                      DataCell(
                        AppStatusBadge(
                          label: 'متوفر',
                          tone: AppStatusTone.success,
                        ),
                      ),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('P-002')),
                      DataCell(Text('مادة ثانية')),
                      DataCell(Text('0')),
                      DataCell(
                        AppStatusBadge(
                          label: 'نافد',
                          tone: AppStatusTone.danger,
                        ),
                      ),
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
