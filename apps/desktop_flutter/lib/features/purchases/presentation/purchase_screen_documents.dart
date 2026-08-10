part of 'purchase_screen.dart';

extension _PurchaseDocumentState on _PurchaseScreenState {
  DocumentOutputRequest _purchaseDocumentRequest() {
    final supplierName = _supplierNameController.text.trim();
    return DocumentOutputRequest(
      title: 'قائمة شراء رقم ${_invoiceNumberController.text}',
      subtitle: supplierName.isEmpty ? 'مجهز غير محدد' : supplierName,
      fileNameBase: 'قائمة شراء ${_invoiceNumberController.text}',
      fields: [
        DocumentField(
          label: 'التاريخ',
          value: AppFormatters.date(_invoiceDateTime),
        ),
        DocumentField(
          label: 'الوقت',
          value: AppFormatters.time(TimeOfDay.fromDateTime(_invoiceDateTime)),
        ),
        DocumentField(label: 'المخزن', value: _warehouse),
        DocumentField(label: 'نوع الشراء', value: _purchaseType),
        DocumentField(label: 'نوع الدفع', value: _paymentType),
        DocumentField(
          label: 'العملة',
          value: AppFormatters.currency(_currency),
        ),
        DocumentField(
          label: 'المصاريف',
          value: _expensesController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'خصم القائمة',
          value: _invoiceDiscountController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المجموع',
          value: _totalController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المدفوع',
          value: _paidController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المتبقي',
          value: _remainingController.text,
          isPrice: true,
        ),
      ],
      columns: const [
        DocumentColumn(label: 'الرمز'),
        DocumentColumn(label: 'المادة'),
        DocumentColumn(label: 'المخزن'),
        DocumentColumn(label: 'الكمية'),
        DocumentColumn(label: 'الحاوية'),
        DocumentColumn(label: 'سعر الشراء', isPrice: true),
        DocumentColumn(label: 'الخصم', isPrice: true),
        DocumentColumn(label: 'السعر بعد الخصم', isPrice: true),
        DocumentColumn(label: 'المجموع', isPrice: true),
        DocumentColumn(label: 'الكلفة', isPrice: true),
        DocumentColumn(label: 'إجمالي الكلفة', isPrice: true),
        DocumentColumn(label: 'سعر البيع', isPrice: true),
      ],
      rows: [
        for (final item in _activeItems.where((item) => !item.isEmpty))
          [
            item.code,
            item.name,
            item.warehouse,
            item.quantity,
            item.container,
            item.purchasePrice,
            item.discount.isEmpty ? '0' : item.discount,
            item.priceAfterDiscount,
            item.total,
            item.cost,
            item.totalCost,
            item.salePrice,
          ],
      ],
    );
  }

  void _printPurchaseInvoice({bool includePrices = true}) {
    unawaited(
      _runPurchaseDocumentAction(
        includePrices
            ? DocumentOutputAction.print
            : DocumentOutputAction.printWithoutPrices,
      ),
    );
  }

  void _exportPurchaseInvoice(DocumentExportFormat format) {
    unawaited(
      _runPurchaseDocumentAction(
        format == DocumentExportFormat.pdf
            ? DocumentOutputAction.pdf
            : DocumentOutputAction.excel,
      ),
    );
  }

  bool get _canUseSelectedPurchaseInvoiceForOutput =>
      _invoiceState.status == AppDataStatus.ready &&
      _selectedInvoice != null &&
      !_hasUnsavedChanges &&
      !_isRepositoryBusy &&
      !_isDocumentActionRunning;

  Future<bool> _reloadSelectedPurchaseInvoiceForOutput() async {
    final selected = _selectedInvoice;
    final coordinator = _coordinator;
    if (selected == null || coordinator == null) return false;

    final selectedEntityId = selected.source.id;
    final state = await coordinator.load();
    if (!mounted) return false;
    final currentSelection = _selectedInvoice;
    if (!_isDocumentActionRunning ||
        currentSelection == null ||
        currentSelection.source.id != selectedEntityId ||
        _hasUnsavedChanges ||
        _isRepositoryBusy) {
      return false;
    }

    final records = state.data;
    if (state.status != AppDataStatus.ready || records == null) {
      final failureState = state.status == AppDataStatus.empty
          ? const AppDataState<List<_DemoPurchaseInvoice>>.missingReference(
              'قائمة الشراء المحددة لم تعد موجودة.',
            )
          : state;
      _setPurchaseState(() {
        _invoiceState = failureState;
        if (state.status == AppDataStatus.empty) {
          _purchaseInvoices.clear();
          _selectedInvoice = null;
        }
      });
      AppToast.showError(
        context,
        failureState.message ?? 'تعذر تحديث قائمة الشراء',
      );
      return false;
    }

    _DemoPurchaseInvoice? refreshed;
    for (final candidate in records) {
      if (candidate.source.id == selectedEntityId) {
        refreshed = candidate;
        break;
      }
    }
    final refreshedInvoice = refreshed;
    if (refreshedInvoice == null) {
      const message = 'قائمة الشراء المحددة لم تعد موجودة.';
      _setPurchaseState(() {
        _purchaseInvoices
          ..clear()
          ..addAll(records);
        _selectedInvoice = null;
        _invoiceState = const AppDataState.missingReference(message);
      });
      AppToast.showError(context, message);
      return false;
    }

    _setPurchaseState(() {
      _purchaseInvoices
        ..clear()
        ..addAll(records);
      _invoiceState = AppDataState.ready(_purchaseInvoices);
      _loadInvoice(refreshedInvoice);
    });
    return true;
  }

  Future<void> _runPurchaseDocumentAction(
    DocumentOutputAction action,
  ) async {
    final requiredPermission = switch (action) {
      DocumentOutputAction.print ||
      DocumentOutputAction.printWithoutPrices => PermissionAction.print,
      DocumentOutputAction.pdf || DocumentOutputAction.excel =>
        PermissionAction.export,
    };
    if (!_allowsPurchaseAction(requiredPermission)) return;
    if (!_canUseSelectedPurchaseInvoiceForOutput) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _setPurchaseState(() => _isDocumentActionRunning = true);
    try {
      if (!await _reloadSelectedPurchaseInvoiceForOutput() || !mounted) {
        return;
      }
      final selectedEntityId = _selectedInvoice!.source.id;
      final request = _purchaseDocumentRequest();
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
      if (!mounted ||
          !_isDocumentActionRunning ||
          _invoiceState.status != AppDataStatus.ready ||
          _selectedInvoice?.source.id != selectedEntityId ||
          _hasUnsavedChanges ||
          _isRepositoryBusy) {
        return;
      }
      await AppDocumentOutputDialog.show(
        context,
        result: result,
        accentColor: AppModuleColors.purchases,
      );
    } on ServiceFailure catch (failure) {
      if (mounted) AppToast.showError(context, failure.message);
    } catch (_) {
      if (mounted) {
        final message = switch (action) {
          DocumentOutputAction.print =>
            'تعذر تجهيز قائمة الشراء للطباعة',
          DocumentOutputAction.printWithoutPrices =>
            'تعذر تجهيز قائمة الشراء للطباعة بدون أسعار',
          DocumentOutputAction.pdf =>
            'تعذر تصدير قائمة الشراء بصيغة PDF',
          DocumentOutputAction.excel =>
            'تعذر تصدير قائمة الشراء بصيغة Excel',
        };
        AppToast.showError(context, message);
      }
    } finally {
      if (mounted) _setPurchaseState(() => _isDocumentActionRunning = false);
    }
  }

  DateTime? _firstPurchaseTransactionDate(EntityId supplierId) {
    DateTime? firstDate;
    for (final invoice in _purchaseInvoices) {
      if (invoice.source.supplierId != supplierId) continue;
      if (firstDate == null || invoice.dateTime.isBefore(firstDate)) {
        firstDate = invoice.dateTime;
      }
    }
    return firstDate;
  }

  List<AppStatementReportEntry> _statementReportEntries(
    PartyStatementResult result,
  ) {
    return [
      for (final entry in result.entries)
        AppStatementReportEntry(
          date: entry.date,
          balance: entry.balance.majorUnits,
          credit: entry.credit.majorUnits,
          debit: entry.debit.majorUnits,
          type: entry.type.label,
          quantity: entry.quantity,
          details: entry.details,
        ),
    ];
  }

  Future<void> _showPurchaseStatement() async {
    if (!_canUseSelectedPurchaseInvoiceForOutput) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _setPurchaseState(() => _isDocumentActionRunning = true);
    try {
      if (!await _reloadSelectedPurchaseInvoiceForOutput() || !mounted) {
        return;
      }
      final selectedInvoice = _selectedInvoice;
      if (selectedInvoice == null) return;
      final supplierId = selectedInvoice.source.supplierId;
      final supplierName = _supplierNameController.text.trim();
      final displayName =
          supplierName.isEmpty ? 'مجهز غير محدد' : supplierName;
      final options = await AppStatementOptionsDialog.show(
        context,
        partyName: displayName,
        partyLabel: 'اسم المجهز',
        accentColor: AppModuleColors.purchases,
        firstTransactionDate: _firstPurchaseTransactionDate(supplierId),
      );
      if (!mounted || options == null) return;

      final result = await _statementService.load(
        PartyStatementQuery(
          partyId: supplierId,
          fromDate: BusinessDate.fromDateTime(options.fromDate),
          toDate: BusinessDate.fromDateTime(options.toDate),
          currency: AppCurrency.parse(options.currencyCode),
        ),
      );
      if (!mounted) return;
      await AppStatementReportDialog.show(
        context,
        partyName: displayName,
        options: options,
        openingBalance: result.openingBalance.majorUnits,
        entries: _statementReportEntries(result),
        accentColor: AppModuleColors.purchases,
        printService: widget.printService,
        exportService: widget.exportService,
        allowPrint: _allowsPurchaseAction(PermissionAction.print),
        allowExport: _allowsPurchaseAction(PermissionAction.export),
      );
    } on ServiceFailure catch (failure) {
      if (mounted) AppToast.showError(context, failure.message);
    } catch (_) {
      if (mounted) {
        AppToast.showError(
          context,
          'تعذر تحميل كشف حساب المجهز. حاول مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        _setPurchaseState(() => _isDocumentActionRunning = false);
      }
    }
  }
}
