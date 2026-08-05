part of 'sales_screen.dart';

extension _SalesScreenViewPart on _SalesScreenState {
  Widget _buildSalesScreen(BuildContext context) {
    final hasSelectedInvoice = _selectedInvoice != null;
    final selectedInvoiceIndex = _selectedInvoiceIndex;
    final hasInvoices = _salesInvoices.isNotEmpty;
    final canMoveToFirstOrPrevious =
        hasInvoices && selectedInvoiceIndex != 0;
    final canMoveToNextOrLast =
        hasInvoices && selectedInvoiceIndex >= 0;
    final currencyName = _currency == 'USD' ? 'دولار' : 'دينار';
    final isEditorReady = _invoiceState.status == AppDataStatus.ready;
    final tint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );

    return PopScope(
      canPop: !_hasUnsavedChanges && !_isRepositoryBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isRepositoryBusy) _attemptBack();
      },
      child: AppScreenShell(
        key: const Key('salesScreen'),
        title: 'المبيعات',
        backgroundColor: tint,
        onBack: _attemptBack,
        onSearch: !isEditorReady || _isRepositoryBusy
            ? null
            : _showSalesSearch,
        onSave: !isEditorReady || _isRepositoryBusy
            ? null
            : hasSelectedInvoice
            ? _hasUnsavedChanges
                ? _update
                : null
            : _save,
        body: Stack(
          fit: StackFit.expand,
          children: [
        ColoredBox(
          key: const Key('salesTintBackground'),
          color: tint,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
              _SalesFieldRow(
                children: [
                  AppReadOnlyField(
                    fieldKey: const Key('salesInvoiceNumberField'),
                    controller: _invoiceNumberController,
                    label: 'رقم القائمة',
                    icon: Icons.receipt_long_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppDateField(
                    fieldKey: const Key('salesDateField'),
                    label: 'التاريخ',
                    value: _invoiceDateTime,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    onChanged: _changeDate,
                  ),
                  AppTimeField(
                    fieldKey: const Key('salesTimeField'),
                    label: 'الوقت',
                    value: TimeOfDay.fromDateTime(_invoiceDateTime),
                    accentColor: AppModuleColors.sales,
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('salesWarehouseField'),
                    label: 'المخزن',
                    icon: Icons.warehouse_rounded,
                    accentColor: AppModuleColors.sales,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _warehouse,
                    options: _warehouseOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changeWarehouse(value);
                    },
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('salesTypeField'),
                    label: 'نوع البيع',
                    icon: Icons.point_of_sale_rounded,
                    accentColor: AppModuleColors.sales,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _saleType,
                    options: _salesTypeOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changeSaleType(value);
                    },
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('salesCurrencyField'),
                    label: 'العملة',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: AppModuleColors.sales,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _currency,
                    options: _salesCurrencyOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changeCurrency(value);
                    },
                  ),
                  AppMoneyField(
                    fieldKey: const Key('salesExchangeRateField'),
                    controller: _exchangeRateController,
                    label: 'سعر الصرف',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decimalPlaces: 4,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SalesFieldRow(
                children: [
                  AppAutocompleteField<String>(
                    fieldKey: const Key('salesCustomerNameField'),
                    controller: _customerNameController,
                    label: 'اسم الزبون',
                    icon: Icons.person_rounded,
                    accentColor: AppModuleColors.sales,
                    options: _customerOptions,
                    displayStringForOption: (value) => value,
                    onSelected: (_) {},
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppTextField(
                    fieldKey: const Key('salesNotesField'),
                    controller: _notesController,
                    label: 'الملاحظات',
                    icon: Icons.notes_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: AppSalesInvoiceTableTemplate(
                  key: const Key('salesItemsTable'),
                  initialRows: _activeItems,
                  dataVersion: _tableDataVersion,
                  summaryQuantity: _summaryQuantity,
                  summaryDiscount: _summaryDiscount,
                  summaryTotal: _summaryTotal,
                  currencyCode: _currency,
                  itemOptions: _itemOptions,
                  onRowsChanged: _changeItems,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SalesFieldRow(
                children: [
                  AppTextField(
                    fieldKey: const Key('salesDriverNameField'),
                    controller: _driverNameController,
                    label: 'اسم السائق',
                    icon: Icons.local_shipping_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.next,
                  ),
                  _SalesMoneyField(
                    fieldKey: const Key('salesInvoiceDiscountField'),
                    controller: _invoiceDiscountController,
                    label: 'خصم القائمة',
                    icon: Icons.discount_rounded,
                    decimalPlaces: _currency == 'USD' ? 2 : 0,
                    onChanged: _changeInvoiceDiscount,
                  ),
                  _SalesMoneyField(
                    fieldKey: const Key('salesDiscountPercentageField'),
                    controller: _discountPercentageController,
                    label: 'نسبة الخصم',
                    icon: Icons.percent_rounded,
                    decimalPlaces: 2,
                    onChanged: _changeDiscountPercentage,
                  ),
                  _SalesMoneyField(
                    fieldKey: const Key('salesReceivedField'),
                    controller: _receivedController,
                    label: 'المقبوض',
                    icon: Icons.payments_rounded,
                    decimalPlaces: _currency == 'USD' ? 2 : 0,
                    enabled: _saleType != 'نقدي',
                    onChanged: _changeReceived,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('salesTotalIqdField'),
                    controller: _totalIqdController,
                    label: 'المجموع $currencyName',
                    icon: Icons.calculate_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('salesRemainingIqdField'),
                    controller: _remainingIqdController,
                    label: 'المتبقي $currencyName',
                    icon: Icons.pending_actions_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('salesCurrentBalanceIqdField'),
                    controller: _currentBalanceIqdController,
                    label: 'الرصيد الحالي $currencyName',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppModuleColors.sales,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppActionBar(
                key: const Key('salesActionBar'),
                middle: _SalesInvoiceButtons(
                  onSearch: !isEditorReady || _isRepositoryBusy
                      ? null
                      : _showSalesSearch,
                  onPrint: !isEditorReady || _isDocumentActionRunning
                      ? null
                      : _printSalesInvoice,
                  onInstallments:
                      isEditorReady && _saleType == 'أقساط'
                          ? _openInstallments
                          : null,
                  onStatement:
                      isEditorReady ? _showSalesStatement : null,
                ),
                firstButtonKey: const Key('salesFirstButton'),
                previousButtonKey: const Key('salesPreviousButton'),
                nextButtonKey: const Key('salesNextButton'),
                lastButtonKey: const Key('salesLastButton'),
                saveButtonKey: const Key('salesSaveButton'),
                updateButtonKey: const Key('salesUpdateButton'),
                undoButtonKey: const Key('salesUndoButton'),
                deleteButtonKey: const Key('salesDeleteButton'),
                accentColor: AppModuleColors.sales,
                onFirst: canMoveToFirstOrPrevious
                    ? () => _navigate(_SalesNavigation.first)
                    : null,
                onPrevious: canMoveToFirstOrPrevious
                    ? () => _navigate(_SalesNavigation.previous)
                    : null,
                onNext: canMoveToNextOrLast
                    ? () => _navigate(_SalesNavigation.next)
                    : null,
                onLast: canMoveToNextOrLast
                    ? () => _navigate(_SalesNavigation.last)
                    : null,
                onSave: !isEditorReady ||
                        _isRepositoryBusy ||
                        hasSelectedInvoice
                    ? null
                    : _save,
                onUpdate: isEditorReady &&
                        hasSelectedInvoice &&
                        _hasUnsavedChanges &&
                        !_isRepositoryBusy
                    ? _update
                    : null,
                onUndo:
                    isEditorReady && _hasUnsavedChanges ? _undo : null,
                onDelete: isEditorReady &&
                        hasSelectedInvoice &&
                        !_isRepositoryBusy
                    ? _delete
                    : null,
              ),
              ],
            ),
          ),
        ),
            if (_invoiceState.status != AppDataStatus.ready)
              ColoredBox(
                color: tint,
                child: AppDataStateView<List<_DemoSalesInvoice>>(
                  state: _invoiceState,
                  dataBuilder: (_, __) => const SizedBox.shrink(),
                  emptyTitle: 'لا توجد قوائم بيع',
                  emptyActionLabel: 'قائمة بيع جديدة',
                  onEmptyAction: _openEmptyEditor,
                  missingReferenceActionLabel: 'إعادة المحاولة',
                  onMissingReferenceAction: () => unawaited(_loadData()),
                  onRetry: () => unawaited(_loadData()),
                  loadingStateKey: const Key('salesLoadingState'),
                  emptyStateKey: const Key('salesEmptyState'),
                  missingReferenceStateKey:
                      const Key('salesMissingReferenceState'),
                  errorStateKey: const Key('salesErrorState'),
                ),
              ),
            if (_isRepositoryBusy)
              AbsorbPointer(
                child: ColoredBox(
                  key: const Key('salesBusyOverlay'),
                  color: AppColors.textPrimary.withAlpha(20),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
