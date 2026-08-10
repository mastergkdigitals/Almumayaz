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

  void _printSalesInvoice() {
    unawaited(_runSalesPrint());
  }

  Future<void> _runSalesPrint() async {
    if (_isDocumentActionRunning) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _setSalesState(() => _isDocumentActionRunning = true);
    try {
      final result = await widget.printService.createPreview(
        _salesDocumentRequest(),
      );
      if (!mounted) return;
      await AppDocumentOutputDialog.show(
        context,
        result: result,
        accentColor: AppModuleColors.sales,
      );
    } on ServiceFailure catch (failure) {
      if (mounted) AppToast.showError(context, failure.message);
    } catch (_) {
      if (mounted) {
        AppToast.showError(context, 'تعذر تجهيز قائمة البيع للطباعة');
      }
    } finally {
      if (mounted) {
        _setSalesState(() => _isDocumentActionRunning = false);
      }
    }
  }

  DateTime? _firstSalesTransactionDate(String customerName) {
    DateTime? firstDate;
    for (final invoice in _salesInvoices) {
      if (invoice.customerName != customerName) continue;
      if (firstDate == null || invoice.dateTime.isBefore(firstDate)) {
        firstDate = invoice.dateTime;
      }
    }
    return firstDate;
  }

  List<AppStatementReportEntry> _salesStatementEntries(
    String customerName,
    AppStatementOptions options,
  ) {
    final fromDate = DateTime(
      options.fromDate.year,
      options.fromDate.month,
      options.fromDate.day,
    );
    final toDateExclusive = DateTime(
      options.toDate.year,
      options.toDate.month,
      options.toDate.day + 1,
    );
    final invoices = _salesInvoices.where((invoice) {
      return invoice.customerName == customerName &&
          invoice.currency == options.currencyCode &&
          !invoice.dateTime.isBefore(fromDate) &&
          invoice.dateTime.isBefore(toDateExclusive);
    }).toList()
      ..sort((left, right) => left.dateTime.compareTo(right.dateTime));

    return [
      for (final invoice in invoices)
        AppStatementReportEntry(
          date: invoice.dateTime,
          balance: AppFormatters.parseNumber(invoice.currentBalance) ?? 0,
          credit: AppFormatters.parseNumber(invoice.received) ?? 0,
          debit: AppFormatters.parseNumber(invoice.total) ?? 0,
          type: 'قائمة بيع',
          quantity: invoice.items.fold<int>(
            0,
            (total, item) => total + item.quantityValue,
          ),
          details: 'قائمة بيع رقم ${invoice.id} • ${invoice.saleType}',
        ),
    ];
  }

  void _openInstallments() {
    unawaited(_showInstallments());
  }

  Future<void> _showInstallments() async {
    if (_saleType != 'أقساط') {
      AppToast.showWarning(context, 'جدول الأقساط متاح للبيع بالأقساط فقط');
      return;
    }
    final remaining =
        AppFormatters.parseNumber(_remainingIqdController.text) ?? 0;
    if (remaining <= 0) {
      AppToast.showInfo(context, 'لا يوجد مبلغ متبقٍ لإنشاء جدول أقساط');
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
  }

  Future<void> _showSalesStatement() async {
    final customerName = _customerNameController.text.trim();
    final displayName =
        customerName.isEmpty ? 'زبون غير محدد' : customerName;
    final options = await AppStatementOptionsDialog.show(
      context,
      partyName: displayName,
      partyLabel: 'اسم الزبون',
      accentColor: AppModuleColors.sales,
      firstTransactionDate: _firstSalesTransactionDate(displayName),
    );
    if (!mounted || options == null) return;

    await AppStatementReportDialog.show(
      context,
      partyName: displayName,
      options: options,
      entries: _salesStatementEntries(displayName, options),
      accentColor: AppModuleColors.sales,
      printService: widget.printService,
      exportService: widget.exportService,
    );
  }

  void _openEmptyEditor() {
    _setSalesState(() {
      _invoiceState = AppDataState.ready(_salesInvoices);
      _setNewForm();
    });
  }

}
