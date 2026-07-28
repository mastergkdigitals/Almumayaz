import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/item.dart';

class ItemFormControllers {
  final code = TextEditingController();
  final name = TextEditingController();
  final barcode = TextEditingController();
  final salePriceIqd = TextEditingController();
  final salePriceUsd = TextEditingController();
  final notes = TextEditingController();

  void setNew() {
    code.clear();
    name.clear();
    barcode.clear();
    salePriceIqd.text = AppFormatters.iqd(0);
    salePriceUsd.text = AppFormatters.usd(0);
    notes.clear();
  }

  void load(Item item) {
    code.text = item.code;
    name.text = item.name;
    barcode.text = item.barcode;
    salePriceIqd.text = AppFormatters.iqd(item.salePriceIqd);
    salePriceUsd.text = AppFormatters.usd(item.salePriceUsd);
    notes.text = item.notes;
  }

  void dispose() {
    code.dispose();
    name.dispose();
    barcode.dispose();
    salePriceIqd.dispose();
    salePriceUsd.dispose();
    notes.dispose();
  }
}

class ItemForm extends StatefulWidget {
  const ItemForm({
    required this.controllers,
    required this.groups,
    required this.types,
    required this.groupId,
    required this.typeId,
    required this.onGroupChanged,
    required this.onTypeChanged,
    super.key,
  });

  final ItemFormControllers controllers;
  final List<ItemGroup> groups;
  final List<ItemType> types;
  final String groupId;
  final String typeId;
  final ValueChanged<String?> onGroupChanged;
  final ValueChanged<String?> onTypeChanged;

  @override
  State<ItemForm> createState() => ItemFormState();
}

class ItemFormState extends State<ItemForm> {
  static final _enterKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  final _keyHoldGuard = AppKeyHoldGuard();
  final _codeFocusNode = FocusNode(debugLabel: 'itemCode');
  final _nameFocusNode = FocusNode(debugLabel: 'itemName');
  final _groupFocusNode = FocusNode(debugLabel: 'itemGroup');
  final _typeFocusNode = FocusNode(debugLabel: 'itemType');
  final _iqdFocusNode = FocusNode(debugLabel: 'itemSalePriceIqd');
  final _usdFocusNode = FocusNode(debugLabel: 'itemSalePriceUsd');
  final _notesFocusNode = FocusNode(debugLabel: 'itemNotes');
  String? _codeErrorText;
  String? _nameErrorText;

  ItemFormControllers get controllers => widget.controllers;

  @override
  void initState() {
    super.initState();
    controllers.code.addListener(_handleCodeChanged);
    controllers.name.addListener(_handleNameChanged);
  }

  @override
  void didUpdateWidget(covariant ItemForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controllers == controllers) return;
    oldWidget.controllers.code.removeListener(_handleCodeChanged);
    oldWidget.controllers.name.removeListener(_handleNameChanged);
    controllers.code.addListener(_handleCodeChanged);
    controllers.name.addListener(_handleNameChanged);
    _codeErrorText = null;
    _nameErrorText = null;
  }

  @override
  void dispose() {
    controllers.code.removeListener(_handleCodeChanged);
    controllers.name.removeListener(_handleNameChanged);
    _keyHoldGuard.dispose();
    _codeFocusNode.dispose();
    _nameFocusNode.dispose();
    _groupFocusNode.dispose();
    _typeFocusNode.dispose();
    _iqdFocusNode.dispose();
    _usdFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  bool validateRequiredFields() {
    final codeIsValid = controllers.code.text.trim().isNotEmpty;
    final nameIsValid = controllers.name.text.trim().isNotEmpty;
    setState(() {
      _codeErrorText = codeIsValid ? null : 'هذا الحقل مطلوب';
      _nameErrorText = nameIsValid ? null : 'هذا الحقل مطلوب';
    });
    if (!codeIsValid) {
      _codeFocusNode.requestFocus();
    } else if (!nameIsValid) {
      _nameFocusNode.requestFocus();
    }
    return codeIsValid && nameIsValid;
  }

  void _handleCodeChanged() {
    if (_codeErrorText == null || !mounted) return;
    setState(() => _codeErrorText = null);
  }

  void _handleNameChanged() {
    if (_nameErrorText == null || !mounted) return;
    setState(() => _nameErrorText = null);
  }

  void _submitCode(String _) {
    if (controllers.code.text.trim().isEmpty) {
      setState(() => _codeErrorText = 'هذا الحقل مطلوب');
      _codeFocusNode.requestFocus();
      return;
    }
    _moveTo(_nameFocusNode);
  }

  void _submitName(String _) {
    if (controllers.name.text.trim().isEmpty) {
      setState(() => _nameErrorText = 'هذا الحقل مطلوب');
      _nameFocusNode.requestFocus();
      return;
    }
    _moveTo(_groupFocusNode);
  }

  void _moveTo(FocusNode target, {bool guardKeyHold = true}) {
    if (!guardKeyHold) {
      target.requestFocus();
      return;
    }
    _keyHoldGuard.runOnce(
      keys: _enterKeys,
      action: target.requestFocus,
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = AppModuleColors.warehouses;

    return KeyedSubtree(
      key: const Key('itemForm'),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ItemFieldsRow(
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: AppTextField(
                    fieldKey: const Key('itemCodeField'),
                    controller: controllers.code,
                    label: 'رمز المادة',
                    icon: Icons.qr_code_2_rounded,
                    accentColor: accentColor,
                    focusNode: _codeFocusNode,
                    errorText: _codeErrorText,
                    textInputAction: TextInputAction.next,
                    onSubmitted: _submitCode,
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: AppTextField(
                    fieldKey: const Key('itemNameField'),
                    controller: controllers.name,
                    label: 'اسم المادة',
                    icon: Icons.inventory_2_outlined,
                    accentColor: accentColor,
                    focusNode: _nameFocusNode,
                    errorText: _nameErrorText,
                    textInputAction: TextInputAction.next,
                    onSubmitted: _submitName,
                  ),
                ),
                AppReadOnlyField(
                  fieldKey: const Key('itemBarcodeField'),
                  controller: controllers.barcode,
                  label: 'الباركود',
                  icon: Icons.barcode_reader,
                  accentColor: accentColor,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ItemFieldsRow(
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: AppDropdownField<String>(
                    fieldKey: const Key('itemGroupField'),
                    label: 'المجموعة',
                    icon: Icons.category_outlined,
                    accentColor: accentColor,
                    focusNode: _groupFocusNode,
                    keyHoldGuard: _keyHoldGuard,
                    value: widget.groupId,
                    options: [
                      for (final group in widget.groups)
                        AppDropdownOption(
                          value: group.id,
                          label: group.label,
                        ),
                    ],
                    onChanged: widget.onGroupChanged,
                    onSubmitted: (_) =>
                        _moveTo(_typeFocusNode, guardKeyHold: false),
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: AppDropdownField<String>(
                    fieldKey: const Key('itemTypeField'),
                    label: 'النوع',
                    icon: Icons.style_outlined,
                    accentColor: accentColor,
                    focusNode: _typeFocusNode,
                    keyHoldGuard: _keyHoldGuard,
                    value: widget.typeId,
                    options: [
                      for (final type in widget.types)
                        AppDropdownOption(
                          value: type.id,
                          label: type.label,
                        ),
                    ],
                    onChanged: widget.onTypeChanged,
                    onSubmitted: (_) =>
                        _moveTo(_iqdFocusNode, guardKeyHold: false),
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(5),
                  child: AppTextField(
                    fieldKey: const Key('itemSalePriceIqdField'),
                    controller: controllers.salePriceIqd,
                    label: 'سعر البيع دينار',
                    icon: Icons.payments_outlined,
                    accentColor: accentColor,
                    focusNode: _iqdFocusNode,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.next,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [AppMoneyInputFormatter()],
                    onSubmitted: (_) => _moveTo(_usdFocusNode),
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(6),
                  child: AppTextField(
                    fieldKey: const Key('itemSalePriceUsdField'),
                    controller: controllers.salePriceUsd,
                    label: 'سعر البيع دولار',
                    icon: Icons.attach_money_rounded,
                    accentColor: accentColor,
                    focusNode: _usdFocusNode,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.next,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [AppMoneyInputFormatter()],
                    onSubmitted: (_) => _moveTo(_notesFocusNode),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FocusTraversalOrder(
              order: const NumericFocusOrder(7),
              child: AppTextField(
                fieldKey: const Key('itemNotesField'),
                controller: controllers.notes,
                label: 'الملاحظات',
                icon: Icons.notes_rounded,
                accentColor: accentColor,
                focusNode: _notesFocusNode,
                textInputAction: TextInputAction.done,
                onEditingComplete: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemFieldsRow extends StatelessWidget {
  const _ItemFieldsRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: children[index]),
        ],
      ],
    );
  }
}
