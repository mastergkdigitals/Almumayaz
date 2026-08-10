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
    unawaited(_runPurchasePrint(includePrices: includePrices));
  }

  Future<void> _runPurchasePrint({required bool includePrices}) async {
    if (_isDocumentActionRunning) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _setPurchaseState(() => _isDocumentActionRunning = true);
    try {
      final result = await widget.printService.createPreview(
        _purchaseDocumentRequest(),
        includePrices: includePrices,
      );
      if (!mounted) return;
      await AppDocumentOutputDialog.show(
        context,
        result: result,
        accentColor: AppModuleColors.purchases,
      );
    } on ServiceFailure catch (failure) {
      if (mounted) AppToast.showError(context, failure.message);
    } catch (_) {
      if (mounted) {
        AppToast.showError(context, 'تعذر تجهيز قائمة الشراء للطباعة');
      }
    } finally {
      if (mounted) _setPurchaseState(() => _isDocumentActionRunning = false);
    }
  }

  DateTime? _firstPurchaseTransactionDate(String supplierName) {
    DateTime? firstDate;
    for (final invoice in _purchaseInvoices) {
      if (invoice.supplierName != supplierName) continue;
      if (firstDate == null || invoice.dateTime.isBefore(firstDate)) {
        firstDate = invoice.dateTime;
      }
    }
    return firstDate;
  }

  num _purchaseInvoiceTotal(_DemoPurchaseInvoice invoice) {
    final lineTotal = invoice.items.fold<num>(
      0,
      (total, item) => total + item.totalValue,
    );
    final expenses = AppFormatters.parseNumber(invoice.expenses) ?? 0;
    final discount =
        AppFormatters.parseNumber(invoice.invoiceDiscount) ?? 0;
    return lineTotal + expenses - discount;
  }

  List<AppStatementReportEntry> _purchaseStatementEntries(
    String supplierName,
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
    final invoices = _purchaseInvoices.where((invoice) {
      return invoice.supplierName == supplierName &&
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
          credit: _purchaseInvoiceTotal(invoice),
          debit: AppFormatters.parseNumber(invoice.paid) ?? 0,
          type: 'قائمة شراء',
          quantity: invoice.items.fold<int>(
            0,
            (total, item) => total + item.quantityValue,
          ),
          details:
              'قائمة شراء رقم ${invoice.id} • ${invoice.purchaseType}',
        ),
    ];
  }

  Future<void> _showPurchaseStatement() async {
    final supplierName = _supplierNameController.text.trim();
    final displayName =
        supplierName.isEmpty ? 'مجهز غير محدد' : supplierName;
    final options = await AppStatementOptionsDialog.show(
      context,
      partyName: displayName,
      partyLabel: 'اسم المجهز',
      accentColor: AppModuleColors.purchases,
      firstTransactionDate: _firstPurchaseTransactionDate(displayName),
    );
    if (!mounted || options == null) return;

    await AppStatementReportDialog.show(
      context,
      partyName: displayName,
      options: options,
      entries: _purchaseStatementEntries(displayName, options),
      accentColor: AppModuleColors.purchases,
      printService: widget.printService,
      exportService: widget.exportService,
    );
  }
}
