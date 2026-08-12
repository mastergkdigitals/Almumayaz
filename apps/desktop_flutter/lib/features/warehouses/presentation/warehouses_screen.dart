import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/app_state/feature_action_permissions.dart';
import '../../../core/data/app_repository.dart';
import '../../../core/design/app_design_system.dart';
import '../../permissions/domain/permission_models.dart';
import '../../items/presentation/items_screen.dart';
import '../domain/warehouse.dart';
import 'warehouses_controller.dart';
import 'widgets/inventory_transfer_dialog.dart';
import 'widgets/warehouse_form.dart';
import 'widgets/warehouse_inventory_panel.dart';
import 'widgets/warehouses_table.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key, this.controller});

  final WarehousesController? controller;

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  late WarehousesController _warehousesController;
  bool _controllerInitialized = false;
  bool _ownsController = false;
  bool _showEditorWhenEmpty = false;
  final _formControllers = WarehouseFormControllers();
  final _formKey = GlobalKey<WarehouseFormState>();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _inventorySearchController = TextEditingController();

  late _WarehouseFormSnapshot _baseline;
  bool _isApplyingFormState = false;
  bool _hasUnsavedChanges = false;
  Future<bool>? _pendingDiscardConfirmation;
  String _inventoryQuery = '';

  bool _allowsWarehouseAction(PermissionAction action) =>
      AppStoreScope.of(context, listen: false).allowsFeatureAction(
        'warehouses',
        action,
      );

  bool _allowsItemAction(PermissionAction action) =>
      AppStoreScope.of(context, listen: false).allowsFeatureAction(
        'items',
        action,
      );

  Iterable<TextEditingController> get _editableControllers => [
        _formControllers.name,
        _formControllers.location,
        _formControllers.notes,
      ];

  @override
  void initState() {
    super.initState();
    _formControllers.setNew(numberValue: 1);
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
    unawaited(_loadWarehouses());
  }

  @override
  void didUpdateWidget(covariant WarehousesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    final previousController = _warehousesController;
    final disposePreviousController = _ownsController;
    _setController(widget.controller);
    _showEditorWhenEmpty = false;
    _hasUnsavedChanges = false;
    _baseline = _currentSnapshot();
    if (disposePreviousController) previousController.dispose();
    unawaited(_loadWarehouses());
  }

  void _setController(WarehousesController? suppliedController) {
    if (suppliedController != null) {
      _warehousesController = suppliedController;
      _ownsController = false;
    } else {
      final store = AppStoreScope.of(context, listen: false);
      _warehousesController = WarehousesController(
        repository: store.repositories.warehouses,
        itemRepository: store.repositories.items,
        onDataChanged: store.markDataChanged,
      );
      _ownsController = true;
    }
  }

  Future<void> _loadWarehouses() async {
    final controller = _warehousesController;
    await controller.load();
    if (!mounted || !identical(controller, _warehousesController)) return;
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
      _warehousesController.dispose();
    }
    _formControllers.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _inventorySearchController.dispose();
    super.dispose();
  }

  void _setNewForm() {
    _isApplyingFormState = true;
    _formControllers.setNew(numberValue: _warehousesController.nextNumber);
    _inventorySearchController.clear();
    _inventoryQuery = '';
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    _hasUnsavedChanges = false;
  }

  void _resetToNewWarehouse() {
    _warehousesController.select(null);
    setState(_setNewForm);
  }

  void _loadWarehouse(Warehouse warehouse) {
    _isApplyingFormState = true;
    _formControllers.load(warehouse);
    _inventorySearchController.clear();
    _inventoryQuery = '';
    _isApplyingFormState = false;
    _baseline = _currentSnapshot();
    setState(() => _hasUnsavedChanges = false);
  }

  void _selectWarehouse(Warehouse warehouse) {
    if (_warehousesController.selectedWarehouse?.id == warehouse.id) return;
    unawaited(_selectWarehouseAfterConfirmation(warehouse));
  }

  Future<void> _selectWarehouseAfterConfirmation(
    Warehouse warehouse,
  ) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    _warehousesController.select(warehouse.id);
    _loadWarehouse(warehouse);
  }

  void _navigate(VoidCallback navigation) {
    unawaited(_navigateAfterConfirmation(navigation));
  }

  Future<void> _navigateAfterConfirmation(VoidCallback navigation) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    navigation();
    final selected = _warehousesController.selectedWarehouse;
    if (selected == null) {
      setState(_setNewForm);
    } else {
      _loadWarehouse(selected);
    }
  }

  _WarehouseFormSnapshot _currentSnapshot() => (
        name: _formControllers.name.text,
        location: _formControllers.location.text,
        notes: _formControllers.notes.text,
      );

  void _refreshUnsavedState() {
    if (_isApplyingFormState || !mounted) return;
    final hasUnsavedChanges = _currentSnapshot() != _baseline;
    if (_hasUnsavedChanges == hasUnsavedChanges) return;
    setState(() => _hasUnsavedChanges = hasUnsavedChanges);
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

  bool _validateName() {
    if (_formKey.currentState?.validateName() ?? false) return true;
    AppToast.showWarning(context, 'أدخل اسم المخزن أولاً');
    return false;
  }

  Warehouse _newWarehouseFromForm() {
    return Warehouse(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      number: _warehousesController.nextNumber,
      name: _formControllers.name.text.trim(),
      location: _formControllers.location.text.trim(),
      notes: _formControllers.notes.text.trim(),
    );
  }

  Warehouse _updatedWarehouseFromForm(Warehouse current) {
    return current.copyWith(
      name: _formControllers.name.text.trim(),
      location: _formControllers.location.text.trim(),
      notes: _formControllers.notes.text.trim(),
    );
  }

  Future<void> _save() async {
    if (!_allowsWarehouseAction(PermissionAction.create)) return;
    if (!_validateName()) return;
    if (_warehousesController.selectedWarehouse != null) {
      AppToast.showWarning(
        context,
        'استخدم زر تحديث لتعديل المخزن المحدد',
      );
      return;
    }

    final warehouse = _newWarehouseFromForm();
    final controller = _warehousesController;
    try {
      final saved = await controller.add(warehouse);
      if (!mounted || !identical(controller, _warehousesController)) return;
      _loadWarehouse(saved);
      AppToast.showInfo(context, 'تم حفظ المخزن');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, _stateErrorMessage(error));
    }
  }

  Future<void> _update() async {
    if (!_allowsWarehouseAction(PermissionAction.update)) return;
    final selected = _warehousesController.selectedWarehouse;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مخزناً من الجدول لتحديثه');
      return;
    }
    if (!_validateName()) return;

    final updated = _updatedWarehouseFromForm(selected);
    final controller = _warehousesController;
    try {
      final saved = await controller.update(updated);
      if (!mounted || !identical(controller, _warehousesController)) return;
      _loadWarehouse(saved);
      AppToast.showSuccess(context, 'تم تحديث المخزن');
    } on StateError catch (error) {
      if (mounted) AppToast.showWarning(context, _stateErrorMessage(error));
    }
  }

  void _undo() {
    final selected = _warehousesController.selectedWarehouse;
    if (selected == null) {
      _resetToNewWarehouse();
    } else {
      _loadWarehouse(selected);
    }
    AppToast.showWarning(context, 'تم التراجع عن التغييرات');
  }

  Future<void> _delete() async {
    if (!_allowsWarehouseAction(PermissionAction.delete)) return;
    final selected = _warehousesController.selectedWarehouse;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مخزناً من الجدول لحذفه');
      return;
    }
    final controller = _warehousesController;
    final decision = await controller.canDeleteSelected();
    if (!mounted || !identical(controller, _warehousesController)) return;
    if (!decision.isAllowed) {
      AppToast.showDanger(
        context,
        decision.reason ?? 'لا يمكن حذف هذا السجل لأنه مرتبط ببيانات أخرى',
      );
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف المخزن',
      message: 'هل تريد حذف ${selected.name}؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted ||
        !confirmed ||
        !identical(controller, _warehousesController)) {
      return;
    }

    await controller.deleteSelected();
    if (!mounted || !identical(controller, _warehousesController)) return;
    setState(_setNewForm);
    AppToast.showDanger(context, 'تم حذف المخزن');
  }

  Future<void> _openProducts() async {
    if (!_allowsItemAction(PermissionAction.view)) return;
    final controller = _warehousesController;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ItemsScreen(),
      ),
    );
    if (!mounted || !identical(controller, _warehousesController)) return;
    await controller.load();
  }

  Future<void> _openTransfer() async {
    final canCreateTransfer =
        _allowsWarehouseAction(PermissionAction.create);
    final canReverseTransfer =
        _allowsWarehouseAction(PermissionAction.update);
    if (!canCreateTransfer && !canReverseTransfer) return;
    final controller = _warehousesController;
    final selected = controller.selectedWarehouse;
    if (selected == null) return;

    final transferred = await InventoryTransferDialog.show(
      context,
      warehouses: controller.state.warehouses,
      inventoryFor: controller.inventoryFor,
      allowTransfer: canCreateTransfer,
      transferHistory: () => controller.state.transferRecords,
      onReverseTransfer:
          canReverseTransfer ? controller.reverseTransfer : null,
      initialFromWarehouseId: selected.id,
      onTransfer: ({
        required String fromWarehouseId,
        required String toWarehouseId,
        required Map<String, int> quantitiesByItemId,
      }) async {
        if (!canCreateTransfer) return false;
        return controller.transferInventory(
          fromWarehouseId: fromWarehouseId,
          toWarehouseId: toWarehouseId,
          quantitiesByItemId: quantitiesByItemId,
        );
      },
    );
    if (!mounted ||
        !transferred ||
        !identical(controller, _warehousesController)) {
      return;
    }
    AppToast.showInfo(context, 'تم تنفيذ النقل المخزني');
  }

  List<WarehouseInventoryItem> _visibleInventory() {
    final selectedId = _warehousesController.state.selectedWarehouseId;
    final items = _warehousesController.inventoryFor(selectedId);
    final query = _inventoryQuery.trim().toLowerCase();
    if (query.isEmpty) return items;
    return List.unmodifiable(
      items.where((item) => item.searchText.contains(query)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _warehousesController,
      builder: (context, _) {
        final selected = _warehousesController.selectedWarehouse;
        final visibleWarehouses =
            _warehousesController.visibleWarehouses;
        final selectedVisibleIndex =
            _warehousesController.selectedVisibleIndex;
        final hasVisibleWarehouses = visibleWarehouses.isNotEmpty;
        final canMoveToFirstOrPrevious =
            hasVisibleWarehouses && selectedVisibleIndex != 0;
        final canMoveToNextOrLast =
            hasVisibleWarehouses && selectedVisibleIndex >= 0;
        final dataState = _warehousesController.state.dataState;
        final showEditor = dataState.status == AppDataStatus.ready ||
            (dataState.status == AppDataStatus.empty &&
                _showEditorWhenEmpty);
        final canCreate =
            _allowsWarehouseAction(PermissionAction.create);
        final canUpdate =
            _allowsWarehouseAction(PermissionAction.update);
        final canDelete =
            _allowsWarehouseAction(PermissionAction.delete);
        final canOpenItems = _allowsItemAction(PermissionAction.view);
        final canOpenTransfer = canCreate || canUpdate;

        return PopScope(
          canPop: !_hasUnsavedChanges,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _attemptBack();
          },
          child: AppScreenShell(
            key: const Key('warehousesScreen'),
            title: 'المخازن',
            subtitle: 'إدارة المخازن ومتابعة أرصدة المواد',
            backgroundColor: Color.alphaBlend(
              AppModuleColors.warehouses.withAlpha(12),
              AppColors.surface,
            ),
            onBack: _attemptBack,
            onSearch: _searchFocusNode.requestFocus,
            onSave: selected != null
                ? _hasUnsavedChanges && canUpdate
                    ? _update
                    : null
                : canCreate
                    ? _save
                    : null,
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: showEditor
                  ? Column(
              children: [
                WarehouseForm(
                  key: _formKey,
                  controllers: _formControllers,
                ),
                const SizedBox(height: AppSpacing.md),
                AppActionBar(
                  key: const Key('warehousesActionBar'),
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  searchFieldKey:
                      const Key('warehousesSearchField'),
                  searchClearButtonKey:
                      const Key('warehousesSearchClearButton'),
                  firstButtonKey:
                      const Key('warehousesFirstButton'),
                  previousButtonKey:
                      const Key('warehousesPreviousButton'),
                  nextButtonKey: const Key('warehousesNextButton'),
                  lastButtonKey: const Key('warehousesLastButton'),
                  saveButtonKey: const Key('warehousesSaveButton'),
                  updateButtonKey:
                      const Key('warehousesUpdateButton'),
                  undoButtonKey: const Key('warehousesUndoButton'),
                  deleteButtonKey:
                      const Key('warehousesDeleteButton'),
                  searchHint: 'رقم المخزن أو الاسم أو الموقع',
                  accentColor: AppModuleColors.warehouses,
                  onSearchChanged: _warehousesController.search,
                  onFirst: canMoveToFirstOrPrevious
                      ? () => _navigate(_warehousesController.first)
                      : null,
                  onPrevious: canMoveToFirstOrPrevious
                      ? () => _navigate(_warehousesController.previous)
                      : null,
                  onNext: canMoveToNextOrLast
                      ? () => _navigate(_warehousesController.next)
                      : null,
                  onLast: canMoveToNextOrLast
                      ? () => _navigate(_warehousesController.last)
                      : null,
                  onSave: selected == null && canCreate ? _save : null,
                  onUpdate:
                      selected != null && _hasUnsavedChanges && canUpdate
                          ? _update
                          : null,
                  onUndo: _hasUnsavedChanges ? _undo : null,
                  onDelete:
                      selected != null && !selected.isMain && canDelete
                          ? _delete
                          : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = AppSpacing.md;
                      final warehouseWidth =
                          (constraints.maxWidth - gap) * 0.42;
                      final inventoryHeight =
                          constraints.maxHeight - 120;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: warehouseWidth,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'قائمة المخازن',
                                  style: AppTypography.sectionTitle,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Expanded(
                                  child: WarehousesTable(
                                    warehouses: visibleWarehouses,
                                    selectedWarehouseId:
                                        _warehousesController
                                            .state
                                            .selectedWarehouseId,
                                    onSelected: _selectWarehouse,
                                    materialCountFor:
                                        _warehousesController
                                            .materialCountFor,
                                    totalQuantityFor:
                                        _warehousesController
                                            .totalQuantityFor,
                                    height: constraints.maxHeight - 40,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: gap),
                          Expanded(
                            child: WarehouseInventoryPanel(
                              warehouse: selected,
                              items: _visibleInventory(),
                              materialCount: selected == null
                                  ? 0
                                  : _warehousesController
                                      .materialCountFor(selected.id),
                              totalQuantity: selected == null
                                  ? 0
                                  : _warehousesController
                                      .totalQuantityFor(selected.id),
                              searchController:
                                  _inventorySearchController,
                              onSearchChanged: (value) {
                                setState(() => _inventoryQuery = value);
                              },
                              onOpenProducts:
                                  canOpenItems ? _openProducts : null,
                              onOpenTransfer: selected == null ||
                                      !canOpenTransfer
                                  ? null
                                  : _openTransfer,
                              height: inventoryHeight,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
                    )
                  : AppDataStateView<List<Warehouse>>(
                      state: dataState,
                      dataBuilder: (_, _) => const SizedBox.shrink(),
                      loadingStateKey:
                          const Key('warehousesLoadingState'),
                      emptyStateKey: const Key('warehousesEmptyState'),
                      missingReferenceStateKey:
                          const Key('warehousesMissingReferenceState'),
                      errorStateKey: const Key('warehousesErrorState'),
                      emptyActionLabel: 'إضافة مخزن',
                      onEmptyAction: canCreate ? () {
                        setState(() {
                          _showEditorWhenEmpty = true;
                          _setNewForm();
                        });
                      } : null,
                      missingReferenceActionLabel: 'إعادة المحاولة',
                      onMissingReferenceAction: _loadWarehouses,
                      onRetry: _loadWarehouses,
                    ),
            ),
          ),
        );
      },
    );
  }
}

typedef _WarehouseFormSnapshot = ({
  String name,
  String location,
  String notes,
});

String _stateErrorMessage(StateError error) {
  return error.message;
}
