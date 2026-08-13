part of 'sales_screen.dart';

extension _SalesScreenViewPart on _SalesScreenState {
  Widget _buildSalesScreen(BuildContext context) {
    final hasSelectedInvoice = _selectedInvoice != null;
    final selectedInvoiceIndex = _coordinator?.selection.selectedIndex ?? -1;
    final hasInvoices = _salesInvoices.isNotEmpty;
    final canMoveToFirstOrPrevious =
        hasInvoices && selectedInvoiceIndex != 0;
    final canMoveToNextOrLast =
        hasInvoices && selectedInvoiceIndex >= 0;
    final currencyName = _currency == 'USD' ? 'دولار' : 'دينار';
    final isEditorReady = _invoiceState.status == AppDataStatus.ready;
    final canCreate = _allowsSalesAction(PermissionAction.create);
    final canUpdate = _allowsSalesAction(PermissionAction.update);
    final canDelete = _allowsSalesAction(PermissionAction.delete);
    final canPrint = _allowsSalesAction(PermissionAction.print);
    final canExport = _allowsSalesAction(PermissionAction.export);
    final canUseSavedInvoiceOutput =
        _canUseSelectedSalesInvoiceForOutput;
    final tint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );

    return PopScope(
      canPop: !_hasUnsavedChanges &&
          !_isRepositoryBusy &&
          !_isDocumentActionRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop &&
            !_isRepositoryBusy &&
            !_isDocumentActionRunning) {
          _attemptBack();
        }
      },
      child: AppScreenShell(
        key: const Key('salesScreen'),
        title: 'المبيعات',
        backgroundColor: tint,
        onBack: _isDocumentActionRunning ? null : _attemptBack,
        onSearch: !isEditorReady ||
                _isRepositoryBusy ||
                _isDocumentActionRunning
            ? null
            : _showSalesSearch,
        onSave: !isEditorReady ||
                _isRepositoryBusy ||
                _isDocumentActionRunning
            ? null
            : hasSelectedInvoice
            ? _hasUnsavedChanges && canUpdate
                ? _update
                : null
            : canCreate
                ? _save
                : null,
        body: ExcludeFocus(
          excluding: _isDocumentActionRunning,
          child: AbsorbPointer(
            key: const Key('salesDocumentActionAbsorber'),
            absorbing: _isDocumentActionRunning,
            child: Stack(
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
                    enabled: !_hasSettledInstallments,
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
                    value: _warehouseId,
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
                    enabled: !_hasSettledInstallments,
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
                    enabled: !_hasSettledInstallments,
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
                    enabled: !_hasSettledInstallments,
                    readOnly: _hasSettledInstallments,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SalesFieldRow(
                children: [
                  AppAutocompleteField<Party>(
                    fieldKey: const Key('salesCustomerNameField'),
                    controller: _customerNameController,
                    label: 'اسم الزبون',
                    icon: Icons.person_rounded,
                    accentColor: AppModuleColors.sales,
                    options: _customerOptions,
                    displayStringForOption: (party) => party.name,
                    searchTermsForOption: (party) => [
                      party.name,
                      '${party.number}',
                      party.phone,
                    ],
                    optionSubtitle: (party) => 'رقم ${party.number}',
                    onSelected: _selectCustomer,
                    onChanged: _changeCustomerText,
                    enabled: !_hasSettledInstallments,
                    createActionLabel: 'إضافة زبون جديد',
                    onCreateRequested:
                        _allowsPartyCreate() && !_hasSettledInstallments
                            ? _createCustomer
                            : null,
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
                  warehouseOptions: _warehouseOptions,
                  defaultWarehouse: _defaultWarehouseId,
                  defaultWarehouseLabel: _defaultWarehouseName,
                  enabled: !_hasSettledInstallments,
                  onRowsChanged: _changeItems,
                  onCreateItemRequested:
                      _allowsItemCreate() && !_hasSettledInstallments
                          ? _createItem
                          : null,
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
                    enabled: !_hasSettledInstallments,
                    onChanged: _changeInvoiceDiscount,
                  ),
                  _SalesMoneyField(
                    fieldKey: const Key('salesDiscountPercentageField'),
                    controller: _discountPercentageController,
                    label: 'نسبة الخصم',
                    icon: Icons.percent_rounded,
                    decimalPlaces: 2,
                    enabled: !_hasSettledInstallments,
                    onChanged: _changeDiscountPercentage,
                  ),
                  _SalesMoneyField(
                    fieldKey: const Key('salesReceivedField'),
                    controller: _receivedController,
                    label: 'المقبوض',
                    icon: Icons.payments_rounded,
                    decimalPlaces: _currency == 'USD' ? 2 : 0,
                    enabled:
                        _saleType != 'نقدي' && !_hasSettledInstallments,
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
                  onPrint: canUseSavedInvoiceOutput && canPrint
                      ? _printSalesInvoice
                      : null,
                  onPrintWithoutPrices:
                      canUseSavedInvoiceOutput && canPrint
                      ? () => _printSalesInvoice(includePrices: false)
                      : null,
                  onExportPdf: canUseSavedInvoiceOutput && canExport
                      ? () => _exportSalesInvoice(
                            DocumentExportFormat.pdf,
                          )
                      : null,
                  onExportExcel: canUseSavedInvoiceOutput && canExport
                      ? () => _exportSalesInvoice(
                            DocumentExportFormat.excel,
                          )
                      : null,
                  onInstallments: canUseSavedInvoiceOutput &&
                          _saleType == 'أقساط'
                          ? _openInstallments
                          : null,
                  onStatement: canUseSavedInvoiceOutput
                      ? _showSalesStatement
                      : null,
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
                    ? () => _navigate(InvoiceEditorNavigation.first)
                    : null,
                onPrevious: canMoveToFirstOrPrevious
                    ? () => _navigate(InvoiceEditorNavigation.previous)
                    : null,
                onNext: canMoveToNextOrLast
                    ? () => _navigate(InvoiceEditorNavigation.next)
                    : null,
                onLast: canMoveToNextOrLast
                    ? () => _navigate(InvoiceEditorNavigation.last)
                    : null,
                onSave: !canCreate ||
                        !isEditorReady ||
                        _isRepositoryBusy ||
                        hasSelectedInvoice
                    ? null
                    : _save,
                onUpdate: canUpdate &&
                        isEditorReady &&
                        hasSelectedInvoice &&
                        _hasUnsavedChanges &&
                        !_isRepositoryBusy
                    ? _update
                    : null,
                onUndo:
                    isEditorReady && _hasUnsavedChanges ? _undo : null,
                onDelete: canDelete &&
                        isEditorReady &&
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
                child: AppDataStateView<List<_SalesInvoiceViewData>>(
                  state: _invoiceState,
                  dataBuilder: (_, _) => const SizedBox.shrink(),
                  emptyTitle: 'لا توجد قوائم بيع',
                  emptyActionLabel: 'قائمة بيع جديدة',
                  onEmptyAction: canCreate ? _openEmptyEditor : null,
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
        ),
      ),
    );
  }
}
