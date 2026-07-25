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
  late final List<_PurchaseDemoRow> _purchaseItems;
  late final List<_SaleDemoRow> _saleItems;
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
        cost: '150',
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
        cost: '50',
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
    for (final row in _purchaseItems) {
      row.dispose();
    }
    for (final row in _saleItems) {
      row.dispose();
    }
    super.dispose();
  }

  void _addPurchaseItem() {
    setState(() {
      _purchaseItems.add(
        _PurchaseDemoRow(
          id: 'p${_purchaseSeed++}',
          code: '',
          name: '',
          warehouse: 'الرئيسي',
          quantity: '1',
          container: '1',
          purchasePrice: '0',
          discount: '0',
          cost: '0',
          salePrice: '0',
        ),
      );
    });
  }

  void _deletePurchaseItem(int index) {
    final removed = _purchaseItems[index];
    setState(() => _purchaseItems.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _addSaleItem() {
    setState(() {
      _saleItems.add(
        _SaleDemoRow(
          id: 's${_saleSeed++}',
          code: '',
          name: '',
          warehouse: 'الرئيسي',
          quantity: '1',
          salePrice: '0',
          discount: '0',
        ),
      );
    });
  }

  void _deleteSaleItem(int index) {
    final removed = _saleItems[index];
    setState(() => _saleItems.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
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
        Text((index + 1).toString()),
        AppInvoiceCellField(
          fieldKey: Key('designPurchaseCode-${row.id}'),
          controller: row.code,
          accentColor: AppModuleColors.purchases,
        ),
        AppInvoiceCellField(
          fieldKey: Key('designPurchaseName-${row.id}'),
          controller: row.name,
          accentColor: AppModuleColors.purchases,
        ),
        AppInvoiceCellDropdown(
          fieldKey: Key('designPurchaseWarehouse-${row.id}'),
          accentColor: AppModuleColors.purchases,
          value: row.warehouse.text,
          options: const ['الرئيسي', 'الفرعي'],
          onChanged: (value) {
            setState(() => row.warehouse.text = value);
          },
        ),
        AppInvoiceCellField(
          fieldKey: Key('designPurchaseQuantity-${row.id}'),
          controller: row.quantity,
          accentColor: AppModuleColors.purchases,
          numeric: true,
          inputFormatters: const [AppIntegerInputFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        AppInvoiceCellField(
          fieldKey: Key('designPurchaseContainer-${row.id}'),
          controller: row.container,
          accentColor: AppModuleColors.purchases,
          numeric: true,
          inputFormatters: const [AppIntegerInputFormatter()],
        ),
        AppInvoiceCellField(
          fieldKey: Key('designPurchasePrice-${row.id}'),
          controller: row.purchasePrice,
          accentColor: AppModuleColors.purchases,
          numeric: true,
          inputFormatters: const [AppMoneyInputFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        AppInvoiceCellField(
          fieldKey: Key('designPurchaseDiscount-${row.id}'),
          controller: row.discount,
          accentColor: AppModuleColors.purchases,
          numeric: true,
          inputFormatters: const [AppMoneyInputFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        Text(row.formatMoney(row.afterDiscount)),
        Text(row.formatMoney(row.total)),
        AppInvoiceCellField(
          fieldKey: Key('designPurchaseCost-${row.id}'),
          controller: row.cost,
          accentColor: AppModuleColors.purchases,
          numeric: true,
          inputFormatters: const [AppMoneyInputFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        Text(row.formatMoney(row.totalCost)),
        AppInvoiceCellField(
          fieldKey: Key('designPurchaseSalePrice-${row.id}'),
          controller: row.salePrice,
          accentColor: AppModuleColors.purchases,
          numeric: true,
          inputFormatters: const [AppMoneyInputFormatter()],
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
          onPressed:
              isLast ? _addPurchaseItem : () => _deletePurchaseItem(index),
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
        Text((index + 1).toString()),
        AppInvoiceCellField(
          fieldKey: Key('designSaleCode-${row.id}'),
          controller: row.code,
          accentColor: AppModuleColors.sales,
        ),
        AppInvoiceCellField(
          fieldKey: Key('designSaleName-${row.id}'),
          controller: row.name,
          accentColor: AppModuleColors.sales,
        ),
        AppInvoiceCellDropdown(
          fieldKey: Key('designSaleWarehouse-${row.id}'),
          accentColor: AppModuleColors.sales,
          value: row.warehouse.text,
          options: const ['الرئيسي', 'الفرعي'],
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
          onChanged: (_) => setState(() {}),
        ),
        AppInvoiceCellField(
          fieldKey: Key('designSalePrice-${row.id}'),
          controller: row.salePrice,
          accentColor: AppModuleColors.sales,
          numeric: true,
          inputFormatters: const [AppMoneyInputFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        AppInvoiceCellField(
          fieldKey: Key('designSaleDiscount-${row.id}'),
          controller: row.discount,
          accentColor: AppModuleColors.sales,
          numeric: true,
          inputFormatters: const [AppMoneyInputFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        Text(row.formatMoney(row.afterDiscount)),
        Text(row.formatMoney(row.total)),
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
          onPressed: isLast ? _addSaleItem : () => _deleteSaleItem(index),
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
      Text(AppFormatters.quantity(quantity)),
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      Text(AppFormatters.iqd(discount)),
      const SizedBox.shrink(),
      Text(AppFormatters.iqd(total)),
      const SizedBox.shrink(),
      Text(AppFormatters.iqd(totalCost)),
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
      (sum, row) => sum + row.discountValue,
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
      Text(AppFormatters.quantity(quantity)),
      const SizedBox.shrink(),
      Text(AppFormatters.iqd(discount)),
      const SizedBox.shrink(),
      Text(AppFormatters.iqd(total)),
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
                'الرأس والمجاميع ثابتان، والصف الأخير للإضافة والصفوف السابقة للحذف. الحقول والحسابات قابلة للتجربة مباشرة.',
            icon: Icons.table_chart_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _TableTitle(
            label: 'جدول مواد المشتريات',
            color: AppModuleColors.purchases,
            icon: Icons.shopping_cart_checkout_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInvoiceItemsTable.purchase(
            key: const Key('designPurchaseItemsTable'),
            tableKey: const Key('designPurchaseItemsDataTable'),
            rows: _purchaseRows(),
            summaryCells: _purchaseSummaryCells(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _TableTitle(
            label: 'جدول مواد المبيعات',
            color: AppModuleColors.sales,
            icon: Icons.point_of_sale_rounded,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppInvoiceItemsTable.sale(
            key: const Key('designSalesItemsTable'),
            tableKey: const Key('designSalesItemsDataTable'),
            rows: _saleRows(),
            summaryCells: _saleSummaryCells(),
          ),
        ],
      ),
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
    required String cost,
    required String salePrice,
  })  : code = TextEditingController(text: code),
        name = TextEditingController(text: name),
        warehouse = TextEditingController(text: warehouse),
        quantity = TextEditingController(text: quantity),
        container = TextEditingController(text: container),
        purchasePrice = TextEditingController(text: purchasePrice),
        discount = TextEditingController(text: discount),
        cost = TextEditingController(text: cost),
        salePrice = TextEditingController(text: salePrice);

  final String id;
  final TextEditingController code;
  final TextEditingController name;
  final TextEditingController warehouse;
  final TextEditingController quantity;
  final TextEditingController container;
  final TextEditingController purchasePrice;
  final TextEditingController discount;
  final TextEditingController cost;
  final TextEditingController salePrice;

  num get _quantity => AppFormatters.parseNumber(quantity.text) ?? 0;
  num get _price => AppFormatters.parseNumber(purchasePrice.text) ?? 0;
  num get _discount => AppFormatters.parseNumber(discount.text) ?? 0;
  num get _cost => AppFormatters.parseNumber(cost.text) ?? 0;

  num get afterDiscount {
    final result = _price - _discount;
    return result < 0 ? 0 : result;
  }

  num get total => afterDiscount * _quantity;
  num get totalCost => total + _cost;
  int get quantityValue => _quantity.toInt();
  num get discountValue => _discount;

  String formatMoney(num value) {
    return AppFormatters.iqd(value);
  }

  void dispose() {
    code.dispose();
    name.dispose();
    warehouse.dispose();
    quantity.dispose();
    container.dispose();
    purchasePrice.dispose();
    discount.dispose();
    cost.dispose();
    salePrice.dispose();
  }
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
  num get discountValue => _discount;

  String formatMoney(num value) {
    return AppFormatters.iqd(value);
  }

  void dispose() {
    code.dispose();
    name.dispose();
    warehouse.dispose();
    quantity.dispose();
    salePrice.dispose();
    discount.dispose();
  }
}
