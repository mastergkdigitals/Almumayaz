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
    return AppScreenShell(
      key: const Key('salesScreen'),
      title: 'المبيعات',
      backgroundColor: Color.alphaBlend(
        AppModuleColors.sales.withAlpha(12),
        AppColors.surface,
      ),
      onBack: () => Navigator.of(context).pop(),
      body: Padding(
        key: const Key('salesTintBackground'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SalesItemsTable(
          key: const Key('salesItemsTable'),
          controller: _itemsController,
        ),
      ),
    );
  }
}
