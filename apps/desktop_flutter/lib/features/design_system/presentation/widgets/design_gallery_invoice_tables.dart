import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import 'design_gallery_section.dart';

class DesignGalleryInvoiceTablesSection extends StatefulWidget {
  const DesignGalleryInvoiceTablesSection({super.key});

  @override
  State<DesignGalleryInvoiceTablesSection> createState() =>
      _DesignGalleryInvoiceTablesSectionState();
}

class _DesignGalleryInvoiceTablesSectionState
    extends State<DesignGalleryInvoiceTablesSection> {
  static const _purchaseProducts = <_PurchaseDemoProduct>[
    _PurchaseDemoProduct(
      code: 'P-001',
      name: 'دفتر ملاحظات',
      salePriceIqd: 3000,
      salePriceUsd: 2,
    ),
    _PurchaseDemoProduct(
      code: 'P-002',
      name: 'قلم أزرق',
      salePriceIqd: 1750,
      salePriceUsd: 1.25,
    ),
    _PurchaseDemoProduct(
      code: 'P-003',
      name: 'طابعة مكتبية',
      salePriceIqd: 175000,
      salePriceUsd: 125,
    ),
  ];

  late final List<_PurchaseDemoRow> _purchaseItems;
  late final List<_SaleDemoRow> _saleItems;
  final _purchaseScrollController = ScrollController();
  final _saleScrollController = ScrollController();
  final _purchaseKeyHoldGuard = AppKeyHoldGuard();
  final _saleKeyHoldGuard = AppKeyHoldGuard();
  var _purchaseCurrency = 'دينار';
  var _saleCurrency = 'دينار';
  var _purchaseSeed = 3;
  var _saleSeed = 3;

  @override
  void initState() {
    super.initState();
    _purchaseItems = [
      _PurchaseDemoRow(
        id: 'p1',
        code: 'P-001',
        name: 'دفتر ملاحظات',
        warehouse: 'الرئيسي',
        quantity: '100',
        container: '1',
        purchasePrice: '2,500',
        discount: '0',
        salePrice: '3,000',
      ),
      _PurchaseDemoRow(
        id: 'p2',
        code: 'P-002',
        name: 'قلم أزرق',
        warehouse: 'الفرعي',
        quantity: '1,000',
        container: '10',
        purchasePrice: '1,250',
        discount: '0',
        salePrice: '1,750',
      ),
    ];
    _saleItems = [
      _SaleDemoRow(
        id: 's1',
        code: 'P-001',
        name: 'دفتر ملاحظات',
        warehouse: 'الرئيسي',
        quantity: '5',
        salePrice: '3,000',
        discount: '0',
      ),
      _SaleDemoRow(
        id: 's2',
        code: 'P-003',
        name: 'طابعة مكتبية',
        warehouse: 'الرئيسي',
        quantity: '1',
        salePrice: '175,000',
        discount: '5,000',
      ),
    ];
  }

  @override
  void dispose() {
    _purchaseScrollController.dispose();
    _saleScrollController.dispose();
    _purchaseKeyHoldGuard.dispose();
    _saleKeyHoldGuard.dispose();
    for (final row in _purchaseItems) {
      row.dispose();
    }
    for (final row in _saleItems) {
      row.dispose();
    }
    super.dispose();
  }

  void _addPurchaseItem() {
    final newRow = _PurchaseDemoRow(
      id: 'p${_purchaseSeed++}',
      code: '',
      name: '',
      warehouse: 'الرئيسي',
      quantity: '0',
      container: '0',
      purchasePrice: _purchaseCurrency == 'دولار' ? '0.00' : '0',
      discount: _purchaseCurrency == 'دولار' ? '0.00' : '0',
      salePrice: _purchaseCurrency == 'دولار' ? '0.00' : '0',
    );
    setState(() {
      _purchaseItems.add(newRow);
    });
    _finishAddingRow(
      controller: _purchaseScrollController,
      focusNode: newRow.codeFocusNode,
    );
  }

  void _deletePurchaseItem(int index) {
    final removed = _purchaseItems[index];
    setState(() => _purchaseItems.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _addSaleItem() {
    final newRow = _SaleDemoRow(
      id: 's${_saleSeed++}',
      code: '',
      name: '',
      warehouse: 'الرئيسي',
      quantity: '1',
      salePrice: _saleCurrency == 'دولار' ? '0.00' : '0',
      discount: _saleCurrency == 'دولار' ? '0.00' : '0',
    );
    setState(() {
      _saleItems.add(newRow);
    });
    _finishAddingRow(
      controller: _saleScrollController,
      focusNode: newRow.codeFocusNode,
    );
  }

  void _deleteSaleItem(int index) {
    final removed = _saleItems[index];
    setState(() => _saleItems.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _finishAddingRow({
    required ScrollController controller,
    required FocusNode focusNode,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (controller.hasClients) {
        controller.jumpTo(controller.position.maxScrollExtent);
      }
      focusNode.requestFocus();
    });
  }

  void _setPurchaseCurrency(String value) {
    if (_purchaseCurrency == value) return;
    setState(() {
      _purchaseCurrency = value;
      for (final row in _purchaseItems) {
        _reformatMoneyController(row.purchasePrice, value);
        _reformatMoneyController(row.discount, value);
        _reformatMoneyController(row.salePrice, value);
      }
    });
  }

  void _setSaleCurrency(String value) {
    if (_saleCurrency == value) return;
    setState(() {
      _saleCurrency = value;
      for (final row in _saleItems) {
        _reformatMoneyController(row.salePrice, value);
        _reformatMoneyController(row.discount, value);
      }
    });
  }

  void _reformatMoneyController(
    TextEditingController controller,
    String currency,
  ) {
    final value = AppFormatters.parseNumber(controller.text) ?? 0;
    final formatted = _formatMoney(value, currency);
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatMoney(num value, String currency) {
    return currency == 'دولار'
        ? AppFormatters.usd(value)
        : AppFormatters.iqd(value);
  }

  AppMoneyInputFormatter _moneyFormatter(String currency) {
    return AppMoneyInputFormatter(
      decimalPlaces: currency == 'دولار' ? 2 : 0,
    );
  }

  void _submitPurchaseRow(int index) {
    final row = _purchaseItems[index];
    if (row.selectedProductCode == null || row.quantityValue <= 0) {
      AppToast.showError(
        context,
        'أكمل بيانات السطر قبل إضافة سطر جديد',
      );
      row.salePriceFocusNode.requestFocus();
      return;
    }
    _addPurchaseItem();
  }

  void _selectPurchaseProduct(
    _PurchaseDemoRow row,
    _PurchaseDemoProduct product,
  ) {
    setState(() {
      row.selectedProductCode = product.code;
      row.code.text = product.code;
      row.name.text = product.name;
      row.salePrice.text = _formatMoney(
        _purchaseCurrency == 'دولار'
            ? product.salePriceUsd
            : product.salePriceIqd,
        _purchaseCurrency,
      );
    });
  }

  void _changePurchaseProductCode(
    _PurchaseDemoRow row,
    String value,
  ) {
    setState(() {
      row.selectedProductCode = null;
      row.name.clear();
      row.salePrice.clear();
    });
  }

  void _changePurchaseProductName(
    _PurchaseDemoRow row,
    String value,
  ) {
    setState(() {
      row.selectedProductCode = null;
      row.code.clear();
      row.salePrice.clear();
    });
  }

  void _commitPurchaseProduct(
    _PurchaseDemoRow row,
    String value, {
    required bool byCode,
  }) {
    final normalized = value.trim().toLowerCase();
    for (final product in _purchaseProducts) {
      final candidate =
          (byCode ? product.code : product.name).trim().toLowerCase();
      if (candidate == normalized) {
        _selectPurchaseProduct(row, product);
        return;
      }
    }
  }

  void _submitSaleRow(int index) {
    if (index == _saleItems.length - 1) {
      _addSaleItem();
      return;
    }
    _saleItems[index + 1].codeFocusNode.requestFocus();
  }

  List<AppTableRow> _purchaseRows() {
    return [
      for (var index = 0; index < _purchaseItems.length; index++)
        _purchaseTableRow(index),
    ];
  }

  AppTableRow _purchaseTableRow(int index) {
    final row = _purchaseItems[index];
    final isLast = index == _purchaseItems.length - 1;

    return AppTableRow(
      rowKey: Key('designPurchaseRow-${row.id}'),
      cells: [
        AppPurchaseInvoiceValueText((index + 1).toString()),
        AppPurchaseInvoiceAutocomplete<_PurchaseDemoProduct>(
          fieldKey: Key('designPurchaseCode-${row.id}'),
          controller: row.code,
          focusNode: row.codeFocusNode,
          nextFocusNode: row.nameFocusNode,
          enabled: true,
          options: _purchaseProducts,
          optionLabel: (product) => product.code,
          optionSubtitle: (product) => product.name,
          optionSearchValues: (product) => [product.code, product.name],
          minMenuWidth: 260,
          keyHoldGuard: _purchaseKeyHoldGuard,
          onChanged: (value) => _changePurchaseProductCode(row, value),
          onSelected: (product) => _selectPurchaseProduct(row, product),
          onSubmitted: (value) =>
              _commitPurchaseProduct(row, value, byCode: true),
          onFocusLost: (value) =>
              _commitPurchaseProduct(row, value, byCode: true),
        ),
        AppPurchaseInvoiceAutocomplete<_PurchaseDemoProduct>(
          fieldKey: Key('designPurchaseName-${row.id}'),
          controller: row.name,
          focusNode: row.nameFocusNode,
          nextFocusNode: row.warehouseFocusNode,
          enabled: true,
          options: _purchaseProducts,
          optionLabel: (product) => product.name,
          optionSubtitle: (product) => product.code,
          optionSearchValues: (product) => [product.name, product.code],
          minMenuWidth: 280,
          keyHoldGuard: _purchaseKeyHoldGuard,
          onChanged: (value) => _changePurchaseProductName(row, value),
          onSelected: (product) => _selectPurchaseProduct(row, product),
          onSubmitted: (value) =>
              _commitPurchaseProduct(row, value, byCode: false),
          onFocusLost: (value) =>
              _commitPurchaseProduct(row, value, byCode: false),
        ),
        AppPurchaseInvoiceCellDropdown(
          fieldKey: Key('designPurchaseWarehouse-${row.id}'),
          value: row.warehouse.text,
          options: const ['الرئيسي', 'الفرعي'],
          focusNode: row.warehouseFocusNode,
          nextFocusNode: row.quantityFocusNode,
          enabled: true,
          onChanged: (value) {
            setState(() => row.warehouse.text = value);
          },
        ),
        AppPurchaseInvoiceCellField(
          fieldKey: Key('designPurchaseQuantity-${row.id}'),
          controller: row.quantity,
          focusNode: row.quantityFocusNode,
          nextFocusNode: row.containerFocusNode,
          numeric: true,
          keyHoldGuard: _purchaseKeyHoldGuard,
          onChanged: (_) => setState(() {}),
        ),
        AppPurchaseInvoiceCellField(
          fieldKey: Key('designPurchaseContainer-${row.id}'),
          controller: row.container,
          focusNode: row.containerFocusNode,
          nextFocusNode: row.purchasePriceFocusNode,
          numeric: true,
          keyHoldGuard: _purchaseKeyHoldGuard,
        ),
        AppPurchaseInvoiceCellField(
          fieldKey: Key('designPurchasePrice-${row.id}'),
          controller: row.purchasePrice,
          focusNode: row.purchasePriceFocusNode,
          nextFocusNode: row.discountFocusNode,
          numeric: true,
          keyHoldGuard: _purchaseKeyHoldGuard,
          onChanged: (_) => setState(() {}),
        ),
        AppPurchaseInvoiceCellField(
          fieldKey: Key('designPurchaseDiscount-${row.id}'),
          controller: row.discount,
          focusNode: row.discountFocusNode,
          nextFocusNode: row.salePriceFocusNode,
          numeric: true,
          keyHoldGuard: _purchaseKeyHoldGuard,
          onChanged: (_) => setState(() {}),
        ),
        AppPurchaseInvoiceValueText(
          _formatMoney(row.afterDiscount, _purchaseCurrency),
        ),
        AppPurchaseInvoiceValueText(
          _formatMoney(row.total, _purchaseCurrency),
        ),
        AppPurchaseInvoiceValueText(
          _formatMoney(row.unitCost, _purchaseCurrency),
          key: Key('designPurchaseCost-${row.id}'),
        ),
        AppPurchaseInvoiceValueText(
          _formatMoney(row.totalCost, _purchaseCurrency),
        ),
        AppPurchaseInvoiceCellField(
          fieldKey: Key('designPurchaseSalePrice-${row.id}'),
          controller: row.salePrice,
          focusNode: row.salePriceFocusNode,
          numeric: true,
          keyHoldGuard: _purchaseKeyHoldGuard,
          onSubmitted: (_) => _submitPurchaseRow(index),
        ),
        AppTableActionButton(
          key: Key(
            isLast
                ? 'designPurchaseAdd-${row.id}'
                : 'designPurchaseDelete-${row.id}',
          ),
          icon: isLast ? Icons.add_rounded : Icons.close_rounded,
          tooltip: isLast ? 'إضافة سطر' : 'حذف السطر',
          variant: isLast
              ? AppButtonVariant.primary
              : AppButtonVariant.danger,
          backgroundColor:
              isLast ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          size: 32,
          iconSize: 19,
          borderRadius: 9,
          onPressed: isLast
              ? () => _addPurchaseItem()
              : () => _deletePurchaseItem(index),
        ),
      ],
    );
  }

  List<AppTableRow> _saleRows() {
    return [
      for (var index = 0; index < _saleItems.length; index++)
        _saleTableRow(index),
    ];
  }

  AppTableRow _saleTableRow(int index) {
    final row = _saleItems[index];
    final isLast = index == _saleItems.length - 1;

    return AppTableRow(
      rowKey: Key('designSaleRow-${row.id}'),
      cells: [
        AppInvoiceValueText((index + 1).toString()),
        AppInvoiceCellField(
          fieldKey: Key('designSaleCode-${row.id}'),
          controller: row.code,
          focusNode: row.codeFocusNode,
          textInputAction: TextInputAction.next,
          keyHoldGuard: _saleKeyHoldGuard,
          onSubmitted: (_) => AppFocusTraversal.next(context),
          accentColor: AppModuleColors.sales,
        ),
        AppInvoiceCellField(
          fieldKey: Key('designSaleName-${row.id}'),
          controller: row.name,
          textInputAction: TextInputAction.next,
          keyHoldGuard: _saleKeyHoldGuard,
          onSubmitted: (_) => AppFocusTraversal.next(context),
          accentColor: AppModuleColors.sales,
        ),
        AppInvoiceCellDropdown(
          fieldKey: Key('designSaleWarehouse-${row.id}'),
          accentColor: AppModuleColors.sales,
          value: row.warehouse.text,
          options: const ['الرئيسي', 'الفرعي'],
          keyHoldGuard: _saleKeyHoldGuard,
          onSubmitted: (_) => AppFocusTraversal.next(context),
          onChanged: (value) {
            setState(() => row.warehouse.text = value);
          },
        ),
        AppInvoiceCellField(
          fieldKey: Key('designSaleQuantity-${row.id}'),
          controller: row.quantity,
          accentColor: AppModuleColors.sales,
          numeric: true,
          inputFormatters: const [AppIntegerInputFormatter()],
          textInputAction: TextInputAction.next,
          keyHoldGuard: _saleKeyHoldGuard,
          onSubmitted: (_) => AppFocusTraversal.next(context),
          onChanged: (_) => setState(() {}),
        ),
        AppInvoiceCellField(
          fieldKey: Key('designSalePrice-${row.id}'),
          controller: row.salePrice,
          accentColor: AppModuleColors.sales,
          numeric: true,
          inputFormatters: [_moneyFormatter(_saleCurrency)],
          textInputAction: TextInputAction.next,
          keyHoldGuard: _saleKeyHoldGuard,
          onSubmitted: (_) => AppFocusTraversal.next(context),
          onChanged: (_) => setState(() {}),
        ),
        AppInvoiceCellField(
          fieldKey: Key('designSaleDiscount-${row.id}'),
          controller: row.discount,
          accentColor: AppModuleColors.sales,
          numeric: true,
          inputFormatters: [_moneyFormatter(_saleCurrency)],
          textInputAction: TextInputAction.done,
          keyHoldGuard: _saleKeyHoldGuard,
          onSubmitted: (_) => _submitSaleRow(index),
          onChanged: (_) => setState(() {}),
        ),
        AppInvoiceValueText(
          _formatMoney(row.afterDiscount, _saleCurrency),
        ),
        AppInvoiceValueText(
          _formatMoney(row.total, _saleCurrency),
        ),
        AppTableActionButton(
          key: Key(
            isLast
                ? 'designSaleAdd-${row.id}'
                : 'designSaleDelete-${row.id}',
          ),
          icon: isLast ? Icons.add_rounded : Icons.close_rounded,
          tooltip: isLast ? 'إضافة سطر' : 'حذف السطر',
          variant: isLast
              ? AppButtonVariant.primary
              : AppButtonVariant.danger,
          backgroundColor:
              isLast ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          size: 32,
          iconSize: 19,
          borderRadius: 9,
          onPressed:
              isLast ? () => _addSaleItem() : () => _deleteSaleItem(index),
        ),
      ],
    );
  }

  List<Widget> _purchaseSummaryCells() {
    final quantity = _purchaseItems.fold<int>(
      0,
      (sum, row) => sum + row.quantityValue,
    );
    final discount = _purchaseItems.fold<num>(
      0,
      (sum, row) => sum + row.discountValue,
    );
    final total = _purchaseItems.fold<num>(
      0,
      (sum, row) => sum + row.total,
    );
    final totalCost = _purchaseItems.fold<num>(
      0,
      (sum, row) => sum + row.totalCost,
    );

    return [
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      const Text('المجموع'),
      const SizedBox.shrink(),
      AppPurchaseInvoiceSummaryValueText(
        AppFormatters.quantity(quantity),
      ),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      AppPurchaseInvoiceSummaryValueText(
        _formatMoney(discount, _purchaseCurrency),
      ),
      const SizedBox.shrink(),
      AppPurchaseInvoiceSummaryValueText(
        _formatMoney(total, _purchaseCurrency),
      ),
      const SizedBox.shrink(),
      AppPurchaseInvoiceSummaryValueText(
        _formatMoney(totalCost, _purchaseCurrency),
      ),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
    ];
  }

  List<Widget> _saleSummaryCells() {
    final quantity = _saleItems.fold<int>(
      0,
      (sum, row) => sum + row.quantityValue,
    );
    final discount = _saleItems.fold<num>(
      0,
      (sum, row) => sum + row.discountTotal,
    );
    final total = _saleItems.fold<num>(
      0,
      (sum, row) => sum + row.total,
    );

    return [
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      const Text('المجموع'),
      const SizedBox.shrink(),
      AppInvoiceValueText(AppFormatters.quantity(quantity)),
      const SizedBox.shrink(),
      AppInvoiceValueText(_formatMoney(discount, _saleCurrency)),
      const SizedBox.shrink(),
      AppInvoiceValueText(_formatMoney(total, _saleCurrency)),
      const SizedBox.shrink(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DesignGallerySection(
      title: 'جداول المشتريات والمبيعات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppInfoBanner(
            message:
                'الرأس والمجاميع ثابتان، والصف الأخير للإضافة والصفوف '
                'السابقة للحذف. الحسابات تتبع عملة الفاتورة، وEnter '
                'ينقل بين الخلايا.',
            icon: Icons.table_chart_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          _TableHeading(
            title: const _TableTitle(
              label: 'جدول مواد المشتريات',
              color: AppModuleColors.purchases,
              icon: Icons.shopping_cart_checkout_rounded,
            ),
            currency: _purchaseCurrency,
            color: AppModuleColors.purchases,
            fieldKey: const Key('designPurchaseCurrency'),
            onCurrencyChanged: _setPurchaseCurrency,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInvoiceItemsTable.purchase(
            key: const Key('designPurchaseItemsTable'),
            tableKey: const Key('designPurchaseItemsDataTable'),
            rows: _purchaseRows(),
            summaryCells: _purchaseSummaryCells(),
            verticalScrollController: _purchaseScrollController,
          ),
          const SizedBox(height: AppSpacing.lg),
          _TableHeading(
            title: const _TableTitle(
              label: 'جدول مواد المبيعات',
              color: AppModuleColors.sales,
              icon: Icons.point_of_sale_rounded,
            ),
            currency: _saleCurrency,
            color: AppModuleColors.sales,
            fieldKey: const Key('designSaleCurrency'),
            onCurrencyChanged: _setSaleCurrency,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInvoiceItemsTable.sale(
            key: const Key('designSalesItemsTable'),
            tableKey: const Key('designSalesItemsDataTable'),
            rows: _saleRows(),
            summaryCells: _saleSummaryCells(),
            verticalScrollController: _saleScrollController,
          ),
        ],
      ),
    );
  }
}

class _TableHeading extends StatelessWidget {
  const _TableHeading({
    required this.title,
    required this.currency,
    required this.color,
    required this.fieldKey,
    required this.onCurrencyChanged,
  });

  final Widget title;
  final String currency;
  final Color color;
  final Key fieldKey;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: title),
        Container(
          width: 190,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Color.alphaBlend(color.withAlpha(8), AppColors.surface),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: color.withAlpha(90)),
          ),
          child: Row(
            children: [
              const Text(
                'العملة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppInvoiceCellDropdown(
                  key: fieldKey,
                  value: currency,
                  options: const ['دينار', 'دولار'],
                  accentColor: color,
                  onChanged: onCurrencyChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableTitle extends StatelessWidget {
  const _TableTitle({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.sectionTitle),
      ],
    );
  }
}

class _PurchaseDemoRow {
  _PurchaseDemoRow({
    required this.id,
    required String code,
    required String name,
    required String warehouse,
    required String quantity,
    required String container,
    required String purchasePrice,
    required String discount,
    required String salePrice,
  })  : code = TextEditingController(text: code),
        name = TextEditingController(text: name),
        warehouse = TextEditingController(text: warehouse),
        quantity = TextEditingController(text: quantity),
        container = TextEditingController(text: container),
        purchasePrice = TextEditingController(text: purchasePrice),
        discount = TextEditingController(text: discount),
        salePrice = TextEditingController(text: salePrice),
        selectedProductCode = code.isEmpty ? null : code;

  final String id;
  final codeFocusNode = FocusNode();
  final nameFocusNode = FocusNode();
  final warehouseFocusNode = FocusNode();
  final quantityFocusNode = FocusNode();
  final containerFocusNode = FocusNode();
  final purchasePriceFocusNode = FocusNode();
  final discountFocusNode = FocusNode();
  final salePriceFocusNode = FocusNode();
  final TextEditingController code;
  final TextEditingController name;
  final TextEditingController warehouse;
  final TextEditingController quantity;
  final TextEditingController container;
  final TextEditingController purchasePrice;
  final TextEditingController discount;
  final TextEditingController salePrice;
  String? selectedProductCode;

  num get _quantity => AppFormatters.parseNumber(quantity.text) ?? 0;
  num get _price => AppFormatters.parseNumber(purchasePrice.text) ?? 0;
  num get _discount => AppFormatters.parseNumber(discount.text) ?? 0;
  num get _baseTotal => _price * _quantity;

  num get afterDiscount {
    if (_quantity <= 0) return 0;
    return total / _quantity;
  }

  num get total => _baseTotal - _discount;

  // لا توجد مصاريف أو خصومات فاتورة في مثال دليل التصميم.
  num get totalCost => total;
  num get unitCost => _quantity <= 0 ? 0 : totalCost / _quantity;
  int get quantityValue => _quantity.toInt();
  num get discountValue => _discount;

  void dispose() {
    codeFocusNode.dispose();
    nameFocusNode.dispose();
    warehouseFocusNode.dispose();
    quantityFocusNode.dispose();
    containerFocusNode.dispose();
    purchasePriceFocusNode.dispose();
    discountFocusNode.dispose();
    salePriceFocusNode.dispose();
    code.dispose();
    name.dispose();
    warehouse.dispose();
    quantity.dispose();
    container.dispose();
    purchasePrice.dispose();
    discount.dispose();
    salePrice.dispose();
  }
}

class _PurchaseDemoProduct {
  const _PurchaseDemoProduct({
    required this.code,
    required this.name,
    required this.salePriceIqd,
    required this.salePriceUsd,
  });

  final String code;
  final String name;
  final num salePriceIqd;
  final num salePriceUsd;
}

class _SaleDemoRow {
  _SaleDemoRow({
    required this.id,
    required String code,
    required String name,
    required String warehouse,
    required String quantity,
    required String salePrice,
    required String discount,
  })  : code = TextEditingController(text: code),
        name = TextEditingController(text: name),
        warehouse = TextEditingController(text: warehouse),
        quantity = TextEditingController(text: quantity),
        salePrice = TextEditingController(text: salePrice),
        discount = TextEditingController(text: discount);

  final String id;
  final codeFocusNode = FocusNode();
  final TextEditingController code;
  final TextEditingController name;
  final TextEditingController warehouse;
  final TextEditingController quantity;
  final TextEditingController salePrice;
  final TextEditingController discount;

  num get _quantity => AppFormatters.parseNumber(quantity.text) ?? 0;
  num get _price => AppFormatters.parseNumber(salePrice.text) ?? 0;
  num get _discount => AppFormatters.parseNumber(discount.text) ?? 0;

  num get afterDiscount {
    final result = _price - _discount;
    return result < 0 ? 0 : result;
  }

  num get total => afterDiscount * _quantity;
  int get quantityValue => _quantity.toInt();
  num get discountTotal => _discount * _quantity;

  void dispose() {
    codeFocusNode.dispose();
    code.dispose();
    name.dispose();
    warehouse.dispose();
    quantity.dispose();
    salePrice.dispose();
    discount.dispose();
  }
}
