import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/warehouse.dart';

typedef WarehouseInventoryReader =
    List<WarehouseInventoryItem> Function(String warehouseId);

typedef WarehouseTransferHandler = FutureOr<bool> Function({
  required String fromWarehouseId,
  required String toWarehouseId,
  required Map<String, int> quantitiesByItemId,
});

typedef WarehouseTransferHistoryReader =
    List<WarehouseTransferRecord> Function();

typedef WarehouseTransferReverseHandler = FutureOr<bool> Function(
  String transferId,
);

enum _InventoryTransferView { create, history }

const _inventoryTransferColumns = <AppInvoiceFieldColumn>[
  AppInvoiceFieldColumn('ت', 54),
  AppInvoiceFieldColumn('المادة', 430, grow: 3),
  AppInvoiceFieldColumn('المتوفر', 150, grow: 0.7),
  AppInvoiceFieldColumn('كمية النقل', 180, grow: 1),
  AppInvoiceFieldColumn('', 100, padding: EdgeInsets.zero),
];

class _InventoryTransferDraftRow {
  _InventoryTransferDraftRow({required this.id})
      : itemController = TextEditingController(),
        availableController = TextEditingController(),
        quantityController = TextEditingController();

  final int id;
  final TextEditingController itemController;
  final TextEditingController availableController;
  final TextEditingController quantityController;
  final FocusNode itemFocusNode = FocusNode();
  final FocusNode quantityFocusNode = FocusNode();
  WarehouseInventoryItem? selectedItem;

  bool get isEmpty =>
      itemController.text.trim().isEmpty &&
      quantityController.text.trim().isEmpty;

  int? get quantity =>
      AppFormatters.parseInteger(quantityController.text);

  void dispose() {
    itemController.dispose();
    availableController.dispose();
    quantityController.dispose();
    itemFocusNode.dispose();
    quantityFocusNode.dispose();
  }
}

class InventoryTransferDialog extends StatefulWidget {
  const InventoryTransferDialog({
    required this.warehouses,
    required this.inventoryFor,
    required this.onTransfer,
    super.key,
    this.initialFromWarehouseId,
    this.transferHistory,
    this.onReverseTransfer,
    this.allowTransfer = true,
  });

  final List<Warehouse> warehouses;
  final WarehouseInventoryReader inventoryFor;
  final WarehouseTransferHandler onTransfer;
  final String? initialFromWarehouseId;
  final WarehouseTransferHistoryReader? transferHistory;
  final WarehouseTransferReverseHandler? onReverseTransfer;
  final bool allowTransfer;

  static Future<bool> show(
    BuildContext context, {
    required List<Warehouse> warehouses,
    required WarehouseInventoryReader inventoryFor,
    required WarehouseTransferHandler onTransfer,
    String? initialFromWarehouseId,
    WarehouseTransferHistoryReader? transferHistory,
    WarehouseTransferReverseHandler? onReverseTransfer,
    bool allowTransfer = true,
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
          transferHistory: transferHistory,
          onReverseTransfer: onReverseTransfer,
          allowTransfer: allowTransfer,
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
  final _dialogMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _historySearchController = TextEditingController();
  final _linesScrollController = ScrollController();

  late final List<WarehouseTransferRecord> _fallbackHistory;
  late List<_InventoryTransferDraftRow> _rows;
  _InventoryTransferView _view = _InventoryTransferView.create;
  var _nextRowId = 0;
  String? _fromWarehouseId;
  String? _toWarehouseId;
  String _historyQuery = '';
  String? _selectedHistoryId;
  bool _didTransfer = false;
  bool _isMutating = false;

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

  bool get _canExecute {
    return widget.allowTransfer &&
        _fromWarehouseId != null &&
        _toWarehouseId != null &&
        _fromWarehouseId != _toWarehouseId &&
        !_isMutating;
  }

  List<_InventoryTransferDraftRow> get _completeRows => _rows
      .where(
        (row) => row.selectedItem != null && (row.quantity ?? 0) > 0,
      )
      .toList(growable: false);

  int get _totalDraftQuantity => _completeRows.fold<int>(
        0,
        (total, row) => total + row.quantity!,
      );

  List<WarehouseTransferRecord> get _history =>
      widget.transferHistory?.call() ?? _fallbackHistory;

  List<WarehouseTransferRecord> get _filteredHistory {
    final query = _historyQuery.trim().toLowerCase();
    if (query.isEmpty) return _history;
    return _history
        .where((entry) => entry.searchText.contains(query))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    if (!widget.allowTransfer) {
      _view = _InventoryTransferView.history;
    }
    _fromWarehouseId = _resolveInitialSourceId();
    _toWarehouseId = _firstOtherWarehouseId(_fromWarehouseId);
    _rows = [_newRow()];
    _fallbackHistory = _seedHistory(_warehouses);
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _linesScrollController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  String? _resolveInitialSourceId() {
    final requestedId = widget.initialFromWarehouseId;
    if (requestedId != null &&
        _warehouses.any((warehouse) => warehouse.id == requestedId)) {
      return requestedId;
    }
    return _warehouses.isEmpty ? null : _warehouses.first.id;
  }

  String? _firstOtherWarehouseId(String? warehouseId) {
    for (final warehouse in _warehouses) {
      if (warehouse.id != warehouseId) return warehouse.id;
    }
    return null;
  }

  String _warehouseName(String? warehouseId) {
    for (final warehouse in _warehouses) {
      if (warehouse.id == warehouseId) return warehouse.name;
    }
    return 'المخزن';
  }

  void _changeSource(String? warehouseId) {
    if (warehouseId == null || warehouseId == _fromWarehouseId) return;
    final oldRows = _rows;
    setState(() {
      _fromWarehouseId = warehouseId;
      if (_toWarehouseId == warehouseId) {
        _toWarehouseId = _firstOtherWarehouseId(warehouseId);
      }
      _rows = [_newRow()];
    });
    _disposeRowsAfterFrame(oldRows);
  }

  void _changeDestination(String? warehouseId) {
    if (warehouseId == null || warehouseId == _toWarehouseId) return;
    List<_InventoryTransferDraftRow>? oldRows;
    setState(() {
      if (_fromWarehouseId == warehouseId) {
        _fromWarehouseId = _firstOtherWarehouseId(warehouseId);
        oldRows = _rows;
        _rows = [_newRow()];
      }
      _toWarehouseId = warehouseId;
    });
    if (oldRows != null) _disposeRowsAfterFrame(oldRows!);
  }

  _InventoryTransferDraftRow _newRow() {
    return _InventoryTransferDraftRow(id: _nextRowId++);
  }

  void _disposeRowsAfterFrame(
    Iterable<_InventoryTransferDraftRow> rows,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final row in rows) {
        row.dispose();
      }
    });
  }

  WarehouseInventoryItem? _sourceItemById(String itemId) {
    for (final item in _sourceItems) {
      if (item.itemId == itemId) return item;
    }
    return null;
  }

  List<WarehouseInventoryItem> _optionsForRow(
    _InventoryTransferDraftRow row,
  ) {
    final selectedElsewhere = {
      for (final candidate in _rows)
        if (!identical(candidate, row) && candidate.selectedItem != null)
          candidate.selectedItem!.itemId,
    };
    return _sourceItems
        .where((item) => !selectedElsewhere.contains(item.itemId))
        .toList(growable: false);
  }

  String _itemDisplayText(WarehouseInventoryItem item) {
    return '${item.productCode} — ${item.productName}';
  }

  void _selectItem(
    _InventoryTransferDraftRow row,
    WarehouseInventoryItem item,
  ) {
    setState(() {
      row.selectedItem = item;
      row.itemController.text = _itemDisplayText(item);
      row.availableController.text =
          AppFormatters.quantity(item.quantity);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _rows.contains(row)) {
        row.quantityFocusNode.requestFocus();
      }
    });
  }

  void _changeItemText(_InventoryTransferDraftRow row) {
    final selected = row.selectedItem;
    if (selected != null &&
        row.itemController.text == _itemDisplayText(selected)) {
      return;
    }
    setState(() {
      row.selectedItem = null;
      row.availableController.clear();
    });
  }

  bool _canAddRow(_InventoryTransferDraftRow row) {
    final item = row.selectedItem;
    final quantity = row.quantity;
    if (item == null ||
        quantity == null ||
        quantity <= 0 ||
        quantity > item.quantity) {
      return false;
    }
    return _sourceItems.any(
      (candidate) => !_rows.any(
        (existing) => existing.selectedItem?.itemId == candidate.itemId,
      ),
    );
  }

  void _addRow(_InventoryTransferDraftRow row) {
    if (_isMutating ||
        !identical(row, _rows.last) ||
        !_canAddRow(row)) {
      return;
    }
    late final _InventoryTransferDraftRow added;
    setState(() {
      added = _newRow();
      _rows.add(added);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_rows.contains(added)) return;
      if (_linesScrollController.hasClients) {
        _linesScrollController.animateTo(
          _linesScrollController.position.maxScrollExtent,
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
        );
      }
      added.itemFocusNode.requestFocus();
    });
  }

  void _removeRow(int index) {
    if (_isMutating || index < 0 || index >= _rows.length) return;
    late final _InventoryTransferDraftRow removed;
    setState(() {
      removed = _rows[index];
      if (_rows.length == 1) {
        _rows = [_newRow()];
      } else {
        _rows.removeAt(index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _handleQuantityChanged(String _) {
    setState(() {});
  }

  void _handleQuantitySubmitted(
    _InventoryTransferDraftRow row,
    int index,
  ) {
    if (index == _rows.length - 1 && _canAddRow(row)) {
      _addRow(row);
      return;
    }
    FocusScope.of(context).nextFocus();
  }

  Future<void> _executeTransfer() async {
    if (_isMutating || !widget.allowTransfer) return;
    final sourceId = _fromWarehouseId;
    final destinationId = _toWarehouseId;

    if (sourceId == null ||
        destinationId == null ||
        sourceId == destinationId) {
      AppToast.showWarning(
        context,
        'تحقق من بيانات النقل',
        messenger: _dialogMessengerKey.currentState,
      );
      return;
    }

    final meaningfulRows = _rows
        .where((row) => !row.isEmpty)
        .toList(growable: false);
    if (meaningfulRows.isEmpty) {
      AppToast.showWarning(
        context,
        'أضف مادة واحدة مكتملة على الأقل',
        messenger: _dialogMessengerKey.currentState,
      );
      return;
    }
    if (meaningfulRows.any((row) => row.selectedItem == null)) {
      AppToast.showWarning(
        context,
        'اختر مادة موجودة لكل سطر نقل',
        messenger: _dialogMessengerKey.currentState,
      );
      return;
    }
    if (meaningfulRows.any(
      (row) => row.quantity == null || row.quantity! <= 0,
    )) {
      AppToast.showWarning(
        context,
        'أدخل كمية صحيحة لكل سطر نقل',
        messenger: _dialogMessengerKey.currentState,
      );
      return;
    }

    final itemIds = <String>{};
    final transferLines = <({WarehouseInventoryItem item, int quantity})>[];
    for (final row in meaningfulRows) {
      final selectedItem = row.selectedItem!;
      if (!itemIds.add(selectedItem.itemId)) {
        AppToast.showWarning(
          context,
          'لا يمكن تكرار المادة في النقل نفسه',
          messenger: _dialogMessengerKey.currentState,
        );
        return;
      }
      final currentItem = _sourceItemById(selectedItem.itemId);
      if (currentItem == null) {
        AppToast.showWarning(
          context,
          'إحدى المواد المحددة لم تعد متوفرة في مخزن المصدر',
          messenger: _dialogMessengerKey.currentState,
        );
        return;
      }
      final quantity = row.quantity!;
      if (quantity > currentItem.quantity) {
        AppToast.showWarning(
          context,
          'لا يمكن نقل ${currentItem.productName} لعدم كفاية الرصيد المخزني',
          messenger: _dialogMessengerKey.currentState,
        );
        return;
      }
      transferLines.add((item: currentItem, quantity: quantity));
    }

    final quantitiesByItemId = <String, int>{
      for (final line in transferLines) line.item.itemId: line.quantity,
    };

    setState(() => _isMutating = true);
    late final bool transferred;
    try {
      transferred = await Future<bool>.value(
        widget.onTransfer(
          fromWarehouseId: sourceId,
          toWarehouseId: destinationId,
          quantitiesByItemId: quantitiesByItemId,
        ),
      );
    } catch (_) {
      transferred = false;
    }
    if (!mounted) return;
    setState(() => _isMutating = false);
    if (!transferred) {
      AppToast.showDanger(
        context,
        'تعذر تنفيذ النقل المخزني',
        messenger: _dialogMessengerKey.currentState,
      );
      return;
    }
    if (widget.transferHistory == null) {
      final createdAt = DateTime.now();
      final nextNumber = _fallbackHistory.isEmpty
          ? 1
          : _fallbackHistory
                  .map((transfer) => transfer.number)
                  .reduce((first, second) => first > second ? first : second) +
              1;
      _fallbackHistory.insert(
        0,
        WarehouseTransferRecord(
          id: 'preview-${createdAt.microsecondsSinceEpoch}-$nextNumber',
          number: nextNumber,
          createdAt: createdAt,
          fromWarehouseId: sourceId,
          fromWarehouseName: _warehouseName(sourceId),
          toWarehouseId: destinationId,
          toWarehouseName: _warehouseName(destinationId),
          lines: List.unmodifiable([
            for (final line in transferLines)
              WarehouseTransferLine(
                itemId: line.item.itemId,
                productCode: line.item.productCode,
                productName: line.item.productName,
                quantity: line.quantity,
              ),
          ]),
        ),
      );
    }
    _didTransfer = true;
    _historySearchController.clear();
    final oldRows = _rows;
    setState(() {
      _historyQuery = '';
      _view = _InventoryTransferView.history;
      _rows = [_newRow()];
      final history = _history;
      _selectedHistoryId = history.isEmpty ? null : history.first.id;
    });
    _disposeRowsAfterFrame(oldRows);
    AppToast.showInfo(
      context,
      'تم تنفيذ النقل المخزني',
      messenger: _dialogMessengerKey.currentState,
    );
  }

  void _close() {
    if (_isMutating) return;
    Navigator.of(context).pop(_didTransfer);
  }

  Future<void> _reverseSelectedTransfer() async {
    if (_isMutating) return;
    final selectedId = _selectedHistoryId;
    final reverse = widget.onReverseTransfer;
    if (selectedId == null || reverse == null) return;

    setState(() => _isMutating = true);
    late final bool reversed;
    try {
      reversed = await Future<bool>.value(reverse(selectedId));
    } catch (_) {
      reversed = false;
    }
    if (!mounted) return;
    setState(() => _isMutating = false);
    if (!reversed) {
      AppToast.showDanger(
        context,
        'تعذر عكس النقل لعدم كفاية الرصيد أو لأنه عُكس مسبقاً',
        messenger: _dialogMessengerKey.currentState,
      );
      return;
    }

    _didTransfer = true;
    setState(() {
      final history = _history;
      _selectedHistoryId = history.isEmpty ? null : history.first.id;
    });
    AppToast.showSuccess(
      context,
      'تم إنشاء حركة عكسية للنقل المخزني',
      messenger: _dialogMessengerKey.currentState,
    );
  }

  void _selectView(_InventoryTransferView view) {
    if (_view == view) return;
    setState(() => _view = view);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isMutating,
      child: ScaffoldMessenger(
        key: _dialogMessengerKey,
        child: Scaffold(
          key: const Key('inventoryTransferToastHost'),
          backgroundColor: Colors.transparent,
          body: AppModuleDialog(
            key: const Key('inventoryTransferDialog'),
            title: 'النقل المخزني',
            subtitle: 'اختر المواد والكميات وانقلها بين مخزنين',
            icon: _view == _InventoryTransferView.create
                ? Icons.compare_arrows_rounded
                : Icons.history_rounded,
            accentColor: AppModuleColors.warehouses,
            centerHeader: true,
            showHeaderCloseButton: !_isMutating,
            width: AppDialogSizes.extraLarge,
            bodyScrollable: false,
            maxHeightFactor: 0.96,
            onClose: _close,
            actionsKey: const Key('inventoryTransferDialogActions'),
            actions: _view == _InventoryTransferView.create
                ? _createActions()
                : _historyActions(),
            child: SizedBox(
              height: 540,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ViewSelector(
                    view: _view,
                    allowCreate: widget.allowTransfer,
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
          ),
        ),
      ),
    );
  }

  List<Widget> _createActions() {
    return [
      AppButton(
        key: const Key('inventoryTransferExecuteButton'),
        label: 'تنفيذ النقل',
        icon: Icons.swap_horiz_rounded,
        width: 200,
        backgroundColor: AppModuleColors.warehouses,
        onPressed: _canExecute && !_isMutating ? _executeTransfer : null,
      ),
    ];
  }

  List<Widget> _historyActions() {
    WarehouseTransferRecord? selected;
    for (final transfer in _history) {
      if (transfer.id == _selectedHistoryId) {
        selected = transfer;
        break;
      }
    }
    final selectedTransfer = selected;
    final alreadyReversed = selectedTransfer != null &&
        _history.any(
          (transfer) => transfer.reversalOfId == selectedTransfer.id,
        );
    return [
      AppButton(
        key: const Key('inventoryTransferReverseButton'),
        label: 'عكس النقل',
        icon: Icons.undo_rounded,
        variant: AppButtonVariant.warning,
        minWidth: 150,
        onPressed: selectedTransfer == null ||
                selectedTransfer.reversalOfId != null ||
                alreadyReversed ||
                widget.onReverseTransfer == null ||
                _isMutating
            ? null
            : _reverseSelectedTransfer,
      ),
      AppButton(
        key: const Key('inventoryTransferHistoryRefreshButton'),
        label: 'تحديث السجل',
        icon: Icons.refresh_rounded,
        variant: AppButtonVariant.success,
        minWidth: 160,
        onPressed: () {
          _historySearchController.clear();
          setState(() => _historyQuery = '');
          AppToast.showSuccess(
            context,
            'تم تحديث السجل',
            messenger: _dialogMessengerKey.currentState,
          );
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
          child: Row(
            children: [
              Expanded(child: _buildSourceField()),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildDestinationField()),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppDialogSection(
            key: const Key('inventoryTransferLinesSection'),
            title: 'مواد النقل',
            icon: Icons.inventory_2_rounded,
            accentColor: AppModuleColors.warehouses,
            expandChild: true,
            child: AppInvoiceFieldTable(
              surfaceKey: const Key('inventoryTransferLinesTable'),
              horizontalScrollKey:
                  const Key('inventoryTransferLinesHorizontalScroll'),
              rowsKey: const Key('inventoryTransferLinesRows'),
              headerKey: const Key('inventoryTransferLinesHeader'),
              summaryKey: const Key('inventoryTransferLinesSummary'),
              columns: _inventoryTransferColumns,
              rowCount: _rows.length,
              verticalScrollController: _linesScrollController,
              accentColor: AppModulePalettes.warehouses.middle,
              lightAccentColor: AppModulePalettes.warehouses.light,
              rowHeight: 80,
              rowKeyBuilder: (index) =>
                  Key('inventoryTransferLineRow-${_rows[index].id}'),
              rowCellsBuilder: (context, index) =>
                  _buildTransferRowCells(_rows[index], index),
              summaryCells: [
                const SizedBox.shrink(),
                const Text('المجموع'),
                Text('${_completeRows.length} مادة'),
                Text(
                  AppFormatters.quantity(_totalDraftQuantity),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                ),
                const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTransferRowCells(
    _InventoryTransferDraftRow row,
    int index,
  ) {
    final rowNumber = index + 1;
    final isLastRow = index == _rows.length - 1;
    return [
      Text(
        '$rowNumber',
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      ),
      Semantics(
        container: true,
        label: 'المادة للسطر $rowNumber',
        child: AppAutocompleteField<WarehouseInventoryItem>(
          fieldKey: Key('inventoryTransferLineItemField-${row.id}'),
          controller: row.itemController,
          focusNode: row.itemFocusNode,
          label: 'المادة',
          options: _optionsForRow(row),
          displayStringForOption: _itemDisplayText,
          searchTermsForOption: (item) => [
            item.productCode,
            item.productName,
          ],
          optionSubtitle: (item) =>
              'المتوفر: ${AppFormatters.quantity(item.quantity)}',
          onSelected: (item) => _selectItem(row, item),
          onChanged: (_) => _changeItemText(row),
          enabled: !_isMutating,
          icon: null,
          accentColor: AppModuleColors.warehouses,
          textDirection: TextDirection.rtl,
          showLabel: false,
          borderRadius: AppRadii.sm,
        ),
      ),
      Semantics(
        container: true,
        label: 'المتوفر للسطر $rowNumber',
        child: AppReadOnlyField(
          fieldKey:
              Key('inventoryTransferLineAvailableField-${row.id}'),
          controller: row.availableController,
          label: 'المتوفر',
          accentColor: AppModuleColors.warehouses,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          showLabel: false,
          borderRadius: AppRadii.sm,
        ),
      ),
      Semantics(
        container: true,
        label: 'كمية النقل للسطر $rowNumber',
        child: AppIntegerField(
          fieldKey:
              Key('inventoryTransferLineQuantityField-${row.id}'),
          controller: row.quantityController,
          focusNode: row.quantityFocusNode,
          label: 'كمية النقل',
          icon: null,
          accentColor: AppModuleColors.warehouses,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          textInputAction:
              isLastRow ? TextInputAction.done : TextInputAction.next,
          onChanged: _handleQuantityChanged,
          onSubmitted: (_) => _handleQuantitySubmitted(row, index),
          enabled: !_isMutating,
          showLabel: false,
          borderRadius: AppRadii.sm,
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLastRow)
            AppTableActionButton(
              key: const Key('inventoryTransferLineAddButton'),
              tooltipKey:
                  const Key('inventoryTransferLineAddButtonTooltip'),
              icon: Icons.add_rounded,
              tooltip: 'إضافة سطر نقل',
              variant: AppButtonVariant.success,
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              size: 36,
              iconSize: AppIconSizes.md,
              borderRadius: AppRadii.sm,
              onPressed: _canAddRow(row) && !_isMutating
                  ? () => _addRow(row)
                  : null,
            ),
          if (isLastRow && (_rows.length > 1 || !row.isEmpty))
            const SizedBox(width: AppSpacing.xs),
          if (_rows.length > 1 || !row.isEmpty)
            AppTableActionButton(
              key: Key('inventoryTransferLineDeleteButton-${row.id}'),
              tooltipKey:
                  Key('inventoryTransferLineDeleteButtonTooltip-${row.id}'),
              icon: Icons.close_rounded,
              tooltip: 'حذف سطر النقل',
              variant: AppButtonVariant.danger,
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              size: 36,
              iconSize: AppIconSizes.md,
              borderRadius: AppRadii.sm,
              onPressed: _isMutating ? null : () => _removeRow(index),
            ),
        ],
      ),
    ];
  }

  Widget _buildSourceField() {
    return AppDropdownField<String>(
      key: const Key('inventoryTransferFromDropdown'),
      fieldKey: const Key('inventoryTransferFromField'),
      label: 'من مخزن',
      icon: Icons.warehouse_rounded,
      accentColor: AppModuleColors.warehouses,
      useIntrinsicHeight: true,
      enabled: !_isMutating,
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
      icon: Icons.warehouse_rounded,
      accentColor: AppModuleColors.warehouses,
      useIntrinsicHeight: true,
      enabled: !_isMutating,
      value: _toWarehouseId,
      options: [
        for (final warehouse in _warehouses)
          AppDropdownOption(
            value: warehouse.id,
            label: warehouse.name,
          ),
      ],
      onChanged: _changeDestination,
    );
  }

  Widget _buildHistoryView() {
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _TransferHistoryTable(
                entries: _filteredHistory,
                height: constraints.maxHeight,
                selectedRecordId: _selectedHistoryId,
                onSelected: (recordId) {
                  setState(() => _selectedHistoryId = recordId);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({
    required this.view,
    required this.allowCreate,
    required this.onChanged,
  });

  final _InventoryTransferView view;
  final bool allowCreate;
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
          minWidth: 180,
          backgroundColor:
              view == _InventoryTransferView.create ? selectedTint : null,
          foregroundColor: view == _InventoryTransferView.create
              ? AppModuleColors.warehouses
              : null,
          onPressed: allowCreate
              ? () => onChanged(_InventoryTransferView.create)
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          key: const Key('inventoryTransferHistoryTab'),
          label: 'سجل النقل المخزني',
          icon: Icons.history_rounded,
          variant: AppButtonVariant.navigation,
          minWidth: 210,
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

class _TransferHistoryTable extends StatefulWidget {
  const _TransferHistoryTable({
    required this.entries,
    required this.height,
    required this.selectedRecordId,
    required this.onSelected,
  });

  final List<WarehouseTransferRecord> entries;
  final double height;
  final String? selectedRecordId;
  final ValueChanged<String> onSelected;

  @override
  State<_TransferHistoryTable> createState() =>
      _TransferHistoryTableState();
}

class _TransferHistoryTableState extends State<_TransferHistoryTable> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDataTable(
      key: const Key('inventoryTransferHistoryTable'),
      height: widget.height,
      rowHeight: 56,
      minimumColumnWidth: 150,
      verticalScrollController: _scrollController,
      accentColor: AppModuleColors.warehouses,
      alternatingRowColor: null,
      columns: const [
        AppTableColumn(label: 'رقم النقل', numeric: true, flex: 0.8),
        AppTableColumn(label: 'التاريخ', numeric: true, flex: 1),
        AppTableColumn(label: 'من مخزن', flex: 1.35),
        AppTableColumn(label: 'إلى مخزن', flex: 1.35),
        AppTableColumn(label: 'المواد', flex: 2.5),
      ],
      rows: [
        for (final entry in widget.entries)
          AppTableRow(
            rowKey: Key('inventoryTransferHistory_${entry.number}'),
            selected: entry.id == widget.selectedRecordId,
            onTap: () => widget.onSelected(entry.id),
            cells: [
              Text(entry.number.toString()),
              Text(entry.formattedDate),
              Text(entry.fromWarehouseName),
              Text(entry.toWarehouseName),
              Text(
                entry.reversalOfId == null
                    ? entry.itemsSummary
                    : 'عكس: ${entry.itemsSummary}',
              ),
            ],
          ),
      ],
      emptyState: const AppStatePanel(
        type: AppStateType.empty,
        title: 'لا توجد عمليات نقل مطابقة',
        message: 'غيّر كلمات البحث.',
      ),
    );
  }
}

List<WarehouseTransferRecord> _seedHistory(List<Warehouse> warehouses) {
  if (warehouses.length < 2) return const [];
  final first = warehouses.first;
  final second = warehouses[1];
  final third = warehouses.length > 2 ? warehouses[2] : first;

  return [
    WarehouseTransferRecord(
      id: 'preview-transfer-104',
      number: 104,
      createdAt: DateTime(2026, 7, 24),
      fromWarehouseId: first.id,
      fromWarehouseName: first.name,
      toWarehouseId: second.id,
      toWarehouseName: second.name,
      lines: [
        WarehouseTransferLine(
          itemId: 'preview-item-1003',
          productCode: 'P-1003',
          productName: 'ورق تصوير A4',
          quantity: 20,
        ),
      ],
    ),
    WarehouseTransferRecord(
      id: 'preview-transfer-103',
      number: 103,
      createdAt: DateTime(2026, 7, 22),
      fromWarehouseId: third.id,
      fromWarehouseName: third.name,
      toWarehouseId: first.id,
      toWarehouseName: first.name,
      lines: [
        WarehouseTransferLine(
          itemId: 'preview-item-1002',
          productCode: 'P-1002',
          productName: 'حبر طابعة أسود',
          quantity: 5,
        ),
        WarehouseTransferLine(
          itemId: 'preview-item-1004',
          productCode: 'P-1004',
          productName: 'آلة حاسبة مكتبية',
          quantity: 2,
        ),
      ],
    ),
  ];
}
