import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
import 'widgets/sales_items_table.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late final SalesItemsController _itemsController;

  @override
  void initState() {
    super.initState();
    _itemsController = SalesItemsController();
  }

  @override
  void dispose() {
    _itemsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = Color.alphaBlend(
      AppModuleColors.sales.withAlpha(12),
      AppColors.surface,
    );

    return AppScreenShell(
      key: const Key('salesScreen'),
      title: 'المبيعات',
      backgroundColor: tint,
      onBack: () => Navigator.of(context).pop(),
      body: ColoredBox(
        key: const Key('salesTintBackground'),
        color: tint,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SalesItemsTable(
            key: const Key('salesItemsTable'),
            controller: _itemsController,
          ),
        ),
      ),
    );
  }
}
