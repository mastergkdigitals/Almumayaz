import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/cashbox_voucher.dart';

class CashboxTable extends StatefulWidget {
  const CashboxTable({
    required this.vouchers,
    required this.selectedVoucherId,
    required this.onSelected,
    required this.height,
    super.key,
  });

  final List<CashboxVoucher> vouchers;
  final String? selectedVoucherId;
  final ValueChanged<CashboxVoucher> onSelected;
  final double height;

  @override
  State<CashboxTable> createState() => _CashboxTableState();
}

class _CashboxTableState extends State<CashboxTable> {
  static const _rowHeight = 56.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _revealSelectedVoucher();
  }

  @override
  void didUpdateWidget(covariant CashboxTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedVoucherId != widget.selectedVoucherId ||
        oldWidget.vouchers != widget.vouchers) {
      _revealSelectedVoucher();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _revealSelectedVoucher() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final selectedIndex = widget.vouchers.indexWhere(
        (voucher) => voucher.id == widget.selectedVoucherId,
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
      AppModuleColors.cashbox.withAlpha(32),
      AppColors.surface,
    );
    final alternateTint = Color.alphaBlend(
      AppModuleColors.cashbox.withAlpha(12),
      AppColors.surface,
    );

    return AppDataTable(
      key: const Key('cashboxTable'),
      height: widget.height,
      rowHeight: _rowHeight,
      verticalScrollController: _scrollController,
      minimumColumnWidth: 135,
      accentColor: AppModuleColors.cashbox,
      selectedRowColor: selectedTint,
      alternatingRowColor: alternateTint,
      columns: const [
        AppTableColumn(label: 'رقم السند', flex: 2),
        AppTableColumn(label: 'التاريخ', flex: 3),
        AppTableColumn(label: 'النوع', flex: 2),
        AppTableColumn(label: 'الحساب الرئيسي', flex: 4),
        AppTableColumn(label: 'الحساب الفرعي', flex: 4),
        AppTableColumn(label: 'المبلغ دينار', numeric: true, flex: 3),
        AppTableColumn(label: 'المبلغ دولار', numeric: true, flex: 3),
      ],
      rows: [
        for (final voucher in widget.vouchers)
          AppTableRow(
            rowKey: Key('cashboxRow_${voucher.id}'),
            selected: voucher.id == widget.selectedVoucherId,
            onTap: () => widget.onSelected(voucher),
            cells: [
              Text(voucher.number.toString()),
              Text(AppFormatters.date(voucher.createdAt)),
              Text(voucher.type.label),
              Text(voucher.mainAccountLabel),
              Text(voucher.subaccountLabel),
              Text(AppFormatters.iqd(voucher.amountIqd)),
              Text(AppFormatters.usd(voucher.amountUsd)),
            ],
          ),
      ],
      emptyState: const AppStatePanel(
        type: AppStateType.empty,
        title: 'لا توجد حركات صندوق',
        message: 'غيّر كلمات البحث أو أضف سنداً جديداً.',
      ),
    );
  }
}
