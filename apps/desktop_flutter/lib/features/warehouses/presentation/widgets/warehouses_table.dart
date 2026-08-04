import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/warehouse.dart';

class WarehousesTable extends StatefulWidget {
  const WarehousesTable({
    required this.warehouses,
    required this.selectedWarehouseId,
    required this.onSelected,
    required this.materialCountFor,
    required this.totalQuantityFor,
    required this.height,
    super.key,
  });

  final List<Warehouse> warehouses;
  final String? selectedWarehouseId;
  final ValueChanged<Warehouse> onSelected;
  final int Function(String warehouseId) materialCountFor;
  final int Function(String warehouseId) totalQuantityFor;
  final double height;

  @override
  State<WarehousesTable> createState() => _WarehousesTableState();
}

class _WarehousesTableState extends State<WarehousesTable> {
  static const _rowHeight = 56.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _revealSelectedWarehouse();
  }

  @override
  void didUpdateWidget(covariant WarehousesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedWarehouseId != widget.selectedWarehouseId ||
        oldWidget.warehouses != widget.warehouses) {
      _revealSelectedWarehouse();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _revealSelectedWarehouse() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final selectedIndex = widget.warehouses.indexWhere(
        (warehouse) => warehouse.id == widget.selectedWarehouseId,
      );
      if (selectedIndex < 0) return;

      final position = _scrollController.position;
      final rowTop = selectedIndex * _rowHeight;
      final rowBottom = rowTop + _rowHeight;
      final viewportTop = position.pixels;
      final viewportBottom = viewportTop + position.viewportDimension;

      double? targetOffset;
      if (rowTop < viewportTop) {
        targetOffset = rowTop;
      } else if (rowBottom > viewportBottom) {
        targetOffset = rowBottom - position.viewportDimension;
      }
      if (targetOffset == null) return;

      unawaited(
        _scrollController.animateTo(
          targetOffset.clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ).toDouble(),
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTint = Color.alphaBlend(
      AppModuleColors.warehouses.withAlpha(32),
      AppColors.surface,
    );

    return AppDataTable(
      key: const Key('warehousesTable'),
      height: widget.height,
      rowHeight: _rowHeight,
      verticalScrollController: _scrollController,
      minimumColumnWidth: 115,
      accentColor: AppModuleColors.warehouses,
      selectedRowColor: selectedTint,
      columns: const [
        AppTableColumn(label: 'الرقم', flex: 1),
        AppTableColumn(label: 'اسم المخزن', flex: 2.2),
        AppTableColumn(label: 'الموقع', flex: 2.4),
        AppTableColumn(label: 'عدد المواد', numeric: true, flex: 1.2),
        AppTableColumn(label: 'إجمالي الكمية', numeric: true, flex: 1.4),
      ],
      rows: [
        for (final warehouse in widget.warehouses)
          AppTableRow(
            rowKey: Key('warehouseRow_${warehouse.id}'),
            selected: warehouse.id == widget.selectedWarehouseId,
            onTap: () => widget.onSelected(warehouse),
            cells: [
              Text(warehouse.number.toString()),
              _WarehouseNameCell(warehouse: warehouse),
              Text(warehouse.location.isEmpty ? '—' : warehouse.location),
              Text(widget.materialCountFor(warehouse.id).toString()),
              Text(widget.totalQuantityFor(warehouse.id).toString()),
            ],
          ),
      ],
      emptyState: const AppStatePanel(
        type: AppStateType.empty,
        title: 'لا توجد مخازن',
        message: 'غيّر كلمات البحث أو أضف مخزناً جديداً.',
      ),
    );
  }
}

class _WarehouseNameCell extends StatelessWidget {
  const _WarehouseNameCell({required this.warehouse});

  final Warehouse warehouse;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Text(warehouse.name)),
        if (warehouse.isMain) ...[
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.star_rounded,
            size: AppIconSizes.sm,
            color: AppModuleColors.warehouses,
          ),
        ],
      ],
    );
  }
}
