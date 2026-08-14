part of 'purchase_screen.dart';

extension _PurchaseViewState on _PurchaseScreenState {
  Widget _buildPurchaseScreen(BuildContext context) {
    final hasSelectedInvoice = _selectedInvoice != null;
    final selectedInvoiceIndex = _coordinator?.selection.selectedIndex ?? -1;
    final hasInvoices = _purchaseInvoices.isNotEmpty;
    final canMoveToFirstOrPrevious =
        hasInvoices && selectedInvoiceIndex != 0;
    final canMoveToNextOrLast =
        hasInvoices && selectedInvoiceIndex >= 0;
    final currencyName = _currency == 'USD' ? 'دولار' : 'دينار';
    final isEditorReady = _invoiceState.status == AppDataStatus.ready;
    final canCreate = _allowsPurchaseAction(PermissionAction.create);
    final canUpdate = _allowsPurchaseAction(PermissionAction.update);
    final canDelete = _allowsPurchaseAction(PermissionAction.delete);
    final canPrint = _allowsPurchaseAction(PermissionAction.print);
    final canExport = _allowsPurchaseAction(PermissionAction.export);
    final canUseSavedInvoiceOutput =
        _canUseSelectedPurchaseInvoiceForOutput;
    final tint = Color.alphaBlend(
      AppModuleColors.purchases.withAlpha(12),
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
        key: const Key('purchaseScreen'),
        title: 'المشتريات',
        backgroundColor: tint,
        onBack: _isRepositoryBusy || _isDocumentActionRunning
            ? null
            : _attemptBack,
        onSearch: !isEditorReady ||
                _isRepositoryBusy ||
                _isDocumentActionRunning
            ? null
            : _showPurchaseSearch,
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
            key: const Key('purchaseDocumentActionAbsorber'),
            absorbing: _isDocumentActionRunning,
            child: AppLoadingOverlay(
              isLoading: _isRepositoryBusy,
              message: 'جاري حفظ قائمة الشراء',
              overlayKey: const Key('purchaseBusyOverlay'),
              child: Stack(
                fit: StackFit.expand,
                children: [
        ColoredBox(
          key: const Key('purchaseTintBackground'),
          color: tint,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
              _PurchaseFieldRow(
                children: [
                  AppReadOnlyField(
                    fieldKey: const Key('purchaseInvoiceNumberField'),
                    controller: _invoiceNumberController,
                    label: 'رقم القائمة',
                    icon: Icons.receipt_long_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppDateField(
                    fieldKey: const Key('purchaseDateField'),
                    label: 'التاريخ',
                    value: _invoiceDateTime,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    onChanged: _changeDate,
                  ),
                  AppTimeField(
                    fieldKey: const Key('purchaseTimeField'),
                    label: 'الوقت',
                    value: TimeOfDay.fromDateTime(_invoiceDateTime),
                    accentColor: AppModuleColors.purchases,
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('purchaseWarehouseField'),
                    label: 'المخزن',
                    icon: Icons.warehouse_rounded,
                    accentColor: AppModuleColors.purchases,
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
                    fieldKey: const Key('purchaseTypeField'),
                    label: 'نوع الشراء',
                    icon: Icons.shopping_cart_checkout_rounded,
                    accentColor: AppModuleColors.purchases,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _purchaseType,
                    options: _purchaseTypeOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changePurchaseType(value);
                    },
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('purchasePaymentTypeField'),
                    label: 'نوع الدفع',
                    icon: Icons.payments_rounded,
                    accentColor: AppModuleColors.purchases,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _paymentType,
                    options: _purchasePaymentTypeOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changePaymentType(value);
                    },
                  ),
                  AppDropdownField<String>(
                    fieldKey: const Key('purchaseCurrencyField'),
                    label: 'العملة',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: AppModuleColors.purchases,
                    useIntrinsicHeight: true,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    menuTextDirection: TextDirection.rtl,
                    value: _currency,
                    options: _purchaseCurrencyOptions,
                    onChanged: (value) {
                      if (value == null) return;
                      _changeCurrency(value);
                    },
                  ),
                  AppMoneyField(
                    fieldKey: const Key('purchaseExchangeRateField'),
                    controller: _exchangeRateController,
                    label: 'سعر الصرف',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    enabled: _currency == 'USD',
                    readOnly: _currency != 'USD',
                    decimalPlaces: 4,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _PurchaseFieldRow(
                children: [
                  AppAutocompleteField<Party>(
                    fieldKey: const Key('purchaseSupplierNameField'),
                    controller: _supplierNameController,
                    label: 'اسم المجهز',
                    icon: Icons.person_search_rounded,
                    accentColor: AppModuleColors.purchases,
                    options: _supplierOptions,
                    displayStringForOption: (party) => party.name,
                    searchTermsForOption: (party) => [
                      party.name,
                      '${party.number}',
                      party.phone,
                    ],
                    optionSubtitle: (party) => 'رقم ${party.number}',
                    onSelected: _selectSupplier,
                    onChanged: _changeSupplierText,
                    createActionLabel: 'إضافة مجهز جديد',
                    onCreateRequested:
                        _allowsPartyCreate() ? _createSupplier : null,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppTextField(
                    fieldKey: const Key('purchaseNotesField'),
                    controller: _notesController,
                    label: 'الملاحظات',
                    icon: Icons.notes_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: AppPurchaseInvoiceTableTemplate(
                  key: const Key('purchaseItemsTable'),
                  initialRows: _activeItems,
                  dataVersion: _tableDataVersion,
                  summaryQuantity: _summaryQuantity,
                  summaryDiscount: _summaryDiscount,
                  summaryTotal: _summaryTotal,
                  summaryTotalCost: _summaryTotalCost,
                  currencyCode: _currency,
                  invoiceAdjustment: _invoiceAdjustment,
                  itemOptions: _itemOptions,
                  warehouseOptions: _warehouseOptions,
                  defaultWarehouse: _defaultWarehouseId,
                  defaultWarehouseLabel: _defaultWarehouseName,
                  onRowsChanged: _changeItems,
                  onCreateItemRequested:
                      _allowsItemCreate() ? _createItem : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PurchaseFieldRow(
                flexes: const [5, 4, 4, 4, 4, 4, 4, 4],
                children: [
                  AppRegularButton(
                    key: const Key('purchaseExpensesButton'),
                    label: 'المصاريف',
                    icon: Icons.receipt_long_rounded,
                    onPressed: () => _expensesFocusNode.requestFocus(),
                  ),
                  _PurchaseMoneyField(
                    fieldKey: const Key('purchaseExpensesField'),
                    controller: _expensesController,
                    focusNode: _expensesFocusNode,
                    label: 'المصاريف',
                    icon: Icons.payments_rounded,
                    decimalPlaces: _currency == 'USD' ? 2 : 0,
                    onChanged: _changeExpenses,
                  ),
                  _PurchaseMoneyField(
                    fieldKey: const Key('purchaseInvoiceDiscountField'),
                    controller: _invoiceDiscountController,
                    label: 'خصم القائمة',
                    icon: Icons.discount_rounded,
                    decimalPlaces: _currency == 'USD' ? 2 : 0,
                    onChanged: _changeInvoiceDiscount,
                  ),
                  _PurchaseMoneyField(
                    fieldKey: const Key('purchaseDiscountPercentageField'),
                    controller: _discountPercentageController,
                    label: 'نسبة الخصم',
                    icon: Icons.percent_rounded,
                    decimalPlaces: 2,
                    onChanged: _changeDiscountPercentage,
                  ),
                  _PurchaseMoneyField(
                    fieldKey: const Key('purchasePaidField'),
                    controller: _paidController,
                    label: 'المدفوع',
                    icon: Icons.payments_rounded,
                    decimalPlaces: _currency == 'USD' ? 2 : 0,
                    enabled: _paymentType != 'نقدي',
                    onChanged: _changePaid,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('purchaseTotalField'),
                    controller: _totalController,
                    label: 'المجموع $currencyName',
                    icon: Icons.calculate_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('purchaseRemainingField'),
                    controller: _remainingController,
                    label: 'المتبقي $currencyName',
                    icon: Icons.pending_actions_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                  AppReadOnlyField(
                    fieldKey: const Key('purchaseCurrentBalanceField'),
                    controller: _currentBalanceController,
                    label: 'الرصيد الحالي $currencyName',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppModuleColors.purchases,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppActionBar(
                key: const Key('purchaseActionBar'),
                middle: _PurchaseInvoiceButtons(
                  onSearch: !isEditorReady || _isRepositoryBusy
                      ? null
                      : _showPurchaseSearch,
                  onPrint: canUseSavedInvoiceOutput && canPrint
                      ? () => _printPurchaseInvoice()
                      : null,
                  onPrintWithoutPrices:
                      canUseSavedInvoiceOutput && canPrint
                      ? () => _printPurchaseInvoice(includePrices: false)
                      : null,
                  onExportPdf: canUseSavedInvoiceOutput && canExport
                      ? () => _exportPurchaseInvoice(
                            DocumentExportFormat.pdf,
                          )
                      : null,
                  onExportExcel: canUseSavedInvoiceOutput && canExport
                      ? () => _exportPurchaseInvoice(
                            DocumentExportFormat.excel,
                          )
                      : null,
                  onStatement: canUseSavedInvoiceOutput
                      ? _showPurchaseStatement
                      : null,
                ),
                firstButtonKey: const Key('purchaseFirstButton'),
                previousButtonKey: const Key('purchasePreviousButton'),
                nextButtonKey: const Key('purchaseNextButton'),
                lastButtonKey: const Key('purchaseLastButton'),
                saveButtonKey: const Key('purchaseSaveButton'),
                updateButtonKey: const Key('purchaseUpdateButton'),
                undoButtonKey: const Key('purchaseUndoButton'),
                deleteButtonKey: const Key('purchaseDeleteButton'),
                accentColor: AppModuleColors.purchases,
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
                child: AppDataStateView<List<_PurchaseInvoiceViewData>>(
                  state: _invoiceState,
                  dataBuilder: (_, _) => const SizedBox.shrink(),
                  emptyTitle: 'لا توجد قوائم شراء',
                  emptyActionLabel: 'قائمة شراء جديدة',
                  onEmptyAction: canCreate ? _openEmptyEditor : null,
                  missingReferenceActionLabel: 'إعادة المحاولة',
                  onMissingReferenceAction: () => unawaited(_loadData()),
                  onRetry: () => unawaited(_loadData()),
                  loadingStateKey: const Key('purchaseLoadingState'),
                  emptyStateKey: const Key('purchaseEmptyState'),
                  missingReferenceStateKey:
                      const Key('purchaseMissingReferenceState'),
                  errorStateKey: const Key('purchaseErrorState'),
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
