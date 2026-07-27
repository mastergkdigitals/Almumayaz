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
  final _quantityController = TextEditingController(text: '1');
  final _historySearchController = TextEditingController();

  late final List<_TransferHistoryEntry> _history;
  _InventoryTransferView _view = _InventoryTransferView.create;
  String? _fromWarehouseId;
  String? _toWarehouseId;
  String? _selectedProductCode;
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

  List<WarehouseInventoryItem> get _destinationItems {
    final destinationId = _toWarehouseId;
    if (destinationId == null) return const [];
    final items = widget.inventoryFor(destinationId).toList(growable: false);
    items.sort(
      (first, second) =>
          first.productCode.compareTo(second.productCode),
    );
    return items;
  }

  WarehouseInventoryItem? get _selectedSourceItem {
    final selectedCode = _selectedProductCode;
    if (selectedCode == null) return null;
    for (final item in _sourceItems) {
      if (item.productCode == selectedCode) return item;
    }
    return null;
  }

  int? get _transferQuantity =>
      AppFormatters.parseInteger(_quantityController.text);

  bool get _canExecute {
    final sourceItem = _selectedSourceItem;
    final quantity = _transferQuantity;
    return _fromWarehouseId != null &&
        _toWarehouseId != null &&
        _fromWarehouseId != _toWarehouseId &&
        sourceItem != null &&
        quantity != null &&
        quantity > 0 &&
        quantity <= sourceItem.quantity;
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
    _fromWarehouseId = _resolveInitialSourceId();
    _toWarehouseId = _firstOtherWarehouseId(_fromWarehouseId);
    _selectedProductCode = _firstSourceProductCode();
    _history = _seedHistory(_warehouses);
    _quantityController.addListener(_handleQuantityChanged);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_handleQuantityChanged);
    _quantityController.dispose();
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

  String? _firstSourceProductCode() {
    final items = _sourceItems;
    return items.isEmpty ? null : items.first.productCode;
  }

  String _warehouseName(String? warehouseId) {
    for (final warehouse in _warehouses) {
      if (warehouse.id == warehouseId) return warehouse.name;
    }
    return 'المخزن';
  }

  void _handleQuantityChanged() {
    if (mounted) setState(() {});
  }

  void _changeSource(String? warehouseId) {
    if (warehouseId == null || warehouseId == _fromWarehouseId) return;
    setState(() {
      _fromWarehouseId = warehouseId;
      if (_toWarehouseId == warehouseId) {
        _toWarehouseId = _firstOtherWarehouseId(warehouseId);
      }
      _selectedProductCode = _firstSourceProductCode();
    });
  }

  void _changeDestination(String? warehouseId) {
    if (warehouseId == null || warehouseId == _toWarehouseId) return;
    setState(() {
      if (_fromWarehouseId == warehouseId) {
        _fromWarehouseId = _firstOtherWarehouseId(warehouseId);
        _selectedProductCode = _firstSourceProductCode();
      }
      _toWarehouseId = warehouseId;
    });
  }

  void _selectProduct(String productCode) {
    setState(() => _selectedProductCode = productCode);
  }

  void _executeTransfer() {
    final sourceId = _fromWarehouseId;
    final destinationId = _toWarehouseId;
    final sourceItem = _selectedSourceItem;
    final quantity = _transferQuantity;

    if (sourceId == null ||
        destinationId == null ||
        sourceItem == null ||
        quantity == null ||
        quantity <= 0) {
      AppToast.showWarning(context, 'تحقق من بيانات النقل');
      return;
    }
    if (quantity > sourceItem.quantity) {
      AppToast.showWarning(
        context,
        'لا يمكن تنفيذ النقل لعدم كفاية الرصيد المخزني',
      );
      return;
    }

    final transferred = widget.onTransfer(
      fromWarehouseId: sourceId,
      toWarehouseId: destinationId,
      quantitiesByProductCode: {
        sourceItem.productCode: quantity,
      },
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
      subtitle: 'اختر المادة والكمية وانقلها بين مخزنين',
      icon: _view == _InventoryTransferView.create
          ? Icons.compare_arrows_rounded
          : Icons.history_rounded,
      accentColor: AppModuleColors.warehouses,
      centerHeader: true,
      showHeaderCloseButton: true,
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
        variant: AppButtonVariant.secondary,
        width: 144,
        onPressed: _close,
      ),
      AppButton(
        key: const Key('inventoryTransferExecuteButton'),
        label: 'تنفيذ النقل',
        icon: Icons.swap_horiz_rounded,
        width: 176,
        backgroundColor: AppModuleColors.warehouses,
        onPressed: _canExecute ? _executeTransfer : null,
      ),
    ];
  }

  List<Widget> _historyActions() {
    return [
      AppButton(
        key: const Key('inventoryTransferHistoryCloseButton'),
        label: 'إغلاق',
        variant: AppButtonVariant.secondary,
        width: 144,
        onPressed: _close,
      ),
      AppButton(
        key: const Key('inventoryTransferHistoryRefreshButton'),
        label: 'تحديث السجل',
        icon: Icons.refresh_rounded,
        variant: AppButtonVariant.success,
        width: 160,
        onPressed: () {
          _historySearchController.clear();
          setState(() => _historyQuery = '');
          AppToast.showSuccess(context, 'تم تحديث السجل المؤقت');
        },
      ),
    ];
  }

  Widget _buildCreateView() {
    final sourceItem = _selectedSourceItem;

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
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: _buildDestinationField()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppDropdownField<String>(
                      key: const Key('inventoryTransferProductDropdown'),
                      fieldKey:
                          const Key('inventoryTransferProductField'),
                      label: 'المادة',
                      icon: Icons.inventory_2_rounded,
                      accentColor: AppModuleColors.warehouses,
                      useIntrinsicHeight: true,
                      value: _selectedProductCode,
                      options: [
                        for (final item in _sourceItems)
                          AppDropdownOption(
                            value: item.productCode,
                            label:
                                '${item.productName} — ${AppFormatters.quantity(item.quantity)}',
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) _selectProduct(value);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      fieldKey:
                          const Key('inventoryTransferQuantityField'),
                      controller: _quantityController,
                      label: 'كمية النقل',
                      icon: Icons.numbers_rounded,
                      accentColor: AppModuleColors.warehouses,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [
                        AppIntegerInputFormatter(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _AvailableQuantity(
                      quantity: sourceItem?.quantity ?? 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _WarehouseStockPanel(
                  key: const Key('inventoryTransferSourceStock'),
                  tableKey:
                      const Key('inventoryTransferSourceStockTable'),
                  title: _warehouseName(_fromWarehouseId),
                  items: _sourceItems,
                  selectedProductCode: _selectedProductCode,
                  onSelected: _selectProduct,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppModuleColors.warehouses,
                    size: AppIconSizes.xl,
                  ),
                ),
              ),
              Expanded(
                child: _WarehouseStockPanel(
                  key: const Key('inventoryTransferDestinationStock'),
                  tableKey:
                      const Key('inventoryTransferDestinationStockTable'),
                  title: _warehouseName(_toWarehouseId),
                  items: _destinationItems,
                ),
              ),
            ],
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
      icon: Icons.warehouse_rounded,
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
      icon: Icons.warehouse_rounded,
      accentColor: AppModuleColors.warehouses,
      useIntrinsicHeight: true,
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

class _WarehouseStockPanel extends StatelessWidget {
  const _WarehouseStockPanel({
    required this.tableKey,
    required this.title,
    required this.items,
    super.key,
    this.selectedProductCode,
    this.onSelected,
  });

  final Key tableKey;
  final String title;
  final List<WarehouseInventoryItem> items;
  final String? selectedProductCode;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return AppDialogSection(
      title: 'مواد $title',
      icon: Icons.inventory_rounded,
      accentColor: AppModuleColors.warehouses,
      expandChild: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AppDataTable(
            key: tableKey,
            height: constraints.maxHeight,
            headerHeight: 44,
            rowHeight: 44,
            minimumColumnWidth: 112,
            accentColor: AppModuleColors.warehouses,
            columns: const [
              AppTableColumn(label: 'رمز المادة'),
              AppTableColumn(label: 'اسم المادة', flex: 1.6),
              AppTableColumn(label: 'الكمية', numeric: true),
            ],
            rows: [
              for (final item in items)
                AppTableRow(
                  rowKey:
                      Key('transferStock-$title-${item.productCode}'),
                  selected: item.productCode == selectedProductCode,
                  onTap: onSelected == null
                      ? null
                      : () => onSelected!(item.productCode),
                  cells: [
                    Text(item.productCode),
                    Text(item.productName),
                    Text(AppFormatters.quantity(item.quantity)),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AvailableQuantity extends StatelessWidget {
  const _AvailableQuantity({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('inventoryTransferAvailableQuantity'),
      constraints: const BoxConstraints(
        minHeight: AppControlHeights.large,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'المتوفر في مخزن المصدر',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppFormatters.quantity(quantity),
            textAlign: TextAlign.center,
            style: AppTypography.fieldText.copyWith(
              color: AppModuleColors.warehouses,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferHistoryTable extends StatefulWidget {
  const _TransferHistoryTable({
    required this.entries,
    required this.height,
  });

  final List<_TransferHistoryEntry> entries;
  final double height;

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
        AppTableColumn(label: 'رقم النقل', flex: 0.8),
        AppTableColumn(label: 'التاريخ', flex: 1),
        AppTableColumn(label: 'من مخزن', flex: 1.35),
        AppTableColumn(label: 'إلى مخزن', flex: 1.35),
        AppTableColumn(label: 'المواد', flex: 2.5),
      ],
      rows: [
        for (final entry in widget.entries)
          AppTableRow(
            rowKey: Key('inventoryTransferHistory_${entry.number}'),
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
  }
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
