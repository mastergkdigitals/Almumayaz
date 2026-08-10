import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/data/app_repository.dart';
import '../../../core/design/app_design_system.dart';
import '../domain/item.dart';
import 'items_controller.dart';
import 'widgets/item_form.dart';
import 'widgets/items_table.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key, this.controller});

  final ItemsController? controller;

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late ItemsController _itemsController;
  bool _controllerInitialized = false;
  bool _ownsController = false;
  bool _showEditorWhenEmpty = false;
  final _formControllers = ItemFormControllers();
  final _formKey = GlobalKey<ItemFormState>();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String _groupId = '';
  String _typeId = '';
  late _ItemFormSnapshot _baseline;
  bool _isApplyingFormState = false;
  bool _hasUnsavedChanges = false;
  Future<bool>? _pendingDiscardConfirmation;

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
      _itemsController.groupById(_groupId)!;

  ItemType get _selectedType =>
      _itemsController.typeById(_typeId)!;

  @override
  void initState() {
    super.initState();
    _formControllers.setNew();
    _baseline = _currentSnapshot();
    for (final controller in _editableControllers) {
      controller.addListener(_refreshUnsavedState);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllerInitialized) return;
    _setController(widget.controller);
    _controllerInitialized = true;
    unawaited(_loadItems());
  }

  @override
  void didUpdateWidget(covariant ItemsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    final previousController = _itemsController;
    final disposePreviousController = _ownsController;
    _setController(widget.controller);
    _showEditorWhenEmpty = false;
    _hasUnsavedChanges = false;
    _baseline = _currentSnapshot();
    if (disposePreviousController) previousController.dispose();
    unawaited(_loadItems());
  }

  void _setController(ItemsController? suppliedController) {
    if (suppliedController != null) {
      _itemsController = suppliedController;
      _ownsController = false;
    } else {
      final store = AppStoreScope.of(context, listen: false);
      _itemsController = ItemsController(
        repository: store.repositories.items,
        onDataChanged: store.markDataChanged,
      );
      _ownsController = true;
    }
  }

  Future<void> _loadItems() async {
    final controller = _itemsController;
    await controller.load();
    if (!mounted || !identical(controller, _itemsController)) return;
    final status = controller.state.dataState.status;
    if (status == AppDataStatus.ready || status == AppDataStatus.empty) {
      setState(_setNewForm);
    }
  }

  @override
  void dispose() {
    for (final controller in _editableControllers) {
      controller.removeListener(_refreshUnsavedState);
    }
    if (_controllerInitialized && _ownsController) {
      _itemsController.dispose();
    }
    _formControllers.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setNewForm() {
    _isApplyingFormState = true;
    final groups = _itemsController.state.groups;
    _groupId = groups.isEmpty ? '' : groups.first.id;
    final types = _groupId.isEmpty
        ? const <ItemType>[]
        : _itemsController.typesFor(_groupId);
    _typeId = types.isEmpty ? '' : types.first.id;
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
      final types = _itemsController.typesFor(value);
      _typeId = types.isEmpty ? '' : types.first.id;
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
    final pendingConfirmation = _pendingDiscardConfirmation;
    if (pendingConfirmation != null) return pendingConfirmation;

    final confirmation = AppDialogs.confirm(
      context: context,
      title: 'تغييرات غير محفوظة',
      message: 'لديك بيانات أو تعديلات غير محفوظة. هل تريد تجاهلها؟',
      confirmLabel: 'تجاهل',
      cancelLabel: 'البقاء',
      isDanger: true,
    );
    _pendingDiscardConfirmation = confirmation;
    try {
      return await confirmation;
    } finally {
      if (identical(_pendingDiscardConfirmation, confirmation)) {
        _pendingDiscardConfirmation = null;
      }
    }
  }

  void _attemptBack() {
    unawaited(_leaveAfterConfirmation());
  }

  Future<void> _leaveAfterConfirmation() async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    if (_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = false);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
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

  Future<void> _save() async {
    if (!_validateForm()) return;
    if (_itemsController.selectedItem != null) {
      AppToast.showWarning(
        context,
        'استخدم زر تحديث لتعديل المادة المحددة',
      );
      return;
    }

    try {
      final item = await _itemsController.add(_newItemFromForm());
      if (!mounted) return;
      _loadItem(item);
      AppToast.showInfo(context, 'تم حفظ المادة');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, _stateErrorMessage(error));
    }
  }

  Future<void> _update() async {
    final selected = _itemsController.selectedItem;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مادة من الجدول لتحديثها');
      return;
    }
    if (!_validateForm()) return;

    try {
      final updated = await _itemsController.update(
        _updatedItemFromForm(selected),
      );
      if (!mounted) return;
      _loadItem(updated);
      AppToast.showSuccess(context, 'تم تحديث المادة');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, _stateErrorMessage(error));
    }
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
    final decision = await _itemsController.canDeleteSelected();
    if (!mounted) return;
    if (!decision.isAllowed) {
      AppToast.showDanger(
        context,
        decision.reason ?? 'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
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

    await _itemsController.deleteSelected();
    if (!mounted) return;
    setState(_setNewForm);
    AppToast.showDanger(context, 'تم حذف المادة');
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
        final dataState = _itemsController.state.dataState;
        final showEditor = dataState.status == AppDataStatus.ready ||
            (dataState.status == AppDataStatus.empty &&
                _showEditorWhenEmpty);

        return PopScope(
          canPop: !_hasUnsavedChanges,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _attemptBack();
          },
          child: AppScreenShell(
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
              child: showEditor
                  ? Column(
              children: [
                ItemForm(
                  key: _formKey,
                  controllers: _formControllers,
                  groups: _itemsController.state.groups,
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
                    )
                  : AppDataStateView<List<Item>>(
                      state: dataState,
                      dataBuilder: (_, _) => const SizedBox.shrink(),
                      loadingStateKey: const Key('itemsLoadingState'),
                      emptyStateKey: const Key('itemsEmptyState'),
                      missingReferenceStateKey:
                          const Key('itemsMissingReferenceState'),
                      errorStateKey: const Key('itemsErrorState'),
                      emptyActionLabel: 'إضافة مادة',
                      onEmptyAction: () {
                        setState(() {
                          _showEditorWhenEmpty = true;
                          _setNewForm();
                        });
                      },
                      missingReferenceActionLabel: 'إعادة المحاولة',
                      onMissingReferenceAction: _loadItems,
                      onRetry: _loadItems,
                    ),
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

String _stateErrorMessage(StateError error) {
  return error.message;
}
