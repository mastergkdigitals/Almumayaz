import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_state/app_store.dart';
import '../../../core/application/invoice_editor_coordinator.dart';
import '../../../core/data/app_repository.dart';
import '../../../core/design/app_design_system.dart';
import '../../../core/domain/business_values.dart';
import '../../../core/printing/document_output_service.dart';
import '../../../core/services/service_failure.dart';
import '../../permissions/domain/permission_models.dart';
import '../../sales/domain/sales_invoice.dart';
import '../domain/sales_return.dart';
import 'sales_return_document.dart';
import 'sales_return_editor_controller.dart';
import 'widgets/sales_return_lines_table.dart';

class SalesReturnScreen extends StatefulWidget {
  const SalesReturnScreen({
    super.key,
    this.printService = const DemoDocumentOutputService(),
    this.exportService = const DemoDocumentOutputService(),
  });

  final DocumentPrintService printService;
  final DocumentExportService exportService;

  static Future<void> open(BuildContext context) async {
    final store = AppStoreScope.of(context, listen: false);
    if (!store.allows('sales', PermissionAction.view)) {
      AppToast.showError(context, 'ليس لديك صلاحية لفتح مرتجعات البيع');
      return;
    }
    final output = store.services.documentOutput;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SalesReturnScreen(
          printService: output,
          exportService: output,
        ),
      ),
    );
  }

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  SalesReturnEditorController? _controller;
  AppStore? _store;
  bool _documentActionRunning = false;

  SalesReturnEditorController get controller => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = AppStoreScope.of(context, listen: false);
    if (identical(_store, store)) return;
    _controller?.removeListener(_handleControllerChanged);
    _controller?.dispose();
    _store = store;
    _controller = SalesReturnEditorController(
      returns: store.repositories.salesReturns,
      sales: store.repositories.sales,
      parties: store.repositories.parties,
    )..addListener(_handleControllerChanged);
    unawaited(_controller!.initialize());
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  bool _allows(PermissionAction action) =>
      _store?.allows('sales', action) ?? false;

  Future<bool> _confirmDiscardChanges() async {
    if (!controller.hasChanges) return true;
    return AppDialogs.confirm(
      context: context,
      title: 'تجاهل التغييرات؟',
      message: 'توجد تغييرات غير محفوظة في مرتجع البيع.',
      confirmLabel: 'تجاهل',
      isDanger: true,
    );
  }

  Future<void> _attemptBack() async {
    if (controller.isBusy || _documentActionRunning) return;
    if (!await _confirmDiscardChanges() || !mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _refresh() async {
    if (controller.isBusy || _documentActionRunning) return;
    if (!await _confirmDiscardChanges() || !mounted) return;
    await controller.reload(showLoading: true);
  }

  Future<void> _showSearch() async {
    if (controller.isBusy || _documentActionRunning) return;
    final result = await AppRecordSearchDialog.show<EntityId>(
      context,
      title: 'بحث مرتجعات البيع',
      subtitle: 'ابحث عن مرتجع محفوظ ثم اختره',
      searchLabel: 'بحث في مرتجعات البيع',
      hint: 'رقم المرتجع أو القائمة الأصلية أو اسم الزبون أو المادة',
      accentColor: AppModuleColors.sales,
      records: [
        for (final value in controller.records)
          AppSearchRecord(
            value: value.id,
            title: 'مرتجع بيع رقم ${value.documentNumber}',
            subtitle: value.customerNameSnapshot,
            details: 'قائمة أصلية ${value.originalSalesInvoiceNumberSnapshot}'
                ' • ${value.searchDetailsSnapshot}',
            searchTerms: [
              '${value.documentNumber}',
              '${value.originalSalesInvoiceNumberSnapshot}',
              value.notes,
              for (final line in value.lines) ...[
                line.itemCodeSnapshot,
                line.itemNameSnapshot,
              ],
            ],
            icon: Icons.assignment_return_rounded,
          ),
      ],
      emptyTitle: 'لا توجد مرتجعات بيع محفوظة',
      noResultsTitle: 'لا توجد مرتجعات بيع مطابقة',
      dialogKey: const Key('salesReturnRecordSearchDialog'),
      searchFieldKey: const Key('salesReturnRecordSearchField'),
      resultKeyPrefix: 'salesReturnRecordSearchResult',
    );
    if (!mounted || result == null) return;
    if (!await _confirmDiscardChanges() || !mounted) return;
    await _runAction(
      () => controller.selectRecord(result),
      failureMessage: 'تعذر فتح مرتجع البيع',
    );
  }

  Future<void> _selectSourceInvoice(SalesInvoice invoice) async {
    await _runAction(
      () => controller.selectSourceInvoice(invoice),
      failureMessage: 'تعذر تحميل قائمة البيع الأصلية',
    );
  }

  Future<void> _save() async {
    if (!_allows(PermissionAction.create)) return;
    final validation = controller.validate();
    if (validation != null) {
      AppToast.showWarning(context, validation);
      return;
    }
    final saved = await _runAction(
      controller.create,
      failureMessage: 'تعذر حفظ مرتجع البيع',
    );
    if (saved == null || !mounted) return;
    _store!.markDataChanged();
    AppToast.showInfo(context, 'تم حفظ مرتجع البيع رقم ${saved.documentNumber}');
  }

  Future<void> _update() async {
    if (!_allows(PermissionAction.update)) return;
    final validation = controller.validate();
    if (validation != null) {
      AppToast.showWarning(context, validation);
      return;
    }
    final saved = await _runAction(
      controller.replace,
      failureMessage: 'تعذر تحديث مرتجع البيع',
    );
    if (saved == null || !mounted) return;
    _store!.markDataChanged();
    AppToast.showSuccess(context, 'تم تحديث مرتجع البيع');
  }

  Future<void> _delete() async {
    if (!_allows(PermissionAction.delete)) return;
    final selected = controller.selected;
    if (selected == null) return;
    final confirmed = await AppDialogs.confirm(
      context: context,
      title: 'حذف مرتجع البيع',
      message: 'هل تريد حذف مرتجع البيع رقم ${selected.documentNumber}؟',
      confirmLabel: 'حذف',
      isDanger: true,
    );
    if (!mounted || !confirmed) return;
    final deleted = await _runAction(
      () async {
        await controller.deleteSelected();
        return true;
      },
      failureMessage: 'تعذر حذف مرتجع البيع',
    );
    if (deleted == null || !mounted) return;
    _store!.markDataChanged();
    AppToast.showDanger(context, 'تم حذف مرتجع البيع');
  }

  Future<void> _undo() async {
    await _runAction(
      controller.undo,
      failureMessage: 'تعذر التراجع عن التغييرات',
    );
    if (mounted) AppToast.showWarning(context, 'تم التراجع عن التغييرات');
  }

  Future<void> _navigate(InvoiceEditorNavigation destination) async {
    if (!await _confirmDiscardChanges() || !mounted) return;
    await _runAction(
      () => controller.navigate(destination),
      failureMessage: 'تعذر فتح مرتجع البيع',
    );
  }

  Future<T?> _runAction<T>(
    Future<T> Function() action, {
    required String failureMessage,
  }) async {
    try {
      return await action();
    } on InvoiceMissingReferenceException catch (error) {
      if (mounted) AppToast.showError(context, error.message);
    } on ServiceFailure catch (error) {
      if (mounted) AppToast.showError(context, error.message);
    } on StateError catch (error) {
      if (mounted) {
        AppToast.showError(
          context,
          error.message.isEmpty ? failureMessage : error.message,
        );
      }
    } on FormatException {
      if (mounted) AppToast.showError(context, 'تحقق من القيم المدخلة');
    } catch (_) {
      if (mounted) AppToast.showError(context, failureMessage);
    }
    return null;
  }

  bool get _canOutput =>
      controller.state.status == AppDataStatus.ready &&
      controller.selected != null &&
      !controller.hasChanges &&
      !controller.isBusy &&
      !_documentActionRunning;

  void _print({bool includePrices = true}) {
    unawaited(
      _runDocumentAction(
        includePrices
            ? DocumentOutputAction.print
            : DocumentOutputAction.printWithoutPrices,
      ),
    );
  }

  void _export(DocumentExportFormat format) {
    unawaited(
      _runDocumentAction(
        format == DocumentExportFormat.pdf
            ? DocumentOutputAction.pdf
            : DocumentOutputAction.excel,
      ),
    );
  }

  Future<void> _runDocumentAction(DocumentOutputAction action) async {
    final permission = switch (action) {
      DocumentOutputAction.print ||
      DocumentOutputAction.printWithoutPrices => PermissionAction.print,
      DocumentOutputAction.pdf || DocumentOutputAction.excel =>
        PermissionAction.export,
    };
    if (!_allows(permission) || !_canOutput) return;
    final selectedId = controller.selected!.id;
    setState(() => _documentActionRunning = true);
    try {
      final latest = await _store!.repositories.salesReturns.getById(selectedId);
      if (latest == null) throw StateError('مرتجع البيع المحدد لم يعد موجوداً');
      final request = salesReturnDocumentRequest(latest);
      final result = switch (action) {
        DocumentOutputAction.print =>
          await widget.printService.createPreview(request),
        DocumentOutputAction.printWithoutPrices =>
          await widget.printService.createPreview(
            request,
            includePrices: false,
          ),
        DocumentOutputAction.pdf => await widget.exportService.export(
            request,
            DocumentExportFormat.pdf,
          ),
        DocumentOutputAction.excel => await widget.exportService.export(
            request,
            DocumentExportFormat.excel,
          ),
      };
      if (!mounted || controller.selected?.id != selectedId) return;
      await AppDocumentOutputDialog.show(
        context,
        result: result,
        accentColor: AppModuleColors.sales,
      );
    } on ServiceFailure catch (error) {
      if (mounted) AppToast.showError(context, error.message);
    } on StateError catch (error) {
      if (mounted) AppToast.showError(context, error.message);
    } catch (_) {
      if (mounted) AppToast.showError(context, 'تعذر تجهيز مرتجع البيع');
    } finally {
      if (mounted) setState(() => _documentActionRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editor = _controller;
    if (editor == null) return const SizedBox.shrink();
    final tint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );
    final ready = editor.state.status == AppDataStatus.ready;
    final selected = editor.selected;
    final canCreate = _allows(PermissionAction.create);
    final canUpdate = _allows(PermissionAction.update);
    final canDelete = _allows(PermissionAction.delete);
    final canPrint = _allows(PermissionAction.print);
    final canExport = _allows(PermissionAction.export);
    final selectedIndex = editor.selection.selectedIndex;
    final hasRecords = editor.records.isNotEmpty;
    final canPrevious = hasRecords && selectedIndex != 0;
    final canNext = hasRecords && selectedIndex >= 0;
    final page = PopScope(
      canPop: !editor.hasChanges && !editor.isBusy && !_documentActionRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_attemptBack());
      },
      child: AppScreenShell(
        key: const Key('salesReturnScreen'),
        title: 'مرتجعات البيع',
        subtitle: 'مستند مستقل مرتبط بقائمة البيع الأصلية',
        backgroundColor: tint,
        onBack: editor.isBusy || _documentActionRunning ? null : _attemptBack,
        onSearch: ready && !editor.isBusy ? _showSearch : null,
        onSave: ready &&
                !editor.isBusy &&
                selected == null &&
                canCreate
            ? _save
            : null,
        body: AppLoadingOverlay(
          isLoading: editor.isBusy || _documentActionRunning,
          message: _documentActionRunning
              ? 'جاري تجهيز المستند'
              : 'جاري تنفيذ العملية',
          overlayKey: const Key('salesReturnBusyOverlay'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildEditor(
                tint: tint,
                enabled: ready && !editor.isBusy,
                canCreate: canCreate,
                canUpdate: canUpdate,
                canDelete: canDelete,
                canPrint: canPrint,
                canExport: canExport,
                canPrevious: canPrevious,
                canNext: canNext,
              ),
              if (!ready)
                ColoredBox(
                  color: tint,
                  child: AppDataStateView<List<SalesReturn>>(
                    state: editor.state,
                    dataBuilder: (_, _) => const SizedBox.shrink(),
                    emptyTitle: 'لا توجد مرتجعات بيع',
                    emptyActionLabel: 'مرتجع بيع جديد',
                    onEmptyAction: canCreate ? editor.openEmptyEditor : null,
                    missingReferenceActionLabel: 'إعادة المحاولة',
                    onMissingReferenceAction: () =>
                        unawaited(editor.reload(showLoading: true)),
                    onRetry: () => unawaited(editor.reload(showLoading: true)),
                    loadingStateKey: const Key('salesReturnLoadingState'),
                    emptyStateKey: const Key('salesReturnEmptyState'),
                    missingReferenceStateKey:
                        const Key('salesReturnMissingReferenceState'),
                    errorStateKey: const Key('salesReturnErrorState'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return AppShortcutScope(
      onSearch: ready && !editor.isBusy
          ? () => unawaited(_showSearch())
          : null,
      onSave: ready && !editor.isBusy
          ? () {
              if (editor.selected == null && canCreate) {
                unawaited(_save());
              } else if (editor.selected != null &&
                  editor.hasChanges &&
                  canUpdate) {
                unawaited(_update());
              }
            }
          : null,
      onEscape: () => unawaited(_attemptBack()),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f5): () =>
              unawaited(_refresh()),
        },
        child: Focus(autofocus: true, child: page),
      ),
    );
  }

  Widget _buildEditor({
    required Color tint,
    required bool enabled,
    required bool canCreate,
    required bool canUpdate,
    required bool canDelete,
    required bool canPrint,
    required bool canExport,
    required bool canPrevious,
    required bool canNext,
  }) {
    final source = controller.source;
    final selected = controller.selected;
    final decimalPlaces = controller.currency.decimalPlaces;
    final fieldsEnabled = enabled &&
        (selected == null ? canCreate : canUpdate);
    return ColoredBox(
      color: tint,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _fieldRow([
              AppReadOnlyField(
                fieldKey: const Key('salesReturnNumberField'),
                controller: controller.documentNumberController,
                label: 'رقم المرتجع',
                icon: Icons.assignment_return_rounded,
                accentColor: AppModuleColors.sales,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              AppDateField(
                fieldKey: const Key('salesReturnDateField'),
                label: 'التاريخ',
                value: controller.documentDateTime,
                accentColor: AppModuleColors.sales,
                enabled: fieldsEnabled,
                onChanged: controller.changeDate,
              ),
              AppTimeField(
                fieldKey: const Key('salesReturnTimeField'),
                label: 'الوقت',
                value: TimeOfDay.fromDateTime(controller.documentDateTime),
                accentColor: AppModuleColors.sales,
              ),
              AppAutocompleteField<SalesInvoice>(
                fieldKey: const Key('salesReturnSourceInvoiceField'),
                controller: controller.sourceInvoiceController,
                label: 'قائمة البيع الأصلية',
                icon: Icons.receipt_long_rounded,
                accentColor: AppModuleColors.sales,
                options: controller.sourceInvoices,
                displayStringForOption: controller.sourceLabel,
                searchTermsForOption: (invoice) => [
                  '${invoice.documentNumber}',
                  invoice.customerNameSnapshot,
                  invoice.date.toString(),
                ],
                optionSubtitle: (invoice) =>
                    '${invoice.date} • ${invoice.currency.arabicName}',
                onSelected: (invoice) =>
                    unawaited(_selectSourceInvoice(invoice)),
                onChanged: controller.handleSourceTextChanged,
                enabled: fieldsEnabled && selected == null,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            _fieldRow([
              AppReadOnlyField(
                fieldKey: const Key('salesReturnCustomerField'),
                controller: controller.customerController,
                label: 'اسم الزبون',
                icon: Icons.person_rounded,
                accentColor: AppModuleColors.sales,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              AppReadOnlyField(
                fieldKey: const Key('salesReturnCurrencyField'),
                controller: controller.currencyController,
                label: 'العملة',
                icon: Icons.currency_exchange_rounded,
                accentColor: AppModuleColors.sales,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              AppReadOnlyField(
                fieldKey: const Key('salesReturnExchangeRateField'),
                controller: controller.exchangeRateController,
                label: 'سعر الصرف',
                icon: Icons.currency_exchange_rounded,
                accentColor: AppModuleColors.sales,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              AppTextField(
                fieldKey: const Key('salesReturnNotesField'),
                controller: controller.notesController,
                label: 'الملاحظات',
                icon: Icons.notes_rounded,
                accentColor: AppModuleColors.sales,
                enabled: fieldsEnabled,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.next,
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: source == null
                  ? const AppStatePanel(
                      key: Key('salesReturnSourceEmptyState'),
                      type: AppStateType.empty,
                      title: 'اختر قائمة البيع الأصلية',
                      message:
                          'ستظهر مواد القائمة والكميات المتاحة للمرتجع هنا.',
                    )
                  : SalesReturnLinesTable(
                      lines: controller.lines,
                      currencyCode: controller.currency.code,
                      enabled: fieldsEnabled,
                      onQuantityChanged: controller.handleLineChanged,
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            _fieldRow([
              AppMoneyField(
                fieldKey: const Key('salesReturnRefundField'),
                controller: controller.refundController,
                label: 'المبلغ المسترد الآن',
                icon: Icons.payments_rounded,
                accentColor: AppModuleColors.sales,
                decimalPlaces: decimalPlaces,
                enabled: fieldsEnabled && source != null,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              AppReadOnlyField(
                fieldKey: const Key('salesReturnTotalField'),
                controller: controller.totalController,
                label: 'قيمة المرتجع',
                icon: Icons.calculate_rounded,
                accentColor: AppModuleColors.sales,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              AppReadOnlyField(
                fieldKey: const Key('salesReturnCreditField'),
                controller: controller.creditedController,
                label: 'المضاف إلى رصيد الزبون',
                icon: Icons.account_balance_rounded,
                accentColor: AppModuleColors.sales,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
              AppReadOnlyField(
                fieldKey: const Key('salesReturnBalanceField'),
                controller: controller.balanceController,
                label: 'الرصيد بعد المرتجع',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: AppModuleColors.sales,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            AppActionBar(
              key: const Key('salesReturnActionBar'),
              middle: _SalesReturnOutputButtons(
                onSearch: enabled ? _showSearch : null,
                onPrint: _canOutput && canPrint ? _print : null,
                onPrintWithoutPrices: _canOutput && canPrint
                    ? () => _print(includePrices: false)
                    : null,
                onPdf: _canOutput && canExport
                    ? () => _export(DocumentExportFormat.pdf)
                    : null,
                onExcel: _canOutput && canExport
                    ? () => _export(DocumentExportFormat.excel)
                    : null,
              ),
              firstButtonKey: const Key('salesReturnFirstButton'),
              previousButtonKey: const Key('salesReturnPreviousButton'),
              nextButtonKey: const Key('salesReturnNextButton'),
              lastButtonKey: const Key('salesReturnLastButton'),
              saveButtonKey: const Key('salesReturnSaveButton'),
              updateButtonKey: const Key('salesReturnUpdateButton'),
              undoButtonKey: const Key('salesReturnUndoButton'),
              deleteButtonKey: const Key('salesReturnDeleteButton'),
              accentColor: AppModuleColors.sales,
              onFirst: canPrevious
                  ? () => unawaited(_navigate(InvoiceEditorNavigation.first))
                  : null,
              onPrevious: canPrevious
                  ? () => unawaited(_navigate(InvoiceEditorNavigation.previous))
                  : null,
              onNext: canNext
                  ? () => unawaited(_navigate(InvoiceEditorNavigation.next))
                  : null,
              onLast: canNext
                  ? () => unawaited(_navigate(InvoiceEditorNavigation.last))
                  : null,
              onSave: canCreate &&
                      enabled &&
                      selected == null &&
                      !controller.isBusy
                  ? _save
                  : null,
              onUpdate: canUpdate &&
                      enabled &&
                      selected != null &&
                      controller.hasChanges
                  ? _update
                  : null,
              onUndo: fieldsEnabled && controller.hasChanges ? _undo : null,
              onDelete: canDelete && enabled && selected != null ? _delete : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow(List<Widget> children) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(width: AppSpacing.md),
            Expanded(child: children[index]),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerChanged);
    _controller?.dispose();
    super.dispose();
  }
}

class _SalesReturnOutputButtons extends StatelessWidget {
  const _SalesReturnOutputButtons({
    required this.onSearch,
    required this.onPrint,
    required this.onPrintWithoutPrices,
    required this.onPdf,
    required this.onExcel,
  });

  final VoidCallback? onSearch;
  final VoidCallback? onPrint;
  final VoidCallback? onPrintWithoutPrices;
  final VoidCallback? onPdf;
  final VoidCallback? onExcel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        AppHeaderIconButton(
          key: const Key('salesReturnSearchButton'),
          tooltipKey: const Key('salesReturnSearchTooltip'),
          icon: Icons.search_rounded,
          tooltip: 'بحث',
          onPressed: onSearch,
        ),
        AppHeaderIconButton(
          key: const Key('salesReturnPrintButton'),
          tooltipKey: const Key('salesReturnPrintTooltip'),
          icon: Icons.print_rounded,
          tooltip: 'طباعة',
          onPressed: onPrint,
        ),
        AppHeaderIconButton(
          key: const Key('salesReturnPrintWithoutPricesButton'),
          tooltipKey: const Key('salesReturnPrintWithoutPricesTooltip'),
          icon: Icons.money_off_rounded,
          tooltip: 'طباعة بدون سعر',
          onPressed: onPrintWithoutPrices,
        ),
        AppHeaderIconButton(
          key: const Key('salesReturnPdfButton'),
          tooltipKey: const Key('salesReturnPdfTooltip'),
          icon: Icons.picture_as_pdf_rounded,
          tooltip: 'تصدير PDF',
          onPressed: onPdf,
        ),
        AppHeaderIconButton(
          key: const Key('salesReturnExcelButton'),
          tooltipKey: const Key('salesReturnExcelTooltip'),
          icon: Icons.table_view_rounded,
          tooltip: 'تصدير Excel',
          onPressed: onExcel,
        ),
      ],
    );
  }
}
