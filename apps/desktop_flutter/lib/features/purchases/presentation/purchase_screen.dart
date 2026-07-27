import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';

class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key});

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
        child: const SizedBox.expand(),
      ),
    );
  }
}
