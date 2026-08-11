import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_button.dart';
import 'app_fields.dart';
import 'app_feedback.dart';
import 'app_module_dialog.dart';

@immutable
class AppPartyQuickCreateValues<T> {
  const AppPartyQuickCreateValues({
    required this.name,
    required this.type,
    required this.phone,
    required this.alternatePhone,
    required this.city,
    required this.address,
    required this.notes,
  });

  final String name;
  final T type;
  final String phone;
  final String alternatePhone;
  final String city;
  final String address;
  final String notes;
}

@immutable
class AppQuickCreateReferenceOption {
  const AppQuickCreateReferenceOption({
    required this.id,
    required this.name,
    required this.number,
    this.parentId,
  });

  final String id;
  final String name;
  final int number;
  final String? parentId;
}

@immutable
class AppItemQuickCreateValues {
  const AppItemQuickCreateValues({
    required this.code,
    required this.name,
    required this.groupId,
    required this.typeId,
  });

  final String code;
  final String name;
  final String groupId;
  final String typeId;
}

@immutable
class AppCashboxMainQuickCreateValues {
  const AppCashboxMainQuickCreateValues({
    required this.mainAccountName,
    required this.subaccountName,
  });

  final String mainAccountName;
  final String subaccountName;
}

/// Design-system dialog for creating a missing named reference in place.
abstract final class AppQuickCreateDialog {
  static Future<String?> showName({
    required BuildContext context,
    required String title,
    required String prompt,
    required String fieldLabel,
    required IconData icon,
    required Color accentColor,
    required String keyPrefix,
    String initialValue = '',
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _QuickCreateNameDialog(
          title: title,
          prompt: prompt,
          fieldLabel: fieldLabel,
          icon: icon,
          accentColor: accentColor,
          keyPrefix: keyPrefix,
          initialValue: initialValue,
        ),
      ),
    );
  }

  /// Creates a party without importing feature-domain types into the Design
  /// System. Callers provide their typed options and receive the same type.
  static Future<AppPartyQuickCreateValues<T>?> showParty<T>({
    required BuildContext context,
    required String title,
    required String prompt,
    required IconData icon,
    required Color accentColor,
    required String keyPrefix,
    required T initialType,
    required List<AppDropdownOption<T>> typeOptions,
    String initialName = '',
  }) {
    return showDialog<AppPartyQuickCreateValues<T>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _QuickCreatePartyDialog<T>(
          title: title,
          prompt: prompt,
          icon: icon,
          accentColor: accentColor,
          keyPrefix: keyPrefix,
          initialName: initialName,
          initialType: initialType,
          typeOptions: typeOptions,
        ),
      ),
    );
  }

  static Future<AppItemQuickCreateValues?> showItem({
    required BuildContext context,
    required String title,
    required String prompt,
    required Color accentColor,
    required String keyPrefix,
    required List<AppQuickCreateReferenceOption> groups,
    required List<AppQuickCreateReferenceOption> types,
    String initialCode = '',
    String initialName = '',
  }) {
    return showDialog<AppItemQuickCreateValues>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _QuickCreateItemDialog(
          title: title,
          prompt: prompt,
          accentColor: accentColor,
          keyPrefix: keyPrefix,
          groups: groups,
          types: types,
          initialCode: initialCode,
          initialName: initialName,
        ),
      ),
    );
  }

  static Future<AppCashboxMainQuickCreateValues?> showCashboxMain({
    required BuildContext context,
    required String title,
    required String prompt,
    required Color accentColor,
    required String keyPrefix,
    String initialMainAccountName = '',
  }) {
    return showDialog<AppCashboxMainQuickCreateValues>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _QuickCreateCashboxMainDialog(
          title: title,
          prompt: prompt,
          accentColor: accentColor,
          keyPrefix: keyPrefix,
          initialMainAccountName: initialMainAccountName,
        ),
      ),
    );
  }
}

class _QuickCreateNameDialog extends StatefulWidget {
  const _QuickCreateNameDialog({
    required this.title,
    required this.prompt,
    required this.fieldLabel,
    required this.icon,
    required this.accentColor,
    required this.keyPrefix,
    required this.initialValue,
  });

  final String title;
  final String prompt;
  final String fieldLabel;
  final IconData icon;
  final Color accentColor;
  final String keyPrefix;
  final String initialValue;

  @override
  State<_QuickCreateNameDialog> createState() =>
      _QuickCreateNameDialogState();
}

class _QuickCreateNameDialogState extends State<_QuickCreateNameDialog> {
  late final TextEditingController _controller;

  bool get _canConfirm => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _cancel() => Navigator.of(context).pop();

  void _confirm() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: Key('${widget.keyPrefix}Dialog'),
      title: widget.title,
      subtitle: 'أدخل البيانات الأساسية للمتابعة دون مغادرة الشاشة',
      icon: widget.icon,
      accentColor: widget.accentColor,
      width: AppDialogSizes.medium,
      onClose: _cancel,
      actionsKey: Key('${widget.keyPrefix}Actions'),
      actions: [
        AppButton(
          key: Key('${widget.keyPrefix}Cancel'),
          label: 'إلغاء',
          variant: AppButtonVariant.secondary,
          width: 144,
          onPressed: _cancel,
        ),
        AppButton(
          key: Key('${widget.keyPrefix}Confirm'),
          label: 'إضافة',
          icon: Icons.add_rounded,
          width: 144,
          backgroundColor: widget.accentColor,
          onPressed: _canConfirm ? _confirm : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInfoBanner(
            key: Key('${widget.keyPrefix}Prompt'),
            message: widget.prompt,
            icon: Icons.help_outline_rounded,
            foregroundColor: widget.accentColor,
            backgroundColor: Color.alphaBlend(
              widget.accentColor.withAlpha(16),
              AppColors.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            fieldKey: Key('${widget.keyPrefix}NameField'),
            controller: _controller,
            label: widget.fieldLabel,
            icon: widget.icon,
            accentColor: widget.accentColor,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_canConfirm) _confirm();
            },
          ),
        ],
      ),
    );
  }
}

class _QuickCreatePartyDialog<T> extends StatefulWidget {
  const _QuickCreatePartyDialog({
    required this.title,
    required this.prompt,
    required this.icon,
    required this.accentColor,
    required this.keyPrefix,
    required this.initialName,
    required this.initialType,
    required this.typeOptions,
  });

  final String title;
  final String prompt;
  final IconData icon;
  final Color accentColor;
  final String keyPrefix;
  final String initialName;
  final T initialType;
  final List<AppDropdownOption<T>> typeOptions;

  @override
  State<_QuickCreatePartyDialog<T>> createState() =>
      _QuickCreatePartyDialogState<T>();
}

class _QuickCreatePartyDialogState<T>
    extends State<_QuickCreatePartyDialog<T>> {
  late final TextEditingController _nameController;
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  late T _type;

  bool get _canConfirm =>
      _nameController.text.trim().isNotEmpty &&
      widget.typeOptions.any((option) => option.value == _type);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName.trim());
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.of(context).pop(
      AppPartyQuickCreateValues<T>(
        name: _nameController.text.trim(),
        type: _type,
        phone: _phoneController.text.trim(),
        alternatePhone: _alternatePhoneController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _QuickCreateDialogFrame(
      keyPrefix: widget.keyPrefix,
      title: widget.title,
      prompt: widget.prompt,
      icon: widget.icon,
      accentColor: widget.accentColor,
      canConfirm: _canConfirm,
      onConfirm: _confirm,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  fieldKey: Key('${widget.keyPrefix}NameField'),
                  controller: _nameController,
                  label: 'الاسم',
                  icon: Icons.person_rounded,
                  accentColor: widget.accentColor,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppDropdownField<T>(
                  fieldKey: Key('${widget.keyPrefix}TypeField'),
                  label: 'نوع الطرف',
                  icon: Icons.groups_rounded,
                  accentColor: widget.accentColor,
                  useIntrinsicHeight: true,
                  value: _type,
                  options: widget.typeOptions,
                  onChanged: (value) {
                    if (value != null) setState(() => _type = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppPhoneField(
                  fieldKey: Key('${widget.keyPrefix}PhoneField'),
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  accentColor: widget.accentColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppPhoneField(
                  fieldKey: Key('${widget.keyPrefix}AlternatePhoneField'),
                  controller: _alternatePhoneController,
                  label: 'رقم الهاتف البديل',
                  accentColor: widget.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  fieldKey: Key('${widget.keyPrefix}CityField'),
                  controller: _cityController,
                  label: 'المدينة',
                  icon: Icons.location_city_rounded,
                  accentColor: widget.accentColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  fieldKey: Key('${widget.keyPrefix}AddressField'),
                  controller: _addressController,
                  label: 'العنوان',
                  icon: Icons.location_on_rounded,
                  accentColor: widget.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            fieldKey: Key('${widget.keyPrefix}NotesField'),
            controller: _notesController,
            label: 'الملاحظات',
            icon: Icons.notes_rounded,
            accentColor: widget.accentColor,
            minLines: 2,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _QuickCreateItemDialog extends StatefulWidget {
  const _QuickCreateItemDialog({
    required this.title,
    required this.prompt,
    required this.accentColor,
    required this.keyPrefix,
    required this.groups,
    required this.types,
    required this.initialCode,
    required this.initialName,
  });

  final String title;
  final String prompt;
  final Color accentColor;
  final String keyPrefix;
  final List<AppQuickCreateReferenceOption> groups;
  final List<AppQuickCreateReferenceOption> types;
  final String initialCode;
  final String initialName;

  @override
  State<_QuickCreateItemDialog> createState() =>
      _QuickCreateItemDialogState();
}

class _QuickCreateItemDialogState extends State<_QuickCreateItemDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  String? _groupId;
  String? _typeId;

  List<AppQuickCreateReferenceOption> get _visibleTypes => widget.types
      .where((type) => type.parentId == _groupId)
      .toList(growable: false);

  bool get _canConfirm =>
      _codeController.text.trim().isNotEmpty &&
      _nameController.text.trim().isNotEmpty &&
      _groupId != null &&
      _visibleTypes.any((type) => type.id == _typeId);

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode.trim());
    _nameController = TextEditingController(text: widget.initialName.trim());
    if (widget.groups.isNotEmpty) {
      _groupId = widget.groups.first.id;
      final types = _visibleTypes;
      if (types.isNotEmpty) _typeId = types.first.id;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _changeGroup(String? groupId) {
    if (groupId == null || groupId == _groupId) return;
    setState(() {
      _groupId = groupId;
      final types = _visibleTypes;
      _typeId = types.isEmpty ? null : types.first.id;
    });
  }

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.of(context).pop(
      AppItemQuickCreateValues(
        code: _codeController.text.trim(),
        name: _nameController.text.trim(),
        groupId: _groupId!,
        typeId: _typeId!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _QuickCreateDialogFrame(
      keyPrefix: widget.keyPrefix,
      title: widget.title,
      prompt: widget.prompt,
      icon: Icons.inventory_2_rounded,
      accentColor: widget.accentColor,
      canConfirm: _canConfirm,
      onConfirm: _confirm,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  fieldKey: Key('${widget.keyPrefix}CodeField'),
                  controller: _codeController,
                  label: 'رمز المادة',
                  icon: Icons.qr_code_rounded,
                  accentColor: widget.accentColor,
                  autofocus: widget.initialCode.trim().isEmpty,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: AppTextField(
                  fieldKey: Key('${widget.keyPrefix}NameField'),
                  controller: _nameController,
                  label: 'اسم المادة',
                  icon: Icons.inventory_2_rounded,
                  accentColor: widget.accentColor,
                  autofocus: widget.initialCode.trim().isNotEmpty &&
                      widget.initialName.trim().isEmpty,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppDropdownField<String>(
                  fieldKey: Key('${widget.keyPrefix}GroupField'),
                  label: 'المجموعة',
                  icon: Icons.category_rounded,
                  accentColor: widget.accentColor,
                  useIntrinsicHeight: true,
                  value: _groupId,
                  options: [
                    for (final group in widget.groups)
                      AppDropdownOption(
                        value: group.id,
                        label: '${group.number} - ${group.name}',
                      ),
                  ],
                  onChanged: _changeGroup,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppDropdownField<String>(
                  fieldKey: Key('${widget.keyPrefix}TypeField'),
                  label: 'النوع',
                  icon: Icons.account_tree_rounded,
                  accentColor: widget.accentColor,
                  useIntrinsicHeight: true,
                  value: _typeId,
                  options: [
                    for (final type in _visibleTypes)
                      AppDropdownOption(
                        value: type.id,
                        label: '${type.number} - ${type.name}',
                      ),
                  ],
                  onChanged: (value) => setState(() => _typeId = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCreateCashboxMainDialog extends StatefulWidget {
  const _QuickCreateCashboxMainDialog({
    required this.title,
    required this.prompt,
    required this.accentColor,
    required this.keyPrefix,
    required this.initialMainAccountName,
  });

  final String title;
  final String prompt;
  final Color accentColor;
  final String keyPrefix;
  final String initialMainAccountName;

  @override
  State<_QuickCreateCashboxMainDialog> createState() =>
      _QuickCreateCashboxMainDialogState();
}

class _QuickCreateCashboxMainDialogState
    extends State<_QuickCreateCashboxMainDialog> {
  late final TextEditingController _mainController;
  final _subaccountController = TextEditingController();

  bool get _canConfirm =>
      _mainController.text.trim().isNotEmpty &&
      _subaccountController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _mainController = TextEditingController(
      text: widget.initialMainAccountName.trim(),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _subaccountController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.of(context).pop(
      AppCashboxMainQuickCreateValues(
        mainAccountName: _mainController.text.trim(),
        subaccountName: _subaccountController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _QuickCreateDialogFrame(
      keyPrefix: widget.keyPrefix,
      title: widget.title,
      prompt: widget.prompt,
      icon: Icons.account_balance_wallet_rounded,
      accentColor: widget.accentColor,
      canConfirm: _canConfirm,
      onConfirm: _confirm,
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              fieldKey: Key('${widget.keyPrefix}MainNameField'),
              controller: _mainController,
              label: 'اسم الحساب الرئيسي',
              icon: Icons.account_balance_wallet_rounded,
              accentColor: widget.accentColor,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppTextField(
              fieldKey: Key('${widget.keyPrefix}SubaccountNameField'),
              controller: _subaccountController,
              label: 'اسم أول حساب فرعي',
              icon: Icons.segment_rounded,
              accentColor: widget.accentColor,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_canConfirm) _confirm();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCreateDialogFrame extends StatelessWidget {
  const _QuickCreateDialogFrame({
    required this.keyPrefix,
    required this.title,
    required this.prompt,
    required this.icon,
    required this.accentColor,
    required this.canConfirm,
    required this.onConfirm,
    required this.child,
  });

  final String keyPrefix;
  final String title;
  final String prompt;
  final IconData icon;
  final Color accentColor;
  final bool canConfirm;
  final VoidCallback onConfirm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    void cancel() => Navigator.of(context).pop();

    return AppModuleDialog(
      key: Key('${keyPrefix}Dialog'),
      title: title,
      subtitle: 'أدخل البيانات الأساسية للمتابعة دون مغادرة الشاشة',
      icon: icon,
      accentColor: accentColor,
      width: AppDialogSizes.large,
      onClose: cancel,
      actionsKey: Key('${keyPrefix}Actions'),
      actions: [
        AppButton(
          key: Key('${keyPrefix}Cancel'),
          label: 'إلغاء',
          variant: AppButtonVariant.secondary,
          width: 144,
          onPressed: cancel,
        ),
        AppButton(
          key: Key('${keyPrefix}Confirm'),
          label: 'إضافة',
          icon: Icons.add_rounded,
          width: 144,
          backgroundColor: accentColor,
          onPressed: canConfirm ? onConfirm : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInfoBanner(
            key: Key('${keyPrefix}Prompt'),
            message: prompt,
            icon: Icons.help_outline_rounded,
            foregroundColor: accentColor,
            backgroundColor: Color.alphaBlend(
              accentColor.withAlpha(16),
              AppColors.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
