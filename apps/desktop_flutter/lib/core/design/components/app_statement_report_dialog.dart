import 'dart:async';

import 'package:flutter/material.dart';

import '../../printing/document_output_service.dart';
import '../../printing/document_output_scope.dart';
import '../../services/service_failure.dart';
import '../app_formatters.dart';
import '../app_tokens.dart';
import 'app_button.dart';
import 'app_document_output_dialog.dart';
import 'app_feedback.dart';
import 'app_module_dialog.dart';
import 'app_statement_dialog.dart';
import 'app_table.dart';

@immutable
class AppStatementReportEntry {
  const AppStatementReportEntry({
    required this.date,
    required this.balance,
    required this.credit,
    required this.debit,
    required this.type,
    required this.details,
    this.quantity,
  });

  final DateTime date;
  final num balance;
  final num credit;
  final num debit;
  final String type;
  final int? quantity;
  final String details;
}

abstract final class AppStatementReportDialog {
  static Future<void> show(
    BuildContext context, {
    required String partyName,
    required AppStatementOptions options,
    required List<AppStatementReportEntry> entries,
    num? openingBalance,
    Color accentColor = AppModuleColors.parties,
    DocumentPrintService? printService,
    DocumentExportService? exportService,
    bool allowPrint = true,
    bool allowExport = true,
  }) {
    final outputScope = DocumentOutputScope.maybeOf(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: _StatementReportBody(
          partyName: partyName,
          options: options,
          entries: entries,
          openingBalance: openingBalance,
          accentColor: accentColor,
          printService: printService ??
              outputScope?.printService ??
              const DemoDocumentOutputService(),
          exportService: exportService ??
              outputScope?.exportService ??
              const DemoDocumentOutputService(),
          allowPrint: allowPrint,
          allowExport: allowExport,
        ),
      ),
    );
  }
}

class _StatementReportBody extends StatefulWidget {
  const _StatementReportBody({
    required this.partyName,
    required this.options,
    required this.entries,
    required this.openingBalance,
    required this.accentColor,
    required this.printService,
    required this.exportService,
    required this.allowPrint,
    required this.allowExport,
  });

  final String partyName;
  final AppStatementOptions options;
  final List<AppStatementReportEntry> entries;
  final num? openingBalance;
  final Color accentColor;
  final DocumentPrintService printService;
  final DocumentExportService exportService;
  final bool allowPrint;
  final bool allowExport;

  @override
  State<_StatementReportBody> createState() =>
      _StatementReportBodyState();
}

class _StatementReportBodyState extends State<_StatementReportBody> {
  DocumentOutputAction? _activeAction;

  DocumentOutputRequest get _request {
    final options = widget.options;
    final period =
        'من ${AppFormatters.date(options.fromDate)} '
        'إلى ${AppFormatters.date(options.toDate)}';

    return DocumentOutputRequest(
      title: 'كشف حساب',
      subtitle: widget.partyName,
      fileNameBase: 'كشف حساب ${widget.partyName}',
      fields: [
        DocumentField(label: 'الفترة', value: period),
        DocumentField(
          label: 'العملة',
          value: AppFormatters.currency(options.currencyCode),
        ),
        if (widget.openingBalance != null)
          DocumentField(
            label: 'الرصيد الافتتاحي',
            value: _formatMoney(
              widget.openingBalance!,
              options.currencyCode,
            ),
          ),
      ],
      columns: const [
        DocumentColumn(label: 'التاريخ'),
        DocumentColumn(label: 'الرصيد', isPrice: true),
        DocumentColumn(label: 'دائن (له)', isPrice: true),
        DocumentColumn(label: 'مدين (عليه)', isPrice: true),
        DocumentColumn(label: 'النوع'),
        DocumentColumn(label: 'الكمية'),
        DocumentColumn(label: 'التفاصيل'),
      ],
      rows: [
        for (final entry in widget.entries)
          [
            AppFormatters.date(entry.date),
            _formatMoney(entry.balance, options.currencyCode),
            _formatMoney(entry.credit, options.currencyCode),
            _formatMoney(entry.debit, options.currencyCode),
            entry.type,
            entry.quantity == null
                ? '—'
                : AppFormatters.quantity(entry.quantity!),
            entry.details,
          ],
      ],
    );
  }

  void _print() {
    unawaited(_runOutput(DocumentOutputAction.print));
  }

  void _export(DocumentExportFormat format) {
    unawaited(
      _runOutput(
        format == DocumentExportFormat.pdf
            ? DocumentOutputAction.pdf
            : DocumentOutputAction.excel,
      ),
    );
  }

  Future<void> _runOutput(DocumentOutputAction action) async {
    final permitted = switch (action) {
      DocumentOutputAction.print ||
      DocumentOutputAction.printWithoutPrices => widget.allowPrint,
      DocumentOutputAction.pdf || DocumentOutputAction.excel =>
        widget.allowExport,
    };
    if (!permitted) return;
    if (_activeAction != null) return;
    setState(() => _activeAction = action);

    try {
      final result = switch (action) {
        DocumentOutputAction.print =>
          await widget.printService.createPreview(_request),
        DocumentOutputAction.pdf => await widget.exportService.export(
            _request,
            DocumentExportFormat.pdf,
          ),
        DocumentOutputAction.excel => await widget.exportService.export(
            _request,
            DocumentExportFormat.excel,
          ),
        DocumentOutputAction.printWithoutPrices =>
          await widget.printService.createPreview(
            _request,
            includePrices: false,
          ),
      };
      if (!mounted) return;
      setState(() => _activeAction = null);
      await AppDocumentOutputDialog.show(
        context,
        result: result,
        accentColor: widget.accentColor,
      );
    } on ServiceFailure catch (failure) {
      if (mounted) AppToast.showError(context, failure.message);
    } catch (_) {
      if (mounted) {
        AppToast.showError(context, 'تعذر تجهيز كشف الحساب حالياً');
      }
    } finally {
      if (mounted && _activeAction == action) {
        setState(() => _activeAction = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    final period =
        'من ${AppFormatters.date(options.fromDate)} '
        'إلى ${AppFormatters.date(options.toDate)}';

    return AppModuleDialog(
      key: const Key('appStatementReportDialog'),
      title: 'كشف حساب',
      subtitle: widget.partyName,
      subtitleStyle: const TextStyle(
        color: Color(0xFF4B5563),
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      centerHeader: true,
      showHeaderCloseButton: true,
      icon: Icons.receipt_long_rounded,
      accentColor: widget.accentColor,
      width: AppDialogSizes.extraLarge,
      onClose: () => Navigator.of(context).pop(),
      actionsKey: const Key('appStatementReportActions'),
      actions: [
        AppButton(
          key: const Key('appStatementPdf'),
          label: 'PDF',
          icon: Icons.picture_as_pdf_rounded,
          variant: AppButtonVariant.danger,
          width: 132,
          isLoading: _activeAction == DocumentOutputAction.pdf,
          onPressed: widget.allowExport && _activeAction == null
              ? () => _export(DocumentExportFormat.pdf)
              : null,
        ),
        AppButton(
          key: const Key('appStatementPrint'),
          label: 'طباعة',
          icon: Icons.print_rounded,
          width: 132,
          backgroundColor: AppColors.blue,
          isLoading: _activeAction == DocumentOutputAction.print,
          onPressed:
              widget.allowPrint && _activeAction == null ? _print : null,
        ),
        AppButton(
          key: const Key('appStatementExcel'),
          label: 'إكسل',
          icon: Icons.table_chart_rounded,
          variant: AppButtonVariant.success,
          width: 132,
          isLoading: _activeAction == DocumentOutputAction.excel,
          onPressed: widget.allowExport && _activeAction == null
              ? () => _export(DocumentExportFormat.excel)
              : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Text(
                  period,
                  key: const Key('appStatementPeriodText'),
                  style: AppTypography.fieldText.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormatters.currency(options.currencyCode),
                  key: const Key('appStatementCurrencyText'),
                  style: AppTypography.fieldText.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.openingBalance != null) ...[
                  const SizedBox(width: AppSpacing.lg),
                  Text(
                    'الرصيد الافتتاحي: '
                    '${_formatMoney(widget.openingBalance!, options.currencyCode)}',
                    key: const Key('appStatementOpeningBalanceText'),
                    style: AppTypography.fieldText.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDataTable(
            key: const Key('appStatementReportTable'),
            height: 340,
            headerHeight: 52,
            rowHeight: 58,
            minimumColumnWidth: 132,
            accentColor: widget.accentColor,
            emptyState: const Text(
              'لا توجد حركات ضمن الفترة والعملة المختارة',
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle,
            ),
            columns: const [
              AppTableColumn(label: 'التاريخ', flex: 1.15),
              AppTableColumn(label: 'الرصيد', numeric: true, flex: 1.25),
              AppTableColumn(label: 'دائن (له)', numeric: true, flex: 1.25),
              AppTableColumn(
                label: 'مدين (عليه)',
                numeric: true,
                flex: 1.25,
              ),
              AppTableColumn(label: 'النوع', flex: 1.2),
              AppTableColumn(label: 'الكمية', numeric: true),
              AppTableColumn(label: 'التفاصيل', flex: 2.5),
            ],
            rows: [
              for (final entry in widget.entries)
                AppTableRow(
                  cells: [
                    Text(AppFormatters.date(entry.date)),
                    Text(_formatMoney(entry.balance, options.currencyCode)),
                    Text(_formatMoney(entry.credit, options.currencyCode)),
                    Text(_formatMoney(entry.debit, options.currencyCode)),
                    Text(entry.type),
                    Text(
                      entry.quantity == null
                          ? '—'
                          : AppFormatters.quantity(entry.quantity!),
                    ),
                    Text(entry.details),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatMoney(num value, String currencyCode) {
    return currencyCode.toUpperCase() == 'USD'
        ? AppFormatters.usd(value)
        : AppFormatters.iqd(value);
  }
}
