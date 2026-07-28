import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
import '../domain/item.dart';
import 'items_controller.dart';
import 'widgets/item_form.dart';
import 'widgets/items_table.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _itemsController = ItemsController();
  final _formControllers = ItemFormControllers();
  final _formKey = GlobalKey<ItemFormState>();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  late String _groupId;
  late String _typeId;
  late _ItemFormSnapshot _baseline;
  bool _isApplyingFormState = false;
  bool _hasUnsavedChanges = false;

  Iterable<TextEditingController> get _editableControllers => [
        _formControllers.code,
        _formControllers.name,
        _formControllers.salePriceIqd,
        _formControllers.salePriceUsd,
        _formControllers.notes,
      ];

  List<ItemType> get _visibleTypes =>
      _itemsController.typesFor(_groupId);

  ItemGroup get _selectedGroup =>
      _itemsController.groupById(_groupId);

  ItemType get _selectedType =>
      _itemsController.typeById(_typeId);

  @override
  void initState() {
    super.initState();
    _setNewForm();
    for (final controller in _editableControllers) {
      controller.addListener(_refreshUnsavedState);
    }
  }

  @override
  void dispose() {
    for (final controller in _editableControllers) {
      controller.removeListener(_refreshUnsavedState);
    }
    _itemsController.dispose();
    _formControllers.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setNewForm() {
    _isApplyingFormState = true;
    _groupId = ItemsController.groups.first.id;
    _typeId = _itemsController.typesFor(_groupId).first.id;
    _formControllers.setNew();
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  void _resetToNewItem() {
    _itemsController.select(null);
    setState(_setNewForm);
  }

  void _loadItem(Item item) {
    _isApplyingFormState = true;
    _groupId = item.groupId;
    _typeId = item.typeId;
    _formControllers.load(item);
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    setState(() => _hasUnsavedChanges = false);
  }

  void _selectItem(Item item) {
    if (_itemsController.selectedItem?.id == item.id) return;
    unawaited(_selectItemAfterConfirmation(item));
  }

  Future<void> _selectItemAfterConfirmation(Item item) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    _itemsController.select(item.id);
    _loadItem(item);
  }

  void _navigate(VoidCallback navigation) {
    unawaited(_navigateAfterConfirmation(navigation));
  }

  Future<void> _navigateAfterConfirmation(VoidCallback navigation) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    navigation();
    final selected = _itemsController.selectedItem;
    if (selected == null) {
      setState(_setNewForm);
    } else {
      _loadItem(selected);
    }
  }

  void _changeGroup(String? value) {
    if (value == null || value == _groupId) return;
    setState(() {
      _groupId = value;
      _typeId = _itemsController.typesFor(value).first.id;
      _refreshSelectionState();
    });
  }

  void _changeType(String? value) {
    if (value == null || value == _typeId) return;
    setState(() {
      _typeId = value;
      _refreshSelectionState();
    });
  }

  _ItemFormSnapshot _currentSnapshot() => (
        code: _formControllers.code.text,
        name: _formControllers.name.text,
        groupId: _groupId,
        typeId: _typeId,
        salePriceIqd: _formControllers.salePriceIqd.text,
        salePriceUsd: _formControllers.salePriceUsd.text,
        notes: _formControllers.notes.text,
      );

  void _refreshUnsavedState() {
    if (_isApplyingFormState || !mounted) return;
    final hasUnsavedChanges = _currentSnapshot() != _baseline;
    if (_hasUnsavedChanges == hasUnsavedChanges) return;
    setState(() => _hasUnsavedChanges = hasUnsavedChanges);
  }

  void _refreshSelectionState() {
    _hasUnsavedChanges = _currentSnapshot() != _baseline;
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    return AppDialogs.confirm(
      context: context,
      title: 'تغييرات غير محفوظة',
      message: 'لديك بيانات أو تعديلات غير محفوظة. هل تريد تجاهلها؟',
      confirmLabel: 'تجاهل',
      cancelLabel: 'البقاء',
      isDanger: true,
    );
  }

  void _attemptBack() {
    unawaited(_leaveAfterConfirmation());
  }

  Future<void> _leaveAfterConfirmation() async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    Navigator.of(context).pop();
  }

  bool _validateForm() {
    if (!(_formKey.currentState?.validateRequiredFields() ?? false)) {
      AppToast.showWarning(context, 'أكمل رمز المادة واسمها أولاً');
      return false;
    }

    final selectedId = _itemsController.selectedItem?.id;
    if (_itemsController.codeExists(
      _formControllers.code.text,
      exceptItemId: selectedId,
    )) {
      AppToast.showWarning(context, 'رمز المادة مستخدم مسبقاً');
      return false;
    }

    final priceIqd =
        AppFormatters.parseNumber(_formControllers.salePriceIqd.text);
    final priceUsd =
        AppFormatters.parseNumber(_formControllers.salePriceUsd.text);
    if (priceIqd == null ||
        priceUsd == null ||
        priceIqd < 0 ||
        priceUsd < 0) {
      AppToast.showWarning(
        context,
        'أدخل أسعار بيع صحيحة وغير سالبة',
      );
      return false;
    }
    return true;
  }

  Item _newItemFromForm() {
    return Item(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      code: _formControllers.code.text.trim(),
      name: _formControllers.name.text.trim(),
      barcode: _formControllers.barcode.text.trim(),
      groupId: _groupId,
      groupName: _selectedGroup.name,
      typeId: _typeId,
      typeName: _selectedType.name,
      salePriceIqd:
          AppFormatters.parseNumber(_formControllers.salePriceIqd.text) ??
              0,
      salePriceUsd:
          AppFormatters.parseNumber(_formControllers.salePriceUsd.text) ??
              0,
      notes: _formControllers.notes.text.trim(),
    );
  }

  Item _updatedItemFromForm(Item current) {
    return current.copyWith(
      code: _formControllers.code.text.trim(),
      name: _formControllers.name.text.trim(),
      barcode: _formControllers.barcode.text.trim(),
      groupId: _groupId,
      groupName: _selectedGroup.name,
      typeId: _typeId,
      typeName: _selectedType.name,
      salePriceIqd:
          AppFormatters.parseNumber(_formControllers.salePriceIqd.text) ??
              0,
      salePriceUsd:
          AppFormatters.parseNumber(_formControllers.salePriceUsd.text) ??
              0,
      notes: _formControllers.notes.text.trim(),
    );
  }

  void _save() {
    if (!_validateForm()) return;
    if (_itemsController.selectedItem != null) {
      AppToast.showWarning(
        context,
        'استخدم زر تحديث لتعديل المادة المحددة',
      );
      return;
    }

    final item = _newItemFromForm();
    _itemsController.add(item);
    _loadItem(item);
    AppToast.showInfo(context, 'تم حفظ المادة مؤقتاً');
  }

  void _update() {
    final selected = _itemsController.selectedItem;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مادة من الجدول لتحديثها');
      return;
    }
    if (!_validateForm()) return;

    final updated = _updatedItemFromForm(selected);
    _itemsController.update(updated);
    _loadItem(updated);
    AppToast.showSuccess(context, 'تم تحديث المادة مؤقتاً');
  }

  void _undo() {
    final selected = _itemsController.selectedItem;
    if (selected == null) {
      _resetToNewItem();
    } else {
      _loadItem(selected);
    }
    AppToast.showWarning(context, 'تم التراجع عن التغييرات');
  }

  Future<void> _delete() async {
    final selected = _itemsController.selectedItem;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مادة من الجدول لحذفها');
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف المادة',
      message: 'هل تريد حذف ${selected.name}؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted || !confirmed) return;

    _itemsController.deleteSelected();
    setState(_setNewForm);
    AppToast.showDanger(context, 'تم حذف المادة مؤقتاً');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _itemsController,
      builder: (context, _) {
        final selected = _itemsController.selectedItem;
        final visibleItems = _itemsController.visibleItems;
        final selectedVisibleIndex =
            _itemsController.selectedVisibleIndex;
        final hasVisibleItems = visibleItems.isNotEmpty;
        final canMoveToFirstOrPrevious =
            hasVisibleItems && selectedVisibleIndex != 0;
        final canMoveToNextOrLast =
            hasVisibleItems && selectedVisibleIndex >= 0;

        return AppScreenShell(
          key: const Key('itemsScreen'),
          title: 'المواد',
          subtitle: 'إدارة المواد والمجموعات والأنواع وأسعار البيع',
          backgroundColor: Color.alphaBlend(
            AppModuleColors.warehouses.withAlpha(12),
            AppColors.surface,
          ),
          onBack: _attemptBack,
          onSearch: _searchFocusNode.requestFocus,
          onSave: selected != null
              ? _hasUnsavedChanges
                  ? _update
                  : null
              : _save,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                ItemForm(
                  key: _formKey,
                  controllers: _formControllers,
                  groups: ItemsController.groups,
                  types: _visibleTypes,
                  groupId: _groupId,
                  typeId: _typeId,
                  onGroupChanged: _changeGroup,
                  onTypeChanged: _changeType,
                ),
                const SizedBox(height: AppSpacing.md),
                AppActionBar(
                  key: const Key('itemsActionBar'),
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  searchFieldKey: const Key('itemsSearchField'),
                  searchClearButtonKey:
                      const Key('itemsSearchClearButton'),
                  firstButtonKey: const Key('itemsFirstButton'),
                  previousButtonKey:
                      const Key('itemsPreviousButton'),
                  nextButtonKey: const Key('itemsNextButton'),
                  lastButtonKey: const Key('itemsLastButton'),
                  saveButtonKey: const Key('itemsSaveButton'),
                  updateButtonKey: const Key('itemsUpdateButton'),
                  undoButtonKey: const Key('itemsUndoButton'),
                  deleteButtonKey: const Key('itemsDeleteButton'),
                  searchHint:
                      'رمز المادة أو اسمها أو المجموعة أو النوع',
                  accentColor: AppModuleColors.warehouses,
                  onSearchChanged: _itemsController.search,
                  onFirst: canMoveToFirstOrPrevious
                      ? () => _navigate(_itemsController.first)
                      : null,
                  onPrevious: canMoveToFirstOrPrevious
                      ? () => _navigate(_itemsController.previous)
                      : null,
                  onNext: canMoveToNextOrLast
                      ? () => _navigate(_itemsController.next)
                      : null,
                  onLast: canMoveToNextOrLast
                      ? () => _navigate(_itemsController.last)
                      : null,
                  onSave: selected == null ? _save : null,
                  onUpdate:
                      selected != null && _hasUnsavedChanges ? _update : null,
                  onUndo: _hasUnsavedChanges ? _undo : null,
                  onDelete: selected != null ? _delete : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ItemsTable(
                        items: visibleItems,
                        selectedItemId:
                            _itemsController.state.selectedItemId,
                        onSelected: _selectItem,
                        height: constraints.maxHeight,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

typedef _ItemFormSnapshot = ({
  String code,
  String name,
  String groupId,
  String typeId,
  String salePriceIqd,
  String salePriceUsd,
  String notes,
});
