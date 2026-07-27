import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/warehouse.dart';

typedef WarehouseInventoryReader =
    List<WarehouseInventoryItem> Function(String warehouseId);

typedef WarehouseTransferHandler = bool Function({
  required String fromWarehouseId,
  required String toWarehouseId,
  required Map<String, int> quantitiesByProductCode,
});

enum _InventoryTransferView { create, history }

class InventoryTransferDialog extends StatefulWidget {
  const InventoryTransferDialog({
    required this.warehouses,
    required this.inventoryFor,
    required this.onTransfer,
    super.key,
    this.initialFromWarehouseId,
  });

  final List<Warehouse> warehouses;
  final WarehouseInventoryReader inventoryFor;
  final WarehouseTransferHandler onTransfer;
  final String? initialFromWarehouseId;

  static Future<bool> show(
    BuildContext context, {
    required List<Warehouse> warehouses,
    required WarehouseInventoryReader inventoryFor,
    required WarehouseTransferHandler onTransfer,
    String? initialFromWarehouseId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: InventoryTransferDialog(
          warehouses: warehouses,
          inventoryFor: inventoryFor,
          onTransfer: onTransfer,
          initialFromWarehouseId: initialFromWarehouseId,
        ),
      ),
    );
    return result ?? false;
  }

  @override
  State<InventoryTransferDialog> createState() =>
      _InventoryTransferDialogState();
}

class _InventoryTransferDialogState
    extends State<InventoryTransferDialog> {
  final _notesController = TextEditingController();
  final _historySearchController = TextEditingController();
  final _rows = <_TransferRowState>[];

  late final List<_TransferHistoryEntry> _history;
  late DateTime _transferDate;
  _InventoryTransferView _view = _InventoryTransferView.create;
  String? _fromWarehouseId;
  String? _toWarehouseId;
  String _historyQuery = '';

  List<Warehouse> get _warehouses => widget.warehouses;

  List<WarehouseInventoryItem> get _sourceItems {
    final sourceId = _fromWarehouseId;
    if (sourceId == null) return const [];
    final items = widget
        .inventoryFor(sourceId)
        .where((item) => item.quantity > 0)
        .toList(growable: false);
    items.sort(
      (first, second) =>
          first.productCode.compareTo(second.productCode),
    );
    return items;
  }

  List<_TransferHistoryEntry> get _filteredHistory {
    final query = _historyQuery.trim().toLowerCase();
    if (query.isEmpty) return _history;
    return _history
        .where((entry) => entry.searchText.contains(query))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _transferDate = DateTime.now();
    _fromWarehouseId = _resolveInitialSourceId();
    _history = _seedHistory(_warehouses);
    _addInitialRow();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _historySearchController.dispose();
    for (final row in _rows) {
      _disposeRow(row);
    }
    super.dispose();
  }

  String? _resolveInitialSourceId() {
    final requestedId = widget.initialFromWarehouseId;
    if (requestedId == null) return null;
    return _warehouses.any((warehouse) => warehouse.id == requestedId)
        ? requestedId
        : null;
  }

  void _addInitialRow() {
    _rows.add(_createRow());
  }

  _TransferRowState _createRow() {
    final row = _TransferRowState();
    row.quantityController.addListener(_handleRowChanged);
    return row;
  }

  void _disposeRow(_TransferRowState row) {
    row.quantityController.removeListener(_handleRowChanged);
    row.dispose();
  }

  void _handleRowChanged() {
    if (mounted) setState(() {});
  }

  void _changeSource(String? warehouseId) {
    if (warehouseId == null || warehouseId == _fromWarehouseId) return;
    setState(() {
      _fromWarehouseId = warehouseId;
      if (_toWarehouseId == warehouseId) {
        _toWarehouseId = null;
      }
      _resetRows();
    });
  }

  void _changeDestination(String? warehouseId) {
    if (warehouseId == null || warehouseId == _toWarehouseId) return;
    setState(() => _toWarehouseId = warehouseId);
  }

  void _resetRows() {
    for (final row in _rows) {
      _disposeRow(row);
    }
    _rows
      ..clear()
      ..add(_createRow());
  }

  void _addRow() {
    setState(() => _rows.add(_createRow()));
  }

  void _removeRow(int index) {
    setState(() {
      final row = _rows.removeAt(index);
      _disposeRow(row);
      if (_rows.isEmpty) {
        _rows.add(_createRow());
      }
    });
  }

  void _selectProduct(int index, String? productCode) {
    if (productCode == null) return;
    setState(() => _rows[index].productCode = productCode);
  }

  WarehouseInventoryItem? _sourceItemFor(String? productCode) {
    if (productCode == null) return null;
    for (final item in _sourceItems) {
      if (item.productCode == productCode) return item;
    }
    return null;
  }

  Map<String, int>? _buildQuantities({required bool showMessages}) {
    final sourceId = _fromWarehouseId;
    final destinationId = _toWarehouseId;

    if (sourceId == null) {
      if (showMessages) {
        AppToast.showWarning(context, 'اختر مخزن المصدر');
      }
      return null;
    }
    if (destinationId == null) {
      if (showMessages) {
        AppToast.showWarning(context, 'اختر مخزن الوجهة');
      }
      return null;
    }
    if (sourceId == destinationId) {
      if (showMessages) {
        AppToast.showWarning(context, 'لا يمكن النقل إلى نفس المخزن');
      }
      return null;
    }

    final quantities = <String, int>{};
    for (final row in _rows) {
      final productCode = row.productCode;
      final quantityText = row.quantityController.text.trim();
      if (productCode == null && quantityText.isEmpty) continue;

      if (productCode == null) {
        if (showMessages) {
          AppToast.showWarning(context, 'اختر المادة في جميع الصفوف');
        }
        return null;
      }

      final quantity = AppFormatters.parseInteger(quantityText);
      if (quantity == null || quantity <= 0) {
        if (showMessages) {
          AppToast.showWarning(context, 'تحقق من كميات النقل');
        }
        return null;
      }
      quantities[productCode] =
          (quantities[productCode] ?? 0) + quantity;
    }

    if (quantities.isEmpty) {
      if (showMessages) {
        AppToast.showWarning(context, 'أضف مادة واحدة على الأقل');
      }
      return null;
    }

    for (final entry in quantities.entries) {
      final sourceItem = _sourceItemFor(entry.key);
      if (sourceItem == null || entry.value > sourceItem.quantity) {
        if (showMessages) {
          AppToast.showWarning(
            context,
            'لا يمكن تنفيذ النقل لعدم كفاية الرصيد المخزني',
          );
        }
        return null;
      }
    }
    return quantities;
  }

  bool get _canExecute => _buildQuantities(showMessages: false) != null;

  void _executeTransfer() {
    final quantities = _buildQuantities(showMessages: true);
    final sourceId = _fromWarehouseId;
    final destinationId = _toWarehouseId;
    if (quantities == null ||
        sourceId == null ||
        destinationId == null) {
      return;
    }

    final transferred = widget.onTransfer(
      fromWarehouseId: sourceId,
      toWarehouseId: destinationId,
      quantitiesByProductCode: quantities,
    );
    if (!transferred) {
      AppToast.showDanger(context, 'تعذر تنفيذ النقل المخزني');
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _close() => Navigator.of(context).pop(false);

  void _selectView(_InventoryTransferView view) {
    if (_view == view) return;
    setState(() => _view = view);
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('inventoryTransferDialog'),
      title: 'النقل المخزني',
      subtitle: 'نقل المواد بين المخازن ومراجعة سجل النقل',
      icon: Icons.compare_arrows_rounded,
      accentColor: AppModuleColors.warehouses,
      centerHeader: true,
      showHeaderCloseButton: true,
      width: AppDialogSizes.extraLarge,
      onClose: _close,
      actionsKey: const Key('inventoryTransferDialogActions'),
      actions: _view == _InventoryTransferView.create
          ? _createActions()
          : _historyActions(),
      child: SizedBox(
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ViewSelector(
              view: _view,
              onChanged: _selectView,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _view == _InventoryTransferView.create
                  ? _buildCreateView()
                  : _buildHistoryView(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _createActions() {
    return [
      AppButton(
        key: const Key('inventoryTransferCloseButton'),
        label: 'إغلاق',
        icon: Icons.close_rounded,
        variant: AppButtonVariant.secondary,
        width: 136,
        onPressed: _close,
      ),
      AppButton(
        key: const Key('inventoryTransferAddRowButton'),
        label: 'إضافة مادة',
        icon: Icons.add_rounded,
        variant: AppButtonVariant.navigation,
        width: 148,
        onPressed:
            _fromWarehouseId == null || _sourceItems.isEmpty ? null : _addRow,
      ),
      AppButton(
        key: const Key('inventoryTransferExecuteButton'),
        label: 'تنفيذ النقل',
        icon: Icons.compare_arrows_rounded,
        backgroundColor: AppModuleColors.warehouses,
        width: 168,
        onPressed: _canExecute ? _executeTransfer : null,
      ),
    ];
  }

  List<Widget> _historyActions() {
    return [
      AppButton(
        key: const Key('inventoryTransferHistoryCloseButton'),
        label: 'إغلاق',
        icon: Icons.close_rounded,
        variant: AppButtonVariant.secondary,
        width: 144,
        onPressed: _close,
      ),
      AppButton(
        key: const Key('inventoryTransferHistoryRefreshButton'),
        label: 'تحديث السجل',
        icon: Icons.refresh_rounded,
        variant: AppButtonVariant.navigation,
        width: 160,
        onPressed: () {
          _historySearchController.clear();
          setState(() => _historyQuery = '');
          AppToast.showInfo(context, 'تم تحديث السجل المؤقت');
        },
      ),
    ];
  }

  Widget _buildCreateView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDialogSection(
          key: const Key('inventoryTransferDetails'),
          title: 'تفاصيل النقل',
          icon: Icons.warehouse_rounded,
          accentColor: AppModuleColors.warehouses,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildSourceField()),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppModuleColors.warehouses,
                      size: AppIconSizes.lg,
                    ),
                  ),
                  Expanded(child: _buildDestinationField()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  SizedBox(
                    width: 270,
                    child: AppDateField(
                      fieldKey: const Key('inventoryTransferDateField'),
                      label: 'تاريخ النقل',
                      value: _transferDate,
                      accentColor: AppModuleColors.warehouses,
                      onChanged: (value) {
                        setState(() => _transferDate = value);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      fieldKey:
                          const Key('inventoryTransferNotesField'),
                      controller: _notesController,
                      label: 'الملاحظات',
                      icon: Icons.notes_rounded,
                      accentColor: AppModuleColors.warehouses,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppDialogSection(
            key: const Key('inventoryTransferItemsSection'),
            title: 'مواد النقل',
            icon: Icons.inventory_2_outlined,
            accentColor: AppModuleColors.warehouses,
            expandChild: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _buildItemsTable(constraints.maxHeight);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceField() {
    return AppDropdownField<String>(
      key: const Key('inventoryTransferFromDropdown'),
      fieldKey: const Key('inventoryTransferFromField'),
      label: 'من مخزن',
      icon: Icons.output_rounded,
      accentColor: AppModuleColors.warehouses,
      useIntrinsicHeight: true,
      value: _fromWarehouseId,
      options: [
        for (final warehouse in _warehouses)
          AppDropdownOption(
            value: warehouse.id,
            label: warehouse.name,
          ),
      ],
      onChanged: _changeSource,
    );
  }

  Widget _buildDestinationField() {
    return AppDropdownField<String>(
      key: const Key('inventoryTransferToDropdown'),
      fieldKey: const Key('inventoryTransferToField'),
      label: 'إلى مخزن',
      icon: Icons.input_rounded,
      accentColor: AppModuleColors.warehouses,
      useIntrinsicHeight: true,
      value: _toWarehouseId,
      options: [
        for (final warehouse in _warehouses)
          if (warehouse.id != _fromWarehouseId)
            AppDropdownOption(
              value: warehouse.id,
              label: warehouse.name,
            ),
      ],
      onChanged: _changeDestination,
    );
  }

  Widget _buildItemsTable(double height) {
    final sourceItems = _sourceItems;
    final canShowRows =
        _fromWarehouseId != null && sourceItems.isNotEmpty;

    return AppDataTable(
      key: const Key('inventoryTransferItemsTable'),
      height: height,
      headerHeight: 48,
      rowHeight: 76,
      minimumColumnWidth: 130,
      showColumnDividers: true,
      showShadow: false,
      accentColor: AppModuleColors.warehouses,
      columns: const [
        AppTableColumn(label: 'ت', flex: 0.45),
        AppTableColumn(label: 'رمز المادة', flex: 1.35),
        AppTableColumn(label: 'اسم المادة', flex: 2.2),
        AppTableColumn(label: 'الرصيد المتوفر', numeric: true, flex: 1.2),
        AppTableColumn(label: 'الكمية', numeric: true, flex: 1.15),
        AppTableColumn(label: 'الإجراء', flex: 0.65),
      ],
      rows: canShowRows
          ? [
              for (var index = 0; index < _rows.length; index++)
                _buildTransferTableRow(index, sourceItems),
            ]
          : const [],
      emptyState: AppStatePanel(
        type: AppStateType.empty,
        title: _fromWarehouseId == null
            ? 'اختر مخزن المصدر'
            : 'لا توجد مواد متوفرة للنقل',
        message: _fromWarehouseId == null
            ? 'ستظهر المواد المتوفرة في جدول النقل.'
            : 'لا يحتوي مخزن المصدر على رصيد قابل للنقل.',
      ),
    );
  }

  AppTableRow _buildTransferTableRow(
    int index,
    List<WarehouseInventoryItem> sourceItems,
  ) {
    final row = _rows[index];
    final selectedItem = _sourceItemFor(row.productCode);

    return AppTableRow(
      rowKey: Key('inventoryTransferRow_$index'),
      cells: [
        Text('${index + 1}'),
        AppDropdownField<String>(
          key: Key('inventoryTransferProductDropdown_$index'),
          fieldKey: Key('inventoryTransferProductField_$index'),
          label: 'المادة',
          accentColor: AppModuleColors.warehouses,
          useIntrinsicHeight: true,
          value: row.productCode,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          options: [
            for (final item in sourceItems)
              AppDropdownOption(
                value: item.productCode,
                label: item.productCode,
              ),
          ],
          onChanged: (value) => _selectProduct(index, value),
        ),
        Text(selectedItem?.productName ?? '—'),
        Text(
          selectedItem == null
              ? '—'
              : AppFormatters.quantity(selectedItem.quantity),
        ),
        AppTextField(
          fieldKey: Key('inventoryTransferQuantityField_$index'),
          controller: row.quantityController,
          label: 'الكمية',
          accentColor: AppModuleColors.warehouses,
          enabled: selectedItem != null,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: const [AppIntegerInputFormatter()],
        ),
        AppTableActionButton(
          key: Key('inventoryTransferDeleteRow_$index'),
          icon: Icons.close_rounded,
          tooltip: 'حذف المادة',
          foregroundColor: AppColors.danger,
          variant: AppButtonVariant.ghost,
          onPressed: () => _removeRow(index),
        ),
      ],
    );
  }

  Widget _buildHistoryView() {
    final history = _filteredHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchField(
          controller: _historySearchController,
          fieldKey: const Key('inventoryTransferHistorySearchField'),
          clearButtonKey:
              const Key('inventoryTransferHistorySearchClearButton'),
          label: 'بحث في سجل النقل',
          hint: 'رقم النقل أو المخزن أو المادة أو التاريخ',
          accentColor: AppModuleColors.warehouses,
          onChanged: (value) => setState(() => _historyQuery = value),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppDialogSection(
            key: const Key('inventoryTransferHistorySection'),
            title: 'سجل النقل المخزني',
            icon: Icons.history_rounded,
            accentColor: AppModuleColors.warehouses,
            expandChild: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AppDataTable(
                  key: const Key('inventoryTransferHistoryTable'),
                  height: constraints.maxHeight,
                  rowHeight: 60,
                  minimumColumnWidth: 165,
                  showColumnDividers: true,
                  showShadow: false,
                  accentColor: AppModuleColors.warehouses,
                  columns: const [
                    AppTableColumn(label: 'رقم النقل', flex: 0.8),
                    AppTableColumn(label: 'التاريخ', flex: 1),
                    AppTableColumn(label: 'من مخزن', flex: 1.35),
                    AppTableColumn(label: 'إلى مخزن', flex: 1.35),
                    AppTableColumn(label: 'المواد', flex: 2.5),
                  ],
                  rows: [
                    for (final entry in history)
                      AppTableRow(
                        rowKey: Key(
                          'inventoryTransferHistory_${entry.number}',
                        ),
                        cells: [
                          Text(entry.number.toString()),
                          Text(entry.date),
                          Text(entry.fromWarehouse),
                          Text(entry.toWarehouse),
                          Text(entry.itemsSummary),
                        ],
                      ),
                  ],
                  emptyState: const AppStatePanel(
                    type: AppStateType.empty,
                    title: 'لا توجد عمليات نقل مطابقة',
                    message: 'غيّر كلمات البحث.',
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({
    required this.view,
    required this.onChanged,
  });

  final _InventoryTransferView view;
  final ValueChanged<_InventoryTransferView> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedTint = Color.alphaBlend(
      AppModuleColors.warehouses.withAlpha(24),
      AppColors.surface,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppButton(
          key: const Key('inventoryTransferCreateTab'),
          label: 'نقل جديد',
          icon: Icons.compare_arrows_rounded,
          variant: AppButtonVariant.navigation,
          width: 180,
          backgroundColor:
              view == _InventoryTransferView.create ? selectedTint : null,
          foregroundColor: view == _InventoryTransferView.create
              ? AppModuleColors.warehouses
              : null,
          onPressed: () => onChanged(_InventoryTransferView.create),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          key: const Key('inventoryTransferHistoryTab'),
          label: 'سجل النقل المخزني',
          icon: Icons.history_rounded,
          variant: AppButtonVariant.navigation,
          width: 210,
          backgroundColor:
              view == _InventoryTransferView.history ? selectedTint : null,
          foregroundColor: view == _InventoryTransferView.history
              ? AppModuleColors.warehouses
              : null,
          onPressed: () => onChanged(_InventoryTransferView.history),
        ),
      ],
    );
  }
}

class _TransferRowState {
  String? productCode;
  final quantityController = TextEditingController();

  void dispose() => quantityController.dispose();
}

@immutable
class _TransferHistoryEntry {
  const _TransferHistoryEntry({
    required this.number,
    required this.date,
    required this.fromWarehouse,
    required this.toWarehouse,
    required this.itemsSummary,
  });

  final int number;
  final String date;
  final String fromWarehouse;
  final String toWarehouse;
  final String itemsSummary;

  String get searchText =>
      '$number $date $fromWarehouse $toWarehouse $itemsSummary'
          .toLowerCase();
}

List<_TransferHistoryEntry> _seedHistory(List<Warehouse> warehouses) {
  if (warehouses.length < 2) return const [];
  final first = warehouses.first;
  final second = warehouses[1];
  final third = warehouses.length > 2 ? warehouses[2] : first;

  return [
    _TransferHistoryEntry(
      number: 104,
      date: '2026/07/24',
      fromWarehouse: first.name,
      toWarehouse: second.name,
      itemsSummary: 'P-1003 - ورق تصوير A4 (20)',
    ),
    _TransferHistoryEntry(
      number: 103,
      date: '2026/07/22',
      fromWarehouse: third.name,
      toWarehouse: first.name,
      itemsSummary:
          'P-1002 - حبر طابعة أسود (5)، P-1004 - آلة حاسبة مكتبية (2)',
    ),
  ];
}
