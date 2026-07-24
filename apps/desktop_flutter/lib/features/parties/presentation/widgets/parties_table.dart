import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/party.dart';

class PartiesTable extends StatefulWidget {
  const PartiesTable({
    required this.parties,
    required this.selectedPartyId,
    required this.onSelected,
    required this.onStatement,
    required this.height,
    super.key,
  });

  final List<Party> parties;
  final String? selectedPartyId;
  final ValueChanged<Party> onSelected;
  final ValueChanged<Party> onStatement;
  final double height;

  @override
  State<PartiesTable> createState() => _PartiesTableState();
}

class _PartiesTableState extends State<PartiesTable> {
  static const _rowHeight = 56.0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _revealSelectedParty();
  }

  @override
  void didUpdateWidget(covariant PartiesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPartyId != widget.selectedPartyId ||
        oldWidget.parties != widget.parties) {
      _revealSelectedParty();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _revealSelectedParty() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final selectedIndex = widget.parties.indexWhere(
        (party) => party.id == widget.selectedPartyId,
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
    return AppDataTable(
      key: const Key('partiesTable'),
      height: widget.height,
      rowHeight: _rowHeight,
      verticalScrollController: _scrollController,
      minimumColumnWidth: 145,
      columns: const [
        AppTableColumn(label: 'اسم الطرف', flex: 1.5),
        AppTableColumn(label: 'النوع', flex: 0.9),
        AppTableColumn(label: 'جهة العمل', flex: 1.25),
        AppTableColumn(label: 'رقم الهاتف', flex: 1.05),
        AppTableColumn(label: 'الرصيد دينار', numeric: true, flex: 1.05),
        AppTableColumn(label: 'الرصيد دولار', numeric: true, flex: 1.05),
        AppTableColumn(label: 'الإجراء', flex: 0.65),
      ],
      rows: [
        for (final party in widget.parties)
          AppTableRow(
            rowKey: Key('partyRow_${party.id}'),
            selected: party.id == widget.selectedPartyId,
            onTap: () => widget.onSelected(party),
            cells: [
              Text(party.name),
              Text(party.type.label),
              _WorkplaceCell(party: party),
              Text(party.phone.isEmpty ? '—' : party.phone),
              Text(AppFormatters.money(party.balanceIqd)),
              Text(AppFormatters.money(party.balanceUsd)),
              AppTableActionButton(
                key: Key('partyStatement_${party.id}'),
                icon: Icons.receipt_long_rounded,
                tooltip: 'كشف الحساب',
                onPressed: () => widget.onStatement(party),
              ),
            ],
          ),
      ],
      emptyState: const AppStatePanel(
        type: AppStateType.empty,
        title: 'لا توجد أطراف',
        message: 'غيّر كلمات البحث أو أضف طرفاً جديداً.',
      ),
    );
  }
}

class _WorkplaceCell extends StatelessWidget {
  const _WorkplaceCell({required this.party});

  final Party party;

  @override
  Widget build(BuildContext context) {
    final workplace = party.workplace.isEmpty ? '—' : party.workplace;
    final branch = party.branch.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(workplace, textAlign: TextAlign.center),
        if (branch.isNotEmpty)
          Text(
            branch,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
