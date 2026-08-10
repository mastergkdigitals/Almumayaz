import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/warehouse.dart';

class WarehouseFormControllers {
  final number = TextEditingController();
  final name = TextEditingController();
  final location = TextEditingController();
  final notes = TextEditingController();

  void setNew({required int numberValue}) {
    number.text = numberValue.toString();
    name.clear();
    location.clear();
    notes.clear();
  }

  void load(Warehouse warehouse) {
    number.text = warehouse.number.toString();
    name.text = warehouse.name;
    location.text = warehouse.location;
    notes.text = warehouse.notes;
  }

  void dispose() {
    number.dispose();
    name.dispose();
    location.dispose();
    notes.dispose();
  }
}

class WarehouseForm extends StatefulWidget {
  const WarehouseForm({
    required this.controllers,
    super.key,
  });

  final WarehouseFormControllers controllers;

  @override
  State<WarehouseForm> createState() => WarehouseFormState();
}

class WarehouseFormState extends State<WarehouseForm> {
  static final _enterKeys = {
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  final _keyHoldGuard = AppKeyHoldGuard();
  final _nameFocusNode = FocusNode(debugLabel: 'warehouseName');
  final _locationFocusNode = FocusNode(debugLabel: 'warehouseLocation');
  final _notesFocusNode = FocusNode(debugLabel: 'warehouseNotes');
  String? _nameErrorText;

  WarehouseFormControllers get controllers => widget.controllers;

  @override
  void initState() {
    super.initState();
    controllers.name.addListener(_handleNameChanged);
  }

  @override
  void didUpdateWidget(covariant WarehouseForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controllers.name == controllers.name) return;
    oldWidget.controllers.name.removeListener(_handleNameChanged);
    controllers.name.addListener(_handleNameChanged);
    _nameErrorText = null;
  }

  @override
  void dispose() {
    controllers.name.removeListener(_handleNameChanged);
    _keyHoldGuard.dispose();
    _nameFocusNode.dispose();
    _locationFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  bool validateName() {
    if (controllers.name.text.trim().isNotEmpty) {
      if (_nameErrorText != null) {
        setState(() => _nameErrorText = null);
      }
      return true;
    }

    setState(() => _nameErrorText = 'هذا الحقل مطلوب');
    _nameFocusNode.requestFocus();
    return false;
  }

  void _handleNameChanged() {
    if (_nameErrorText == null || !mounted) return;
    setState(() => _nameErrorText = null);
  }

  void _submitName(String _) {
    if (!validateName()) return;
    _keyHoldGuard.runOnce(
      keys: _enterKeys,
      action: _locationFocusNode.requestFocus,
    );
  }

  void _submitLocation(String _) {
    _keyHoldGuard.runOnce(
      keys: _enterKeys,
      action: _notesFocusNode.requestFocus,
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = AppModuleColors.warehouses;

    return KeyedSubtree(
      key: const Key('warehouseForm'),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WarehouseFieldsRow(
              children: [
                AppReadOnlyField(
                  fieldKey: const Key('warehouseNumberField'),
                  controller: controllers.number,
                  label: 'رقم المخزن',
                  icon: Icons.tag_rounded,
                  accentColor: accentColor,
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: AppTextField(
                    fieldKey: const Key('warehouseNameField'),
                    controller: controllers.name,
                    label: 'اسم المخزن',
                    icon: Icons.warehouse_rounded,
                    accentColor: accentColor,
                    focusNode: _nameFocusNode,
                    errorText: _nameErrorText,
                    textInputAction: TextInputAction.next,
                    onSubmitted: _submitName,
                  ),
                ),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: AppTextField(
                    fieldKey: const Key('warehouseLocationField'),
                    controller: controllers.location,
                    label: 'الموقع',
                    icon: Icons.location_on_rounded,
                    accentColor: accentColor,
                    focusNode: _locationFocusNode,
                    textInputAction: TextInputAction.next,
                    onSubmitted: _submitLocation,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FocusTraversalOrder(
              order: const NumericFocusOrder(3),
              child: AppTextField(
                fieldKey: const Key('warehouseNotesField'),
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

class _WarehouseFieldsRow extends StatelessWidget {
  const _WarehouseFieldsRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.md),
          Expanded(child: children[index]),
        ],
      ],
    );
  }
}
