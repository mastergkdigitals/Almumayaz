import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryQuickCreateSection extends StatelessWidget {
  const DesignGalleryQuickCreateSection({super.key});

  static const _specs = [
    _QuickCreateSpec(
      kind: _QuickCreateKind.party,
      keyName: 'designQuickParty',
      buttonLabel: 'طرف جديد',
      title: 'إضافة طرف جديد',
      prompt: 'هذا الطرف غير موجود، هل تود إضافته؟',
      icon: Icons.groups_rounded,
      accentColor: AppModuleColors.parties,
    ),
    _QuickCreateSpec(
      kind: _QuickCreateKind.item,
      keyName: 'designQuickItem',
      buttonLabel: 'مادة جديدة',
      title: 'إضافة مادة جديدة',
      prompt: 'هذه المادة غير موجودة، هل تود إضافتها؟',
      icon: Icons.inventory_2_rounded,
      accentColor: AppModuleColors.warehouses,
    ),
    _QuickCreateSpec(
      kind: _QuickCreateKind.workplace,
      keyName: 'designQuickWorkplace',
      buttonLabel: 'جهة عمل جديدة',
      title: 'إضافة جهة عمل جديدة',
      prompt: 'جهة العمل غير موجودة، هل تود إضافتها؟',
      icon: Icons.business_center_rounded,
      accentColor: AppModuleColors.parties,
    ),
    _QuickCreateSpec(
      kind: _QuickCreateKind.workplaceBranch,
      keyName: 'designQuickWorkplaceBranch',
      buttonLabel: 'فرع جهة عمل',
      title: 'إضافة فرع لجهة عمل',
      prompt: 'هذا الفرع غير موجود، هل تود إضافته؟',
      icon: Icons.account_tree_rounded,
      accentColor: AppModuleColors.parties,
    ),
    _QuickCreateSpec(
      kind: _QuickCreateKind.itemGroup,
      keyName: 'designQuickItemGroup',
      buttonLabel: 'مجموعة مواد',
      title: 'إضافة مجموعة مواد',
      prompt: 'هذه المجموعة غير موجودة، هل تود إضافتها؟',
      icon: Icons.category_rounded,
      accentColor: AppModuleColors.warehouses,
    ),
    _QuickCreateSpec(
      kind: _QuickCreateKind.itemType,
      keyName: 'designQuickItemType',
      buttonLabel: 'نوع مادة',
      title: 'إضافة نوع ضمن مجموعة',
      prompt: 'هذا النوع غير موجود، هل تود إضافته؟',
      icon: Icons.account_tree_rounded,
      accentColor: AppModuleColors.warehouses,
    ),
    _QuickCreateSpec(
      kind: _QuickCreateKind.cashboxMain,
      keyName: 'designQuickCashboxMain',
      buttonLabel: 'حساب صندوق',
      title: 'إضافة حساب صندوق',
      prompt: 'هذا الحساب غير موجود، هل تود إضافته؟',
      icon: Icons.account_balance_wallet_rounded,
      accentColor: AppModuleColors.cashbox,
    ),
    _QuickCreateSpec(
      kind: _QuickCreateKind.cashboxSub,
      keyName: 'designQuickCashboxSub',
      buttonLabel: 'حساب صندوق فرعي',
      title: 'إضافة حساب صندوق فرعي',
      prompt: 'هذا الحساب الفرعي غير موجود، هل تود إضافته؟',
      icon: Icons.segment_rounded,
      accentColor: AppModuleColors.cashbox,
    ),
  ];

  Future<void> _open(
    BuildContext context,
    _QuickCreateSpec spec,
  ) async {
    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _QuickCreateDialog(spec: spec),
      ),
    );

    if (added == true && context.mounted) {
      AppToast.showSuccess(
        context,
        'تمت إضافة ' + spec.buttonLabel + ' بنجاح',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      title: 'الإضافة السريعة من داخل الشاشات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInfoBanner(
            message:
                'تُستخدم عند عدم وجود الطرف أو المادة أو المرجع المطلوب. تعرض الحقول الأساسية فقط ثم تعيد المستخدم إلى عمله.',
            icon: Icons.add_box_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final spec in _specs)
                AppButton(
                  key: Key(spec.keyName + 'Button'),
                  label: spec.buttonLabel,
                  icon: spec.icon,
                  backgroundColor: spec.accentColor,
                  onPressed: () => _open(context, spec),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _QuickCreateKind {
  party,
  item,
  workplace,
  workplaceBranch,
  itemGroup,
  itemType,
  cashboxMain,
  cashboxSub,
}

@immutable
class _QuickCreateSpec {
  const _QuickCreateSpec({
    required this.kind,
    required this.keyName,
    required this.buttonLabel,
    required this.title,
    required this.prompt,
    required this.icon,
    required this.accentColor,
  });

  final _QuickCreateKind kind;
  final String keyName;
  final String buttonLabel;
  final String title;
  final String prompt;
  final IconData icon;
  final Color accentColor;
}

class _QuickCreateDialog extends StatefulWidget {
  const _QuickCreateDialog({required this.spec});

  final _QuickCreateSpec spec;

  @override
  State<_QuickCreateDialog> createState() => _QuickCreateDialogState();
}

class _QuickCreateDialogState extends State<_QuickCreateDialog> {
  final Map<String, TextEditingController> _controllers = {};
  String _partyType = 'customer';
  String _workplace = 'company';
  String _itemGroup = 'stationery';
  String _cashboxMain = 'expenses';

  _QuickCreateSpec get _spec => widget.spec;

  TextEditingController _controller(String name) {
    return _controllers.putIfAbsent(
      name,
      TextEditingController.new,
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _cancel() => Navigator.of(context).pop(false);

  void _confirm() => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: Key(_spec.keyName + 'Dialog'),
      title: _spec.title,
      subtitle: 'أدخل البيانات الأساسية للمتابعة دون مغادرة الشاشة',
      icon: _spec.icon,
      accentColor: _spec.accentColor,
      width: AppDialogSizes.large,
      onClose: _cancel,
      actionsKey: Key(_spec.keyName + 'Actions'),
      actions: [
        AppButton(
          key: Key(_spec.keyName + 'Cancel'),
          label: 'إلغاء',
          variant: AppButtonVariant.secondary,
          width: 144,
          onPressed: _cancel,
        ),
        AppButton(
          key: Key(_spec.keyName + 'Confirm'),
          label: 'إضافة',
          icon: Icons.add_rounded,
          width: 144,
          backgroundColor: _spec.accentColor,
          onPressed: _confirm,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInfoBanner(
            key: Key(_spec.keyName + 'Prompt'),
            message: _spec.prompt,
            icon: Icons.help_outline_rounded,
            foregroundColor: _spec.accentColor,
            backgroundColor: Color.alphaBlend(
              _spec.accentColor.withAlpha(16),
              AppColors.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFields(),
        ],
      ),
    );
  }

  Widget _buildFields() {
    return switch (_spec.kind) {
      _QuickCreateKind.party => _buildPartyFields(),
      _QuickCreateKind.item => _buildItemFields(),
      _QuickCreateKind.workplace => _buildSingleField(
          name: 'workplaceName',
          label: 'اسم جهة العمل',
          icon: Icons.business_center_rounded,
        ),
      _QuickCreateKind.workplaceBranch => _buildWorkplaceBranchFields(),
      _QuickCreateKind.itemGroup => _buildSingleField(
          name: 'groupName',
          label: 'اسم المجموعة',
          icon: Icons.category_rounded,
        ),
      _QuickCreateKind.itemType => _buildItemTypeFields(),
      _QuickCreateKind.cashboxMain => _buildCashboxMainFields(),
      _QuickCreateKind.cashboxSub => _buildCashboxSubFields(),
    };
  }

  Widget _buildPartyFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                'partyName',
                'الاسم',
                Icons.person_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppDropdownField<String>(
                fieldKey: Key(_spec.keyName + 'Type'),
                label: 'نوع الطرف',
                icon: Icons.groups_rounded,
                accentColor: _spec.accentColor,
                value: _partyType,
                options: const [
                  AppDropdownOption(value: 'customer', label: 'زبون'),
                  AppDropdownOption(value: 'supplier', label: 'مجهز'),
                  AppDropdownOption(value: 'employee', label: 'موظف'),
                  AppDropdownOption(
                    value: 'both',
                    label: 'زبون ومجهز',
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _partyType = value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _field(
                'partyWorkplace',
                'جهة العمل',
                Icons.business_center_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _field(
                'partyBranch',
                'الفرع',
                Icons.account_tree_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _field(
                'partyCity',
                'المدينة',
                Icons.location_city_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppPhoneField(
                fieldKey: Key(_spec.keyName + 'Phone'),
                controller: _controller('partyPhone'),
                label: 'رقم الهاتف',
                accentColor: _spec.accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _field(
                'itemCode',
                'رمز المادة',
                Icons.qr_code_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: _field(
                'itemName',
                'اسم المادة',
                Icons.inventory_2_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _field(
                'itemGroup',
                'المجموعة',
                Icons.category_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _field(
                'itemType',
                'النوع',
                Icons.account_tree_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkplaceBranchFields() {
    return Column(
      children: [
        AppDropdownField<String>(
          fieldKey: Key(_spec.keyName + 'Workplace'),
          label: 'جهة العمل',
          icon: Icons.business_center_rounded,
          accentColor: _spec.accentColor,
          value: _workplace,
          options: const [
            AppDropdownOption(value: 'company', label: 'شركة النور'),
            AppDropdownOption(value: 'market', label: 'أسواق دجلة'),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _workplace = value);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          'workplaceBranchName',
          'اسم الفرع',
          Icons.account_tree_rounded,
        ),
      ],
    );
  }

  Widget _buildItemTypeFields() {
    return Column(
      children: [
        AppDropdownField<String>(
          fieldKey: Key(_spec.keyName + 'Group'),
          label: 'المجموعة',
          icon: Icons.category_rounded,
          accentColor: _spec.accentColor,
          value: _itemGroup,
          options: const [
            AppDropdownOption(value: 'stationery', label: 'قرطاسية'),
            AppDropdownOption(value: 'devices', label: 'أجهزة مكتبية'),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _itemGroup = value);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _field(
          'itemTypeName',
          'اسم النوع',
          Icons.account_tree_rounded,
        ),
      ],
    );
  }

  Widget _buildCashboxMainFields() {
    return Row(
      children: [
        Expanded(
          child: _field(
            'cashboxMainName',
            'اسم الحساب الرئيسي',
            Icons.account_balance_wallet_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _field(
            'cashboxMainCode',
            'رمز الحساب',
            Icons.numbers_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildCashboxSubFields() {
    return Column(
      children: [
        AppDropdownField<String>(
          fieldKey: Key(_spec.keyName + 'MainAccount'),
          label: 'الحساب الرئيسي',
          icon: Icons.account_balance_wallet_rounded,
          accentColor: _spec.accentColor,
          value: _cashboxMain,
          options: const [
            AppDropdownOption(value: 'expenses', label: 'المصاريف'),
            AppDropdownOption(value: 'parties', label: 'الأطراف'),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _cashboxMain = value);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _field(
                'cashboxSubName',
                'اسم الحساب الفرعي',
                Icons.segment_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _field(
                'cashboxSubNotes',
                'الملاحظات',
                Icons.notes_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleField({
    required String name,
    required String label,
    required IconData icon,
  }) {
    return _field(name, label, icon);
  }

  Widget _field(String name, String label, IconData icon) {
    return AppTextField(
      fieldKey: Key(_spec.keyName + name),
      controller: _controller(name),
      label: label,
      icon: icon,
      accentColor: _spec.accentColor,
    );
  }
}
