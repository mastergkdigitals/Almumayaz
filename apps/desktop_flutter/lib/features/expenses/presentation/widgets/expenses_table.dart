import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../../domain/expense.dart';

class ExpensesTable extends StatelessWidget {
  const ExpensesTable({
    required this.expenses,
    required this.selectedExpenseId,
    required this.onSelected,
    required this.height,
    super.key,
  });

  final List<Expense> expenses;
  final String? selectedExpenseId;
  final ValueChanged<Expense> onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppDataTable(
      key: const Key('expensesTable'),
      height: height,
      rowHeight: 58,
      minimumColumnWidth: 130,
      accentColor: AppModuleColors.cashbox,
      alternatingRowColor: null,
      selectedRowColor: Color.alphaBlend(
        AppModuleColors.cashbox.withAlpha(28),
        AppColors.surface,
      ),
      columns: const [
        AppTableColumn(label: 'رقم المصروف', numeric: true, flex: 0.8),
        AppTableColumn(label: 'التاريخ', numeric: true),
        AppTableColumn(label: 'البيان', flex: 1.8),
        AppTableColumn(label: 'المجهز', flex: 1.3),
        AppTableColumn(label: 'الحالة'),
        AppTableColumn(label: 'العملة'),
        AppTableColumn(label: 'المبلغ', numeric: true),
      ],
      rows: [
        for (final expense in expenses)
          AppTableRow(
            rowKey: Key('expenseRow_${expense.id.value}'),
            selected: expense.id.value == selectedExpenseId,
            onTap: () => onSelected(expense),
            cells: [
              Text('${expense.documentNumber}'),
              Text(AppFormatters.date(expense.date.value)),
              Text(expense.description),
              Text(expense.supplierNameSnapshot ?? '—'),
              _ExpenseStatusCell(status: expense.paymentStatus),
              Text(expense.amount.currency.arabicName),
              Text(
                AppFormatters.moneyByCurrency(
                  expense.amount.majorUnits,
                  expense.amount.currency.code,
                ),
              ),
            ],
          ),
      ],
      emptyState: const _ExpensesEmptyState(),
    );
  }
}

class _ExpensesEmptyState extends StatelessWidget {
  const _ExpensesEmptyState();

  static const _expandedMinimumHeight = 176.0;
  static const _message =
      'لا توجد مصاريف. غيّر كلمات البحث أو أضف مصروفاً جديداً.';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight < _expandedMinimumHeight) {
          return const AppInfoBanner(
            message: _message,
            icon: Icons.inbox_rounded,
            foregroundColor: AppColors.neutralForeground,
            backgroundColor: AppColors.neutralSurface,
            textAlign: TextAlign.center,
            announce: true,
          );
        }
        return const AppStatePanel(
          type: AppStateType.empty,
          title: 'لا توجد مصاريف',
          message: 'غيّر كلمات البحث أو أضف مصروفاً جديداً.',
        );
      },
    );
  }
}

class _ExpenseStatusCell extends StatelessWidget {
  const _ExpenseStatusCell({required this.status});

  final ExpensePaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final isPaid = status == ExpensePaymentStatus.paid;
    final color = isPaid ? AppColors.success : AppColors.warning;
    return Semantics(
      label: 'حالة المصروف: ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withAlpha(20), AppColors.surface),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Text(
          status.label,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
