import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';
import 'app_button.dart';
import 'app_header_button.dart';
import 'app_loading_indicator.dart';

class AppTableColumn {
  const AppTableColumn({
    required this.label,
    this.numeric = false,
    this.flex = 1,
    this.textDirection,
    this.textAlign,
  }) : assert(flex > 0);

  final String label;
  final bool numeric;
  final double flex;
  final TextDirection? textDirection;
  final TextAlign? textAlign;

  TextDirection get effectiveTextDirection =>
      textDirection ?? (numeric ? TextDirection.ltr : TextDirection.rtl);

  TextAlign get effectiveTextAlign => textAlign ?? TextAlign.center;
}

class AppTableRow {
  const AppTableRow({
    required this.cells,
    this.onTap,
    this.selected = false,
    this.rowKey,
  });

  final List<Widget> cells;
  final VoidCallback? onTap;
  final bool selected;
  final Key? rowKey;
}

class AppDataTable extends StatefulWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    super.key,
    this.height = 360,
    this.headerHeight = 56,
    this.rowHeight = 56,
    this.minimumColumnWidth = 180,
    this.isLoading = false,
    this.emptyState,
    this.focusNode,
    this.verticalScrollController,
    this.onKeyboardSelectionChanged,
    this.accentColor,
    this.borderColor,
    this.headerBackgroundColor,
    this.headerForegroundColor,
    this.cellHorizontalPadding = AppSpacing.md,
    this.showColumnDividers = false,
    this.showShadow = true,
    this.borderRadius = AppRadii.lg,
    this.alternatingRowColor,
    this.selectedRowColor,
  });

  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final double height;
  final double headerHeight;
  final double rowHeight;
  final double minimumColumnWidth;
  final bool isLoading;
  final Widget? emptyState;
  final FocusNode? focusNode;
  final ScrollController? verticalScrollController;
  final ValueChanged<int>? onKeyboardSelectionChanged;
  final Color? accentColor;
  final Color? borderColor;
  final Color? headerBackgroundColor;
  final Color? headerForegroundColor;
  final double cellHorizontalPadding;
  final bool showColumnDividers;
  final bool showShadow;
  final double borderRadius;
  final Color? alternatingRowColor;
  final Color? selectedRowColor;

  @override
  State<AppDataTable> createState() => _AppDataTableState();
}

class _AppDataTableState extends State<AppDataTable> {
  final _internalVerticalScrollController = ScrollController();
  final _horizontalScrollController = ScrollController();
  final _internalFocusNode = FocusNode(debugLabel: 'appDataTable');

  int? _keyboardSelectionIndex;

  ScrollController get _verticalScrollController =>
      widget.verticalScrollController ?? _internalVerticalScrollController;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _keyboardSelectionIndex = _selectedRowIndex(widget.rows);
  }

  @override
  void didUpdateWidget(covariant AppDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSelectedIndex = _selectedRowIndex(oldWidget.rows);
    final selectedIndex = _selectedRowIndex(widget.rows);
    if (selectedIndex != oldSelectedIndex) {
      _keyboardSelectionIndex = selectedIndex;
    } else if (widget.rows.isEmpty) {
      _keyboardSelectionIndex = null;
    } else if (_keyboardSelectionIndex != null) {
      _keyboardSelectionIndex = _keyboardSelectionIndex!.clamp(
        0,
        widget.rows.length - 1,
      ).toInt();
    }
  }

  @override
  void dispose() {
    _internalVerticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _internalFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent || widget.rows.isEmpty) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveKeyboardSelection(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveKeyboardSelection(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.home) {
      _moveKeyboardSelectionTo(0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      _moveKeyboardSelectionTo(widget.rows.length - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final index = _keyboardSelectionIndex ??
          _selectedRowIndex(widget.rows) ??
          0;
      final onTap = widget.rows[index].onTap;
      if (onTap == null) return KeyEventResult.ignored;
      _selectAndActivate(index, onTap);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _moveKeyboardSelection(int delta) {
    final currentIndex = _keyboardSelectionIndex;
    final nextIndex = currentIndex == null
        ? delta > 0
            ? 0
            : widget.rows.length - 1
        : (currentIndex + delta)
            .clamp(0, widget.rows.length - 1)
            .toInt();
    _moveKeyboardSelectionTo(nextIndex);
  }

  void _moveKeyboardSelectionTo(int index) {
    final nextIndex = index.clamp(0, widget.rows.length - 1).toInt();
    if (_keyboardSelectionIndex != nextIndex) {
      setState(() => _keyboardSelectionIndex = nextIndex);
    }
    _focusNode.requestFocus();
    widget.onKeyboardSelectionChanged?.call(nextIndex);
    _ensureSelectionVisible(nextIndex);
  }

  void _selectAndActivate(int index, VoidCallback onTap) {
    if (_keyboardSelectionIndex != index) {
      setState(() => _keyboardSelectionIndex = index);
    }
    _focusNode.requestFocus();
    onTap();
    if (mounted) _focusNode.requestFocus();
  }

  void _ensureSelectionVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_verticalScrollController.hasClients) return;
      final position = _verticalScrollController.position;
      final rowStart = index * widget.rowHeight;
      final rowEnd = rowStart + widget.rowHeight;
      var target = position.pixels;
      if (rowStart < target) {
        target = rowStart;
      } else if (rowEnd > target + position.viewportDimension) {
        target = rowEnd - position.viewportDimension;
      }
      target = target.clamp(0, position.maxScrollExtent).toDouble();
      if (target != position.pixels) {
        _verticalScrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.rows.every(
        (row) => row.cells.length == widget.columns.length,
      ),
      'Every table row must contain one cell for each column.',
    );

    final borderRadius = BorderRadius.circular(widget.borderRadius);
    final effectiveBorderColor = widget.borderColor ??
        (widget.accentColor == null
            ? AppColors.border
            : Color.lerp(
                widget.accentColor,
                AppColors.surface,
                0.62,
              )!);
    final effectiveSelectedRowColor = widget.selectedRowColor ??
        (widget.accentColor == null
            ? AppColors.infoSurface
            : Color.alphaBlend(
                widget.accentColor!.withAlpha(22),
                AppColors.surface,
              ));
    final columnWidths = <int, TableColumnWidth>{
      for (var index = 0; index < widget.columns.length; index++)
        index: FlexColumnWidth(widget.columns[index].flex),
    };

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: borderRadius,
          boxShadow: widget.showShadow ? AppShadows.soft : null,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: effectiveBorderColor, width: 1.4),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : widget.minimumColumnWidth * widget.columns.length;
            final tableWidth = math.max(
              availableWidth,
              widget.minimumColumnWidth * widget.columns.length,
            );

            return SizedBox(
              height: widget.height,
              child: Scrollbar(
                controller: _horizontalScrollController,
                thumbVisibility: true,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    height: widget.height,
                    child: Column(
                      children: [
                        _TableHeader(
                          columns: widget.columns,
                          columnWidths: columnWidths,
                          height: widget.headerHeight,
                          accentColor: widget.accentColor,
                          borderColor: effectiveBorderColor,
                          backgroundColor: widget.headerBackgroundColor,
                          foregroundColor: widget.headerForegroundColor,
                          horizontalPadding: widget.cellHorizontalPadding,
                          showColumnDividers: widget.showColumnDividers,
                        ),
                        Expanded(
                          child: _buildBody(
                            columnWidths,
                            effectiveBorderColor,
                            effectiveSelectedRowColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    Map<int, TableColumnWidth> columnWidths,
    Color borderColor,
    Color selectedRowColor,
  ) {
    if (widget.isLoading) {
      return const Center(
        child: AppLoadingIndicator(size: 40, strokeWidth: 4),
      );
    }

    if (widget.rows.isEmpty) {
      return Center(
        child: widget.emptyState ??
            const Text(
              'لا توجد بيانات',
              style: AppTypography.tableCell,
            ),
      );
    }

    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _verticalScrollController,
        itemCount: widget.rows.length,
        itemExtent: widget.rowHeight,
        itemBuilder: (context, index) {
          final row = widget.rows[index];
          final selected = _keyboardSelectionIndex == null
              ? row.selected
              : _keyboardSelectionIndex == index;
          return Semantics(
            container: true,
            selected: selected,
            child: _TableBodyRow(
              columns: widget.columns,
              row: row,
              selected: selected,
              onActivate: row.onTap == null
                  ? null
                  : () => _selectAndActivate(index, row.onTap!),
              columnWidths: columnWidths,
              height: widget.rowHeight,
              showBottomBorder: index < widget.rows.length - 1,
              horizontalPadding: widget.cellHorizontalPadding,
              showColumnDividers: widget.showColumnDividers,
              backgroundColor:
                  index.isOdd ? widget.alternatingRowColor : null,
              selectedColor: selectedRowColor,
              borderColor: borderColor,
            ),
          );
        },
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.columns,
    required this.columnWidths,
    required this.height,
    required this.accentColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.horizontalPadding,
    required this.showColumnDividers,
  });

  final List<AppTableColumn> columns;
  final Map<int, TableColumnWidth> columnWidths;
  final double height;
  final Color? accentColor;
  final Color borderColor;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double horizontalPadding;
  final bool showColumnDividers;

  @override
  Widget build(BuildContext context) {
    final headerColor = backgroundColor ??
        (accentColor == null
            ? AppColors.tableHeaderSurface
            : Color.alphaBlend(
                accentColor!.withAlpha(18),
                AppColors.surface,
              ));

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: headerColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 0.8),
        ),
      ),
      child: Table(
        textDirection: TextDirection.rtl,
        columnWidths: columnWidths,
        children: [
          TableRow(
            children: [
              for (var index = 0; index < columns.length; index++)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: showColumnDividers &&
                            index < columns.length - 1
                        ? Border(
                            left: BorderSide(
                              color: borderColor,
                              width: 0.8,
                            ),
                          )
                        : null,
                  ),
                  child: SizedBox(
                    height: height,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Directionality(
                        textDirection:
                            columns[index].effectiveTextDirection,
                        child: Align(
                          alignment: _alignmentForTextAlign(
                            columns[index].effectiveTextAlign,
                          ),
                          child: Text(
                            columns[index].label,
                            textAlign:
                                columns[index].effectiveTextAlign,
                            style: AppTypography.tableHeader.copyWith(
                              color: foregroundColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableBodyRow extends StatelessWidget {
  const _TableBodyRow({
    required this.columns,
    required this.row,
    required this.selected,
    required this.onActivate,
    required this.columnWidths,
    required this.height,
    required this.showBottomBorder,
    required this.horizontalPadding,
    required this.showColumnDividers,
    required this.backgroundColor,
    required this.selectedColor,
    required this.borderColor,
  });

  final List<AppTableColumn> columns;
  final AppTableRow row;
  final bool selected;
  final VoidCallback? onActivate;
  final Map<int, TableColumnWidth> columnWidths;
  final double height;
  final bool showBottomBorder;
  final double horizontalPadding;
  final bool showColumnDividers;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: row.rowKey,
      color: selected
          ? selectedColor ?? AppColors.infoSurface
          : backgroundColor ?? AppColors.surface,
      child: InkWell(
        onTap: onActivate,
        canRequestFocus: false,
        mouseCursor: onActivate == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        splashFactory: NoSplash.splashFactory,
        overlayColor:
            const WidgetStatePropertyAll<Color>(Colors.transparent),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: showBottomBorder
                ? Border(
                    bottom: BorderSide(color: borderColor, width: 0.8),
                  )
                : null,
          ),
          child: Table(
            textDirection: TextDirection.rtl,
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  for (var index = 0; index < row.cells.length; index++)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: showColumnDividers &&
                                index < row.cells.length - 1
                            ? Border(
                                left: BorderSide(
                                  color: borderColor,
                                  width: 0.8,
                                ),
                              )
                            : null,
                      ),
                      child: SizedBox(
                        height: height,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: Directionality(
                            textDirection:
                                columns[index].effectiveTextDirection,
                            child: Align(
                              alignment: _alignmentForTextAlign(
                                columns[index].effectiveTextAlign,
                              ),
                              child: DefaultTextStyle(
                                textAlign:
                                    columns[index].effectiveTextAlign,
                                style: AppTypography.tableCell,
                                child: row.cells[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int? _selectedRowIndex(List<AppTableRow> rows) {
  final index = rows.indexWhere((row) => row.selected);
  return index < 0 ? null : index;
}

AlignmentGeometry _alignmentForTextAlign(TextAlign textAlign) {
  return switch (textAlign) {
    TextAlign.left => Alignment.centerLeft,
    TextAlign.right => Alignment.centerRight,
    TextAlign.start => AlignmentDirectional.centerStart,
    TextAlign.end => AlignmentDirectional.centerEnd,
    TextAlign.center => Alignment.center,
    TextAlign.justify => Alignment.center,
  };
}

class AppTableActionButton extends StatelessWidget {
  const AppTableActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
    this.tooltipKey,
    this.size = AppControlHeights.compact,
    this.variant = AppButtonVariant.navigation,
    this.backgroundColor,
    this.foregroundColor,
    this.iconSize = AppIconSizes.md,
    this.borderRadius,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Key? tooltipKey;
  final double size;
  final AppButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double iconSize;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return AppTooltipIconButton(
      tooltipKey: tooltipKey,
      icon: icon,
      tooltip: tooltip,
      size: size,
      iconSize: iconSize,
      borderRadius: borderRadius,
      variant: variant,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      onPressed: onPressed,
    );
  }
}
