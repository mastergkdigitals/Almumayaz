import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
import '../../items/presentation/items_screen.dart';
import '../domain/warehouse.dart';
import 'warehouses_controller.dart';
import 'widgets/inventory_transfer_dialog.dart';
import 'widgets/warehouse_form.dart';
import 'widgets/warehouse_inventory_panel.dart';
import 'widgets/warehouses_table.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  final _warehousesController = WarehousesController();
  final _formControllers = WarehouseFormControllers();
  final _formKey = GlobalKey<WarehouseFormState>();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _inventorySearchController = TextEditingController();

  late _WarehouseFormSnapshot _baseline;
  bool _isApplyingFormState = false;
  bool _hasUnsavedChanges = false;
  String _inventoryQuery = '';

  Iterable<TextEditingController> get _editableControllers => [
        _formControllers.name,
        _formControllers.location,
        _formControllers.notes,
      ];

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
    _warehousesController.dispose();
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

  void _newWarehouse() {
    unawaited(_newWarehouseAfterConfirmation());
  }

  Future<void> _newWarehouseAfterConfirmation() async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    _resetToNewWarehouse();
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

  void _save() {
    if (!_validateName()) return;
    if (_warehousesController.selectedWarehouse != null) {
      AppToast.showWarning(
        context,
        'استخدم زر تحديث لتعديل المخزن المحدد',
      );
      return;
    }

    final warehouse = _newWarehouseFromForm();
    _warehousesController.add(warehouse);
    _loadWarehouse(warehouse);
    AppToast.showSuccess(context, 'تم حفظ المخزن مؤقتاً');
  }

  void _update() {
    final selected = _warehousesController.selectedWarehouse;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مخزناً من الجدول لتحديثه');
      return;
    }
    if (!_validateName()) return;

    final updated = _updatedWarehouseFromForm(selected);
    _warehousesController.update(updated);
    _loadWarehouse(updated);
    AppToast.showSuccess(context, 'تم تحديث المخزن مؤقتاً');
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
    final selected = _warehousesController.selectedWarehouse;
    if (selected == null) {
      AppToast.showWarning(context, 'اختر مخزناً من الجدول لحذفه');
      return;
    }
    if (selected.isMain) {
      AppToast.showWarning(context, 'لا يمكن حذف المخزن الرئيسي');
      return;
    }

    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف المخزن',
      message: 'هل تريد حذف ${selected.name}؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted || !confirmed) return;

    _warehousesController.deleteSelected();
    setState(_setNewForm);
    AppToast.showDanger(context, 'تم حذف المخزن مؤقتاً');
  }

  Future<void> _openProducts() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ItemsScreen(),
      ),
    );
  }

  void _openGroupsTypes() {
    AppToast.showInfo(
      context,
      'سيتم ربط شاشة المجموعات والأنواع لاحقاً',
    );
  }

  Future<void> _openTransfer() async {
    final selected = _warehousesController.selectedWarehouse;
    if (selected == null) return;

    final transferred = await InventoryTransferDialog.show(
      context,
      warehouses: _warehousesController.state.warehouses,
      inventoryFor: _warehousesController.inventoryFor,
      initialFromWarehouseId: selected.id,
      onTransfer: ({
        required String fromWarehouseId,
        required String toWarehouseId,
        required Map<String, int> quantitiesByProductCode,
      }) {
        return _warehousesController.transferInventory(
          fromWarehouseId: fromWarehouseId,
          toWarehouseId: toWarehouseId,
          quantitiesByProductCode: quantitiesByProductCode,
        );
      },
    );
    if (!mounted || !transferred) return;
    AppToast.showSuccess(context, 'تم تنفيذ النقل المخزني مؤقتاً');
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

        return AppScreenShell(
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
              ? _hasUnsavedChanges
                  ? _update
                  : null
              : _save,
          onNew: _newWarehouse,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
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
                  onSave: selected == null ? _save : null,
                  onUpdate:
                      selected != null && _hasUnsavedChanges ? _update : null,
                  onUndo: _hasUnsavedChanges ? _undo : null,
                  onDelete:
                      selected != null && !selected.isMain ? _delete : null,
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
                              onOpenProducts: _openProducts,
                              onOpenGroupsTypes: _openGroupsTypes,
                              onOpenTransfer:
                                  selected == null ? null : _openTransfer,
                              height: inventoryHeight,
                            ),
                          ),
                        ],
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

typedef _WarehouseFormSnapshot = ({
  String name,
  String location,
  String notes,
});
