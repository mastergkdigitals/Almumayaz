import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';

class DesignGalleryTransferDialog extends StatefulWidget {
  const DesignGalleryTransferDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Directionality(
        textDirection: TextDirection.rtl,
        child: DesignGalleryTransferDialog(),
      ),
    );
  }

  @override
  State<DesignGalleryTransferDialog> createState() =>
      _DesignGalleryTransferDialogState();
}

class _DesignGalleryTransferDialogState
    extends State<DesignGalleryTransferDialog> {
  static const _warehouseOptions = [
    AppDropdownOption(value: 'main', label: 'المخزن الرئيسي'),
    AppDropdownOption(value: 'secondary', label: 'المخزن الفرعي'),
  ];

  final _quantityController = TextEditingController(text: '10');
  final Map<String, List<_WarehouseItem>> _stock = {
    'main': [
      _WarehouseItem(
        id: 'p001',
        code: 'P-001',
        name: 'دفتر ملاحظات',
        quantity: 1200,
      ),
      _WarehouseItem(
        id: 'p002',
        code: 'P-002',
        name: 'قلم أزرق',
        quantity: 450,
      ),
      _WarehouseItem(
        id: 'p003',
        code: 'P-003',
        name: 'طابعة مكتبية',
        quantity: 12,
      ),
    ],
    'secondary': [
      _WarehouseItem(
        id: 'p001',
        code: 'P-001',
        name: 'دفتر ملاحظات',
        quantity: 80,
      ),
      _WarehouseItem(
        id: 'p002',
        code: 'P-002',
        name: 'قلم أزرق',
        quantity: 35,
      ),
      _WarehouseItem(
        id: 'p003',
        code: 'P-003',
        name: 'طابعة مكتبية',
        quantity: 2,
      ),
    ],
  };

  String _fromWarehouse = 'main';
  String _toWarehouse = 'secondary';
  String _selectedProduct = 'p001';

  List<_WarehouseItem> get _sourceItems => _stock[_fromWarehouse]!;
  List<_WarehouseItem> get _destinationItems => _stock[_toWarehouse]!;

  _WarehouseItem get _selectedSourceItem {
    return _sourceItems.firstWhere(
      (item) => item.id == _selectedProduct,
      orElse: () => _sourceItems.first,
    );
  }

  int? get _transferQuantity {
    return AppFormatters.parseInteger(_quantityController.text);
  }

  bool get _canExecute {
    final quantity = _transferQuantity;
    return _fromWarehouse != _toWarehouse &&
        quantity != null &&
        quantity > 0 &&
        quantity <= _selectedSourceItem.quantity;
  }

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_handleQuantityChanged);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_handleQuantityChanged);
    _quantityController.dispose();
    super.dispose();
  }

  void _handleQuantityChanged() {
    if (mounted) setState(() {});
  }

  void _changeSource(String value) {
    setState(() {
      _fromWarehouse = value;
      if (_toWarehouse == value) {
        _toWarehouse = value == 'main' ? 'secondary' : 'main';
      }
      _selectedProduct = _stock[_fromWarehouse]!.first.id;
    });
  }

  void _changeDestination(String value) {
    setState(() {
      _toWarehouse = value;
      if (_fromWarehouse == value) {
        _fromWarehouse = value == 'main' ? 'secondary' : 'main';
        _selectedProduct = _stock[_fromWarehouse]!.first.id;
      }
    });
  }

  void _executeTransfer() {
    if (!_canExecute) return;
    final quantity = _transferQuantity!;
    final sourceItems = _stock[_fromWarehouse]!;
    final destinationItems = _stock[_toWarehouse]!;
    final sourceIndex = sourceItems.indexWhere(
      (item) => item.id == _selectedProduct,
    );
    final destinationIndex = destinationItems.indexWhere(
      (item) => item.id == _selectedProduct,
    );
    final sourceItem = sourceItems[sourceIndex];

    setState(() {
      sourceItems[sourceIndex] = sourceItem.copyWith(
        quantity: sourceItem.quantity - quantity,
      );
      if (destinationIndex < 0) {
        destinationItems.add(sourceItem.copyWith(quantity: quantity));
      } else {
        final destinationItem = destinationItems[destinationIndex];
        destinationItems[destinationIndex] = destinationItem.copyWith(
          quantity: destinationItem.quantity + quantity,
        );
      }
    });
    _quantityController.text = '1';
  }

  @override
  Widget build(BuildContext context) {
    return AppModuleDialog(
      key: const Key('designTransferDialog'),
      title: 'النقل المخزني',
      subtitle: 'اختر المادة والكمية وانقلها بين مخزنين',
      icon: Icons.compare_arrows_rounded,
      accentColor: AppModuleColors.warehouses,
      width: AppDialogSizes.extraLarge,
      onClose: () => Navigator.of(context).pop(),
      actionsKey: const Key('designTransferDialogActions'),
      actions: [
        AppButton(
          key: const Key('designTransferDialogCancel'),
          label: 'إغلاق',
          variant: AppButtonVariant.secondary,
          width: 144,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          key: const Key('designTransferDialogConfirm'),
          label: 'تنفيذ النقل',
          icon: Icons.swap_horiz_rounded,
          width: 176,
          backgroundColor: AppModuleColors.warehouses,
          onPressed: _canExecute ? _executeTransfer : null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppDialogSection(
            key: const Key('designTransferControls'),
            title: 'تفاصيل النقل',
            icon: Icons.warehouse_rounded,
            accentColor: AppModuleColors.warehouses,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppDropdownField<String>(
                        fieldKey:
                            const Key('designTransferFromWarehouse'),
                        label: 'من مخزن',
                        icon: Icons.warehouse_rounded,
                        accentColor: AppModuleColors.warehouses,
                        useIntrinsicHeight: true,
                        value: _fromWarehouse,
                        options: _warehouseOptions,
                        onChanged: (value) {
                          if (value != null) _changeSource(value);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppDropdownField<String>(
                        fieldKey: const Key('designTransferToWarehouse'),
                        label: 'إلى مخزن',
                        icon: Icons.warehouse_rounded,
                        accentColor: AppModuleColors.warehouses,
                        useIntrinsicHeight: true,
                        value: _toWarehouse,
                        options: _warehouseOptions,
                        onChanged: (value) {
                          if (value != null) _changeDestination(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppDropdownField<String>(
                        fieldKey: const Key('designTransferProduct'),
                        label: 'المادة',
                        icon: Icons.inventory_2_rounded,
                        accentColor: AppModuleColors.warehouses,
                        useIntrinsicHeight: true,
                        value: _selectedProduct,
                        options: [
                          for (final item in _sourceItems)
                            AppDropdownOption(
                              value: item.id,
                              label:
                                  '${item.name} — ${AppFormatters.quantity(item.quantity)}',
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedProduct = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        fieldKey: const Key('designTransferQuantity'),
                        controller: _quantityController,
                        label: 'كمية النقل',
                        icon: Icons.numbers_rounded,
                        accentColor: AppModuleColors.warehouses,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [AppIntegerInputFormatter()],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _AvailableQuantity(
                        quantity: _selectedSourceItem.quantity,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _WarehouseStockPanel(
                  key: const Key('designTransferSourceStock'),
                  title: _warehouseLabel(_fromWarehouse),
                  items: _sourceItems,
                  selectedProduct: _selectedProduct,
                  onSelected: (value) =>
                      setState(() => _selectedProduct = value),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 88,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppModuleColors.warehouses,
                  size: AppIconSizes.xl,
                ),
              ),
              Expanded(
                child: _WarehouseStockPanel(
                  key: const Key('designTransferDestinationStock'),
                  title: _warehouseLabel(_toWarehouse),
                  items: _destinationItems,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _warehouseLabel(String value) {
    return value == 'main' ? 'المخزن الرئيسي' : 'المخزن الفرعي';
  }
}

class _WarehouseStockPanel extends StatelessWidget {
  const _WarehouseStockPanel({
    required this.title,
    required this.items,
    super.key,
    this.selectedProduct,
    this.onSelected,
  });

  final String title;
  final List<_WarehouseItem> items;
  final String? selectedProduct;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return AppDialogSection(
      title: 'مواد $title',
      icon: Icons.inventory_rounded,
      accentColor: AppModuleColors.warehouses,
      child: AppDataTable(
        height: 180,
        headerHeight: 44,
        rowHeight: 44,
        minimumColumnWidth: 112,
        accentColor: AppModuleColors.warehouses,
        columns: const [
          AppTableColumn(label: 'رمز المادة'),
          AppTableColumn(label: 'اسم المادة', flex: 1.6),
          AppTableColumn(label: 'الكمية', numeric: true),
        ],
        rows: [
          for (final item in items)
            AppTableRow(
              rowKey: Key(
                'transferStock-$title-${item.id}',
              ),
              selected: item.id == selectedProduct,
              onTap: onSelected == null
                  ? null
                  : () => onSelected!(item.id),
              cells: [
                Text(item.code),
                Text(item.name),
                Text(AppFormatters.quantity(item.quantity)),
              ],
            ),
        ],
      ),
    );
  }
}

class _AvailableQuantity extends StatelessWidget {
  const _AvailableQuantity({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: AppControlHeights.large,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'المتوفر في مخزن المصدر',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppFormatters.quantity(quantity),
            textAlign: TextAlign.center,
            style: AppTypography.fieldText.copyWith(
              color: AppModuleColors.warehouses,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class _WarehouseItem {
  const _WarehouseItem({
    required this.id,
    required this.code,
    required this.name,
    required this.quantity,
  });

  final String id;
  final String code;
  final String name;
  final int quantity;

  _WarehouseItem copyWith({required int quantity}) {
    return _WarehouseItem(
      id: id,
      code: code,
      name: name,
      quantity: quantity,
    );
  }
}
