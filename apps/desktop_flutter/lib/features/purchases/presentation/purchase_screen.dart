import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
import 'widgets/purchase_items_table.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  late final PurchaseItemsController _itemsController;

  @override
  void initState() {
    super.initState();
    _itemsController = PurchaseItemsController();
  }

  @override
  void dispose() {
    _itemsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = Color.alphaBlend(
      AppModuleColors.purchases.withAlpha(12),
      AppColors.surface,
    );

    return AppScreenShell(
      key: const Key('purchaseScreen'),
      title: 'المشتريات',
      backgroundColor: tint,
      onBack: () => Navigator.of(context).pop(),
      body: ColoredBox(
        key: const Key('purchaseTintBackground'),
        color: tint,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PurchaseItemsTable(
            key: const Key('purchaseItemsTable'),
            controller: _itemsController,
          ),
        ),
      ),
    );
  }
}
