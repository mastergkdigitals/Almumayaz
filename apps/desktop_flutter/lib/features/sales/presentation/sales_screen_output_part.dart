part of 'sales_screen.dart';

extension _SalesScreenOutputPart on _SalesScreenState {
  Future<void> _showSalesSearch() async {
    final result = await AppRecordSearchDialog.show<String>(
      context,
      title: 'بحث قوائم البيع',
      subtitle: 'ابحث عن قائمة بيع محفوظة ثم اخترها',
      searchLabel: 'بحث في قوائم البيع',
      hint: 'رقم القائمة أو اسم الزبون أو اسم المادة',
      accentColor: AppModuleColors.sales,
      records: _salesSearchRecords,
      emptyTitle: 'لا توجد قوائم بيع محفوظة',
      noResultsTitle: 'لا توجد قوائم بيع مطابقة',
      dialogKey: const Key('salesRecordSearchDialog'),
      searchFieldKey: const Key('salesRecordSearchField'),
      resultKeyPrefix: 'salesRecordSearchResult',
    );

    if (!mounted || result == null) return;
    final invoice = _salesInvoices.firstWhere(
      (candidate) => candidate.id == result,
    );
    if (!await _confirmDiscardChanges() || !mounted) return;
    _setSalesState(() => _loadInvoice(invoice));
    AppToast.showInfo(context, 'تم اختيار قائمة البيع رقم $result');
  }

  DocumentOutputRequest _salesDocumentRequest() {
    final customerName = _customerNameController.text.trim();
    final currencyName = AppFormatters.currency(_currency);
    return DocumentOutputRequest(
      title: 'قائمة بيع رقم ${_invoiceNumberController.text}',
      subtitle: customerName.isEmpty ? 'زبون غير محدد' : customerName,
      fileNameBase: 'قائمة بيع ${_invoiceNumberController.text}',
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
        DocumentField(label: 'نوع البيع', value: _saleType),
        DocumentField(label: 'العملة', value: currencyName),
        DocumentField(
          label: 'خصم القائمة',
          value: _invoiceDiscountController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المقبوض',
          value: _receivedController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المجموع',
          value: _totalIqdController.text,
          isPrice: true,
        ),
        DocumentField(
          label: 'المتبقي',
          value: _remainingIqdController.text,
          isPrice: true,
        ),
      ],
      columns: const [
        DocumentColumn(label: 'الرمز'),
        DocumentColumn(label: 'المادة'),
        DocumentColumn(label: 'المخزن'),
        DocumentColumn(label: 'الكمية'),
        DocumentColumn(label: 'سعر البيع', isPrice: true),
        DocumentColumn(label: 'الخصم', isPrice: true),
        DocumentColumn(label: 'السعر بعد الخصم', isPrice: true),
        DocumentColumn(label: 'المجموع', isPrice: true),
      ],
      rows: [
        for (final item in _activeItems.where((item) => !item.isEmpty))
          [
            item.code,
            item.name,
            item.warehouse,
            item.quantity,
            item.salePrice,
            item.discount.isEmpty ? '0' : item.discount,
            item.priceAfterDiscount,
            item.total,
          ],
      ],
    );
  }

  void _printSalesInvoice({bool includePrices = true}) {
    unawaited(
      _runSalesDocumentAction(
        includePrices
            ? DocumentOutputAction.print
            : DocumentOutputAction.printWithoutPrices,
      ),
    );
  }

  void _exportSalesInvoice(DocumentExportFormat format) {
    unawaited(
      _runSalesDocumentAction(
        format == DocumentExportFormat.pdf
            ? DocumentOutputAction.pdf
            : DocumentOutputAction.excel,
      ),
    );
  }

  bool get _canUseSelectedSalesInvoiceForOutput =>
      _invoiceState.status == AppDataStatus.ready &&
      _selectedInvoice != null &&
      !_hasUnsavedChanges &&
      !_isRepositoryBusy &&
      !_isDocumentActionRunning;

  Future<bool> _reloadSelectedSalesInvoiceForOutput() async {
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
          ? const AppDataState<List<_DemoSalesInvoice>>.missingReference(
              'قائمة البيع المحددة لم تعد موجودة.',
            )
          : state;
      _setSalesState(() {
        _invoiceState = failureState;
        if (state.status == AppDataStatus.empty) {
          _salesInvoices.clear();
          _selectedInvoice = null;
        }
      });
      AppToast.showError(
        context,
        failureState.message ?? 'تعذر تحديث قائمة البيع',
      );
      return false;
    }

    _DemoSalesInvoice? refreshed;
    for (final candidate in records) {
      if (candidate.source.id == selectedEntityId) {
        refreshed = candidate;
        break;
      }
    }
    final refreshedInvoice = refreshed;
    if (refreshedInvoice == null) {
      const message = 'قائمة البيع المحددة لم تعد موجودة.';
      _setSalesState(() {
        _salesInvoices
          ..clear()
          ..addAll(records);
        _selectedInvoice = null;
        _invoiceState = const AppDataState.missingReference(message);
      });
      AppToast.showError(context, message);
      return false;
    }

    _setSalesState(() {
      _salesInvoices
        ..clear()
        ..addAll(records);
      _invoiceState = AppDataState.ready(_salesInvoices);
      _loadInvoice(refreshedInvoice);
    });
    return true;
  }

  Future<void> _runSalesDocumentAction(
    DocumentOutputAction action,
  ) async {
    if (!_canUseSelectedSalesInvoiceForOutput) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _setSalesState(() => _isDocumentActionRunning = true);
    try {
      if (!await _reloadSelectedSalesInvoiceForOutput() || !mounted) return;
      final selectedEntityId = _selectedInvoice!.source.id;
      final request = _salesDocumentRequest();
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
        accentColor: AppModuleColors.sales,
      );
    } on ServiceFailure catch (failure) {
      if (mounted) AppToast.showError(context, failure.message);
    } catch (_) {
      if (mounted) {
        final message = switch (action) {
          DocumentOutputAction.print =>
            'تعذر تجهيز قائمة البيع للطباعة',
          DocumentOutputAction.printWithoutPrices =>
            'تعذر تجهيز قائمة البيع للطباعة بدون أسعار',
          DocumentOutputAction.pdf =>
            'تعذر تصدير قائمة البيع بصيغة PDF',
          DocumentOutputAction.excel =>
            'تعذر تصدير قائمة البيع بصيغة Excel',
        };
        AppToast.showError(context, message);
      }
    } finally {
      if (mounted) {
        _setSalesState(() => _isDocumentActionRunning = false);
      }
    }
  }

  DateTime? _firstSalesTransactionDate(EntityId customerId) {
    DateTime? firstDate;
    for (final invoice in _salesInvoices) {
      if (invoice.source.customerId != customerId) continue;
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

  void _openInstallments() {
    unawaited(_showInstallments());
  }

  Future<void> _showInstallments() async {
    if (!_canUseSelectedSalesInvoiceForOutput) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _setSalesState(() => _isDocumentActionRunning = true);
    try {
      if (!await _reloadSelectedSalesInvoiceForOutput() || !mounted) return;
      if (_saleType != 'أقساط') {
        AppToast.showWarning(
          context,
          'جدول الأقساط متاح للبيع بالأقساط فقط',
        );
        return;
      }
      final remaining =
          AppFormatters.parseNumber(_remainingIqdController.text) ?? 0;
      if (remaining <= 0) {
        AppToast.showInfo(
          context,
          'لا يوجد مبلغ متبقٍ لإنشاء جدول أقساط',
        );
        return;
      }

      final schedule = InstallmentScheduleBuilder.build(
        remaining: remaining,
        currencyCode: _currency,
        invoiceDate: _invoiceDateTime,
      );
      final entries = <AppInstallmentScheduleEntry>[
        for (final installment in schedule)
          AppInstallmentScheduleEntry(
            number: installment.number,
            dueDate: installment.dueDate,
            amount: installment.amount,
            status: 'غير مسدد',
          ),
      ];
      final customerName = _customerNameController.text.trim();
      await AppInstallmentScheduleDialog.show(
        context,
        invoiceNumber: _invoiceNumberController.text,
        customerName:
            customerName.isEmpty ? 'زبون غير محدد' : customerName,
        currencyCode: _currency,
        entries: entries,
        accentColor: AppModuleColors.sales,
      );
    } finally {
      if (mounted) {
        _setSalesState(() => _isDocumentActionRunning = false);
      }
    }
  }

  Future<void> _showSalesStatement() async {
    if (!_canUseSelectedSalesInvoiceForOutput) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _setSalesState(() => _isDocumentActionRunning = true);
    try {
      if (!await _reloadSelectedSalesInvoiceForOutput() || !mounted) return;
      final selectedInvoice = _selectedInvoice;
      if (selectedInvoice == null) return;
      final customerId = selectedInvoice.source.customerId;
      final customerName = _customerNameController.text.trim();
      final displayName =
          customerName.isEmpty ? 'زبون غير محدد' : customerName;
      final options = await AppStatementOptionsDialog.show(
        context,
        partyName: displayName,
        partyLabel: 'اسم الزبون',
        accentColor: AppModuleColors.sales,
        firstTransactionDate: _firstSalesTransactionDate(customerId),
      );
      if (!mounted || options == null) return;

      final result = await _statementService.load(
        PartyStatementQuery(
          partyId: customerId,
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
        accentColor: AppModuleColors.sales,
        printService: widget.printService,
        exportService: widget.exportService,
      );
    } on ServiceFailure catch (failure) {
      if (mounted) AppToast.showError(context, failure.message);
    } catch (_) {
      if (mounted) {
        AppToast.showError(
          context,
          'تعذر تحميل كشف حساب الزبون. حاول مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        _setSalesState(() => _isDocumentActionRunning = false);
      }
    }
  }

  void _openEmptyEditor() {
    _setSalesState(() {
      _invoiceState = AppDataState.ready(_salesInvoices);
      _setNewForm();
    });
  }

}
