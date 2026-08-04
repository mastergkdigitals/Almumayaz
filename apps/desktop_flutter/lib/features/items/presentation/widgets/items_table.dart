import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/item.dart';

class ItemsTable extends StatefulWidget {
  const ItemsTable({
    required this.items,
    required this.selectedItemId,
    required this.onSelected,
    required this.height,
    super.key,
  });

  final List<Item> items;
  final String? selectedItemId;
  final ValueChanged<Item> onSelected;
  final double height;

  @override
  State<ItemsTable> createState() => _ItemsTableState();
}

class _ItemsTableState extends State<ItemsTable> {
  static const _rowHeight = 60.0 * AppDensity.scale;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _revealSelectedItem();
  }

  @override
  void didUpdateWidget(covariant ItemsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItemId != widget.selectedItemId ||
        oldWidget.items != widget.items) {
      _revealSelectedItem();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _revealSelectedItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final selectedIndex = widget.items.indexWhere(
        (item) => item.id == widget.selectedItemId,
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
      key: const Key('itemsTable'),
      height: widget.height,
      rowHeight: _rowHeight,
      verticalScrollController: _scrollController,
      minimumColumnWidth: 170 * AppDensity.scale,
      accentColor: AppModuleColors.warehouses,
      alternatingRowColor: null,
      selectedRowColor: selectedTint,
      columns: const [
        AppTableColumn(label: 'رمز المادة', flex: 0.8),
        AppTableColumn(label: 'اسم المادة', flex: 1.5),
        AppTableColumn(label: 'المجموعة', flex: 1.35),
        AppTableColumn(label: 'سعر البيع دينار', numeric: true),
        AppTableColumn(label: 'سعر البيع دولار', numeric: true),
      ],
      rows: [
        for (final item in widget.items)
          AppTableRow(
            rowKey: Key('itemRow_${item.id}'),
            selected: item.id == widget.selectedItemId,
            onTap: () => widget.onSelected(item),
            cells: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(item.code, textAlign: TextAlign.center),
              ),
              Text(item.name),
              _GroupTypeCell(item: item),
              Text(AppFormatters.iqd(item.salePriceIqd)),
              Text(AppFormatters.usd(item.salePriceUsd)),
            ],
          ),
      ],
      emptyState: const AppStatePanel(
        type: AppStateType.empty,
        title: 'لا توجد مواد',
        message: 'غيّر كلمات البحث أو أضف مادة جديدة.',
      ),
    );
  }
}

class _GroupTypeCell extends StatelessWidget {
  const _GroupTypeCell({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.groupName, textAlign: TextAlign.center),
        Text(
          item.typeName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12 * AppDensity.scale,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
